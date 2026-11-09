import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});
  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _query = '';
  EventStatus? _status;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final events =
        store.events
            .where(
              (e) =>
                  (_status == null || e.status == _status) &&
                  '${e.title} ${e.organization}'.toLowerCase().contains(
                    _query.toLowerCase(),
                  ),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Sự kiện & hình ảnh',
            subtitle:
                'Tạo nội dung, quản lý ảnh và cập nhật trạng thái sự kiện.',
            trailing: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDatabaseDialog(context),
                  icon: const Icon(Icons.storage_rounded, size: 18),
                  label: const Text('Cơ sở dữ liệu'),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/events/new'),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Thêm sự kiện'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 350,
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tên sự kiện, đơn vị tổ chức...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 245,
                child: DropdownButtonFormField<EventStatus>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: [
                    const DropdownMenuItem<EventStatus>(
                      child: Text('Tất cả trạng thái'),
                    ),
                    ...EventStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (s) => setState(() => _status = s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (events.isEmpty)
            const EmptyPanel(
              title: 'Chưa có sự kiện phù hợp',
              message: 'Thêm sự kiện mới hoặc điều chỉnh bộ lọc.',
            )
          else
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final info = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 7,
                              children: [
                                LabelPill(e.status.label),
                                if (e.featured)
                                  const LabelPill(
                                    'Nổi bật',
                                    color: Color(0xFF997315),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              e.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${DateFormat('dd/MM/yyyy · HH:mm').format(e.start)}   /   ${e.venue}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${store.registrationCount(e.id)}/${e.capacity} người đăng ký · ${store.waitlistCount(e.id)} chờ',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                        final actions = Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Chỉnh sửa sự kiện',
                              onPressed: () =>
                                  context.push('/admin/events/${e.id}/edit'),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.blue,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Xem chi tiết',
                              onPressed: () => context.push('/events/${e.id}'),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            if (e.status == EventStatus.pending)
                              IconButton(
                                tooltip: 'Duyệt sự kiện',
                                onPressed: () => runAction(
                                  context,
                                  () => store.setEventStatus(
                                    e.id,
                                    EventStatus.published,
                                  ),
                                  success: 'Đã duyệt sự kiện.',
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                              ),
                            IconButton(
                              tooltip: 'Hủy hoặc lưu trữ',
                              onPressed: () async {
                                if (await confirmAction(
                                      context,
                                      'Hủy hoặc lưu trữ sự kiện?',
                                      'Sự kiện có đăng ký sẽ được hủy và thông báo cho người tham gia. Dữ liệu đăng ký được giữ lại.',
                                    ) &&
                                    context.mounted) {
                                  await runAction(
                                    context,
                                    () => store.deleteEvent(e.id),
                                    success: 'Đã cập nhật sự kiện.',
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.archive_outlined,
                                color: Color(0xFF9D5555),
                              ),
                            ),
                          ],
                        );
                        return c.maxWidth > 700
                            ? Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 160,
                                      height: 116,
                                      child: EventImage(e.image),
                                    ),
                                  ),
                                  const SizedBox(width: 22),
                                  Expanded(child: info),
                                  const SizedBox(width: 14),
                                  actions,
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 180,
                                      width: double.infinity,
                                      child: EventImage(e.image),
                                    ),
                                  ),
                                  const SizedBox(height: 17),
                                  info,
                                  const SizedBox(height: 13),
                                  actions,
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDatabaseDialog(BuildContext context) {
    final store = context.read<AppStore>();
    final importController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: AppColors.blue),
            SizedBox(width: 10),
            Text('Quản lý Cơ sở dữ liệu'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cơ sở dữ liệu đang lưu trữ toàn bộ sự kiện, thông tin và hình ảnh cục bộ (SQLite / LocalStorage).',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCCE4FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tổng số sự kiện hiện có: ${store.events.length} sự kiện',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '1. Sao lưu dữ liệu vĩnh viễn:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final json = store.exportDatabaseJson();
                      Clipboard.setData(ClipboardData(text: json));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã sao chép toàn bộ dữ liệu CSDL (gồm tất cả sự kiện và hình ảnh) vào bộ nhớ tạm!',
                          ),
                          backgroundColor: AppColors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Sao chép toàn bộ CSDL (.json)'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '2. Khôi phục từ bản sao lưu JSON:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: importController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Dán chuỗi JSON đã sao lưu vào đây...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final text = importController.text.trim();
                      if (text.isEmpty) return;
                      try {
                        await store.importDatabaseJson(text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Khôi phục CSDL thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi định dạng CSDL: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Khôi phục CSDL ngay'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
