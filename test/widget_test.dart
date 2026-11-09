import 'package:dack/app/hutech_app.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryRepository extends LocalRepository {
  @override
  Future<Map<String, dynamic>?> read() async => null;
  @override
  Future<void> save(Map<String, dynamic> data) async {}
}

Future<AppStore> makeStore({String? email}) async {
  final store = AppStore(repository: MemoryRepository());
  await store.initialize();
  if (email != null) await store.login(email, '123');
  return store;
}

void main() {
  setUpAll(() async => initializeDateFormatting('vi_VN'));
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1100.0, 1440.0]) {
    for (final route in ['/', '/login', '/events', '/events/flutter-lab']) {
      testWidgets('$route fits ${width.toInt()}px viewport', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = await makeStore();
        await tester.pumpWidget(
          HutechApp(store: store, initialLocation: route),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      });
    }
  }
  for (final route in [
    '/admin',
    '/admin/events',
    '/admin/events/new',
    '/admin/categories',
    '/admin/participants',
  ]) {
    testWidgets('$route renders for admin at mobile width', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await makeStore(email: 'admin@gmail.com');
      await tester.pumpWidget(HutechApp(store: store, initialLocation: route));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }
  testWidgets('guest is redirected to login for private data', (tester) async {
    final store = await makeStore();
    await tester.pumpWidget(
      HutechApp(store: store, initialLocation: '/profile'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng bạn trở lại!'), findsOneWidget);
  });
  testWidgets('student cannot open admin URL directly', (tester) async {
    final store = await makeStore(email: 'HA@gmail.com');
    await tester.pumpWidget(
      HutechApp(store: store, initialLocation: '/admin/events'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có quyền truy cập'), findsOneWidget);
  });
  testWidgets('admin student routes return to the dedicated admin workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await makeStore(email: 'admin@gmail.com');
    addTearDown(store.dispose);
    await tester.pumpWidget(
      HutechApp(store: store, initialLocation: '/profile'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan quản trị'), findsWidgets);
    expect(find.byKey(const Key('admin-create-event-action')), findsOneWidget);
    expect(find.text('Hồ sơ sinh viên'), findsNothing);
    expect(find.text('Hồ sơ cá nhân'), findsNothing);
  });
  testWidgets('admin login ignores a student-only return target', (
    tester,
  ) async {
    final store = await makeStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      HutechApp(
        store: store,
        initialLocation: '/login?from=${Uri.encodeComponent('/profile')}',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Tổng quan quản trị'), findsWidgets);
    expect(find.text('Hồ sơ sinh viên'), findsNothing);
  });
  testWidgets('login validates then authenticates the supplied student', (
    tester,
  ) async {
    final store = await makeStore();
    await tester.pumpWidget(HutechApp(store: store, initialLocation: '/login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'HA@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(store.profile?.email.toLowerCase(), 'ha@gmail.com');
    expect(find.textContaining('Xin chào,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('login accepts the supplied admin email and opens admin area', (
    tester,
  ) async {
    final store = await makeStore();
    await tester.pumpWidget(HutechApp(store: store, initialLocation: '/login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email hợp lệ'), findsNothing);
    expect(store.isAdmin, isTrue);
    expect(find.text('Tổng quan quản trị'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
