import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact week selector sharing the calendar's selected date and limits.
class WeekDateTimeline extends StatelessWidget {
  const WeekDateTimeline({
    super.key,
    required this.selectedDay,
    required this.firstDay,
    required this.lastDay,
    required this.onSelected,
    this.hasActivity,
  });

  final DateTime selectedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final ValueChanged<DateTime> onSelected;
  final bool Function(DateTime day)? hasActivity;

  DateTime _date(DateTime day) => DateTime(day.year, day.month, day.day);
  bool _sameDay(DateTime a, DateTime b) => _date(a) == _date(b);

  DateTime _clamp(DateTime day) {
    if (day.isBefore(_date(firstDay))) return _date(firstDay);
    if (day.isAfter(_date(lastDay))) return _date(lastDay);
    return day;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _date(selectedDay);
    final monday = DateTime(
      selected.year,
      selected.month,
      selected.day - selected.weekday + 1,
    );
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'vi_VN').format(selected),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tuần trước',
              onPressed: monday.isAfter(_date(firstDay))
                  ? () => onSelected(
                      _clamp(
                        DateTime(
                          selected.year,
                          selected.month,
                          selected.day - 7,
                        ),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Tuần sau',
              onPressed: sunday.isBefore(_date(lastDay))
                  ? () => onSelected(
                      _clamp(
                        DateTime(
                          selected.year,
                          selected.month,
                          selected.day + 7,
                        ),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Chọn ngày trên lịch',
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: _clamp(selected),
                  firstDate: firstDay,
                  lastDate: lastDay,
                  helpText: 'Chọn ngày xem lịch',
                );
                if (day != null && context.mounted) onSelected(day);
              },
              icon: const Icon(Icons.date_range_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final day = DateTime(monday.year, monday.month, monday.day + index);
            final isSelected = _sameDay(day, selected);
            final enabled =
                !day.isBefore(_date(firstDay)) && !day.isAfter(_date(lastDay));
            final today = _sameDay(day, DateTime.now());
            final foreground = isSelected ? colors.onPrimary : colors.onSurface;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  enabled: enabled,
                  label: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(day),
                  child: Material(
                    color: isSelected
                        ? colors.primary
                        : colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: ValueKey(
                        'week-day-${DateFormat('yyyy-MM-dd').format(day)}',
                      ),
                      onTap: enabled ? () => onSelected(day) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: today && !isSelected
                                ? const Color(0xFFD7AA16)
                                : Colors.transparent,
                          ),
                        ),
                        child: Opacity(
                          opacity: enabled ? 1 : .35,
                          child: Column(
                            children: [
                              Text(
                                index == 6 ? 'CN' : 'T${index + 2}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: foreground,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: foreground,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      enabled &&
                                          (hasActivity?.call(day) ?? false)
                                      ? (isSelected
                                            ? colors.onPrimary
                                            : colors.primary)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
