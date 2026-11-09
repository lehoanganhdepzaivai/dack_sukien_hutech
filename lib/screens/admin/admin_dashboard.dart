import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final groups = {
      for (final category in store.categories)
        category: store.events
            .where(
              (e) => e.category == category && e.status != EventStatus.archived,
            )
            .length,
    };
    final active = groups.entries.where((e) => e.value > 0).toList();
    const colors = [
      AppColors.blue,
      Color(0xFFFFCD37),
      Color(0xFF57B5B0),
      Color(0xFF8F9FDB),
      Color(0xFFED9B68),
      Color(0xFF9ABF76),
    ];
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Tổng quan quản trị',
            subtitle: 'Theo dõi và quản lý những trải nghiệm của cộng đồng sinh viên.',
            trailing: FilledButton.icon(
              onPressed: () => context.go('/admin/events/new'),
              icon: const Icon(Icons.add, size: 19),
              label: const Text('Tạo sự kiện'),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: store.isCloudBackend
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: store.isCloudBackend
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  store.isCloudBackend
                      ? Icons.cloud_done_outlined
                      : Icons.storage_outlined,
                  size: 20,
                  color: store.isCloudBackend
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trạng thái backend: ${store.backendStatusText}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: store.isCloudBackend
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeading(
            'Thao tác nhanh',
            subtitle: 'Mỗi chức năng quản trị chính được mở trực tiếp từ đây.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _actionCard(
                  context,
                  c.maxWidth,
                  title: 'Thêm sự kiện',
                  description: 'Tạo sự kiện mới, tải ảnh và mở đăng ký.',
                  icon: Icons.add_circle_outline_rounded,
                  route: '/admin/events/new',
                  primary: true,
                  key: const Key('admin-create-event-action'),
                ),
                _actionCard(
                  context,
                  c.maxWidth,
                  title: 'Sự kiện & hình ảnh',
                  description: 'Chỉnh sửa nội dung, trạng thái và hình ảnh.',
                  icon: Icons.edit_calendar_outlined,
                  route: '/admin/events',
                ),
                _actionCard(
                  context,
                  c.maxWidth,
                  title: 'Danh mục',
                  description: 'Quản lý các nhóm sự kiện trong hệ thống.',
                  icon: Icons.category_outlined,
                  route: '/admin/categories',
                ),
                _actionCard(
                  context,
                  c.maxWidth,
                  title: 'Người tham gia',
                  description: 'Theo dõi đăng ký và trạng thái tham dự.',
                  icon: Icons.groups_outlined,
                  route: '/admin/participants',
                ),
                _actionCard(
                  context,
                  c.maxWidth,
                  title: 'Điểm danh QR',
                  description: 'Quét mã QR vé hoặc nhập mã để ghi nhận tham dự.',
                  icon: Icons.qr_code_scanner_rounded,
                  route: '/admin/checkin',
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _metric(
                  c.maxWidth,
                  'Tổng sự kiện',
                  '${store.events.length}',
                  Icons.event_note_outlined,
                  AppColors.blue,
                ),
                _metric(
                  c.maxWidth,
                  'Đang nhận đăng ký',
                  '${store.events.where((e) => e.isRegistrationOpen).length}',
                  Icons.event_available_outlined,
                  const Color(0xFF258B73),
                ),
                _metric(
                  c.maxWidth,
                  'Lượt đăng ký',
                  '${store.allRegistrations.where((r) => r.status.name != 'canceled').length}',
                  Icons.groups_outlined,
                  const Color(0xFFBA8412),
                ),
                _metric(
                  c.maxWidth,
                  'Chờ phê duyệt',
                  '${store.events.where((e) => e.status == EventStatus.pending).length}',
                  Icons.pending_actions_outlined,
                  const Color(0xFF8760AF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    'Sự kiện theo chủ đề',
                    subtitle:
                        'Phân bố từ những sự kiện đang có trong hệ thống.',
                  ),
                  const SizedBox(height: 22),
                  if (active.isEmpty)
                    const Text('Chưa có dữ liệu sự kiện.')
                  else
                    LayoutBuilder(
                      builder: (context, c) {
                        final chart = SizedBox(
                          width: 250,
                          height: 230,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 55,
                              sectionsSpace: 4,
                              sections: [
                                for (var i = 0; i < active.length; i++)
                                  PieChartSectionData(
                                    value: active[i].value.toDouble(),
                                    title: '${active[i].value}',
                                    radius: 38,
                                    color: colors[i % colors.length],
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                        final legend = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < active.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: colors[i % colors.length],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Flexible(child: Text(active[i].key)),
                                    const SizedBox(width: 18),
                                    Text(
                                      '${active[i].value}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                        return c.maxWidth > 600
                            ? Row(
                                children: [
                                  chart,
                                  const SizedBox(width: 45),
                                  Expanded(child: legend),
                                ],
                              )
                            : Column(children: [chart, legend]);
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          const EmptyPanel(
            title: 'Chưa đủ dữ liệu để đánh giá',
            message: 'Báo cáo hiệu quả sẽ xuất hiện khi có điểm danh và bài đánh giá trước, sau sự kiện.',
            icon: Icons.insights_outlined,
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context,
    double width, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
    bool primary = false,
    Key? key,
  }) {
    final cardWidth = width > 1000
        ? (width - 42) / 4
        : width > 560
        ? (width - 14) / 2
        : width;
    return SizedBox(
      width: cardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: primary ? const Color(0xFFFFF4B8) : null,
        child: InkWell(
          key: key,
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary
                            ? AppColors.blue
                            : AppColors.blue.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: primary ? Colors.white : AppColors.blue,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metric(
    double width,
    String title,
    String count,
    IconData icon,
    Color color,
  ) => SizedBox(
    width: width > 1000
        ? (width - 48) / 4
        : width > 540
        ? (width - 16) / 2
        : width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              count,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}
