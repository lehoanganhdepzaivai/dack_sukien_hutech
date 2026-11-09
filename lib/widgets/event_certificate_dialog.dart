import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app/app_theme.dart';
import '../models/event_model.dart';
import '../models/user_profile.dart';
import '../widgets/hutech_logo.dart';

class EventCertificateDialog extends StatelessWidget {
  final EventModel event;
  final UserProfile profile;
  final String certificateCode;
  final DateTime checkInTime;

  const EventCertificateDialog({
    super.key,
    required this.event,
    required this.profile,
    required this.certificateCode,
    required this.checkInTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HutechLogoMark(size: 40),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'TRƯỜNG ĐẠI HỌC CÔNG NGHỆ TP.HCM',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.navy,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'HUTECH EVENT INTELLIGENCE SYSTEM',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFD4AF37), thickness: 1.5),
                      const SizedBox(height: 16),
                      const Text(
                        'GIẤY CHỨNG NHẬN THAM DỰ',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF084F98),
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chứng nhận sinh viên',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'MSSV: ${profile.studentId} • Khoa: ${profile.faculty.isEmpty ? "CNTT" : profile.faculty}',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Đã hoàn thành xuất sắc và tham dự đầy đủ sự kiện:',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“${event.title}”',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBA8412),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      if (event.skills.isNotEmpty) ...[
                        const Text(
                          'Kỹ năng tích lũy:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: event.skills.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF084F98).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF084F98), fontWeight: FontWeight.w600),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mã chứng nhận: $certificateCode',
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black54),
                              ),
                              Text(
                                'Ngày cấp: ${DateFormat("dd/MM/yyyy").format(checkInTime)}',
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red.shade700, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HUTECH VERIFIED',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Xác thực điện tử',
                                style: TextStyle(fontSize: 9, color: Colors.black45),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang tạo tệp chứng nhận PDF chất lượng cao...'),
                            backgroundColor: Color(0xFF084F98),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Tải chứng nhận PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
