import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/recommendation_config.dart';
import '../../models/event_model.dart';
import '../../models/recommendation.dart';
import '../../models/registration_model.dart';
import '../../providers/app_store.dart';
import 'student_widgets.dart';

class DevelopmentScreen extends StatelessWidget {
  const DevelopmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final profile = store.profile;
    if (profile == null) {
      return const StudentPage(
        child: StudentEmpty(
          icon: Icons.route_outlined,
          title: 'Lộ trình dành riêng cho bạn',
          message: 'Đăng nhập và bổ sung mục tiêu nghề nghiệp để nhận đề xuất.',
        ),
      );
    }
    final requiredSkills =
        RecommendationConfig.careerSkills[profile.careerGoal] ?? <String>[];
    final held = requiredSkills
        .where((skill) => profile.skills.contains(skill))
        .toList();
    final missing = requiredSkills
        .where((skill) => !profile.skills.contains(skill))
        .toList();
    final upcoming = store.events.where((event) {
      final registration = store.registrationFor(event.id);
      final alreadyRegistered =
          registration != null &&
          registration.status != RegistrationStatus.canceled;
      return !alreadyRegistered &&
          event.isPublic &&
          event.isRegistrationOpen &&
          event.deadline.isAfter(DateTime.now()) &&
          event.start.isAfter(DateTime.now());
    }).toList();
    final scores = {
      for (final event in upcoming) event.id: store.recommendation(event),
    };
    upcoming.sort((a, b) => scores[b.id]!.score.compareTo(scores[a.id]!.score));
    final recommended = upcoming.take(4).toList();
    final matchingRoadmap = upcoming
        .where((event) => event.skills.any(missing.contains))
        .toList();
    const config = RecommendationConfig();
    return StudentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentHeading(
            eyebrow: 'Hiểu mình · Chọn đúng · Đi xa',
            title: 'Hành trình phát triển',
            subtitle: 'Kết nối điều bạn muốn trở thành với những trải nghiệm giúp bạn tiến gần hơn.',
            action: OutlinedButton.icon(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Cập nhật mục tiêu'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF084E95), Color(0xFF087DC1)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MỤC TIÊU NGHỀ NGHIỆP',
                      style: TextStyle(
                        color: Color(0xFFC6E7FF),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.careerGoal.isEmpty
                          ? 'Bạn muốn trở thành ai?'
                          : profile.careerGoal,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      requiredSkills.isEmpty
                          ? 'Chọn một mục tiêu trong hồ sơ để xem nhóm kỹ năng và sự kiện phù hợp.'
                          : '${held.length}/${requiredSkills.length} kỹ năng mục tiêu đã tự khai · ${missing.length} kỹ năng cần phát triển',
                      style: const TextStyle(
                        color: Color(0xFFE4F2FF),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Kỹ năng tự khai giúp định hướng. Tiến độ có minh chứng chỉ được ghi nhận khi đủ điều kiện hoàn thành.',
                      style: TextStyle(
                        color: Color(0xFFCCE7FA),
                        height: 1.6,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 560) return content;
                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 32),
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .2),
                        ),
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: studentGold,
                        size: 60,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          StudentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StudentSectionTitle(
                  'Bản đồ kỹ năng',
                  subtitle: 'Mục tiêu nghề nghiệp → Kỹ năng cần có → Sự kiện hỗ trợ → Minh chứng hoàn thành.',
                ),
                if (requiredSkills.isEmpty)
                  const StudentEmpty(
                    icon: Icons.flag_outlined,
                    title: 'Chưa có khung kỹ năng cho mục tiêu này',
                    message: 'Bạn có thể chọn một mục tiêu được gợi ý trong hồ sơ. Những kỹ năng tự khai vẫn được lưu nguyên vẹn.',
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: requiredSkills.map((skill) {
                      final has = profile.skills.contains(skill);
                      return Container(
                        padding: const EdgeInsets.all(16),
                        width: 206,
                        decoration: BoxDecoration(
                          color: has
                              ? studentBlue.withValues(alpha: .045)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: has
                                ? studentBlue.withValues(alpha: .2)
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              has
                                  ? Icons.check_circle_outline
                                  : Icons.add_circle_outline,
                              color: has
                                  ? studentBlue
                                  : const Color(0xFFB68C0B),
                              size: 23,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              skill,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              has ? 'Đã tự khai' : 'Cần phát triển',
                              style: TextStyle(
                                fontSize: 12,
                                color: has
                                    ? studentBlue
                                    : const Color(0xFF9C7700),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const StudentSectionTitle(
            'Những bước tiếp theo',
            subtitle:
                'Gợi ý dựa trên kỹ năng bạn còn thiếu trong mục tiêu đã chọn.',
          ),
          if (requiredSkills.isEmpty ||
              missing.isEmpty ||
              matchingRoadmap.isEmpty)
            StudentCard(
              child: StudentEmpty(
                icon: Icons.route_outlined,
                title: missing.isEmpty && requiredSkills.isNotEmpty
                    ? 'Bạn đã khai đủ kỹ năng mục tiêu'
                    : 'Chưa có sự kiện phù hợp với kỹ năng còn thiếu',
                message: missing.isEmpty && requiredSkills.isNotEmpty
                    ? 'Tiếp tục tích lũy minh chứng qua các hoạt động và điều kiện hoàn thành được xác nhận.'
                    : 'Lộ trình sẽ được bổ sung khi có sự kiện hỗ trợ nhóm kỹ năng này.',
                action: TextButton(
                  onPressed: () => context.go('/events'),
                  child: const Text('Xem tất cả sự kiện'),
                ),
              ),
            )
          else
            Column(
              children: matchingRoadmap.take(4).toList().asMap().entries.map((
                item,
              ) {
                final event = item.value;
                final skills = event.skills.where(missing.contains).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StudentCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: studentGold.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.key + 1}'.padLeft(2, '0'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8E6B00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Giúp bạn phát triển: ${skills.join(', ')}.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(height: 1.6),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                studentDateTime(event.start),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Xem sự kiện',
                          onPressed: () => context.go('/events/${event.id}'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: studentBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 18),
          StudentSectionTitle(
            'Dành riêng cho bạn',
            subtitle: 'Điểm phù hợp được tính bằng công thức trọng số, có giải thích cho từng lựa chọn.',
            trailing: TextButton(
              onPressed: () => _showWeights(context, config),
              child: const Text('Cách tính điểm'),
            ),
          ),
          if (recommended.isEmpty)
            const StudentCard(
              child: StudentEmpty(
                icon: Icons.auto_awesome_outlined,
                title: 'Chưa có sự kiện đang mở phù hợp',
                message: 'Các đề xuất sẽ xuất hiện khi có sự kiện mới đang nhận đăng ký.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 780 ? 2 : 1;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: recommended
                      .map(
                        (event) => SizedBox(
                          width:
                              (constraints.maxWidth - (columns - 1) * 18) /
                              columns,
                          child: _RecommendationCard(
                            event: event,
                            result: scores[event.id]!,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          const SizedBox(height: 26),
          StudentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StudentSectionTitle(
                  'Minh chứng & chứng nhận',
                  subtitle: 'Chỉ ghi nhận khi đã đăng ký, điểm danh hợp lệ và hoàn thành yêu cầu đánh giá.',
                ),
                const StudentEmpty(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Chưa có minh chứng hoàn thành',
                  message: 'Đăng ký sự kiện không tự động cộng kỹ năng hoặc cấp chứng nhận. Minh chứng sẽ xuất hiện sau khi kết quả được xác nhận.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  void _showWeights(
    BuildContext context,
    RecommendationConfig config,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Điểm phù hợp được tính thế nào?'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mỗi tiêu chí được chuẩn hóa từ 0 đến 1, nhân trọng số rồi quy đổi ra thang điểm 100.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              ...config.weights.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(
                        '${(entry.value * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: studentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Khoảng đệm di chuyển giữa các cơ sở: ${config.travelBufferMinutes} phút. Đây là quy tắc lập kế hoạch; không phải ước tính giao thông thực tế.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.event, required this.result});
  final EventModel event;
  final Recommendation result;

  @override
  Widget build(BuildContext context) => StudentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: StudentPill(event.category)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: studentGold.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${result.score}% phù hợp',
                style: const TextStyle(
                  color: Color(0xFF896900),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          event.title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          '${studentDateTime(event.start)} · ${event.venue}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 18),
        ...result.reasons
            .take(3)
            .map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: studentBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 12, height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ...result.warnings.map(
          (warning) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB57D00),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(
                      color: Color(0xFF9D6A00),
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const Text(
            'Xem từng tiêu chí',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          children: result.breakdown.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: entry.value.clamp(0, 1),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.go('/events/${event.id}'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Xem sự kiện'),
          ),
        ),
      ],
    ),
  );
}
