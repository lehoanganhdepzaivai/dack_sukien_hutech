import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/recommendation_config.dart';
import '../data/prototype_seed.dart';
import '../models/models.dart';
import '../repositories/local_repository.dart';
import '../services/domain_exception.dart';
import '../services/event_database_helper.dart';
import '../services/local_auth_service.dart';
import '../services/recommendation_service.dart';
import '../services/registration_service.dart';
import '../services/schedule_conflict_service.dart';
import '../services/supabase_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({DateTime Function()? clock, LocalRepository? repository})
    : _clock = clock ?? DateTime.now,
      _repository = repository ?? LocalRepository();

  final DateTime Function() _clock;
  final LocalRepository _repository;
  final _auth = const LocalAuthService();
  final _registrationService = const RegistrationService();
  final _recommendations = const RecommendationService();
  final _scheduleConflicts = const ScheduleConflictService();
  Future<void> _pending = Future.value();
  String? _userId;
  List<EventModel> _events = [];
  List<UserProfile> _profiles = [];
  List<RegistrationModel> _registrations = [];
  Map<String, List<ScheduleEntry>> _schedules = {};
  Map<String, Set<String>> _favorites = {}, _viewed = {};
  Map<String, List<String>> _notifications = {};
  Map<String, int> _readNotifications = {};
  final Map<String, String> _userRoles = {};
  List<String> _categories = [...PrototypeSeed.categories];
  ThemeMode _themeMode = ThemeMode.light;
  String _search = '',
      _categoryFilter = '',
      _venueFilter = '',
      _sortOrder = 'soonest';
  String? persistenceError;
  bool _initialized = false;

  UserProfile? get profile =>
      _profiles.where((item) => item.id == _userId).firstOrNull;
  bool get isAuthenticated => profile != null;
  bool get isAdmin =>
      isAuthenticated &&
      (_auth.roleFor(_userId) == 'admin' || _userRoles[_userId] == 'admin');
  bool get isOrganizer =>
      isAuthenticated &&
      (_auth.roleFor(_userId) == 'organizer' ||
          _userRoles[_userId] == 'organizer');
  List<EventModel> get events => List.unmodifiable(
    isAdmin ? _events : _events.where((item) => item.isPublic),
  );
  List<UserProfile> get allUsers =>
      List.unmodifiable(isAdmin ? _profiles : <UserProfile>[]);
  Set<String> get favorites =>
      Set.unmodifiable(_favorites[_userId] ?? <String>{});
  List<RegistrationModel> get registrations =>
      List.unmodifiable(_registrations.where((item) => item.userId == _userId));
  List<RegistrationModel> get allRegistrations =>
      List.unmodifiable(isAdmin ? _registrations : <RegistrationModel>[]);
  List<ScheduleEntry> get schedules =>
      List.unmodifiable(_schedules[_userId] ?? <ScheduleEntry>[]);
  List<String> get notifications =>
      List.unmodifiable(_notifications[_userId] ?? <String>[]);
  int get unreadNotifications =>
      (notifications.length - (_readNotifications[_userId] ?? 0)).clamp(
        0,
        notifications.length,
      );
  List<String> get faculties => List.unmodifiable(PrototypeSeed.faculties);
  List<String> get categories => List.unmodifiable(_categories);
  List<String> get skills => List.unmodifiable(PrototypeSeed.skills);
  List<String> get venues => List.unmodifiable(PrototypeSeed.venues);
  Map<String, List<String>> get careerSkills =>
      RecommendationConfig.careerSkills;
  ThemeMode get themeMode => _themeMode;
  String get search => _search;
  String get categoryFilter => _categoryFilter;
  String get venueFilter => _venueFilter;
  String get sortOrder => _sortOrder;
  bool get isCloudBackend =>
      SupabaseService.instance.isConfigured &&
      SupabaseService.instance.isInitialized;
  String get backendStatusText => isCloudBackend
      ? 'Đã kết nối Supabase Cloud'
      : 'Lưu trữ cục bộ thiết bị';

  List<EventModel> get visibleEvents {
    final query = _search.trim().toLowerCase();
    final result = events
        .where(
          (item) =>
              (query.isEmpty ||
                  '${item.title} ${item.subtitle} ${item.organization} ${item.skills.join(' ')}'
                      .toLowerCase()
                      .contains(query)) &&
              (_categoryFilter.isEmpty ||
                  _categoryFilter == 'Tất cả' ||
                  item.category == _categoryFilter) &&
              (_venueFilter.isEmpty ||
                  _venueFilter == 'Tất cả' ||
                  item.venue == _venueFilter),
        )
        .toList();
    switch (_sortOrder) {
      case 'recommended':
      case 'relevance':
        result.sort(
          (a, b) => recommendation(b).score.compareTo(recommendation(a).score),
        );
      case 'latest':
        result.sort((a, b) => b.start.compareTo(a.start));
      case 'title':
        result.sort((a, b) => a.title.compareTo(b.title));
      default:
        result.sort((a, b) => a.start.compareTo(b.start));
    }
    return result;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _seed();
    Map<String, dynamic>? saved;
    try {
      saved = await _repository.read();
    } on FormatException {
      await _repository.preserveRecovery();
      persistenceError = 'Dữ liệu đã lưu không đọc được. Đã giữ bản phục hồi và mở dữ liệu ban đầu.';
      _initialized = true;
      notifyListeners();
      return;
    }
    if (saved != null) {
      try {
        final savedVersion = (saved['version'] as num?)?.toInt() ?? 1;
        _restore(saved);
        if (savedVersion < 2) {
          _migrateToVersion2();
          await _repository.save(_toJson());
        }
      } catch (_) {
        await _repository.preserveRecovery();
        _seed();
        persistenceError = 'Dữ liệu đã lưu không đọc được. Đã giữ bản phục hồi và mở dữ liệu ban đầu.';
      }
    } else {
      try {
        final dbEvents = await EventDatabaseHelper.instance.getEvents();
        if (dbEvents.isNotEmpty) {
          _events = dbEvents;
        }
      } catch (_) {}
      await _repository.save(_toJson());
    }
    _initialized = true;
    notifyListeners();
  }

  void _seed() {
    final now = _clock();
    _events = PrototypeSeed.events(now);
    _profiles = PrototypeSeed.profiles();
    _schedules = {'student-ha': PrototypeSeed.schedules(now), 'admin': []};
    _favorites = {
      'student-ha': {'flutter-lab', 'music-night'},
      'admin': {},
    };
    _viewed = {};
    _registrations = [
      RegistrationModel(
        id: 'registration-ha-teamwork',
        eventId: 'teamwork-studio',
        userId: 'student-ha',
        status: RegistrationStatus.confirmed,
        createdAt: now,
      ),
    ];
    _notifications = {
      'student-ha': [
        'Bạn đã đăng ký “Làm việc nhóm: cùng nhau tạo khác biệt”.',
        'Hồ sơ đã có mục tiêu Flutter Developer. Bạn có thể cập nhật sở thích và lịch học.',
      ],
      'admin': [],
    };
    _readNotifications = {};
    _categories = [...PrototypeSeed.categories];
    _userId = null;
    _themeMode = ThemeMode.light;
    _search = '';
    _categoryFilter = '';
    _venueFilter = '';
    _sortOrder = 'soonest';
  }

  void _migrateToVersion2() {
    final studentSchedules = _schedules.putIfAbsent('student-ha', () => []);
    for (final sample in PrototypeSeed.schedules(_clock())) {
      final index = studentSchedules.indexWhere((item) => item.id == sample.id);
      if (index < 0) {
        studentSchedules.add(sample);
      } else {
        studentSchedules[index] = sample;
      }
    }
  }

  EventModel? eventById(String id) {
    final event = _events.where((item) => item.id == id).firstOrNull;
    if (event == null) return null;
    final hasHistory =
        event.status == EventStatus.archived &&
        registrations.any((item) => item.eventId == id);
    return isAdmin || event.isPublic || hasHistory ? event : null;
  }

  RegistrationModel? registrationFor(String eventId) {
    final matches = registrations
        .where((item) => item.eventId == eventId)
        .toList();
    return matches
            .where((item) => item.status != RegistrationStatus.canceled)
            .firstOrNull ??
        matches.lastOrNull;
  }

  int registrationCount(String eventId) => _registrations
      .where((item) => item.eventId == eventId && item.occupiesSeat)
      .length;
  int confirmedCount(String eventId) => registrationCount(eventId);
  int waitlistCount(String eventId) => _registrations
      .where(
        (item) =>
            item.eventId == eventId &&
            item.status == RegistrationStatus.waitlisted,
      )
      .length;

  Recommendation recommendation(EventModel event) => _recommendations.evaluate(
    event,
    profile: profile,
    schedules: schedules,
    events: events,
    registrations: registrations,
    favorites: favorites,
    viewedEvents: _viewed[_userId] ?? {},
  );

  List<String> registrationConflicts(String eventId) {
    if (!isAuthenticated || isAdmin || isOrganizer) return const [];
    final event = eventById(eventId);
    if (event == null) return const [];
    return List.unmodifiable(_registrationConflictsFor(event));
  }

  Future<void> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();

    // 1. Thử xác thực qua Supabase nếu đã cấu hình
    if (SupabaseService.instance.isConfigured &&
        SupabaseService.instance.isInitialized) {
      try {
        final res = await SupabaseService.instance.signIn(
          email: normalized,
          password: password,
        );
        if (res.user != null) {
          final roles = await SupabaseService.instance.fetchCurrentUserRoles();
          final detectedRole = roles.contains(UserRole.admin)
              ? 'admin'
              : roles.contains(UserRole.organizer)
                  ? 'organizer'
                  : 'student';
          _userRoles[res.user!.id] = detectedRole;
          await _commit(() {
            _userId = res.user!.id;
            if (!_profiles.any((p) => p.id == _userId)) {
              _profiles = [
                ..._profiles,
                UserProfile(
                  id: _userId!,
                  name: res.user!.userMetadata?['full_name'] as String? ??
                      normalized.split('@').first,
                  email: normalized,
                  studentId: '',
                  faculty: 'Công nghệ thông tin',
                  major: 'Kỹ thuật phần mềm',
                  cohort: '2023 - 2027',
                  phone: '',
                  careerGoal: 'Software Engineer',
                  interests: [],
                  skills: [],
                ),
              ];
            }
          });
          return;
        }
      } catch (e) {
        if (normalized != 'ha@gmail.com' && normalized != 'admin@gmail.com') {
          rethrow;
        }
      }
    }

    // 2. Kiểm tra tài khoản sinh viên đăng ký cục bộ
    final localMatch = _profiles.where((p) => p.email.toLowerCase() == normalized).firstOrNull;
    if (localMatch != null && localMatch.id != 'student-ha' && localMatch.id != 'admin') {
      if (password.length < 6) {
        throw const DomainException('Mật khẩu tối thiểu 6 ký tự.');
      }
      await _commit(() {
        _userId = localMatch.id;
      });
      return;
    }

    // 3. Tài khoản định nghĩa sẵn theo yêu cầu đề tài (ha@gmail.com / admin@gmail.com)
    final id = _auth.signIn(email, password);
    await _commit(() {
      _userId = id;
    });
  }

  Future<void> registerLocalStudent({
    required String name,
    required String email,
    required String studentId,
    required String password,
  }) => _commit(() {
    final lowerEmail = email.trim().toLowerCase();
    if (_profiles.any((p) => p.email.toLowerCase() == lowerEmail)) {
      throw const DomainException('Địa chỉ email này đã được sử dụng.');
    }
    final newId = 'student_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = UserProfile(
      id: newId,
      name: name.trim(),
      email: lowerEmail,
      studentId: studentId.trim(),
      faculty: 'Công nghệ thông tin',
      major: 'Kỹ thuật phần mềm',
      cohort: '2023 - 2027',
      phone: '',
      careerGoal: 'Software Engineer',
      interests: [],
      skills: [],
    );
    _profiles = [..._profiles, newProfile];
    _schedules[newId] = [];
    _favorites[newId] = {};
    _notifications[newId] = [
      'Chào mừng bạn đến với Cổng sự kiện sinh viên HUTECH!',
    ];
  });

  Future<void> logout() => _commit(() {
    _userId = null;
  });

  Future<void> updateProfile(UserProfile value) => _commit(() {
    _requireLogin();
    if (value.id != _userId) {
      throw const DomainException('Bạn chỉ được cập nhật hồ sơ của mình.');
    }
    if (value.name.trim().isEmpty) {
      throw const DomainException('Vui lòng nhập họ và tên.');
    }
    if (value.email.trim().toLowerCase() != profile!.email.toLowerCase()) {
      throw const DomainException(
        'Email đăng nhập chưa thể thay đổi trong phiên bản hiện tại.',
      );
    }
    if (value.availableStartMinutes < 0 ||
        value.availableEndMinutes > 1440 ||
        value.availableStartMinutes >= value.availableEndMinutes) {
      throw const DomainException('Khung giờ cá nhân chưa hợp lệ.');
    }
    _profiles = _profiles
        .map(
          (item) => item.id == value.id
              ? value.copyWith(name: value.name.trim())
              : item,
        )
        .toList();
  });

  Future<void> setThemeMode(ThemeMode value) => _commit(() {
    _themeMode = value;
  });

  Future<void> toggleFavorite(String eventId) => _commit(() {
    _requireLogin();
    if (eventById(eventId) == null) {
      throw const DomainException(
        'Sự kiện không tồn tại hoặc không được công bố.',
      );
    }
    final set = _favorites.putIfAbsent(_userId!, () => <String>{});
    if (!set.remove(eventId)) set.add(eventId);
  });

  Future<void> recordEventView(String eventId) => _commit(() {
    if (!isAuthenticated || eventById(eventId) == null) return;
    _viewed.putIfAbsent(_userId!, () => <String>{}).add(eventId);
  });

  Future<String> registerEvent(
    String eventId, {
    bool continueOnConflict = false,
  }) => _commit(() {
    _requireStudent();
    final event = eventById(eventId);
    if (event == null) throw const DomainException('Không tìm thấy sự kiện.');
    final conflicts = _registrationConflictsFor(event);
    if (conflicts.isNotEmpty && !continueOnConflict) {
      throw const DomainException(
        'Lịch của bạn đang bị trùng. Hãy kiểm tra cảnh báo trước khi tiếp tục đăng ký.',
      );
    }
    final change = _registrationService.register(
      event: event,
      userId: _userId!,
      registrations: _registrations,
      now: _clock(),
      id: _newId('registration'),
    );
    _registrations = change.registrations;
    _replaceEvent(event.copyWith(status: change.eventStatus));
    _notifyPromotions(event, change.promotions);
    final feedback = change.registration.status == RegistrationStatus.waitlisted
        ? 'Bạn đã vào danh sách chờ. Hệ thống sẽ thông báo khi có chỗ.'
        : 'Đăng ký thành công. Sự kiện đã được thêm vào lịch của bạn.';
    _notify(_userId!, '${event.title}: $feedback');
    return feedback;
  });

  List<String> _registrationConflictsFor(EventModel event) {
    final registeredIds = _registrations
        .where(
          (item) =>
              item.userId == _userId &&
              item.status != RegistrationStatus.canceled,
        )
        .map((item) => item.eventId)
        .toSet();
    return _scheduleConflicts.conflicts(
      event,
      schedules: _schedules[_userId] ?? const [],
      registeredEvents: _events
          .where((item) => registeredIds.contains(item.id))
          .toList(),
      profile: profile,
    );
  }

  Future<String> cancelRegistration(String eventId) => _commit(() {
    _requireStudent();
    final event = _events.where((item) => item.id == eventId).firstOrNull;
    if (event == null) throw const DomainException('Không tìm thấy sự kiện.');
    final change = _registrationService.cancel(
      event: event,
      userId: _userId!,
      registrations: _registrations,
      now: _clock(),
    );
    _registrations = change.registrations;
    _replaceEvent(event.copyWith(status: change.eventStatus));
    _notify(_userId!, 'Bạn đã hủy đăng ký “${event.title}”.');
    _notifyPromotions(event, change.promotions);
    return 'Đã hủy đăng ký sự kiện.';
  });

  Future<void> saveSchedule(ScheduleEntry value) => _commit(() {
    _requireStudent();
    if (value.title.trim().isEmpty ||
        value.weekday < 1 ||
        value.weekday > 7 ||
        value.startMinutes < 0 ||
        value.endMinutes > 1440 ||
        value.startMinutes >= value.endMinutes ||
        !venues.contains(value.venue)) {
      throw const DomainException(
        'Vui lòng kiểm tra tên môn học, ngày, giờ và cơ sở.',
      );
    }
    if (value.validFrom != null &&
        value.validUntil != null &&
        value.validFrom!.isAfter(value.validUntil!)) {
      throw const DomainException(
        'Ngày kết thúc học kỳ phải sau ngày bắt đầu.',
      );
    }
    final entries = _schedules.putIfAbsent(_userId!, () => []);
    final id = value.id.isEmpty ? _newId('schedule') : value.id;
    final index = entries.indexWhere((item) => item.id == id);
    final entry = value.copyWith(id: id, title: value.title.trim());
    if (index < 0) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
  });

  Future<void> deleteSchedule(String id) => _commit(() {
    _requireStudent();
    _schedules[_userId]?.removeWhere((item) => item.id == id);
  });

  Future<void> saveEvent(EventModel value) => _commit(() {
    _requireAdmin();
    _validateEvent(value);
    var event = value.id.isEmpty ? value.copyWith(id: _newId('event')) : value;
    final old = _events.where((item) => item.id == event.id).firstOrNull;
    if (registrationCount(event.id) > event.capacity) {
      throw const DomainException(
        'Sức chứa không được nhỏ hơn số người đã đăng ký.',
      );
    }
    event = _reconcileEventSeats(event);
    if (old == null) {
      _events.add(event);
    } else {
      _replaceEvent(event);
    }
    if (old != null &&
        event.status == EventStatus.canceled &&
        old.status != EventStatus.canceled) {
      _notifyCancellation(event);
    }
  });

  Future<void> deleteEvent(String id) => _commit(() {
    _requireAdmin();
    final event = _events.where((item) => item.id == id).firstOrNull;
    if (event == null) throw const DomainException('Không tìm thấy sự kiện.');
    final hasRegistrations = _registrations.any((item) => item.eventId == id);
    final status = hasRegistrations && event.status != EventStatus.completed
        ? EventStatus.canceled
        : EventStatus.archived;
    _replaceEvent(event.copyWith(status: status));
    if (status == EventStatus.canceled &&
        event.status != EventStatus.canceled) {
      _notifyCancellation(event);
    }
  });

  Future<void> setEventStatus(String id, EventStatus status) => _commit(() {
    _requireAdmin();
    final event = _events.where((item) => item.id == id).firstOrNull;
    if (event == null) throw const DomainException('Không tìm thấy sự kiện.');
    var updated = event.copyWith(status: status);
    _validateEvent(updated);
    updated = _reconcileEventSeats(updated);
    _replaceEvent(updated);
    if (status == EventStatus.canceled &&
        event.status != EventStatus.canceled) {
      _notifyCancellation(updated);
    }
  });

  Future<void> addCategory(String value) => _commit(() {
    _requireAdmin();
    final name = value.trim();
    if (name.isEmpty) {
      throw const DomainException('Vui lòng nhập tên danh mục.');
    }
    if (_categories.any((item) => item.toLowerCase() == name.toLowerCase())) {
      throw const DomainException('Danh mục đã tồn tại.');
    }
    _categories.add(name);
  });

  Future<void> removeCategory(String value) => _commit(() {
    _requireAdmin();
    if (_events.any((item) => item.category == value)) {
      throw const DomainException(
        'Danh mục đang được sử dụng bởi sự kiện. Hãy đổi danh mục của sự kiện trước.',
      );
    }
    _categories.remove(value);
    if (_categoryFilter == value) _categoryFilter = '';
  });

  void setFilters({
    String? search,
    String? category,
    String? venue,
    String? sort,
  }) {
    if (search != null) _search = search;
    if (category != null) {
      _categoryFilter = category == 'Tất cả' ? '' : category;
    }
    if (venue != null) _venueFilter = venue == 'Tất cả' ? '' : venue;
    if (sort != null) _sortOrder = sort;
    notifyListeners();
    unawaited(
      _commit(() {}).catchError((Object error) {
        persistenceError = error.toString();
        notifyListeners();
      }),
    );
  }

  Future<void> markNotificationsRead() => _commit(() {
    _requireLogin();
    _readNotifications[_userId!] = notifications.length;
  });

  void _validateEvent(EventModel event) {
    if (event.title.trim().isEmpty ||
        event.subtitle.trim().isEmpty ||
        event.description.trim().isEmpty ||
        event.organization.trim().isEmpty) {
      throw const DomainException(
        'Vui lòng nhập tên, mô tả và đơn vị tổ chức.',
      );
    }
    if (!event.start.isBefore(event.end)) {
      throw const DomainException('Giờ kết thúc phải sau giờ bắt đầu.');
    }
    if (event.deadline.isAfter(event.start)) {
      throw const DomainException(
        'Hạn đăng ký phải trước hoặc bằng thời gian bắt đầu.',
      );
    }
    if (event.isRegistrationOpen && !_clock().isBefore(event.deadline)) {
      throw const DomainException(
        'Vui lòng cập nhật hạn đăng ký trước khi mở lại sự kiện.',
      );
    }
    if (event.capacity <= 0) {
      throw const DomainException('Sức chứa phải lớn hơn 0.');
    }
    if (!_categories.contains(event.category) ||
        !venues.contains(event.venue)) {
      throw const DomainException('Danh mục hoặc địa điểm chưa hợp lệ.');
    }
  }

  void _notifyCancellation(EventModel event) {
    final users = _registrations
        .where(
          (item) =>
              item.eventId == event.id &&
              item.status != RegistrationStatus.canceled,
        )
        .map((item) => item.userId)
        .toSet();
    for (final user in users) {
      _notify(user, 'Sự kiện “${event.title}” đã bị hủy bởi quản trị viên.');
    }
  }

  EventModel _reconcileEventSeats(EventModel event) {
    final change = _registrationService.reconcileWaitlist(
      event: event,
      registrations: _registrations,
      now: _clock(),
    );
    _registrations = change.registrations;
    _notifyPromotions(event, change.promotions);
    return event.copyWith(status: change.eventStatus);
  }

  void _notifyPromotions(EventModel event, List<RegistrationModel> promotions) {
    for (final registration in promotions) {
      _notify(
        registration.userId,
        'Đã có chỗ cho bạn tại “${event.title}”. Đăng ký đã được xác nhận.',
      );
    }
  }

  void _replaceEvent(EventModel event) {
    _events = _events
        .map((item) => item.id == event.id ? event : item)
        .toList();
  }

  void _notify(String user, String text) {
    _notifications.putIfAbsent(user, () => []).add(text);
  }

  int _sequence = 0;
  String _newId(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}-${_sequence++}';
  void _requireLogin() {
    if (!isAuthenticated) {
      throw const DomainException('Vui lòng đăng nhập để tiếp tục.');
    }
  }

  void _requireStudent() {
    _requireLogin();
    if (_auth.roleFor(_userId) != 'student') {
      throw const DomainException(
        'Chức năng này dành cho tài khoản sinh viên.',
      );
    }
  }

  void _requireAdmin() {
    if (!isAdmin) throw const DomainException('Bạn không có quyền quản trị.');
  }

  Future<T> _commit<T>(T Function() change) {
    final operation = _pending.then((_) async {
      final before = _toJson();
      try {
        final value = change();
        await _repository.save(_toJson());
        try {
          await EventDatabaseHelper.instance.syncEvents(_events);
        } catch (_) {}
        persistenceError = null;
        notifyListeners();
        return value;
      } catch (_) {
        _restore(before);
        notifyListeners();
        rethrow;
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  String exportDatabaseJson() => jsonEncode(_toJson());

  Future<void> importDatabaseJson(String raw) => _commit(() {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu CSDL không hợp lệ.');
    }
    _restore(decoded);
  });

  Map<String, dynamic> _toJson() => {
    'version': 2,
    'userId': _userId,
    'events': _events.map((item) => item.toJson()).toList(),
    'profiles': _profiles.map((item) => item.toJson()).toList(),
    'registrations': _registrations.map((item) => item.toJson()).toList(),
    'schedules': _schedules.map(
      (key, value) =>
          MapEntry(key, value.map((item) => item.toJson()).toList()),
    ),
    'favorites': _favorites.map((key, value) => MapEntry(key, value.toList())),
    'viewed': _viewed.map((key, value) => MapEntry(key, value.toList())),
    'notifications': _notifications.map(
      (key, value) => MapEntry(key, [...value]),
    ),
    'readNotifications': {..._readNotifications},
    'categories': [..._categories],
    'theme': _themeMode.name,
    'search': _search,
    'categoryFilter': _categoryFilter,
    'venueFilter': _venueFilter,
    'sortOrder': _sortOrder,
  };

  void _restore(Map<String, dynamic> data) {
    _userId = data['userId'] as String?;
    _events = (data['events'] as List)
        .map(
          (item) => EventModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    _profiles = (data['profiles'] as List)
        .map(
          (item) =>
              UserProfile.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    _registrations = (data['registrations'] as List)
        .map(
          (item) => RegistrationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    _schedules = (data['schedules'] as Map).map(
      (key, value) => MapEntry(
        key as String,
        (value as List)
            .map(
              (item) => ScheduleEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      ),
    );
    _favorites = (data['favorites'] as Map).map(
      (key, value) => MapEntry(key as String, Set<String>.from(value as List)),
    );
    _viewed = (data['viewed'] as Map? ?? {}).map(
      (key, value) => MapEntry(key as String, Set<String>.from(value as List)),
    );
    _notifications = (data['notifications'] as Map).map(
      (key, value) => MapEntry(key as String, List<String>.from(value as List)),
    );
    _readNotifications = (data['readNotifications'] as Map).map(
      (key, value) => MapEntry(key as String, (value as num).toInt()),
    );
    _categories = List<String>.from(data['categories'] as List);
    _themeMode = ThemeMode.values.byName(data['theme'] as String? ?? 'light');
    _search = data['search'] as String? ?? '';
    _categoryFilter = data['categoryFilter'] as String? ?? '';
    _venueFilter = data['venueFilter'] as String? ?? '';
    if (_categoryFilter == 'Tất cả') _categoryFilter = '';
    if (_venueFilter == 'Tất cả') _venueFilter = '';
    _sortOrder = data['sortOrder'] as String? ?? 'soonest';
    if (_auth.roleFor(_userId) == 'guest') _userId = null;
  }
}
