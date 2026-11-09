import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../providers/app_store.dart';
import '../../services/event_link.dart';
import '../../widgets/common.dart';
import '../../widgets/event_certificate_dialog.dart';
import '../../widgets/event_feedback_dialog.dart';
import '../../widgets/event_image_viewer.dart';
import '../../widgets/event_qa_section.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String get eventId => widget.eventId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        runAction(
          context,
          () => context.read<AppStore>().recordEventView(eventId),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final event = store.eventById(eventId);
    if (event == null) {
      return const ContentArea(
        child: EmptyPanel(
          title: 'Không tìm thấy sự kiện',
          message: 'Sự kiện không tồn tại hoặc bạn chưa có quyền truy cập.',
        ),
      );
    }
    final rec = store.isAdmin ? null : store.recommendation(event);
    final reg = store.registrationFor(eventId);
    final registered = reg != null && reg.status.name != 'canceled';
    final canRegister =
        event.isRegistrationOpen &&
        DateTime.now().isBefore(event.deadline) &&
        DateTime.now().isBefore(event.start);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Về sự kiện'),
        const SizedBox(height: 16),
        Text(
          event.description,
          style: const TextStyle(height: 1.9, fontSize: 15),
        ),
        const SizedBox(height: 25),
        const SectionHeading('Bạn sẽ nhận được gì?'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: event.skills.map((s) => LabelPill(s)).toList(),
        ),
        const SizedBox(height: 25),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info(
                  Icons.apartment_outlined,
                  'Đơn vị tổ chức',
                  event.organization,
                ),
                const SizedBox(height: 20),
                _info(Icons.location_on_outlined, 'Địa điểm', event.venue),
                const SizedBox(height: 20),
                _info(
                  Icons.groups_outlined,
                  'Đối tượng',
                  'Sinh viên quan tâm đến ${event.category.toLowerCase()}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 27),
        if (store.isAuthenticated && rec != null) ...[
          SectionHeading(
            'Vì sao phù hợp với bạn?',
            trailing: LabelPill('${rec.score}/100 điểm'),
          ),
          const SizedBox(height: 12),
          ...rec.reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF288675),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...rec.warnings.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFB07A12),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Điểm phù hợp được tính bằng các tiêu chí và trọng số minh bạch.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 28),
        const SectionHeading('Tài liệu & Học liệu sự kiện'),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.blue),
                  ),
                  title: const Text('Slide báo cáo & Tài liệu hướng dẫn.pdf', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Định dạng PDF • Cung cấp bởi Ban tổ chức HUTECH', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang tải tài liệu sự kiện...'),
                          backgroundColor: AppColors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Tải về'),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.green),
                  ),
                  title: const Text('Kho mã nguồn & Tài nguyên thực hành', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('GitHub & Google Drive đính kèm', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép liên kết tài nguyên thực hành.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Mở link'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        EventQASection(eventId: event.id),
      ],
    );
    final booking = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabelPill(
              event.status.label,
              color: event.status == EventStatus.canceled
                  ? Colors.red
                  : const Color(0xFF24846C),
            ),
            const SizedBox(height: 23),
            _info(
              Icons.calendar_month_outlined,
              'Thời gian',
              DateFormat('dd/MM/yyyy').format(event.start),
            ),
            const SizedBox(height: 18),
            _info(
              Icons.access_time_rounded,
              'Khung giờ',
              '${DateFormat('HH:mm').format(event.start)} – ${DateFormat('HH:mm, dd/MM').format(event.end)}',
            ),
            const SizedBox(height: 18),
            _info(
              Icons.hourglass_bottom_outlined,
              'Hạn đăng ký',
              DateFormat('HH:mm · dd/MM/yyyy').format(event.deadline),
            ),
            const SizedBox(height: 18),
            _info(Icons.people_outline, 'Sức chứa', '${event.capacity} chỗ'),
            const SizedBox(height: 23),
            if (store.isAdmin)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/admin/events/$eventId/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Chỉnh sửa sự kiện'),
                ),
              )
            else if (registered) ...[
              Text(
                'Trạng thái vé: ${reg.status.label}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/ticket/$eventId'),
                  icon: const Icon(Icons.qr_code_rounded, size: 20),
                  label: const Text('Xem vé của tôi'),
                ),
              ),
              if (reg.status == RegistrationStatus.attended && store.profile != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF084F98),
                      side: const BorderSide(color: Color(0xFF084F98)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EventCertificateDialog(
                          event: event,
                          profile: store.profile!,
                          certificateCode: 'HUTECH-CERT-${event.id.toUpperCase()}-${store.profile!.studentId}',
                          checkInTime: reg.createdAt,
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 19),
                    label: const Text('Nhận Giấy chứng nhận'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBA8412),
                      side: const BorderSide(color: Color(0xFFBA8412)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EventFeedbackDialog(
                          event: event,
                          onSubmit: (rating, content, speaker, org, comment) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cảm ơn bạn đã gửi đánh giá! Ý kiến của bạn đã được ghi nhận.'),
                                backgroundColor: Color(0xFF24846C),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rounded, size: 19),
                    label: const Text('Đánh giá sự kiện'),
                  ),
                ),
              ],
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !canRegister
                      ? null
                      : () async {
                          if (!store.isAuthenticated) {
                            context.push(
                              '/login?from=${Uri.encodeComponent('/events/$eventId')}',
                            );
                            return;
                          }
                          final conflicts = store.registrationConflicts(
                            eventId,
                          );
                          if (conflicts.isNotEmpty) {
                            final ok = await confirmAction(
                              context,
                              'Lịch của bạn đang bị trùng',
                              '${conflicts.join('\n\n')}\n\n'
                                  'Bạn muốn hủy thao tác hay vẫn đăng ký sự kiện này?',
                              cancelLabel: 'Hủy',
                              confirmLabel: 'Vẫn đăng ký',
                            );
                            if (!ok || !context.mounted) return;
                          }
                          if (context.mounted) {
                            await runAction(
                              context,
                              () => store.registerEvent(
                                eventId,
                                continueOnConflict: conflicts.isNotEmpty,
                              ),
                            );
                          }
                        },
                  icon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 20,
                  ),
                  label: Text(
                    event.status == EventStatus.full
                        ? 'Tham gia danh sách chờ'
                        : 'Đăng ký tham gia',
                  ),
                ),
              ),
            if (!store.isAdmin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!store.isAuthenticated) {
                      context.push('/login');
                      return;
                    }
                    runAction(context, () => store.toggleFavorite(eventId));
                  },
                  icon: Icon(
                    store.favorites.contains(eventId)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 19,
                  ),
                  label: Text(
                    store.favorites.contains(eventId)
                        ? 'Đã lưu sự kiện'
                        : 'Lưu để xem sau',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => runAction(
                  context,
                  () => Clipboard.setData(
                    ClipboardData(
                      text: eventPageUri(Uri.base, eventId).toString(),
                    ),
                  ),
                  success: 'Đã sao chép liên kết sự kiện.',
                ),
                icon: const Icon(Icons.link_rounded, size: 20),
                label: const Text('Sao chép liên kết'),
              ),
            ),
            if (!store.isAdmin && !canRegister && !registered)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Sự kiện hiện không nhận đăng ký.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () =>
                context.go(store.isAdmin ? '/admin/events' : '/events'),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: Text(store.isAdmin ? 'Quản lý sự kiện' : 'Khám phá sự kiện'),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              LabelPill(event.category),
              LabelPill(event.venue, color: const Color(0xFF8E6E1A)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 25),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              child: InkWell(
                onTap: () => showEventImageViewer(
                  context,
                  source: event.image,
                  title: event.title,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).width < 700 ? 220 : 350,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EventImage(event.image),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xDD101B2B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Xem ảnh toàn màn hình',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          LayoutBuilder(
            builder: (context, c) => c.maxWidth > 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: details),
                      const SizedBox(width: 35),
                      SizedBox(width: 315, child: booking),
                    ],
                  )
                : Column(
                    children: [booking, const SizedBox(height: 30), details],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.blue, size: 21),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
