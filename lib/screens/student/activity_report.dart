import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/event_model.dart';
import '../../models/registration_model.dart';
import '../../models/user_profile.dart';

/// Exports records belonging to the signed-in student, not a certificate.
class ActivityReport {
  static Future<Uint8List> build({
    required UserProfile profile,
    required List<RegistrationModel> registrations,
    required List<EventModel> events,
  }) async {
    // Await each asset explicitly: cached bundles can return SynchronousFuture,
    // whose inline callbacks do not work with Future.wait's result collection.
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final document = pw.Document();
    final rows = registrations.where((item) => item.userId == profile.id).map((
      registration,
    ) {
      final event = events
          .where((item) => item.id == registration.eventId)
          .firstOrNull;
      return [
        event?.title ?? 'Sự kiện không còn công khai',
        event == null ? '—' : _date(event.start),
        registration.status.label,
        _date(registration.createdAt),
      ];
    }).toList();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 18),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'HUTECH · EVENT INTELLIGENCE',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'HỒ SƠ HOẠT ĐỘNG',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Xuất ngày ${_date(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Text(
            'Hồ sơ hoạt động sinh viên',
            style: pw.TextStyle(
              fontSize: 23,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            profile.name,
            style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Mã số sinh viên: ${profile.studentId}'),
          pw.SizedBox(height: 5),
          pw.Text('Khoa / Viện: ${profile.faculty}'),
          pw.SizedBox(height: 5),
          pw.Text('Ngành học: ${profile.major} · Khóa: ${profile.cohort}'),
          pw.SizedBox(height: 5),
          pw.Text('Email: ${profile.email}'),
          pw.SizedBox(height: 24),
          pw.Text(
            'Lịch sử đăng ký',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text('Chưa có đăng ký sự kiện.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Sự kiện',
                'Ngày tổ chức',
                'Trạng thái',
                'Ngày đăng ký',
              ],
              data: rows,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellPadding: const pw.EdgeInsets.all(8),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.1),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.1),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Text(
              'Tài liệu tổng hợp thông tin hồ sơ và trạng thái đăng ký trong ứng dụng tại thời điểm xuất. Đây không phải giấy chứng nhận tham gia hoặc xác nhận của nhà trường. Đăng ký không đồng nghĩa với đã điểm danh hay hoàn thành sự kiện.',
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 4),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
