import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/schedule_entry.dart';
import '../../providers/app_store.dart';
import 'student_widgets.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  Future<void> _edit(BuildContext context, [ScheduleEntry? entry]) async {
    final store = context.read<AppStore>();
    final result = await showDialog<ScheduleEntry>(
      context: context,
      builder: (context) => _ScheduleDialog(entry: entry, venues: store.venues),
    );
    if (result == null || !context.mounted) return;
    try {
      await store.saveSchedule(result);
      if (context.mounted) studentMessage(context, 'Đã lưu lịch học của bạn.');
    } catch (error) {
      if (context.mounted) {
        studentMessage(context, error.toString(), error: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, ScheduleEntry entry) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch học?'),
        content: Text(
          'Xóa “${entry.title}” khỏi lịch cá nhân? Các sự kiện bạn đã đăng ký vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa lịch'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      await context.read<AppStore>().deleteSchedule(entry.id);
      if (context.mounted) studentMessage(context, 'Đã xóa lịch học.');
    } catch (error) {
      if (context.mounted) {
        studentMessage(context, error.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final schedules = [...store.schedules]
      ..sort(
        (a, b) => a.weekday == b.weekday
            ? a.startMinutes.compareTo(b.startMinutes)
            : a.weekday.compareTo(b.weekday),
      );
    return StudentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentHeading(
            eyebrow: 'Sắp xếp thời gian',
            title: 'Lịch học cá nhân',
            subtitle: 'Cập nhật thời khóa biểu để tìm những sự kiện phù hợp với lịch trống của bạn.',
            action: FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm lịch học'),
            ),
          ),
          StudentCard(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .25),
            padding: const EdgeInsets.all(18),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_outlined, color: studentBlue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lịch học được sử dụng để kiểm tra trùng giờ và thời gian di chuyển. Bạn vẫn là người quyết định đăng ký khi có cảnh báo.',
                    style: TextStyle(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (schedules.isEmpty)
            StudentCard(
              child: StudentEmpty(
                icon: Icons.calendar_month_outlined,
                title: 'Thêm môn học đầu tiên',
                message: 'Lịch học chỉ thuộc về tài khoản của bạn. Nhập môn học, thời gian và cơ sở để bắt đầu.',
                action: FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lịch học'),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 980
                    ? 3
                    : constraints.maxWidth > 620
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final daySchedules = schedules
                        .where((entry) => entry.weekday == weekday)
                        .toList();
                    return SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 18) / columns,
                      child: StudentCard(
                        padding: const EdgeInsets.all(19),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: daySchedules.isEmpty
                                        ? Theme.of(context)
                                              .colorScheme
                                              .outlineVariant
                                        : studentBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  studentWeekday(weekday),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${daySchedules.length} môn',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            if (daySchedules.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  'Chưa có lịch học',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ...daySchedules.map(
                              (entry) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLowest,
                                  border: Border(
                                    left: BorderSide(
                                      color: studentBlue.withValues(alpha: .75),
                                      width: 3,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: 'Tùy chọn lịch học',
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.more_horiz,
                                            size: 20,
                                          ),
                                          onSelected: (value) => value == 'edit'
                                              ? _edit(context, entry)
                                              : _delete(context, entry),
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Chỉnh sửa'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Xóa lịch'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      studentStudyTime(
                                        entry.startMinutes,
                                        entry.endMinutes,
                                      ),
                                      style: const TextStyle(
                                        color: studentBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            entry.venue,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (entry.validFrom != null ||
                                        entry.validUntil != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '${entry.validFrom == null ? 'Từ nay' : studentDate(entry.validFrom!)} – ${entry.validUntil == null ? 'Không giới hạn' : studentDate(entry.validUntil!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }
}

enum _StudySession { morning, afternoon, custom }

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({this.entry, required this.venues});
  final ScheduleEntry? entry;
  final List<String> venues;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late int _weekday;
  late int _start;
  late int _end;
  late _StudySession _session;
  late String _venue;
  DateTime? _from;
  DateTime? _until;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _weekday = entry?.weekday ?? 1;
    _start = entry?.startMinutes ?? 7 * 60 + 30;
    _end = entry?.endMinutes ?? 11 * 60 + 45;
    _session = _detectSession();
    _venue = entry?.venue ?? widget.venues.firstOrNull ?? 'HUTECH khu A,B';
    _from = entry?.validFrom;
    _until = entry?.validUntil;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  _StudySession _detectSession() {
    if (_start == 450 && _end == 705) return _StudySession.morning;
    if (_start == 750 && _end == 1005) return _StudySession.afternoon;
    return _StudySession.custom;
  }

  void _selectSession(_StudySession? session) {
    if (session == null) return;
    setState(() {
      _session = session;
      if (session == _StudySession.morning) {
        _start = 450;
        _end = 705;
      } else if (session == _StudySession.afternoon) {
        _start = 750;
        _end = 1005;
      }
      _error = null;
    });
  }

  Future<void> _pickTime(bool start) async {
    final value = start ? _start : _end;
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
          _start = result.hour * 60 + result.minute;
        } else {
          _end = result.hour * 60 + result.minute;
        }
        _session = _detectSession();
        _error = null;
      });
    }
  }

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _until) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
      helpText: from ? 'Ngày bắt đầu học kỳ' : 'Ngày kết thúc học kỳ',
    );
    if (result != null) {
      setState(() {
        if (from) {
          _from = result;
        } else {
          _until = result;
        }
        _error = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_end <= _start) {
      setState(() => _error = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }
    if (_from != null && _until != null && _until!.isBefore(_from!)) {
      setState(() => _error = 'Ngày kết thúc phải từ ngày bắt đầu trở đi.');
      return;
    }
    Navigator.pop(
      context,
      ScheduleEntry(
        id:
            widget.entry?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        weekday: _weekday,
        startMinutes: _start,
        endMinutes: _end,
        venue: _venue,
        validFrom: _from,
        validUntil: _until,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = {...widget.venues, _venue}.toList();
    return AlertDialog(
      title: Text(
        widget.entry == null ? 'Thêm lịch học' : 'Chỉnh sửa lịch học',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lặp lại theo tuần trong khoảng thời gian bạn chọn.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Tên môn học',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Nhập tên môn học từ 2 ký tự.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  decoration: const InputDecoration(
                    labelText: 'Ngày trong tuần',
                  ),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(studentWeekday(index + 1)),
                    ),
                  ),
                  onChanged: (value) => setState(() => _weekday = value!),
                ),
                const SizedBox(height: 12),
                RadioGroup<_StudySession>(
                  groupValue: _session,
                  onChanged: _selectSession,
                  child: const Column(
                    children: [
                      RadioListTile<_StudySession>(
                        value: _StudySession.morning,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Buổi sáng · Tiết 2–6'),
                        subtitle: Text(
                          '07:30 – 11:45',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      RadioListTile<_StudySession>(
                        value: _StudySession.afternoon,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Buổi chiều · Tiết 7–11'),
                        subtitle: Text(
                          '12:30 – 16:45',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      RadioListTile<_StudySession>(
                        value: _StudySession.custom,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Tùy chỉnh giờ học'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(true),
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text('Từ ${studentTime(_start)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(false),
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text('Đến ${studentTime(_end)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _venue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Cơ sở học'),
                  items: venues
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _venue = value!),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Thời gian áp dụng',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        _from == null ? 'Ngày bắt đầu' : studentDate(_from!),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Text(
                        _until == null ? 'Ngày kết thúc' : studentDate(_until!),
                      ),
                    ),
                    if (_from != null || _until != null)
                      IconButton(
                        tooltip: 'Bỏ giới hạn học kỳ',
                        onPressed: () => setState(() {
                          _from = null;
                          _until = null;
                        }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu lịch học')),
      ],
    );
  }
}
