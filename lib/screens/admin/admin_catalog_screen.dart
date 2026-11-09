import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class AdminCatalogScreen extends StatelessWidget {
  const AdminCatalogScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Danh mục hệ thống',
            subtitle: 'Tổ chức chủ đề để sinh viên dễ tìm trải nghiệm phù hợp.',
            trailing: FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm chủ đề'),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: store.categories
                  .map(
                    (c) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 6,
                      ),
                      leading: const Icon(
                        Icons.category_outlined,
                        color: AppColors.blue,
                      ),
                      title: Text(c),
                      subtitle: Text(
                        '${store.events.where((e) => e.category == c).length} sự kiện',
                      ),
                      trailing: IconButton(
                        tooltip: 'Xóa chủ đề',
                        onPressed: () async {
                          if (await confirmAction(
                                context,
                                'Xóa chủ đề?',
                                'Chỉ có thể xóa chủ đề chưa được sử dụng.',
                              ) &&
                              context.mounted) {
                            await runAction(
                              context,
                              () => store.removeCategory(c),
                              success: 'Đã xóa chủ đề.',
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeading('Địa điểm'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: store.venues
                .map(
                  (v) => Chip(
                    avatar: const Icon(Icons.place_outlined, size: 18),
                    label: Text(v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 27),
          const SectionHeading(
            'Khoa, viện & đơn vị đào tạo',
            subtitle: 'Danh sách đối chiếu từ website HUTECH.',
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: store.faculties
                  .map(
                    (f) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      title: Text(f),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 27),
          const SectionHeading('Kỹ năng'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.skills.map((s) => LabelPill(s)).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm chủ đề sự kiện'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên chủ đề'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (name != null && context.mounted) {
      await runAction(
        context,
        () => context.read<AppStore>().addCategory(name),
        success: 'Đã thêm chủ đề.',
      );
    }
    // Dispose after the dialog's closing transition has released the TextField.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }
}

class AdminParticipantsScreen extends StatefulWidget {
  const AdminParticipantsScreen({super.key});
  @override
  State<AdminParticipantsScreen> createState() =>
      _AdminParticipantsScreenState();
}

class _AdminParticipantsScreenState extends State<AdminParticipantsScreen> {
  String? _event;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final rows = store.allRegistrations
        .where((r) => _event == null || r.eventId == _event)
        .toList();
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            'Người tham gia',
            subtitle: 'Danh sách đăng ký theo từng sự kiện.',
            trailing: OutlinedButton.icon(
              onPressed: rows.isEmpty
                  ? null
                  : () async {
                      String quote(String s) => '"${s.replaceAll('"', '""')}"';
                      final lines = [
                        'Họ tên,Email,Sự kiện,Trạng thái',
                        ...rows.map((r) {
                          final user = store.allUsers
                              .where((u) => u.id == r.userId)
                              .firstOrNull;
                          return [
                            user?.name ?? r.userId,
                            user?.email ?? '',
                            store.eventById(r.eventId)?.title ?? r.eventId,
                            r.status.label,
                          ].map(quote).join(',');
                        }),
                      ];
                      await Clipboard.setData(
                        ClipboardData(text: lines.join('\r\n')),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép danh sách CSV.'),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Sao chép CSV'),
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _event,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lọc theo sự kiện'),
            items: [
              const DropdownMenuItem<String>(child: Text('Tất cả sự kiện')),
              ...store.events.map(
                (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _event = v),
          ),
          const SizedBox(height: 24),
          if (rows.isEmpty)
            const EmptyPanel(
              title: 'Chưa có người đăng ký',
              message: 'Danh sách sẽ cập nhật khi sinh viên đăng ký sự kiện.',
              icon: Icons.groups_outlined,
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: rows.map((r) {
                  final user = store.allUsers
                      .where((u) => u.id == r.userId)
                      .firstOrNull;
                  return ListTile(
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      user?.name ?? r.userId,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${store.eventById(r.eventId)?.title ?? r.eventId}\n${user?.studentId ?? ''} · ${r.status.label}',
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 28),
          const SectionHeading('Tài khoản trong hệ thống'),
          const SizedBox(height: 15),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: store.allUsers
                  .map(
                    (u) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.blue,
                      ),
                      title: Text(u.name),
                      subtitle: Text(u.email),
                      trailing: LabelPill(
                        u.id == 'admin' ? 'Quản trị viên' : 'Sinh viên',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
