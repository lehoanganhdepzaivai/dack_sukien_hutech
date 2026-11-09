import 'dart:async';

import 'package:dack/screens/student/activity_pdf_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host() => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) =>
              ActivityPdfPreview(bytes: Uint8List(0), fileName: 'activity.pdf'),
        ),
        child: const Text('Mở PDF'),
      ),
    ),
  ),
);

void main() {
  const channel = MethodChannel('net.nfet.printing');

  testWidgets('PDF preview reports unavailable renderer and can be closed', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => <String, dynamic>{'canRaster': false},
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Mở PDF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa hiển thị được PDF'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng bản xem trước'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityPdfPreview), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF renderer timeout replaces the spinner with recovery text', (
    tester,
  ) async {
    final response = Completer<Map<String, dynamic>>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) => response.future,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Mở PDF'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Chưa hiển thị được PDF'), findsOneWidget);
    response.complete({'canRaster': false});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
