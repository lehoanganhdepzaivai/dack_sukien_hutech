import 'package:dack/models/registration_model.dart';
import 'package:dack/models/schedule_entry.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:dack/screens/student/calendar_screen.dart';
import 'package:dack/screens/student/my_events_screen.dart';
import 'package:dack/screens/student/schedule_screen.dart';
import 'package:dack/screens/student/student_widgets.dart';
import 'package:dack/widgets/week_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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

Widget _host(Widget screen, {AppStore? store}) {
  final app = MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('vi')],
    home: Scaffold(body: screen),
  );
  return store == null
      ? app
      : ChangeNotifierProvider.value(value: store, child: app);
}

void main() {
  setUpAll(() async => initializeDateFormatting('vi_VN'));

  testWidgets('week navigation crosses the year and respects date bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = DateTime(2026, 12, 31);
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            return WeekDateTimeline(
              selectedDay: selected,
              firstDay: DateTime(2026, 12, 30),
              lastDay: DateTime(2027, 1, 10),
              onSelected: (day) => setState(() => selected = day),
            );
          },
        ),
      ),
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Tuần trước',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2027, 1, 7));
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Tuần sau',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('week-day-2027-01-05')));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2027, 1, 5));
    await tester.tap(find.byTooltip('Tuần trước'));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 12, 30));
    await tester.tap(find.byKey(const ValueKey('week-day-2026-12-28')));
    expect(selected, DateTime(2026, 12, 30));
    await tester.tap(find.byTooltip('Chọn ngày trên lịch'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('week selector updates the main calendar and today resets it', (
    tester,
  ) async {
    final store = await _studentStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(_host(const CalendarScreen(), store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pumpAndSettle();
    final selected = tester
        .widget<WeekDateTimeline>(find.byType(WeekDateTimeline))
        .selectedDay;
    final calendar = tester.widget<TableCalendar<Object>>(
      find.byType(TableCalendar<Object>),
    );
    expect(isSameDay(calendar.focusedDay, selected), isTrue);
    expect(calendar.selectedDayPredicate!(selected), isTrue);
    await tester.tap(find.text('Hôm nay'));
    await tester.pumpAndSettle();
    expect(
      isSameDay(
        tester
            .widget<WeekDateTimeline>(find.byType(WeekDateTimeline))
            .selectedDay,
        DateTime.now(),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration tabs filter the visible event cards', (
    tester,
  ) async {
    final store = await _studentStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(_host(const MyEventsScreen(), store: store));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Xem trước PDF'), findsOneWidget);
    for (final status in RegistrationStatus.values) {
      final registrations = store.registrations
          .where((r) => r.status == status)
          .toList();
      final tab = find.widgetWithText(
        Tab,
        '${status.label} (${registrations.length})',
      );
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      for (final registration in store.registrations) {
        final event = store.eventById(registration.eventId)!;
        expect(
          find.text(event.title),
          registration.status == status ? findsOneWidget : findsNothing,
        );
      }
      if (registrations.isEmpty) {
        expect(
          find.text('Chưa có sự kiện ${status.label.toLowerCase()}'),
          findsOneWidget,
        );
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing afternoon saves the correct study period on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _studentStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(_host(const ScheduleScreen(), store: store));
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm lịch học').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Thiết kế giao diện',
    );
    final afternoon = find.text('Buổi chiều · Tiết 7–11');
    await tester.ensureVisible(afternoon);
    await tester.tap(afternoon);
    await tester.pumpAndSettle();
    expect(find.text('Từ 12:30'), findsOneWidget);
    expect(find.text('Đến 16:45'), findsOneWidget);
    await tester.tap(find.text('Lưu lịch học'));
    await tester.pumpAndSettle();
    final saved = store.schedules.singleWhere(
      (s) => s.title == 'Thiết kế giao diện',
    );
    expect(saved.startMinutes, 750);
    expect(saved.endMinutes, 1005);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a custom study period keeps its existing times', (
    tester,
  ) async {
    final store = await _studentStore();
    addTearDown(store.dispose);
    await store.saveSchedule(
      ScheduleEntry(
        id: 'custom-period',
        title: 'Thực hành riêng',
        weekday: 1,
        startMinutes: 550,
        endMinutes: 625,
        venue: store.venues.first,
      ),
    );
    await tester.pumpWidget(_host(const ScheduleScreen(), store: store));
    await tester.pumpAndSettle();
    final card = find.ancestor(
      of: find.text('Thực hành riêng'),
      matching: find.byType(StudentCard),
    );
    final menu = find
        .descendant(of: card, matching: find.byType(PopupMenuButton<String>))
        .first;
    // Monday also contains seeded courses. Locate the menu inside this course.
    final course = find
        .ancestor(
          of: find.text('Thực hành riêng'),
          matching: find.byType(Column),
        )
        .first;
    final courseMenu = find.descendant(
      of: course,
      matching: find.byType(PopupMenuButton<String>),
    );
    await tester.ensureVisible(
      courseMenu.evaluate().isEmpty ? menu : courseMenu,
    );
    await tester.tap(courseMenu.evaluate().isEmpty ? menu : courseMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Từ 09:10'), findsOneWidget);
    expect(find.text('Đến 10:25'), findsOneWidget);
    await tester.tap(find.text('Lưu lịch học'));
    await tester.pumpAndSettle();
    final saved = store.schedules.singleWhere((s) => s.id == 'custom-period');
    expect(saved.startMinutes, 550);
    expect(saved.endMinutes, 625);
    expect(tester.takeException(), isNull);
  });
}
