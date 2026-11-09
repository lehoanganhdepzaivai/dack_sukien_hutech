import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/schedule_entry.dart';
import '../../providers/app_store.dart';
import '../../widgets/week_date_timeline.dart';
import 'student_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  bool _showCourses = true;
  bool _onlyRegistered = false;

  bool _courseOnDay(ScheduleEntry entry, DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    if (entry.weekday != day.weekday) return false;
    if (entry.validFrom != null &&
        date.isBefore(
          DateTime(
            entry.validFrom!.year,
            entry.validFrom!.month,
            entry.validFrom!.day,
          ),
        )) {
      return false;
    }
    if (entry.validUntil != null &&
        date.isAfter(
          DateTime(
            entry.validUntil!.year,
            entry.validUntil!.month,
            entry.validUntil!.day,
          ),
        )) {
      return false;
    }
    return true;
  }

  bool _eventOnDay(EventModel event, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return event.start.isBefore(end) && event.end.isAfter(start);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final events = store.events.where((event) {
      final registration = store.registrationFor(event.id);
      return event.isPublic &&
          (!_onlyRegistered ||
              (registration != null &&
                  registration.status != RegistrationStatus.canceled));
    }).toList();
    final selectedEvents =
        events.where((event) => _eventOnDay(event, _selectedDay)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final courses = _showCourses
        ? store.schedules
              .where((entry) => _courseOnDay(entry, _selectedDay))
              .toList()
        : <ScheduleEntry>[];
    courses.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return StudentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentHeading(
            eyebrow: 'Mỗi ngày một trải nghiệm',
            title: 'Lịch của bạn',
            subtitle: 'Sự kiện và lịch học, cùng trong một góc nhìn.',
            action: OutlinedButton.icon(
              onPressed: () => context.go('/schedule'),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Quản lý lịch học'),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Lịch học của tôi'),
                avatar: const Icon(Icons.menu_book_outlined, size: 17),
                selected: _showCourses,
                onSelected: (value) => setState(() => _showCourses = value),
              ),
              FilterChip(
                label: const Text('Chỉ sự kiện đã đăng ký'),
                avatar: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 17,
                ),
                selected: _onlyRegistered,
                onSelected: (value) => setState(() => _onlyRegistered = value),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = _focusedDay;
                }),
                icon: const Icon(Icons.today_outlined, size: 18),
                label: const Text('Hôm nay'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          StudentCard(
            padding: const EdgeInsets.all(16),
            child: WeekDateTimeline(
              selectedDay: _selectedDay,
              firstDay: DateTime(DateTime.now().year - 3),
              lastDay: DateTime(DateTime.now().year + 5, 12, 31),
              onSelected: (day) => setState(() {
                _selectedDay = day;
                _focusedDay = day;
              }),
              hasActivity: (day) =>
                  events.any((event) => _eventOnDay(event, day)) ||
                  (_showCourses &&
                      store.schedules.any((entry) => _courseOnDay(entry, day))),
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final calendar = StudentCard(
                padding: EdgeInsets.all(constraints.maxWidth < 500 ? 8 : 18),
                child: Column(
                  children: [
                    TableCalendar<Object>(
                      locale: 'vi_VN',
                      firstDay: DateTime(DateTime.now().year - 3),
                      lastDay: DateTime(DateTime.now().year + 5, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      calendarFormat: _format,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Tháng',
                        CalendarFormat.twoWeeks: '2 tuần',
                        CalendarFormat.week: 'Tuần',
                      },
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      rowHeight: constraints.maxWidth > 900 ? 70 : 52,
                      daysOfWeekHeight: 32,
                      headerStyle: HeaderStyle(
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        formatButtonDecoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        formatButtonTextStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: studentGold.withValues(alpha: .5),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: Color(0xFF725C00),
                          fontWeight: FontWeight.w700,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: studentBlue,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: studentBlue,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 5,
                        markersMaxCount: 3,
                        cellMargin: const EdgeInsets.all(8),
                        weekendTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      eventLoader: (day) => <Object>[
                        ...events.where((event) => _eventOnDay(event, day)),
                        if (_showCourses)
                          ...store.schedules.where(
                            (entry) => _courseOnDay(entry, day),
                          ),
                      ],
                      calendarBuilders: CalendarBuilders<Object>(
                        markerBuilder: (context, day, markers) {
                          if (markers.isEmpty) return null;
                          final hasEvent = markers.any(
                            (item) => item is EventModel,
                          );
                          final hasCourse = markers.any(
                            (item) => item is ScheduleEntry,
                          );
                          return Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasEvent)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: studentBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasCourse)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD7AA16),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      onDaySelected: (selected, focused) => setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      }),
                      onFormatChanged: (format) =>
                          setState(() => _format = format),
                      onPageChanged: (focused) => _focusedDay = focused,
                    ),
                    const Divider(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          StudentPill(
                            'Sự kiện',
                            icon: Icons.circle,
                            color: studentBlue,
                          ),
                          StudentPill(
                            'Lịch học',
                            icon: Icons.circle,
                            color: Color(0xFFA57E00),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              final agenda = StudentCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentSectionTitle(
                      studentWeekday(_selectedDay.weekday),
                      subtitle: studentDate(_selectedDay),
                      trailing: StudentPill(
                        '${courses.length + selectedEvents.length} hoạt động',
                      ),
                    ),
                    if (courses.isEmpty && selectedEvents.isEmpty)
                      StudentEmpty(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Một ngày còn trống',
                        message: 'Dành thời gian cho bản thân hoặc khám phá một trải nghiệm mới.',
                        action: TextButton(
                          onPressed: () => context.go('/events'),
                          child: const Text('Khám phá sự kiện'),
                        ),
                      ),
                    ...courses.map(
                      (entry) => _AgendaItem(
                        title: entry.title,
                        subtitle: entry.venue,
                        time: studentStudyTime(
                          entry.startMinutes,
                          entry.endMinutes,
                        ),
                        category: 'LỊCH HỌC',
                        color: const Color(0xFFB38B00),
                        icon: Icons.menu_book_outlined,
                        onTap: () => context.go('/schedule'),
                      ),
                    ),
                    ...selectedEvents.map((event) {
                      final warnings = store
                          .recommendation(event)
                          .warnings
                          .where((warning) {
                            final text = warning.toLowerCase();
                            return text.contains('trùng') ||
                                text.contains('khung giờ') ||
                                text.contains('chuyển cơ sở');
                          })
                          .toList();
                      return _AgendaItem(
                        title: event.title,
                        subtitle: event.venue,
                        time:
                            '${studentTime(event.start.hour * 60 + event.start.minute)} – ${studentTime(event.end.hour * 60 + event.end.minute)}',
                        category: event.category.toUpperCase(),
                        color: studentBlue,
                        icon: Icons.local_activity_outlined,
                        warning: warnings.isEmpty ? null : warnings.first,
                        onTap: () => context.go('/events/${event.id}'),
                      );
                    }),
                  ],
                ),
              );
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [calendar, const SizedBox(height: 20), agenda],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: calendar),
                  const SizedBox(width: 22),
                  Expanded(flex: 4, child: agenda),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  const _AgendaItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.category,
    required this.color,
    required this.icon,
    required this.onTap,
    this.warning,
  });
  final String title;
  final String subtitle;
  final String time;
  final String category;
  final String? warning;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: color.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 3)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              if (warning != null) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFB77900),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning!,
                        style: const TextStyle(
                          color: Color(0xFF9A6900),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
