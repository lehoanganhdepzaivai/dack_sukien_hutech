import '../config/recommendation_config.dart';
import '../models/models.dart';
import 'schedule_conflict_service.dart';

class RecommendationService {
  const RecommendationService({this.config = const RecommendationConfig()});
  final RecommendationConfig config;

  Recommendation evaluate(
    EventModel event, {
    UserProfile? profile,
    List<ScheduleEntry> schedules = const [],
    List<EventModel> events = const [],
    List<RegistrationModel> registrations = const [],
    Set<String> favorites = const {},
    Set<String> viewedEvents = const {},
  }) {
    if (profile == null) {
      return const Recommendation(
        score: 0,
        reasons: ['Đăng nhập và bổ sung hồ sơ để xem mức phù hợp.'],
        warnings: [],
        breakdown: {},
      );
    }
    final reasons = <String>[];
    final targetSkills =
        RecommendationConfig.careerSkills[profile.careerGoal] ?? <String>[];
    final missingSkills = targetSkills
        .where((skill) => !profile.skills.contains(skill))
        .toSet();
    final matches = event.skills.toSet().where(missingSkills.contains).toList();
    final interestTopics = {event.category, ...event.skills};
    final interests = profile.interests.where(interestTopics.contains).toList();
    final interestScore = interests.isEmpty ? 0.0 : 1.0;
    final skillScore = missingSkills.isEmpty
        ? 0.0
        : matches.length / missingSkills.length;
    final registeredIds = registrations
        .where((item) => item.occupiesSeat)
        .map((item) => item.eventId)
        .toSet();
    final conflicts = ScheduleConflictService(config: config).conflicts(
      event,
      schedules: schedules,
      registeredEvents: events
          .where((item) => registeredIds.contains(item.id))
          .toList(),
      profile: profile,
    );
    final availability = conflicts.isEmpty ? 1.0 : 0.0;
    final engagedIds = {
      ...favorites,
      ...viewedEvents,
      ...registrations
          .where((item) => item.status != RegistrationStatus.canceled)
          .map((item) => item.eventId),
    };
    final relatedHistory = events.any(
      (item) => engagedIds.contains(item.id) && item.category == event.category,
    );
    final history = relatedHistory ? 1.0 : 0.0;
    final location = profile.preferredVenue == event.venue ? 1.0 : 0.0;
    final breakdown = {
      'Sở thích': interestScore,
      'Kỹ năng cần phát triển': skillScore,
      'Lịch trống': availability,
      'Lịch sử tương tác': history,
      'Địa điểm': location,
    };
    final total = breakdown.entries.fold<double>(
      0,
      (sum, item) => sum + item.value * (config.weights[item.key] ?? 0),
    );
    final score = config.weightSum <= 0
        ? 0
        : (100 * total / config.weightSum).round().clamp(0, 100);
    if (interests.isNotEmpty) {
      reasons.add('Khớp sở thích: ${interests.join(', ')}.');
    }
    if (matches.isNotEmpty) {
      reasons.add('Hỗ trợ kỹ năng cần phát triển: ${matches.join(', ')}.');
    }
    if (conflicts.isEmpty) {
      reasons.add(
        'Không trùng lịch học và sự kiện đã đăng ký trong dữ liệu hiện có.',
      );
    }
    if (relatedHistory) {
      reasons.add('Cùng chủ đề với sự kiện bạn đã xem, lưu hoặc đăng ký.');
    }
    if (location == 1) reasons.add('Tổ chức tại cơ sở bạn ưu tiên.');
    final warnings = [...conflicts];
    if (schedules.isEmpty) {
      warnings.add('Chưa có lịch học để kiểm tra đầy đủ thời gian trống.');
    }
    if (profile.interests.isEmpty) {
      warnings.add('Chưa có sở thích để đối chiếu.');
    }
    if (targetSkills.isEmpty) {
      warnings.add('Chưa có bộ kỹ năng cho mục tiêu nghề nghiệp này.');
    }
    if (!relatedHistory) warnings.add('Chưa có lịch sử tương tác cùng chủ đề.');
    if (location == 0) warnings.add('Địa điểm khác cơ sở bạn ưu tiên.');
    return Recommendation(
      score: score,
      reasons: reasons,
      warnings: warnings,
      breakdown: breakdown,
    );
  }
}
