import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class CheckInScreen extends StatefulWidget {
  final String? initialEventId;
  const CheckInScreen({super.key, this.initialEventId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? _selectedEventId;
  final _manualCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  bool _useManualInput = false;
  DateTime _lastScannedTime = DateTime.fromMillisecondsSinceEpoch(0);
  String? _statusMessage;
  bool _isSuccessStatus = false;
  final List<Map<String, dynamic>> _recentCheckIns = [];

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCodeScanned(String code) async {
    final now = DateTime.now();
    if (now.difference(_lastScannedTime).inSeconds < 2) return;
    _lastScannedTime = now;

    if (_isProcessing) return;
    if (_selectedEventId == null) {
      setState(() {
        _statusMessage = 'Vui lòng chọn sự kiện trước khi điểm danh!';
        _isSuccessStatus = false;
      });
      return;
    }

    setState(() => _isProcessing = true);
    final store = context.read<AppStore>();

    try {
      final res = await store.checkInRegistration(
        eventId: _selectedEventId!,
        ticketCode: code.trim(),
        method: _useManualInput ? 'manual' : 'qr',
      );

      final success = res['success'] == true;
      setState(() {
        _statusMessage = res['message'] as String?;
        _isSuccessStatus = success;
        if (success) {
          _recentCheckIns.insert(0, {
            'student': res['student'],
            'time': res['timestamp'] ?? DateTime.now(),
            'code': code.trim(),
            'method': _useManualInput ? 'Thủ công' : 'QR Code',
          });
          _manualCodeController.clear();
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi xử lý: $e';
        _isSuccessStatus = false;
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final activeEvents = store.events.where((e) => e.status != EventStatus.archived).toList();

    if (_selectedEventId == null && activeEvents.isNotEmpty) {
      _selectedEventId = activeEvents.first.id;
    }

    final confirmedCount = _selectedEventId != null ? store.confirmedCount(_selectedEventId!) : 0;
    final attendedCount = _selectedEventId != null ? store.attendedCount(_selectedEventId!) : 0;
    final rate = confirmedCount > 0 ? ((attendedCount / confirmedCount) * 100).toStringAsFixed(1) : '0';

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SectionHeading(
                  'Điểm danh sự kiện',
                  subtitle: 'Quét mã QR vé hoặc nhập mã thủ công để ghi nhận tham dự.',
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.qr_code_scanner),
                        label: Text('Camera'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.keyboard_alt_outlined),
                        label: Text('Nhập mã'),
                      ),
                    ],
                    selected: {_useManualInput},
                    onSelectionChanged: (set) => setState(() => _useManualInput = set.first),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chọn sự kiện
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.event_note, color: AppColors.blue),
                  const SizedBox(width: 12),
                  const Text('Chọn sự kiện:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedEventId,
                        isExpanded: true,
                        items: activeEvents.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              '${e.title} (${e.venue})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedEventId = val;
                            _statusMessage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Thẻ chỉ số thống kê điểm danh
          LayoutBuilder(
            builder: (context, c) => Row(
              children: [
                Expanded(
                  child: _metricBox(
                    'ĐÃ ĐIỂM DANH',
                    '$attendedCount / $confirmedCount',
                    Icons.how_to_reg_rounded,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    'TỶ LỆ THAM DỰ',
                    '$rate%',
                    Icons.pie_chart_outline_rounded,
                    AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    'CHƯA ĐIỂM DANH',
                    '${(confirmedCount - attendedCount).clamp(0, confirmedCount)}',
                    Icons.person_off_outlined,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Trạng thái thông báo
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isSuccessStatus ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSuccessStatus ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccessStatus ? Icons.check_circle : Icons.error_outline,
                    color: _isSuccessStatus ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isSuccessStatus ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Khu vực Quét Camera hoặc Nhập thủ công
          if (!_useManualInput)
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null && rawValue.isNotEmpty) {
                          _handleCodeScanned(rawValue);
                          break;
                        }
                      }
                    },
                  ),
                  // Khung ngắm quét QR
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.yellow, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Hướng camera vào mã QR vé tham dự',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _scannerController.toggleTorch(),
                          icon: const Icon(Icons.flash_on, size: 20),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _scannerController.switchCamera(),
                          icon: const Icon(Icons.flip_camera_android, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập mã vé thủ công',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sử dụng khi camera không quét được hoặc sinh viên cung cấp mã đăng ký.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Mã vé tham dự (ID vé)',
                              hintText: 'Ví dụ: registration-ha-teamwork',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                            onSubmitted: (v) => _handleCodeScanned(v),
                          ),
                        ),
                        const SizedBox(width: 14),
                        FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleCodeScanned(_manualCodeController.text),
                          icon: const Icon(Icons.check),
                          label: const Text('Điểm danh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          const SectionHeading(
            'Lịch sử điểm danh vừa thực hiện',
            subtitle: 'Danh sách sinh viên vừa ghi nhận thành công trong phiên này.',
          ),
          const SizedBox(height: 12),

          if (_recentCheckIns.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Chưa có lượt điểm danh nào trong phiên hiện tại.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentCheckIns.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _recentCheckIns[index];
                  final dynamic student = item['student'];
                  final DateTime time = item['time'];
                  final timeStr = DateFormat('HH:mm:ss').format(time);

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.check, color: Colors.green),
                    ),
                    title: Text(
                      student != null ? student.name : 'Mã vé: ${item['code']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'MSSV: ${student?.studentId ?? "N/A"} · Phương thức: ${item['method']}',
                    ),
                    trailing: Text(
                      timeStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
