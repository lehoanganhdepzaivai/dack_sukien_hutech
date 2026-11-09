import 'dart:convert';

import 'package:dack/app/hutech_app.dart';
import 'package:dack/models/event_model.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRepository extends LocalRepository {
  @override
  Future<Map<String, dynamic>?> read() async => null;

  @override
  Future<void> save(Map<String, dynamic> data) async {}
}

class _FeaturedCountStore extends AppStore {
  _FeaturedCountStore(this.featuredCount)
    : super(repository: _MemoryRepository());

  final int featuredCount;

  @override
  List<EventModel> get events => [
    for (final (index, event) in super.events.indexed)
      event.copyWith(featured: index < featuredCount),
  ];
}

Future<int> _pumpHome(
  WidgetTester tester, {
  int? featuredCount,
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = featuredCount == null
      ? AppStore(repository: _MemoryRepository())
      : _FeaturedCountStore(featuredCount);
  await store.initialize();
  addTearDown(store.dispose);
  await tester.pumpWidget(HutechApp(store: store, initialLocation: '/'));
  await tester.pumpAndSettle();
  return store.events
      .where((event) => event.featured && event.isPublic)
      .take(3)
      .length;
}

Future<AppStore> _storeWithUploadedPublicEvent() async {
  final now = DateTime(2026, 10, 17, 9);
  final store = AppStore(repository: _MemoryRepository(), clock: () => now);
  await store.initialize();
  await store.login('admin@gmail.com', '123');
  final imageBytes = await rootBundle.load('assets/images/music.png');
  final uploadedImage =
      'data:image/png;base64,${base64Encode(imageBytes.buffer.asUint8List())}';
  await store.saveEvent(
    EventModel(
      id: 'admin-uploaded-concert',
      title: 'Đêm nhạc do admin vừa thêm',
      subtitle: 'Ảnh tải lên xuất hiện trực tiếp trên banner trang chủ.',
      description: 'Thông tin riêng của sự kiện dùng để xác nhận banner mở đúng trang chi tiết.',
      category: store.categories.first,
      organization: 'Ban Công tác Sinh viên HUTECH',
      venue: store.venues.first,
      image: uploadedImage,
      start: now.add(const Duration(days: 10)),
      end: now.add(const Duration(days: 10, hours: 3)),
      deadline: now.add(const Duration(days: 8)),
      capacity: 300,
      status: EventStatus.published,
      skills: const ['Kết nối'],
    ),
  );
  await store.logout();
  return store;
}

Future<void> _pumpHomeWithStore(WidgetTester tester, AppStore store) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(store.dispose);
  await tester.pumpWidget(HutechApp(store: store, initialLocation: '/'));
  await tester.pumpAndSettle();
}

Finder _page(int page, int count) =>
    find.bySemanticsLabel('Sự kiện nổi bật, trang $page trên $count');

Future<void> _finishSlide(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pump();
}

void main() {
  setUpAll(() async => initializeDateFormatting('vi_VN'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('featured carousel exposes controls and changes page', (
    tester,
  ) async {
    final featuredCount = await _pumpHome(tester);

    expect(featuredCount, greaterThan(1));
    expect(
      find.byKey(const ValueKey('featured-carousel-previous')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('featured-carousel-next')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Sự kiện nổi bật, trang 1 trên $featuredCount'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('featured-carousel-next')));
    await _finishSlide(tester);

    expect(
      find.bySemanticsLabel('Sự kiện nổi bật, trang 2 trên $featuredCount'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'carousel centers a full-opacity card and shows dimmed side cards',
    (tester) async {
      final count = await _pumpHome(tester);
      expect(count, greaterThan(2));

      final slider = tester.widget<CarouselSlider>(
        find.byKey(const ValueKey('featured-carousel-pages')),
      );
      expect(slider.options.viewportFraction, lessThan(1));
      expect(slider.options.enlargeCenterPage, isTrue);
      expect(slider.options.enableInfiniteScroll, isTrue);

      final activeOpacity = tester.widgetList<AnimatedOpacity>(
        find.byKey(const ValueKey('featured-carousel-slide-opacity-0')),
      );
      final adjacentOpacity = tester.widgetList<AnimatedOpacity>(
        find.byKey(const ValueKey('featured-carousel-slide-opacity-1')),
      );
      expect(activeOpacity, isNotEmpty);
      expect(activeOpacity.every((widget) => widget.opacity == 1), isTrue);
      expect(adjacentOpacity, isNotEmpty);
      expect(adjacentOpacity.every((widget) => widget.opacity < 1), isTrue);

      final cta = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('featured-carousel-cta')).first,
      );
      final ctaDecoration = cta.decoration as BoxDecoration;
      expect(ctaDecoration.borderRadius, BorderRadius.circular(10));
      final ctaText = tester.widget<Text>(find.text('Khám phá ngay').first);
      expect(ctaText.style?.fontSize, 10);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('mobile carousel keeps side previews without overflowing', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    final slider = tester.widget<CarouselSlider>(
      find.byKey(const ValueKey('featured-carousel-pages')),
    );
    expect(slider.options.viewportFraction, closeTo(.82, .001));
    expect(slider.options.enlargeCenterPage, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'newly added public event jumps into the front of the home carousel',
    (tester) async {
      final now = DateTime(2026, 10, 17, 9);
      final store = AppStore(repository: _MemoryRepository(), clock: () => now);
      await store.initialize();
      await store.login('admin@gmail.com', '123');
      await store.saveEvent(
        EventModel(
          id: 'custom-robotics-workshop',
          title: 'Workshop Robotics & AI HUTECH',
          subtitle: 'Sự kiện công nghệ mới thêm xuất hiện ngay đầu banner.',
          description: 'Mô tả chi tiết của sự kiện robotics vừa được thêm.',
          category: store.categories.first,
          organization: 'CLB Robotics HUTECH',
          venue: store.venues.first,
          image: 'assets/images/technology.png',
          start: now.add(const Duration(days: 5)),
          end: now.add(const Duration(days: 5, hours: 2)),
          deadline: now.add(const Duration(days: 4)),
          capacity: 150,
          status: EventStatus.registrationOpen,
          skills: const ['Lập trình', 'Sáng tạo'],
        ),
      );
      await store.logout();

      await _pumpHomeWithStore(tester, store);

      expect(find.text('Workshop Robotics & AI HUTECH'), findsOneWidget);
      expect(find.text('Khám phá ngay'), findsWidgets);

      await tester.tap(
        find.byKey(
          const ValueKey('featured-carousel-event-custom-robotics-workshop'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Về sự kiện'), findsOneWidget);
      expect(
        find.text('Mô tả chi tiết của sự kiện robotics vừa được thêm.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'public event with an admin-uploaded image becomes a slide and opens its detail',
    (tester) async {
      final store = await _storeWithUploadedPublicEvent();
      await _pumpHomeWithStore(tester, store);

      final seedFeaturedCount = store.events
          .where((event) => event.featured && event.isPublic)
          .length;
      const uploadedSlideIndex = 0;
      final slideCount = seedFeaturedCount + 1;
      expect(
        find.byKey(ValueKey('featured-carousel-indicator-$uploadedSlideIndex')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(ValueKey('featured-carousel-indicator-$uploadedSlideIndex')),
      );
      await _finishSlide(tester);

      expect(_page(uploadedSlideIndex + 1, slideCount), findsOneWidget);
      expect(find.text('Đêm nhạc do admin vừa thêm'), findsOneWidget);
      expect(find.text('Khám phá ngay'), findsWidgets);
      expect(
        find.bySemanticsLabel('Khám phá ngay: Đêm nhạc do admin vừa thêm'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('featured-carousel-event-admin-uploaded-concert'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Về sự kiện'), findsOneWidget);
      expect(
        find.text(
          'Thông tin riêng của sự kiện dùng để xác nhận banner mở đúng trang chi tiết.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'inactive side preview is dimmed, hidden from semantics, and does not open the current event',
    (tester) async {
      final count = await _pumpHome(tester, size: const Size(390, 844));
      final carousel = find.byKey(
        const ValueKey('featured-carousel-pages'),
      );
      final bounds = tester.getRect(carousel);

      expect(_page(1, count), findsOneWidget);
      final inactiveSemantics = tester.widgetList<ExcludeSemantics>(
        find.descendant(
          of: carousel,
          matching: find.byType(ExcludeSemantics),
        ),
      );
      expect(
        inactiveSemantics.where((widget) => widget.excluding),
        isNotEmpty,
      );

      await tester.tapAt(Offset(bounds.left + 2, bounds.center.dy));
      await tester.pump(const Duration(milliseconds: 500));

      expect(_page(1, count), findsOneWidget);
      expect(find.text('Về sự kiện'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('featured carousel automatically advances and loops', (
    tester,
  ) async {
    final count = await _pumpHome(tester);
    expect(_page(1, count), findsOneWidget);

    for (var index = 1; index <= count; index++) {
      await tester.pump(const Duration(seconds: 3));
      await _finishSlide(tester);
      expect(_page(index % count + 1, count), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'hover pauses the banner and leaving resumes after five seconds',
    (tester) async {
      final count = await _pumpHome(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('featured-carousel-pages'))),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      expect(_page(1, count), findsOneWidget);
      await mouse.removePointer();
      await tester.pump(const Duration(seconds: 4));
      expect(_page(1, count), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await _finishSlide(tester);
      expect(_page(2, count), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('touch hold pauses and release waits five seconds', (
    tester,
  ) async {
    final count = await _pumpHome(tester, size: const Size(390, 844));
    final center = tester.getCenter(
      find.byKey(const ValueKey('featured-carousel-pages')),
    );
    final touch = await tester.startGesture(center);
    await tester.pump(const Duration(seconds: 8));
    expect(_page(1, count), findsOneWidget);
    await touch.up();
    await tester.pump(const Duration(seconds: 4));
    expect(_page(1, count), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await _finishSlide(tester);
    expect(_page(2, count), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('short touch on a mobile banner opens one detail route', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));
    final banner = find.byKey(const ValueKey('featured-carousel-pages'));
    final touch = await tester.startGesture(tester.getCenter(banner));
    await tester.pump(const Duration(milliseconds: 100));
    await touch.up();
    await tester.pumpAndSettle();

    expect(find.text('Về sự kiện'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('featured-carousel-pages')),
      findsOneWidget,
    );
    expect(find.text('Về sự kiện'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('entering again cancels the five second resume countdown', (
    tester,
  ) async {
    final count = await _pumpHome(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    final banner = tester.getCenter(
      find.byKey(const ValueKey('featured-carousel-pages')),
    );
    await mouse.moveTo(banner);
    await tester.pump();
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 4));
    await mouse.moveTo(banner);
    await tester.pump(const Duration(seconds: 3));
    expect(_page(1, count), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 5));
    await _finishSlide(tester);
    expect(_page(2, count), findsOneWidget);
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('manual navigation gets five seconds before autoplay resumes', (
    tester,
  ) async {
    final count = await _pumpHome(tester);
    expect(
      find.byKey(const ValueKey('featured-carousel-autoplay-toggle')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('featured-carousel-next')));
    await _finishSlide(tester);
    expect(_page(2, count), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(_page(2, count), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await _finishSlide(tester);
    expect(_page(3, count), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final count in [0, 1]) {
    testWidgets('$count featured event needs no autoplay controls', (
      tester,
    ) async {
      await _pumpHome(tester, featuredCount: count);
      expect(
        find.byKey(const ValueKey('featured-carousel-pages')),
        count == 0 ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('featured-carousel-autoplay-toggle')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('featured-carousel-next')),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
