import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/recommendation_config.dart';
import '../../models/user_profile.dart';
import '../../providers/app_store.dart';
import 'student_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _major = TextEditingController();
  final _cohort = TextEditingController();
  final _phone = TextEditingController();
  final _goal = TextEditingController();
  String? _loadedId;
  String _faculty = '';
  String _venue = '';
  int _availableStart = 420;
  int _availableEnd = 1320;
  final Set<String> _interests = {};
  final Set<String> _skills = {};
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<AppStore>().profile;
    if (profile != null && _loadedId != profile.id) _load(profile);
  }

  void _load(UserProfile profile) {
    _loadedId = profile.id;
    _name.text = profile.name;
    _studentId.text = profile.studentId;
    _major.text = profile.major;
    _cohort.text = profile.cohort;
    _phone.text = profile.phone;
    _goal.text = profile.careerGoal;
    _faculty = profile.faculty;
    _venue = profile.preferredVenue;
    _availableStart = profile.availableStartMinutes;
    _availableEnd = profile.availableEndMinutes;
    _interests
      ..clear()
      ..addAll(profile.interests);
    _skills
      ..clear()
      ..addAll(profile.skills);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _studentId,
      _major,
      _cohort,
      _phone,
      _goal,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_availableEnd <= _availableStart) {
      studentMessage(
        context,
        'Khung giờ thuận tiện phải có giờ kết thúc sau giờ bắt đầu.',
        error: true,
      );
      return;
    }
    final store = context.read<AppStore>();
    final profile = store.profile;
    if (profile == null) return;
    setState(() => _saving = true);
    try {
      await store.updateProfile(
        profile.copyWith(
          name: _name.text.trim(),
          studentId: _studentId.text.trim(),
          faculty: _faculty,
          major: _major.text.trim(),
          cohort: _cohort.text.trim(),
          phone: _phone.text.trim(),
          careerGoal: _goal.text.trim(),
          interests: _interests.toList(),
          skills: _skills.toList(),
          preferredVenue: _venue,
          availableStartMinutes: _availableStart,
          availableEndMinutes: _availableEnd,
        ),
      );
      if (mounted) {
        studentMessage(
          context,
          'Đã lưu hồ sơ. Đề xuất sự kiện đã được cập nhật.',
        );
      }
    } catch (error) {
      if (mounted) studentMessage(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _time(bool start) async {
    final value = start ? _availableStart : _availableEnd;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (result != null) {
      setState(() {
        if (start) {
          _availableStart = result.hour * 60 + result.minute;
        } else {
          _availableEnd = result.hour * 60 + result.minute;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final profile = store.profile;
    if (profile == null) {
      return const StudentPage(
        child: StudentEmpty(
          icon: Icons.person_outline,
          title: 'Đăng nhập để xem hồ sơ',
          message:
              'Hồ sơ, sở thích và lịch học được lưu theo tài khoản của bạn.',
        ),
      );
    }
    final faculties = {
      ...store.faculties,
      if (_faculty.isNotEmpty) _faculty,
    }.toList();
    final venues = {...store.venues, if (_venue.isNotEmpty) _venue}.toList();
    final interests = {
      ...store.categories,
      ...store.skills,
      ..._interests,
    }.toList();
    final skills = {...store.skills, ..._skills}.toList();
    return StudentPage(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentHeading(
              eyebrow: 'Dấu ấn của bạn',
              title: 'Hồ sơ sinh viên',
              subtitle: 'Một hồ sơ đầy đủ giúp mỗi đề xuất đến gần hơn với điều bạn quan tâm.',
              action: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ),
            StudentCard(
              padding: const EdgeInsets.all(26),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1476C6), studentBlue],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.name.trim().isEmpty
                          ? 'SV'
                          : profile.name
                                .trim()
                                .split(RegExp(r'\s+'))
                                .take(2)
                                .map(
                                  (word) => word.characters.first.toUpperCase(),
                                )
                                .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          profile.email,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const StudentPill(
                          'Sinh viên HUTECH',
                          icon: Icons.school_outlined,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StudentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StudentSectionTitle(
                    'Thông tin cá nhân',
                    subtitle: 'Thông tin sẽ xuất hiện trên vé đăng ký của bạn.',
                  ),
                  _Fields(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Nhập họ và tên từ 2 ký tự.'
                            : null,
                      ),
                      TextFormField(
                        controller: _studentId,
                        decoration: const InputDecoration(
                          labelText: 'Mã số sinh viên *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập mã số sinh viên.'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _faculty.isEmpty ? null : _faculty,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Khoa / Viện',
                        ),
                        items: faculties
                            .map(
                              (faculty) => DropdownMenuItem(
                                value: faculty,
                                child: Text(
                                  faculty,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _faculty = value ?? ''),
                      ),
                      TextFormField(
                        controller: _major,
                        decoration: const InputDecoration(
                          labelText: 'Ngành học',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _cohort,
                        decoration: const InputDecoration(
                          labelText: 'Khóa học',
                          hintText: 'Ví dụ: 2024 – 2028',
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          return RegExp(r'^\+?[0-9\s().-]{9,16}$').hasMatch(raw)
                              ? null
                              : 'Số điện thoại chưa đúng định dạng.';
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StudentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentSectionTitle(
                    'Bạn quan tâm điều gì?',
                    subtitle:
                        'Chọn nhiều chủ đề. Sở thích đóng góp ${(const RecommendationConfig().interestWeight * 100).round()}% vào điểm phù hợp của sự kiện.',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map(
                          (interest) => FilterChip(
                            label: Text(interest),
                            selected: _interests.contains(interest),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _interests.add(interest)
                                  : _interests.remove(interest);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StudentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StudentSectionTitle(
                    'Mục tiêu & kỹ năng',
                    subtitle: 'Chọn hướng đi để xây dựng lộ trình phát triển phù hợp.',
                  ),
                  TextFormField(
                    controller: _goal,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu nghề nghiệp',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: RecommendationConfig.careerSkills.keys
                        .map(
                          (goal) => ActionChip(
                            label: Text(
                              goal,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => setState(() => _goal.text = goal),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kỹ năng bạn đã có',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thông tin tự khai để cá nhân hóa đề xuất. Minh chứng hoàn thành sự kiện được quản lý riêng.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => FilterChip(
                            label: Text(skill),
                            selected: _skills.contains(skill),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _skills.add(skill)
                                  : _skills.remove(skill);
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StudentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StudentSectionTitle(
                    'Thời gian & địa điểm thuận tiện',
                    subtitle: 'Được dùng để phát hiện thời gian không phù hợp và tính điểm địa điểm.',
                  ),
                  _Fields(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _venue.isEmpty ? null : _venue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Cơ sở thường học',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: venues
                            .map(
                              (venue) => DropdownMenuItem(
                                value: venue,
                                child: Text(venue),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _venue = value ?? ''),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _time(true),
                              icon: const Icon(Icons.schedule, size: 16),
                              label: Text('Từ ${studentTime(_availableStart)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _time(false),
                              icon: const Icon(Icons.schedule, size: 16),
                              label: Text('Đến ${studentTime(_availableEnd)}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => context.go('/schedule'),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('Cập nhật lịch học chi tiết'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Lưu hồ sơ của tôi'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth > 620;
      final width = twoColumns
          ? (constraints.maxWidth - 20) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}
