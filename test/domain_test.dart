import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dack/config/recommendation_config.dart';
import 'package:dack/data/prototype_seed.dart';
import 'package:dack/models/models.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/file_local_repository_backend.dart';
import 'package:dack/repositories/indexed_db_local_repository_backend.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:dack/services/domain_exception.dart';
import 'package:dack/services/recommendation_service.dart';
import 'package:dack/services/registration_service.dart';
import 'package:dack/services/schedule_conflict_service.dart';

final now = DateTime(2026, 10, 15, 9);
EventModel event({int capacity = 2}) => EventModel(
  id: 'event',
  title: 'Flutter workshop',
  subtitle: 'Thực hành',
  description: 'Nội dung chi tiết',
  category: 'Học thuật',
  organization: 'Nhóm tổ chức',
  venue: 'HUTECH khu E',
  image: '',
  start: DateTime(2026, 10, 16, 10),
  end: DateTime(2026, 10, 16, 12),
  deadline: DateTime(2026, 10, 16, 9),
  capacity: capacity,
  status: EventStatus.registrationOpen,
  skills: ['Flutter', 'REST API'],
);

RegistrationModel registration(
  String user, {
  String id = 'r',
  RegistrationStatus status = RegistrationStatus.confirmed,
  DateTime? at,
}) => RegistrationModel(
  id: id,
  userId: user,
  eventId: 'event',
  status: status,
  createdAt: at ?? now,
);

class MemoryRepository extends LocalRepository {
  Map<String, dynamic>? data;
  bool failNext = false;
  @override
  Future<void> initialize() async {}
  @override
  Future<Map<String, dynamic>?> read() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (failNext) {
      failNext = false;
      throw StateError('storage full');
    }
    data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'malformed local storage recovers without discarding its original bytes',
    () async {
      const corrupt = '{not-valid-json';
      SharedPreferences.setMockInitialValues({
        LocalRepository.dataKey: corrupt,
      });
      final backend = IndexedDbLocalRepositoryBackend(
        factory: idbFactoryMemory,
        databaseName: 'malformed-recovery-test',
      );
      addTearDown(
        () => idbFactoryMemory.deleteDatabase('malformed-recovery-test'),
      );
      final repository = LocalRepository(backend: backend);
      final store = AppStore(clock: () => now, repository: repository);
      await store.initialize();
      expect(store.events.length, 6);
      expect(store.persistenceError, isNotNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LocalRepository.dataKey), corrupt);
      expect(preferences.getString(LocalRepository.recoveryKey), corrupt);
      await store.login('HA@gmail.com', '123');
      expect(preferences.getString(LocalRepository.recoveryKey), corrupt);
      expect(await repository.read(), isA<Map>());
      expect(await backend.read(LocalRepository.recoveryKey), corrupt);
      store.dispose();
    },
  );

  test(
    'valid JSON with an incompatible schema also preserves recovery data',
    () async {
      const corrupt = '{"version":1,"events":[{"id":"incomplete"}]}';
      SharedPreferences.setMockInitialValues({
        LocalRepository.dataKey: corrupt,
      });
      final backend = IndexedDbLocalRepositoryBackend(
        factory: idbFactoryMemory,
        databaseName: 'incompatible-recovery-test',
      );
      addTearDown(
        () => idbFactoryMemory.deleteDatabase('incompatible-recovery-test'),
      );
      final store = AppStore(
        clock: () => now,
        repository: LocalRepository(backend: backend),
      );
      await store.initialize();
      expect(store.events.length, 6);
      expect(store.persistenceError, isNotNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LocalRepository.dataKey), corrupt);
      expect(preferences.getString(LocalRepository.recoveryKey), corrupt);
      expect(await backend.read(LocalRepository.recoveryKey), corrupt);
      store.dispose();
    },
  );

  group('Durable local repository', () {
    test('uploaded images are kept out of the small legacy preferences store', () async {
      const databaseName = 'durable-storage-only-test';
      addTearDown(() => idbFactoryMemory.deleteDatabase(databaseName));
      final backend = IndexedDbLocalRepositoryBackend(
        factory: idbFactoryMemory,
        databaseName: databaseName,
      );
      final repository = LocalRepository(backend: backend);
      final image =
          'data:image/png;base64,${base64Encode(List<int>.generate(512 * 1024, (index) => index % 251))}';

      await repository.save({
        'version': 2,
        'events': [
          event().copyWith(id: 'large-image-event', image: image).toJson(),
        ],
      });

      final durableRaw = await backend.read(LocalRepository.dataKey);
      expect(durableRaw, contains('large-image-event'));
      expect(durableRaw, contains(image));
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(LocalRepository.dataKey), isNull);
    });

    test('admin event and embedded image survive a native repository restart', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'hutech-events-persistence-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      Future<Directory> directoryProvider() async => temporaryDirectory;
      final image =
          'data:image/png;base64,${base64Encode(List<int>.generate(512 * 1024, (index) => index % 251))}';

      final firstStore = AppStore(
        clock: () => now,
        repository: LocalRepository(
          backend: FileLocalRepositoryBackend(
            directoryProvider: directoryProvider,
          ),
        ),
      );
      await firstStore.initialize();
      await firstStore.login('admin@gmail.com', '123');
      await firstStore.saveEvent(
        event().copyWith(
          id: 'admin-uploaded-event',
          title: 'Sự kiện có ảnh tải lên',
          image: image,
          featured: true,
        ),
      );
      firstStore.dispose();

      final restartedStore = AppStore(
        clock: () => now,
        repository: LocalRepository(
          backend: FileLocalRepositoryBackend(
            directoryProvider: directoryProvider,
          ),
        ),
      );
      await restartedStore.initialize();
      await restartedStore.login('admin@gmail.com', '123');

      final restored = restartedStore.eventById('admin-uploaded-event');
      expect(restored?.title, 'Sự kiện có ảnh tải lên');
      expect(restored?.image, image);
      expect(restored?.featured, isTrue);
      restartedStore.dispose();
    });

    test('web IndexedDB data survives repository recreation', () async {
      const databaseName = 'indexed-db-recreation-test';
      addTearDown(() => idbFactoryMemory.deleteDatabase(databaseName));
      const image = 'data:image/png;base64,aHV0ZWNoLWV2ZW50LWltYWdl';
      final data = {
        'version': 2,
        'events': [
          event().copyWith(id: 'indexed-event', image: image).toJson(),
        ],
      };

      final first = LocalRepository(
        backend: IndexedDbLocalRepositoryBackend(
          factory: idbFactoryMemory,
          databaseName: databaseName,
        ),
      );
      await first.save(data);
      final recreated = LocalRepository(
        backend: IndexedDbLocalRepositoryBackend(
          factory: idbFactoryMemory,
          databaseName: databaseName,
        ),
      );

      final restored = await recreated.read();
      final restoredEvent = EventModel.fromJson(
        Map<String, dynamic>.from((restored!['events'] as List).single as Map),
      );
      expect(restoredEvent.id, 'indexed-event');
      expect(restoredEvent.image, image);
    });

    test('admin uploaded public event stays visible to student and both roles after web restart', () async {
      const databaseName = 'indexed-db-cross-role-event-test';
      addTearDown(() => idbFactoryMemory.deleteDatabase(databaseName));
      final image =
          'data:image/png;base64,${base64Encode(List<int>.generate(128 * 1024, (index) => index % 251))}';
      final uploadedEvent = event().copyWith(
        id: 'admin-public-upload',
        title: 'Sự kiện công khai do admin thêm',
        image: image,
        status: EventStatus.registrationOpen,
        featured: true,
      );
      void expectUploadedEventVisible(AppStore store) {
        final visible = store.eventById(uploadedEvent.id);
        expect(store.events.map((item) => item.id), contains(uploadedEvent.id));
        expect(visible?.title, uploadedEvent.title);
        expect(visible?.image, image);
        expect(visible?.status, EventStatus.registrationOpen);
        expect(visible?.featured, isTrue);
        expect(visible?.isPublic, isTrue);
      }

      final firstStore = AppStore(
        clock: () => now,
        repository: LocalRepository(
          backend: IndexedDbLocalRepositoryBackend(
            factory: idbFactoryMemory,
            databaseName: databaseName,
          ),
        ),
      );
      await firstStore.initialize();
      await firstStore.login('admin@gmail.com', '123');
      await firstStore.saveEvent(uploadedEvent);

      expect(firstStore.isAdmin, isTrue);
      expectUploadedEventVisible(firstStore);

      await firstStore.logout();
      await firstStore.login('HA@gmail.com', '123');
      expect(firstStore.isAdmin, isFalse);
      expectUploadedEventVisible(firstStore);
      firstStore.dispose();

      // A new repository and store represent closing and reopening the web app.
      final reopenedStore = AppStore(
        clock: () => now,
        repository: LocalRepository(
          backend: IndexedDbLocalRepositoryBackend(
            factory: idbFactoryMemory,
            databaseName: databaseName,
          ),
        ),
      );
      await reopenedStore.initialize();

      expect(reopenedStore.profile?.email, 'HA@gmail.com');
      expectUploadedEventVisible(reopenedStore);

      await reopenedStore.logout();
      await reopenedStore.login('admin@gmail.com', '123');
      expect(reopenedStore.isAdmin, isTrue);
      expectUploadedEventVisible(reopenedStore);

      await reopenedStore.logout();
      await reopenedStore.login('HA@gmail.com', '123');
      expectUploadedEventVisible(reopenedStore);
      reopenedStore.dispose();
    });

    test('legacy SharedPreferences data migrates to durable storage', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'hutech-events-migration-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      Future<Directory> directoryProvider() async => temporaryDirectory;
      const image = 'data:image/jpeg;base64,bGVnYWN5LWltYWdl';
      final legacyData = {
        'version': 2,
        'events': [event().copyWith(id: 'legacy-event', image: image).toJson()],
      };
      SharedPreferences.setMockInitialValues({
        LocalRepository.dataKey: jsonEncode(legacyData),
      });

      final migratingRepository = LocalRepository(
        backend: FileLocalRepositoryBackend(
          directoryProvider: directoryProvider,
        ),
      );
      expect((await migratingRepository.read())?['events'], isNotEmpty);

      // A fresh process no longer needs the legacy preferences value.
      SharedPreferences.setMockInitialValues({});
      final restartedRepository = LocalRepository(
        backend: FileLocalRepositoryBackend(
          directoryProvider: directoryProvider,
        ),
      );
      final migrated = await restartedRepository.read();
      final restoredEvent = EventModel.fromJson(
        Map<String, dynamic>.from((migrated!['events'] as List).single as Map),
      );
      expect(restoredEvent.id, 'legacy-event');
      expect(restoredEvent.image, image);
    });
  });

  group('Registration rules', () {
    const service = RegistrationService();
    test('a valid first registration takes a seat', () {
      final result = service.register(
        event: event(),
        userId: 'a',
        registrations: [],
        now: now,
        id: 'a',
      );
      expect(result.registration.status, RegistrationStatus.confirmed);
      expect(result.registrations.length, 1);
      expect(result.eventStatus, EventStatus.registrationOpen);
    });
    test(
      'duplicate confirmed and waitlisted registrations are both rejected',
      () {
        for (final status in [
          RegistrationStatus.confirmed,
          RegistrationStatus.waitlisted,
        ]) {
          expect(
            () => service.register(
              event: event(),
              userId: 'a',
              registrations: [registration('a', status: status)],
              now: now,
              id: 'b',
            ),
            throwsA(isA<DomainException>()),
          );
        }
      },
    );
    test('the deadline is exclusive and elapsed dates are rejected', () {
      for (final time in [
        event().deadline,
        event().deadline.add(const Duration(seconds: 1)),
      ]) {
        expect(
          () => service.register(
            event: event(),
            userId: 'a',
            registrations: [],
            now: time,
            id: 'a',
          ),
          throwsA(isA<DomainException>()),
        );
      }
    });
    test(
      'private, closed, canceled and completed events reject registrations',
      () {
        for (final status in [
          EventStatus.draft,
          EventStatus.pending,
          EventStatus.published,
          EventStatus.registrationClosed,
          EventStatus.ongoing,
          EventStatus.completed,
          EventStatus.canceled,
          EventStatus.archived,
        ]) {
          expect(
            () => service.register(
              event: event().copyWith(status: status),
              userId: 'a',
              registrations: [],
              now: now,
              id: 'a',
            ),
            throwsA(isA<DomainException>()),
          );
        }
      },
    );
    test('capacity marks event full and next registration enters waitlist', () {
      final first = service.register(
        event: event(capacity: 1),
        userId: 'a',
        registrations: [],
        now: now,
        id: 'a',
      );
      expect(first.eventStatus, EventStatus.full);
      final second = service.register(
        event: event(capacity: 1).copyWith(status: first.eventStatus),
        userId: 'b',
        registrations: first.registrations,
        now: now,
        id: 'b',
      );
      expect(second.registration.status, RegistrationStatus.waitlisted);
      expect(second.registrations.where((item) => item.occupiesSeat).length, 1);
    });
    test(
      'new registrations cannot bypass existing waiters after capacity grows',
      () {
        final result = service.register(
          event: event(capacity: 2),
          userId: 'newcomer',
          registrations: [
            registration('owner', id: 'owner'),
            registration(
              'waiter',
              id: 'waiter',
              status: RegistrationStatus.waitlisted,
            ),
          ],
          now: now.add(const Duration(hours: 1)),
          id: 'newcomer',
        );
        expect(result.promotions.map((item) => item.userId), ['waiter']);
        expect(result.registration.status, RegistrationStatus.waitlisted);
        expect(result.eventStatus, EventStatus.full);
      },
    );
    test('additional seats promote the complete queue in FIFO order up to capacity', () {
      final result = service.reconcileWaitlist(
        event: event(capacity: 3),
        registrations: [
          registration('owner', id: 'owner'),
          registration(
            'later',
            id: 'later',
            status: RegistrationStatus.waitlisted,
            at: now.add(const Duration(minutes: 1)),
          ),
          registration(
            'first',
            id: 'first',
            status: RegistrationStatus.waitlisted,
          ),
          registration(
            'second',
            id: 'second',
            status: RegistrationStatus.waitlisted,
          ),
        ],
        now: now.add(const Duration(hours: 1)),
      );
      expect(result.promotions.map((item) => item.userId), ['first', 'second']);
      expect(
        result.registrations.firstWhere((item) => item.id == 'later').status,
        RegistrationStatus.waitlisted,
      );
      expect(result.registrations.where((item) => item.occupiesSeat).length, 3);
      expect(result.eventStatus, EventStatus.full);
    });
    test(
      'queue reconciliation does not confirm unpublished or terminal events',
      () {
        for (final status in [
          EventStatus.draft,
          EventStatus.pending,
          EventStatus.published,
          EventStatus.ongoing,
          EventStatus.completed,
          EventStatus.canceled,
          EventStatus.archived,
        ]) {
          final result = service.reconcileWaitlist(
            event: event().copyWith(status: status),
            registrations: [
              registration('waiter', status: RegistrationStatus.waitlisted),
            ],
            now: now,
          );
          expect(result.promotions, isEmpty, reason: status.name);
          expect(result.eventStatus, status);
        }
        expect(
          service
              .reconcileWaitlist(
                event: event(),
                registrations: [
                  registration('waiter', status: RegistrationStatus.waitlisted),
                ],
                now: event().start,
              )
              .promotions,
          isEmpty,
        );
      },
    );
    test('cancellation preserves history and promotes earliest waiter', () {
      final records = [
        registration('owner', id: 'a'),
        registration(
          'later',
          id: 'c',
          status: RegistrationStatus.waitlisted,
          at: now.add(const Duration(minutes: 2)),
        ),
        registration(
          'earliest',
          id: 'b',
          status: RegistrationStatus.waitlisted,
          at: now.add(const Duration(minutes: 1)),
        ),
      ];
      final result = service.cancel(
        event: event(capacity: 1),
        userId: 'owner',
        registrations: records,
        now: now.add(const Duration(hours: 1)),
      );
      expect(result.registrations.length, 3);
      expect(result.registration.status, RegistrationStatus.canceled);
      expect(result.promoted?.userId, 'earliest');
      expect(result.eventStatus, EventStatus.full);
    });
    test('a waiting person canceling does not promote another waiter', () {
      final result = service.cancel(
        event: event(capacity: 1),
        userId: 'waiter',
        registrations: [
          registration('owner'),
          registration(
            'waiter',
            id: 'w',
            status: RegistrationStatus.waitlisted,
          ),
        ],
        now: now,
      );
      expect(result.promoted, isNull);
      expect(result.registrations.first.status, RegistrationStatus.confirmed);
    });
    test('equal timestamps preserve FIFO insertion order', () {
      final result = service.cancel(
        event: event(capacity: 1),
        userId: 'owner',
        registrations: [
          registration('owner'),
          registration(
            'first',
            id: 'first',
            status: RegistrationStatus.waitlisted,
          ),
          registration(
            'second',
            id: 'second',
            status: RegistrationStatus.waitlisted,
          ),
        ],
        now: now,
      );
      expect(result.promoted?.userId, 'first');
    });
    test('existing waiters can be promoted after new registration closes', () {
      final result = service.cancel(
        event: event(capacity: 1),
        userId: 'owner',
        registrations: [
          registration('owner'),
          registration(
            'waiter',
            id: 'w',
            status: RegistrationStatus.waitlisted,
          ),
        ],
        now: event().deadline.add(const Duration(minutes: 5)),
      );
      expect(result.promoted?.userId, 'waiter');
      expect(result.eventStatus, EventStatus.registrationClosed);
    });
    test('a canceled event never promotes waiting students', () {
      final result = service.cancel(
        event: event(capacity: 1).copyWith(status: EventStatus.canceled),
        userId: 'owner',
        registrations: [
          registration('owner'),
          registration(
            'waiter',
            id: 'w',
            status: RegistrationStatus.waitlisted,
          ),
        ],
        now: now,
      );
      expect(result.promoted, isNull);
    });
    test('cancellation after start cannot rewrite attendance history', () {
      expect(
        () => service.cancel(
          event: event(),
          userId: 'a',
          registrations: [registration('a')],
          now: event().start,
        ),
        throwsA(isA<DomainException>()),
      );
    });
    test('a canceled registration allows a new registration without deleting history', () {
      final result = service.register(
        event: event(),
        userId: 'a',
        registrations: [registration('a', status: RegistrationStatus.canceled)],
        now: now,
        id: 'new',
      );
      expect(result.registrations.length, 2);
      expect(result.registration.status, RegistrationStatus.confirmed);
    });
  });

  group('Schedule conflicts', () {
    const service = ScheduleConflictService();
    const lesson = ScheduleEntry(
      id: 'lesson',
      title: 'Cơ sở dữ liệu',
      weekday: 5,
      startMinutes: 630,
      endMinutes: 690,
      venue: 'HUTECH khu E',
    );
    test('detects recurring class overlap', () {
      final conflicts = service.conflicts(
        event(),
        schedules: [lesson],
        registeredEvents: [],
      );
      expect(conflicts, contains(contains('Trùng lịch học')));
      expect(conflicts, contains(contains('Cơ sở dữ liệu')));
      expect(conflicts, contains(contains('10:30–11:30')));
    });
    test(
      'sample timetable uses full study blocks and overlaps seeded events',
      () {
        final schedules = PrototypeSeed.schedules(now);
        expect(
          schedules.where(
            (item) => item.startMinutes == 450 && item.endMinutes == 705,
          ),
          isNotEmpty,
        );
        expect(
          schedules.where(
            (item) => item.startMinutes == 750 && item.endMinutes == 1005,
          ),
          isNotEmpty,
        );
        final events = PrototypeSeed.events(now);
        for (final eventId in ['flutter-lab', 'career-connect']) {
          final seededEvent = events.firstWhere((item) => item.id == eventId);
          expect(
            service.conflicts(
              seededEvent,
              schedules: schedules,
              registeredEvents: const [],
            ),
            contains(contains('Trùng lịch học')),
          );
        }
      },
    );
    test('classes outside their term do not overlap', () {
      expect(
        service.conflicts(
          event(),
          schedules: [lesson.copyWith(validUntil: DateTime(2026, 10, 10))],
          registeredEvents: [],
        ),
        isEmpty,
      );
    });
    test('adjacent time ranges in one campus do not conflict', () {
      expect(
        service.conflicts(
          event(),
          schedules: [lesson.copyWith(startMinutes: 720, endMinutes: 800)],
          registeredEvents: [],
        ),
        isEmpty,
      );
    });
    test('travel buffer warns when a different campus begins too soon', () {
      final nearby = lesson.copyWith(
        startMinutes: 730,
        endMinutes: 800,
        venue: 'HUTECH khu A, B',
      );
      expect(
        service.conflicts(event(), schedules: [nearby], registeredEvents: []),
        contains(contains('chuyển cơ sở')),
      );
    });
    test('detects registered event overlap without comparing itself', () {
      expect(
        service.conflicts(event(), schedules: [], registeredEvents: [event()]),
        isEmpty,
      );
      expect(
        service.conflicts(
          event(),
          schedules: [],
          registeredEvents: [event().copyWith(id: 'other')],
        ),
        contains(contains('Trùng sự kiện')),
      );
    });
    test('warns about user availability', () {
      final profile = PrototypeSeed.profiles().first.copyWith(
        availableStartMinutes: 780,
      );
      expect(
        service.conflicts(
          event(),
          schedules: [],
          registeredEvents: [],
          profile: profile,
        ),
        contains(contains('khung giờ')),
      );
    });
  });

  group('Explainable scoring', () {
    const service = RecommendationService();
    test('computes configured weighted score from evidence without inventing history', () {
      final profile = PrototypeSeed.profiles().first;
      final result = service.evaluate(
        event(),
        profile: profile,
        events: [event()],
        favorites: {'event'},
      );
      // 30 interest + 25 * 2/3 missing skills + 20 free + 15 saved + 10 campus.
      expect(result.score, 92);
      expect(result.breakdown['Lịch sử tương tác'], 1);
      expect(result.breakdown['Kỹ năng cần phát triển'], closeTo(2 / 3, .0001));
      expect(result.reasons.any((item) => item.contains('Flutter')), isTrue);
    });
    test('no interaction evidence yields zero history points', () {
      final result = service.evaluate(
        event(),
        profile: PrototypeSeed.profiles().first,
        events: [event()],
      );
      expect(result.breakdown['Lịch sử tương tác'], 0);
      expect(result.score, 77);
    });
    test('conflicts reduce availability and preserve explanations', () {
      final result = service.evaluate(
        event(),
        profile: PrototypeSeed.profiles().first,
        events: [
          event(),
          event().copyWith(id: 'other'),
        ],
        registrations: [
          RegistrationModel(
            id: 'r',
            eventId: 'other',
            userId: 'student-ha',
            status: RegistrationStatus.confirmed,
            createdAt: now,
          ),
        ],
      );
      expect(result.breakdown['Lịch trống'], 0);
      expect(result.warnings, contains(contains('Trùng sự kiện')));
    });
    test('weights are configurable and missing profile returns no personalized claim', () {
      const customized = RecommendationService(
        config: RecommendationConfig(
          interestWeight: 1,
          skillGapWeight: 0,
          availabilityWeight: 0,
          historyWeight: 0,
          venueWeight: 0,
        ),
      );
      expect(
        customized
            .evaluate(event(), profile: PrototypeSeed.profiles().first)
            .score,
        100,
      );
      expect(service.evaluate(event()).score, 0);
    });
  });

  group('AppStore access and persistence', () {
    late MemoryRepository repository;
    late AppStore store;
    setUp(() async {
      repository = MemoryRepository();
      store = AppStore(clock: () => now, repository: repository);
      await store.initialize();
    });
    tearDown(() {
      store.dispose();
    });

    Future<void> restoreWithQueue({
      EventStatus status = EventStatus.full,
    }) async {
      repository.data!['events'] = [
        event(capacity: 1).copyWith(status: status).toJson(),
      ];
      repository.data!['registrations'] = [
        registration('owner', id: 'owner').toJson(),
        registration(
          'student-ha',
          id: 'ha',
          status: RegistrationStatus.waitlisted,
        ).toJson(),
        registration(
          'next',
          id: 'next',
          status: RegistrationStatus.waitlisted,
          at: now.add(const Duration(minutes: 1)),
        ).toJson(),
      ];
      store.dispose();
      store = AppStore(clock: () => now, repository: repository);
      await store.initialize();
      await store.login('admin@gmail.com', '123');
    }

    test('capacity edits promote and notify waiters before reopening remaining seats', () async {
      await restoreWithQueue();
      await store.saveEvent(store.eventById('event')!.copyWith(capacity: 2));
      expect(store.registrationCount('event'), 2);
      expect(store.waitlistCount('event'), 1);
      expect(store.eventById('event')!.status, EventStatus.full);
      await store.saveEvent(store.eventById('event')!.copyWith(capacity: 4));
      expect(store.registrationCount('event'), 3);
      expect(store.waitlistCount('event'), 0);
      expect(store.eventById('event')!.status, EventStatus.registrationOpen);
      await store.saveEvent(store.eventById('event')!.copyWith(capacity: 3));
      expect(store.eventById('event')!.status, EventStatus.full);
      await expectLater(
        store.saveEvent(store.eventById('event')!.copyWith(capacity: 2)),
        throwsA(isA<DomainException>()),
      );
      expect(store.eventById('event')!.capacity, 3);
      expect(store.registrationCount('event'), 3);
      await store.login('HA@gmail.com', '123');
      expect(
        store.registrationFor('event')!.status,
        RegistrationStatus.confirmed,
      );
      expect(
        store.notifications.where((item) => item.contains('Đã có chỗ')).length,
        1,
      );
    });
    test(
      'failed capacity write rolls back promotions and their notifications',
      () async {
        await restoreWithQueue();
        repository.failNext = true;
        await expectLater(
          store.saveEvent(store.eventById('event')!.copyWith(capacity: 2)),
          throwsStateError,
        );
        expect(store.eventById('event')!.capacity, 1);
        expect(store.registrationCount('event'), 1);
        expect(store.waitlistCount('event'), 2);
        await store.login('HA@gmail.com', '123');
        expect(
          store.registrationFor('event')!.status,
          RegistrationStatus.waitlisted,
        );
        expect(
          store.notifications.where((item) => item.contains('Đã có chỗ')),
          isEmpty,
        );
      },
    );
    test('reopening a canceled event fills its enlarged capacity from the existing queue', () async {
      await restoreWithQueue(status: EventStatus.canceled);
      await store.saveEvent(store.eventById('event')!.copyWith(capacity: 2));
      expect(store.registrationCount('event'), 1);
      await store.setEventStatus('event', EventStatus.registrationOpen);
      expect(store.registrationCount('event'), 2);
      expect(store.waitlistCount('event'), 1);
      expect(store.eventById('event')!.status, EventStatus.full);
    });
    test(
      'event editor cannot bypass the expired registration status guard',
      () async {
        await store.login('admin@gmail.com', '123');
        final expired = event().copyWith(deadline: now);
        await expectLater(
          store.saveEvent(expired),
          throwsA(isA<DomainException>()),
        );
        expect(store.eventById('event'), isNull);
        await store.saveEvent(
          expired.copyWith(status: EventStatus.registrationClosed),
        );
        await expectLater(
          store.setEventStatus('event', EventStatus.registrationOpen),
          throwsA(isA<DomainException>()),
        );
        expect(
          store.eventById('event')!.status,
          EventStatus.registrationClosed,
        );
      },
    );

    test('rejects wrong login and protects admin operations', () async {
      await expectLater(
        store.login('HA@gmail.com', 'wrong'),
        throwsA(isA<DomainException>()),
      );
      await expectLater(
        store.saveEvent(event()),
        throwsA(isA<DomainException>()),
      );
      await store.login(' HA@gmail.com ', '123');
      expect(store.profile?.name, 'Hoàng Anh');
      expect(store.isAdmin, isFalse);
      expect(store.allUsers, isEmpty);
      expect(store.allRegistrations, isEmpty);
      await expectLater(
        store.addCategory('New'),
        throwsA(isA<DomainException>()),
      );
      await expectLater(
        store.setEventStatus('flutter-lab', EventStatus.canceled),
        throwsA(isA<DomainException>()),
      );
    });
    test(
      'does not allow updating another user or making display name empty',
      () async {
        await store.login('HA@gmail.com', '123');
        await expectLater(
          store.updateProfile(store.profile!.copyWith(id: 'admin')),
          throwsA(isA<DomainException>()),
        );
        await expectLater(
          store.updateProfile(store.profile!.copyWith(name: '  ')),
          throwsA(isA<DomainException>()),
        );
        expect(store.profile!.name, 'Hoàng Anh');
      },
    );
    test('registration does not award skills and concurrent clicks cannot duplicate', () async {
      await store.login('HA@gmail.com', '123');
      final before = [...store.profile!.skills];
      final first = store.registerEvent(
        'flutter-lab',
        continueOnConflict: true,
      );
      final second = expectLater(
        store.registerEvent('flutter-lab', continueOnConflict: true),
        throwsA(isA<DomainException>()),
      );
      await first;
      await second;
      expect(
        store.registrations
            .where((item) => item.eventId == 'flutter-lab')
            .length,
        1,
      );
      expect(store.profile!.skills, before);
    });
    test(
      'registration requires an explicit choice when a class overlaps',
      () async {
        await store.login('HA@gmail.com', '123');
        final conflicts = store.registrationConflicts('flutter-lab');
        expect(conflicts, contains(contains('Lập trình ứng dụng di động')));
        expect(conflicts, contains(contains('07:30–11:45')));
        await expectLater(
          store.registerEvent('flutter-lab'),
          throwsA(isA<DomainException>()),
        );
        expect(store.registrationFor('flutter-lab'), isNull);
        await store.registerEvent('flutter-lab', continueOnConflict: true);
        expect(store.registrationFor('flutter-lab'), isNotNull);
      },
    );
    test('version 1 timetable migration keeps custom courses', () async {
      repository.data!['version'] = 1;
      final schedules = Map<String, dynamic>.from(
        repository.data!['schedules'] as Map,
      );
      final studentSchedules = List<dynamic>.from(
        schedules['student-ha'] as List,
      );
      final mobileIndex = studentSchedules.indexWhere(
        (item) => (item as Map)['id'] == 'class-mobile',
      );
      final oldMobile = Map<String, dynamic>.from(
        studentSchedules[mobileIndex] as Map,
      );
      oldMobile['endMinutes'] = 660;
      studentSchedules[mobileIndex] = oldMobile;
      studentSchedules.add(
        const ScheduleEntry(
          id: 'custom-course',
          title: 'Môn người dùng tự thêm',
          weekday: DateTime.saturday,
          startMinutes: 540,
          endMinutes: 600,
          venue: 'HUTECH khu E',
        ).toJson(),
      );
      schedules['student-ha'] = studentSchedules;
      repository.data!['schedules'] = schedules;

      store.dispose();
      store = AppStore(clock: () => now, repository: repository);
      await store.initialize();
      await store.login('HA@gmail.com', '123');

      expect(repository.data!['version'], 2);
      expect(
        store.schedules
            .firstWhere((item) => item.id == 'class-mobile')
            .endMinutes,
        705,
      );
      expect(store.schedules.any((item) => item.id == 'custom-course'), isTrue);
    });
    test('state survives a new store and no password is persisted', () async {
      await store.login('HA@gmail.com', '123');
      await store.setThemeMode(ThemeMode.dark);
      await store.toggleFavorite('career-connect');
      await store.updateProfile(
        store.profile!.copyWith(name: 'Hoàng Anh Nguyễn'),
      );
      final restored = AppStore(clock: () => now, repository: repository);
      await restored.initialize();
      expect(restored.profile?.name, 'Hoàng Anh Nguyễn');
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.favorites, contains('career-connect'));
      expect(
        jsonEncode(repository.data).toLowerCase(),
        isNot(contains('password')),
      );
      restored.dispose();
    });
    test(
      'failed writes roll back changes and later changes still work',
      () async {
        await store.login('admin@gmail.com', '123');
        repository.failNext = true;
        await expectLater(store.addCategory('Temporary'), throwsStateError);
        expect(store.categories, isNot(contains('Temporary')));
        await store.addCategory('New category');
        expect(store.categories, contains('New category'));
      },
    );
    test('admin drafts are hidden and deleting a registered event preserves records', () async {
      await store.login('admin@gmail.com', '123');
      await store.saveEvent(
        event().copyWith(id: 'private', status: EventStatus.draft),
      );
      await store.deleteEvent('teamwork-studio');
      expect(store.allRegistrations.length, 1);
      expect(store.eventById('teamwork-studio')?.status, EventStatus.canceled);
      await store.logout();
      expect(store.eventById('private'), isNull);
      await store.login('HA@gmail.com', '123');
      expect(store.registrations.length, 1);
      expect(
        store.notifications.any((item) => item.contains('đã bị hủy')),
        isTrue,
      );
    });
    test('invalid event ordering and capacity are rejected', () async {
      await store.login('admin@gmail.com', '123');
      await expectLater(
        store.saveEvent(event().copyWith(end: event().start)),
        throwsA(isA<DomainException>()),
      );
      await expectLater(
        store.saveEvent(event(capacity: 0)),
        throwsA(isA<DomainException>()),
      );
      await expectLater(
        store.saveEvent(event().copyWith(deadline: event().end)),
        throwsA(isA<DomainException>()),
      );
    });
    test('model JSON roundtrip preserves status, time and optional term', () {
      expect(
        EventModel.fromJson(
          event().copyWith(status: EventStatus.registrationClosed).toJson(),
        ).status,
        EventStatus.registrationClosed,
      );
      final schedule = PrototypeSeed.schedules().first.copyWith(
        validUntil: DateTime(2027, 1, 1),
      );
      expect(
        ScheduleEntry.fromJson(schedule.toJson()).validUntil,
        DateTime(2027, 1, 1),
      );
      expect(
        UserProfile.fromJson(PrototypeSeed.profiles().first.toJson()).name,
        'Hoàng Anh',
      );
      expect(
        RegistrationModel.fromJson(registration('a').toJson()).createdAt,
        now,
      );
    });
  });
}
