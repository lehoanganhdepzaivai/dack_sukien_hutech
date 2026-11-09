import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../providers/app_store.dart';
import 'activity_report.dart';
import 'activity_pdf_preview.dart';
import 'student_widgets.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  RegistrationStatus? _filter;
  bool _exporting = false;
  String? _canceling;

  Future<void> _export({bool preview = false}) async {
    final store = context.read<AppStore>();
    final profile = store.profile;
    if (profile == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = await ActivityReport.build(
        profile: profile,
        registrations: store.registrations,
        events: store.events,
      );
      if (!mounted) return;
      final fileName = 'Ho-so-hoat-dong-${profile.studentId}.pdf';
      if (preview) {
        await showDialog<void>(
          context: context,
          useSafeArea: false,
          builder: (_) => ActivityPdfPreview(bytes: bytes, fileName: fileName),
        );
      } else {
        await Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
      }
    } catch (_) {
      if (mounted) {
        studentMessage(
          context,
          'Chưa xuất được PDF. Hãy tải lại trang và thử lại.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _cancel(EventModel event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký sự kiện?'),
        content: Text(
          'Bạn muốn hủy đăng ký “${event.title}”? Nếu có người trong danh sách chờ, chỗ trống sẽ được chuyển cho người tiếp theo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ đăng ký'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    setState(() => _canceling = event.id);
    try {
      final message = await context.read<AppStore>().cancelRegistration(
        event.id,
      );
      if (mounted) studentMessage(context, message);
    } catch (error) {
      if (mounted) studentMessage(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _canceling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final registrations = [...store.registrations]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filtered = registrations
        .where((item) => _filter == null || item.status == _filter)
        .toList();
    return DefaultTabController(
      length: RegistrationStatus.values.length + 1,
      child: StudentPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentHeading(
              eyebrow: 'Trải nghiệm của bạn',
              title: 'Sự kiện của tôi',
              subtitle: 'Theo dõi đăng ký, quản lý vé và nhìn lại những hoạt động bạn đã chọn.',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : () => _export(preview: true),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Xem trước PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : () => _export(),
                    icon: _exporting
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(
                      _exporting ? 'Đang tạo PDF...' : 'Xuất hồ sơ PDF',
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              onTap: (index) => setState(() {
                _filter = index == 0
                    ? null
                    : RegistrationStatus.values[index - 1];
              }),
              tabs: [
                Tab(text: 'Tất cả (${registrations.length})'),
                ...RegistrationStatus.values.map(
                  (status) => Tab(
                    text:
                        '${status.label} (${registrations.where((item) => item.status == status).length})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (filtered.isEmpty)
              StudentCard(
                child: StudentEmpty(
                  icon: Icons.confirmation_number_outlined,
                  title: _filter == null
                      ? 'Hành trình của bạn bắt đầu từ đây'
                      : 'Chưa có sự kiện ${_filter!.label.toLowerCase()}',
                  message: 'Khám phá những hoạt động theo sở thích, lưu một lựa chọn và dành chỗ cho trải nghiệm tiếp theo.',
                  action: FilledButton.icon(
                    onPressed: () => context.go('/events'),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text('Khám phá sự kiện'),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final registration = filtered[index];
                  final event = store.eventById(registration.eventId);
                  if (event == null) {
                    return StudentCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Sự kiện không còn công khai'),
                        subtitle: Text('Mã đăng ký: ${registration.id}'),
                        trailing: StudentPill(registration.status.label),
                      ),
                    );
                  }
                  final active =
                      registration.status == RegistrationStatus.confirmed ||
                      registration.status == RegistrationStatus.waitlisted;
                  final canceled = event.status == EventStatus.canceled;
                  final canCancel =
                      active &&
                      !canceled &&
                      event.start.isAfter(DateTime.now());
                  final canTicket =
                      !canceled &&
                      (registration.status == RegistrationStatus.confirmed ||
                          registration.status == RegistrationStatus.attended);
                  return StudentCard(
                    padding: const EdgeInsets.all(22),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final information = Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 58,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: studentBlue.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    event.start.day.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: studentBlue,
                                    ),
                                  ),
                                  Text(
                                    'TH ${event.start.month}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: .6,
                                      fontWeight: FontWeight.w700,
                                      color: studentBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      StudentPill(
                                        registration.status.label,
                                        color: _statusColor(
                                          registration.status,
                                        ),
                                      ),
                                      if (canceled)
                                        const StudentPill(
                                          'Sự kiện đã hủy',
                                          color: Color(0xFFB33B3B),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      _Meta(
                                        Icons.schedule,
                                        studentDateTime(event.start),
                                      ),
                                      _Meta(
                                        Icons.location_on_outlined,
                                        event.venue,
                                      ),
                                    ],
                                  ),
                                  if (registration.status ==
                                      RegistrationStatus.waitlisted) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Bạn sẽ được thông báo khi có chỗ trống.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF987000),
                                      ),
                                    ),
                                  ],
                                  if (canceled) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Vé không còn hiệu lực vì sự kiện đã bị hủy.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB33B3B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (canTicket)
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    context.go('/ticket/${event.id}'),
                                icon: const Icon(
                                  Icons.qr_code_rounded,
                                  size: 18,
                                ),
                                label: const Text('Xem vé'),
                              ),
                            OutlinedButton(
                              onPressed: () =>
                                  context.go('/events/${event.id}'),
                              child: const Text('Chi tiết'),
                            ),
                            if (canCancel)
                              TextButton(
                                onPressed: _canceling == event.id
                                    ? null
                                    : () => _cancel(event),
                                child: Text(
                                  _canceling == event.id
                                      ? 'Đang hủy...'
                                      : 'Hủy đăng ký',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        );
                        if (constraints.maxWidth < 850) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              information,
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: information),
                            const SizedBox(width: 20),
                            SizedBox(width: 265, child: actions),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _statusColor(RegistrationStatus status) => switch (status) {
    RegistrationStatus.confirmed => studentBlue,
    RegistrationStatus.waitlisted => const Color(0xFF9D7700),
    RegistrationStatus.canceled => const Color(0xFFAD4F4F),
    RegistrationStatus.attended => const Color(0xFF238461),
  };
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 5),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}
