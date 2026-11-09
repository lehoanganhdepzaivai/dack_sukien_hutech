import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:dack/screens/student/activity_report.dart';
import 'package:dack/screens/student/calendar_screen.dart';
import 'package:dack/screens/student/development_screen.dart';
import 'package:dack/screens/student/my_events_screen.dart';
import 'package:dack/screens/student/profile_screen.dart';
import 'package:dack/screens/student/schedule_screen.dart';
import 'package:dack/screens/student/ticket_screen.dart';
import 'package:dack/screens/public/event_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<Map<String, dynamic>?> read() async => null;
  @override
  Future<void> save(Map<String, dynamic> data) async {}
}

Future<AppStore> _studentStore() async {
  final store = AppStore(repository: _MemoryRepository());
  await store.initialize();
  await store.login('HA@gmail.com', '123');
  return store;
}

Widget _host(AppStore store, Widget screen) => ChangeNotifierProvider.value(
  value: store,
  child: MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('vi')],
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: screen),
  ),
);

void main() {
  setUpAll(() async => initializeDateFormatting('vi_VN'));

  final pages = <String, Widget>{
    'calendar': const CalendarScreen(),
    'profile': const ProfileScreen(),
    'schedule': const ScheduleScreen(),
    'development': const DevelopmentScreen(),
    'registrations': const MyEventsScreen(),
    'ticket': const TicketScreen(eventId: 'teamwork-studio'),
  };
  for (final page in pages.entries) {
    testWidgets('${page.key} fits a mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await _studentStore();
      await tester.pumpWidget(_host(store, page.value));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('schedule validates a blank course before saving', (
    tester,
  ) async {
    final store = await _studentStore();
    final count = store.schedules.length;
    await tester.pumpWidget(_host(store, const ScheduleScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm lịch học').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu lịch học'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên môn học từ 2 ký tự.'), findsOneWidget);
    expect(store.schedules.length, count);
  });

  testWidgets('schedule shows the study period directly below the course', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(_host(store, const ScheduleScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Lập trình ứng dụng di động'), findsOneWidget);
    expect(find.text('Tiết 2–6 · 07:30 – 11:45'), findsWidgets);
    expect(find.text('Tiết 7–11 · 12:30 – 16:45'), findsWidgets);
  });

  testWidgets('canceling a class conflict leaves the event unregistered', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(
      _host(store, const EventDetailScreen(eventId: 'flutter-lab')),
    );
    await tester.pumpAndSettle();
    final register = find.widgetWithText(FilledButton, 'Đăng ký tham gia');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.text('Lịch của bạn đang bị trùng'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining('Lập trình ứng dụng di động'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.textContaining('07:30–11:45')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(store.registrationFor('flutter-lab'), isNull);
  });

  testWidgets('student can continue after acknowledging a class conflict', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(
      _host(store, const EventDetailScreen(eventId: 'flutter-lab')),
    );
    await tester.pumpAndSettle();
    final register = find.widgetWithText(FilledButton, 'Đăng ký tham gia');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Vẫn đăng ký'));
    await tester.pumpAndSettle();
    expect(store.registrationFor('flutter-lab'), isNotNull);
    expect(find.text('Xem vé của tôi'), findsOneWidget);
  });

  testWidgets('soft recommendation warnings do not block registration', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(
      _host(store, const EventDetailScreen(eventId: 'music-night')),
    );
    await tester.pumpAndSettle();
    final register = find.widgetWithText(FilledButton, 'Đăng ký tham gia');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.text('Lịch của bạn đang bị trùng'), findsNothing);
    expect(store.registrationFor('music-night'), isNotNull);
  });

  testWidgets('ticket is hidden for a student without a registration', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(
      _host(store, const TicketScreen(eventId: 'flutter-lab')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có vé hợp lệ'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('confirmed registration exposes its reference, not attendance', (
    tester,
  ) async {
    final store = await _studentStore();
    await tester.pumpWidget(
      _host(store, const TicketScreen(eventId: 'teamwork-studio')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Mã đăng ký'), findsOneWidget);
    expect(
      find.textContaining(
        'Điểm danh xác thực trên máy chủ chưa được kích hoạt',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PDF can be built with the bundled Vietnamese fonts', (
    tester,
  ) async {
    final store = await _studentStore();
    final bytes = await tester.runAsync(
      () => ActivityReport.build(
        profile: store.profile!,
        registrations: store.registrations,
        events: store.events,
      ),
    );
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
