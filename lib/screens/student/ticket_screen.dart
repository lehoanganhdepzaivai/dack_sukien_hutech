import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../providers/app_store.dart';
import 'student_widgets.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final profile = store.profile;
    final event = store.eventById(eventId);
    final registration = store.registrationFor(eventId);
    final valid =
        profile != null &&
        event != null &&
        event.status != EventStatus.canceled &&
        registration != null &&
        (registration.status == RegistrationStatus.confirmed ||
            registration.status == RegistrationStatus.attended);
    if (!valid) {
      return StudentPage(
        child: StudentCard(
          child: StudentEmpty(
            icon: Icons.confirmation_number_outlined,
            title: 'Chưa có vé hợp lệ',
            message: registration?.status == RegistrationStatus.waitlisted
                ? 'Bạn đang ở danh sách chờ. Vé sẽ xuất hiện khi đăng ký được xác nhận.'
                : 'Vé chỉ hiển thị khi đăng ký đã được xác nhận và sự kiện chưa bị hủy.',
            action: FilledButton(
              onPressed: () => context.go('/my-events'),
              child: const Text('Về sự kiện của tôi'),
            ),
          ),
        ),
      );
    }
    return StudentPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentHeading(
            eyebrow: 'Một trải nghiệm đang chờ',
            title: 'Vé của bạn',
            subtitle: 'Thông tin đăng ký và mã tham chiếu của sự kiện.',
            action: OutlinedButton.icon(
              onPressed: () => context.go('/my-events'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Sự kiện của tôi'),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF084F98), Color(0xFF067CC0)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_activity_outlined,
                              color: studentGold,
                              size: 23,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'HUTECH EVENTS',
                                style: TextStyle(
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                registration.status.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 25,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              size: 17,
                              color: Color(0xFFD3EAFA),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                studentDateTime(event.start),
                                style: const TextStyle(
                                  color: Color(0xFFE1F1FC),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: Color(0xFFD3EAFA),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                event.venue,
                                style: const TextStyle(
                                  color: Color(0xFFE1F1FC),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TicketField('SINH VIÊN', profile.name),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _TicketField(
                                'MÃ SỐ SINH VIÊN',
                                profile.studentId,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 25),
                          child: Divider(),
                        ),
                        const Text(
                          'Mã đăng ký',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3E9F0)),
                          ),
                          child: QrImageView(
                            data: registration.id,
                            version: QrVersions.auto,
                            size: 206,
                            backgroundColor: Colors.white,
                            semanticsLabel: 'Mã QR tham chiếu đăng ký sự kiện',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          registration.id,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: registration.id),
                            );
                            if (context.mounted) {
                              studentMessage(
                                context,
                                'Đã sao chép mã đăng ký.',
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_outlined, size: 16),
                          label: const Text('Sao chép mã'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: studentGold.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFFA07800),
                                size: 19,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'QR chứa mã tham chiếu đăng ký. Điểm danh xác thực trên máy chủ chưa được kích hoạt; mã này chưa dùng để xác nhận tham gia.',
                                  style: TextStyle(fontSize: 12, height: 1.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/events/${event.id}'),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                          ),
                          label: const Text('Thông tin sự kiện'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _TicketField extends StatelessWidget {
  const _TicketField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ),
    ],
  );
}
