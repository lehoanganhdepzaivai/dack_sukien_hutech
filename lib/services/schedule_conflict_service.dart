import '../config/recommendation_config.dart';
import '../models/models.dart';

class ScheduleConflictService {
  const ScheduleConflictService({this.config = const RecommendationConfig()});
  final RecommendationConfig config;

  static bool overlaps(
    DateTime start,
    DateTime end,
    DateTime otherStart,
    DateTime otherEnd,
  ) => start.isBefore(otherEnd) && end.isAfter(otherStart);

  List<String> conflicts(
    EventModel event, {
    required List<ScheduleEntry> schedules,
    required List<EventModel> registeredEvents,
    UserProfile? profile,
  }) {
    final warnings = <String>{};
    // Include the preceding/following day for travel around midnight.
    var date = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    ).subtract(const Duration(days: 1));
    final last = DateTime(
      event.end.year,
      event.end.month,
      event.end.day,
    ).add(const Duration(days: 1));
    while (!date.isAfter(last)) {
      for (final lesson in schedules.where((item) => item.occursOn(date))) {
        final start = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          lesson.startMinutes,
        );
        final end = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          lesson.endMinutes,
        );
        if (overlaps(event.start, event.end, start, end)) {
          warnings.add(
            'Trùng lịch học “${lesson.title}” '
            '(${_weekday(date.weekday)}, ${_date(date)} · '
            '${_studyPeriod(lesson.startMinutes, lesson.endMinutes)}'
            '${_time(lesson.startMinutes)}–${_time(lesson.endMinutes)}, '
            '${lesson.venue}).',
          );
        } else if (_needsTravel(event, start, end, lesson.venue)) {
          warnings.add(
            'Khoảng chuyển cơ sở với môn ${lesson.title} dưới ${config.travelBufferMinutes} phút.',
          );
        }
      }
      date = DateTime(date.year, date.month, date.day + 1);
    }
    for (final other in registeredEvents) {
      if (other.id == event.id ||
          other.status == EventStatus.canceled ||
          other.status == EventStatus.archived) {
        continue;
      }
      if (overlaps(event.start, event.end, other.start, other.end)) {
        warnings.add('Trùng sự kiện đã đăng ký: ${other.title}.');
      } else if (_needsTravel(event, other.start, other.end, other.venue)) {
        warnings.add(
          'Khoảng chuyển cơ sở với ${other.title} dưới ${config.travelBufferMinutes} phút.',
        );
      }
    }
    if (profile != null) {
      final start = event.start.hour * 60 + event.start.minute;
      final end = event.end.hour * 60 + event.end.minute;
      final sameDay =
          event.start.year == event.end.year &&
          event.start.month == event.end.month &&
          event.start.day == event.end.day;
      if (!sameDay ||
          start < profile.availableStartMinutes ||
          end > profile.availableEndMinutes) {
        warnings.add('Sự kiện nằm ngoài khung giờ cá nhân đã chọn.');
      }
    }
    return warnings.toList();
  }

  bool _needsTravel(
    EventModel event,
    DateTime otherStart,
    DateTime otherEnd,
    String venue,
  ) {
    if (venue == event.venue) return false;
    final gap = !event.start.isBefore(otherEnd)
        ? event.start.difference(otherEnd).inMinutes
        : otherStart.difference(event.end).inMinutes;
    return gap >= 0 && gap < config.travelBufferMinutes;
  }

  static String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _weekday(int weekday) =>
      weekday == DateTime.sunday ? 'Chủ nhật' : 'Thứ ${weekday + 1}';

  static String _studyPeriod(int startMinutes, int endMinutes) {
    if (startMinutes == 450 && endMinutes == 705) return 'tiết 2–6 · ';
    if (startMinutes == 750 && endMinutes == 1005) return 'tiết 7–11 · ';
    return '';
  }
}
