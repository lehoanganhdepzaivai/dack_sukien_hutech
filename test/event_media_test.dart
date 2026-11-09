import 'dart:convert';

import 'package:dack/app/hutech_app.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:dack/screens/public/event_detail_screen.dart';
import 'package:dack/services/event_link.dart';
import 'package:dack/widgets/event_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<Map<String, dynamic>?> read() async => null;
  @override
  Future<void> save(Map<String, dynamic> data) async {}
}

Future<AppStore> _store({String? email}) async {
  final store = AppStore(repository: _MemoryRepository());
  await store.initialize();
  if (email != null) await store.login(email, '123');
  return store;
}

Widget _viewerHost(String source) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => FilledButton(
        onPressed: () => showEventImageViewer(
          context,
          source: source,
          title: 'Ngày hội sáng tạo và công nghệ dành cho sinh viên HUTECH',
        ),
        child: const Text('Mở ảnh'),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async => initializeDateFormatting('vi_VN'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('event link retains host and deployment path with the event hash', () {
    final link = eventPageUri(
      Uri.parse('http://127.0.0.1:8080/hutech/index.html?q=old#/events'),
      'flutter-lab',
    );
    expect(
      link.toString(),
      'http://127.0.0.1:8080/hutech/index.html#/events/flutter-lab',
    );
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('image viewer zooms, resets and closes at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_viewerHost('assets/images/technology.png'));
      await tester.tap(find.text('Mở ảnh'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.byTooltip('Phóng to ảnh'));
      await tester.pump();
      expect(find.text('125%'), findsOneWidget);
      await tester.tap(find.byTooltip('Thu nhỏ ảnh'));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      for (var i = 0; i < 9; i++) {
        await tester.tap(find.byTooltip('Phóng to ảnh'));
        await tester.pump();
      }
      expect(find.text('500%'), findsOneWidget);
      await tester.tap(find.byTooltip('Khôi phục kích thước ảnh'));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(EventImageViewer), findsNothing);
      expect(find.text('Mở ảnh'), findsOneWidget);
    });
  }

  testWidgets('image viewer supports uploaded data images and pinch/pan', (
    tester,
  ) async {
    final bytes = await rootBundle.load('assets/images/technology.png');
    final source =
        'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}';
    await tester.pumpWidget(_viewerHost(source));
    await tester.tap(find.text('Mở ảnh'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage),
      findsOneWidget,
    );
    final viewerFinder = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewerFinder);
    final first = await tester.startGesture(
      center - const Offset(40, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(40, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center - const Offset(100, 0));
    await second.moveTo(center + const Offset(100, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(viewerFinder)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    final translation = controller.value.getTranslation().x;
    await tester.drag(viewerFinder, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(controller.value.getTranslation().x, greaterThan(translation));
    await tester.tap(find.byTooltip('Đóng ảnh (Esc)'));
    await tester.pumpAndSettle();
    expect(find.byType(EventImageViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event image opens and copy link writes the selected event', (
    tester,
  ) async {
    final store = await _store(email: 'HA@gmail.com');
    addTearDown(store.dispose);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const MaterialApp(
          home: Scaffold(body: EventDetailScreen(eventId: 'flutter-lab')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xem ảnh toàn màn hình'));
    await tester.tap(find.text('Xem ảnh toàn màn hình'));
    await tester.pumpAndSettle();
    expect(find.byType(EventImageViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng ảnh (Esc)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sao chép liên kết'));
    await tester.tap(find.text('Sao chép liên kết'));
    await tester.pump();
    expect(copied, eventPageUri(Uri.base, 'flutter-lab').toString());
    expect(find.text('Đã sao chép liên kết sự kiện.'), findsOneWidget);
    expect(find.text('Vì sao phù hợp với bạn?'), findsOneWidget);
    expect(find.text('Đăng ký tham gia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin event detail offers editing without student actions', (
    tester,
  ) async {
    final store = await _store(email: 'admin@gmail.com');
    addTearDown(store.dispose);
    await tester.pumpWidget(
      HutechApp(store: store, initialLocation: '/events/flutter-lab'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa sự kiện'), findsOneWidget);
    expect(find.text('Đăng ký tham gia'), findsNothing);
    expect(find.text('Lưu để xem sau'), findsNothing);
    expect(find.text('Vì sao phù hợp với bạn?'), findsNothing);
    await tester.ensureVisible(find.text('Chỉnh sửa sự kiện'));
    await tester.tap(find.text('Chỉnh sửa sự kiện'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
