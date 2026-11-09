import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/event_card.dart';

const _seedEventIds = {
  'flutter-lab',
  'music-night',
  'career-connect',
  'teamwork-studio',
  'green-action',
  'active-campus',
};

List<EventModel> _homeCarouselEvents(Iterable<EventModel> events) {
  final publicEvents = events.where((event) => event.isPublic).toList();
  final carouselEvents = <EventModel>[];
  final includedIds = <String>{};

  void include(EventModel event) {
    if (includedIds.add(event.id)) carouselEvents.add(event);
  }

  // 1. Newly created / custom public events (non-seed events) appear first,
  // in reverse chronological order (newest first).
  // Also any events with uploaded data:image.
  for (final event in publicEvents.reversed.where(
    (event) =>
        !_seedEventIds.contains(event.id) ||
        event.image.trimLeft().toLowerCase().startsWith('data:image/'),
  )) {
    include(event);
  }
  for (final event in publicEvents.where((event) => event.featured)) {
    include(event);
  }
  return carouselEvents;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final featured = _homeCarouselEvents(store.events);
    final recommended = store.events.where((e) => e.isPublic).toList()
      ..sort(
        (a, b) => store
            .recommendation(b)
            .score
            .compareTo(store.recommendation(a).score),
      );
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.isAuthenticated
                          ? 'Xin chào, ${store.profile!.name} 👋'
                          : 'Chào bạn, cùng khám phá nhé! 👋',
                      style: TextStyle(
                        fontSize: narrow ? 23 : 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Một ngày mới, thêm nhiều cơ hội để kết nối và trưởng thành.',
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!narrow)
                LabelPill(
                  DateFormat('EEEE, dd/MM', 'vi_VN').format(DateTime.now()),
                ),
            ],
          ),
          const SizedBox(height: 27),
          if (featured.isNotEmpty)
            _FeaturedCarousel(events: featured, narrow: narrow),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                _stat(
                  context,
                  c.maxWidth,
                  Icons.event_available_outlined,
                  '${store.events.where((e) => e.isPublic).length}',
                  'Sự kiện công khai',
                  const Color(0xFFE7F2FC),
                ),
                _stat(
                  context,
                  c.maxWidth,
                  Icons.confirmation_number_outlined,
                  '${store.registrations.where((r) => r.status.name != 'canceled').length}',
                  'Vé của bạn',
                  const Color(0xFFFFF6D7),
                ),
                _stat(
                  context,
                  c.maxWidth,
                  Icons.bookmark_border_rounded,
                  '${store.favorites.length}',
                  'Sự kiện đã lưu',
                  const Color(0xFFE7F5F0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          SectionHeading(
            'Tìm điều bạn yêu thích',
            subtitle:
                'Từ giảng đường đến sân khấu, mọi trải nghiệm đều có giá trị.',
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _category(context, 'Tất cả sự kiện', Icons.apps_rounded, null),
                ...store.categories.map(
                  (c) => _category(context, c, _categoryIcon(c), c),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SectionHeading(
            store.isAuthenticated
                ? 'Dành riêng cho bạn'
                : 'Sự kiện đáng khám phá',
            subtitle: store.isAuthenticated
                ? 'Gợi ý dựa trên sở thích, kỹ năng và lịch của bạn.'
                : 'Chọn một trải nghiệm, mở ra những kết nối mới.',
            trailing: TextButton.icon(
              onPressed: () {
                store.setFilters(search: '', category: '', venue: '');
                context.go('/events');
              },
              label: const Text('Xem tất cả'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            ),
          ),
          const SizedBox(height: 21),
          if (recommended.isEmpty)
            const EmptyPanel(
              title: 'Chưa có sự kiện',
              message:
                  'Những hoạt động mới sẽ xuất hiện tại đây khi được công bố.',
            )
          else
            EventGrid(events: recommended.take(3).toList()),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(narrow ? 24 : 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFEDF6FB), Color(0xFFFFFAE7)],
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 18,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.route_rounded, color: AppColors.blue, size: 38),
                    SizedBox(width: 17),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hành trình của bạn, do bạn viết nên.',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Đặt mục tiêu. Khám phá kỹ năng. Chọn trải nghiệm phù hợp.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/development'),
                  icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                  label: const Text('Khám phá lộ trình'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'HUTECH EVENT INTELLIGENCE   /   Kết nối những hành trình sinh viên',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    double width,
    IconData icon,
    String count,
    String label,
    Color color,
  ) => Container(
    width: width > 700
        ? (width - 28) / 3
        : width > 480
        ? (width - 14) / 2
        : width,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.blue, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          count,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ],
    ),
  );
  Widget _category(
    BuildContext context,
    String label,
    IconData icon,
    String? category,
  ) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: category == null
            ? AppColors.blue
            : Theme.of(context).cardColor,
        foregroundColor: category == null ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
      ),
      onPressed: () {
        context.read<AppStore>().setFilters(
          category: category ?? '',
          search: '',
          venue: '',
        );
        context.go('/events');
      },
      icon: Icon(icon, size: 19),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    ),
  );
  IconData _categoryIcon(String c) => c.toLowerCase().contains('nhạc')
      ? Icons.music_note_outlined
      : c.toLowerCase().contains('nghề')
      ? Icons.work_outline
      : c.toLowerCase().contains('nguyện')
      ? Icons.volunteer_activism_outlined
      : c.toLowerCase().contains('thể')
      ? Icons.sports_basketball_outlined
      : c.toLowerCase().contains('kỹ')
      ? Icons.psychology_outlined
      : Icons.school_outlined;
}

class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.events, required this.narrow});

  final List<EventModel> events;
  final bool narrow;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _autoPlayInterval = Duration(seconds: 3);
  static const _interactionResumeDelay = Duration(seconds: 5);
  static const _animationDuration = Duration(milliseconds: 700);

  final _carouselController = CarouselSliderController();
  final _carouselViewportKey = GlobalKey();
  int _current = 0;
  Timer? _advanceTimer;
  bool _mouseOverBanner = false;
  final Set<int> _pressedPointers = <int>{};
  bool _waitingAfterInteraction = false;
  int? _tapCandidatePointer;
  Offset? _tapCandidatePosition;
  String? _tapCandidateEventId;
  Timer? _tapCandidateExpiry;
  String? _lastOpenedEventId;
  DateTime? _lastOpenedAt;

  bool get _hasMultiplePages => widget.events.length > 1;
  bool get _isInteracting => _mouseOverBanner || _pressedPointers.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleNext(_autoPlayInterval);
    });
  }

  static double _viewportFraction(bool narrow) => narrow ? .82 : .78;

  @override
  void didUpdateWidget(covariant _FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameEventOrder(oldWidget.events, widget.events)) return;

    final hasNewFirstEvent = widget.events.isNotEmpty &&
        (oldWidget.events.isEmpty ||
            widget.events.first.id != oldWidget.events.first.id);
    if (hasNewFirstEvent) {
      _current = 0;
    } else {
      final currentEventId = oldWidget.events.isEmpty
          ? null
          : oldWidget.events[_current.clamp(0, oldWidget.events.length - 1)].id;
      final preservedIndex = currentEventId == null
          ? -1
          : widget.events.indexWhere((event) => event.id == currentEventId);
      _current = preservedIndex >= 0 ? preservedIndex : 0;
    }
    _advanceTimer?.cancel();
    _waitingAfterInteraction = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_carouselController.ready) {
        _carouselController.jumpToPage(_current);
      }
      _scheduleNext(_autoPlayInterval);
    });
  }

  bool _sameEventOrder(List<EventModel> before, List<EventModel> after) {
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].id != after[i].id) return false;
    }
    return true;
  }

  void _scheduleNext(Duration delay) {
    _advanceTimer?.cancel();
    if (!mounted || !_hasMultiplePages || _isInteracting) return;
    _advanceTimer = Timer(delay, () {
      _advanceTimer = null;
      _waitingAfterInteraction = false;
      if (!mounted || !_hasMultiplePages || _isInteracting) return;
      if (!_carouselController.ready) {
        _scheduleNext(const Duration(milliseconds: 250));
        return;
      }
      unawaited(
        _carouselController.nextPage(
          duration: _animationDuration,
          curve: Curves.easeInOutCubic,
        ),
      );
    });
  }

  void _holdForInteraction() {
    _advanceTimer?.cancel();
    _waitingAfterInteraction = false;
  }

  void _resumeAfterInteraction() {
    if (_isInteracting) return;
    _waitingAfterInteraction = true;
    _scheduleNext(_interactionResumeDelay);
  }

  void _onMouseEnter(PointerEnterEvent _) {
    _mouseOverBanner = true;
    _holdForInteraction();
  }

  void _onMouseExit(PointerExitEvent _) {
    _mouseOverBanner = false;
    _resumeAfterInteraction();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pressedPointers.add(event.pointer);
    _holdForInteraction();
    if (widget.narrow &&
        _tapCandidatePointer == null &&
        _pointerTargetsActiveSlide(event)) {
      _tapCandidatePointer = event.pointer;
      _tapCandidatePosition = event.position;
      _tapCandidateEventId = widget.events[_current].id;
      _tapCandidateExpiry?.cancel();
      _tapCandidateExpiry = Timer(
        const Duration(milliseconds: 450),
        _clearTapCandidate,
      );
    }
  }

  bool _pointerTargetsActiveSlide(PointerDownEvent event) {
    final renderObject = _carouselViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return true;
    final localPosition = renderObject.globalToLocal(event.position);
    final sidePreviewWidth =
        renderObject.size.width * (1 - _viewportFraction(widget.narrow)) / 2;
    return localPosition.dx >= sidePreviewWidth &&
        localPosition.dx <= renderObject.size.width - sidePreviewWidth;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_tapCandidatePointer != event.pointer ||
        _tapCandidatePosition == null) {
      return;
    }
    if ((event.position - _tapCandidatePosition!).distance > 18) {
      _clearTapCandidate();
    }
  }

  void _onPointerReleased(PointerUpEvent event) {
    final eventId = _tapCandidatePointer == event.pointer
        ? _tapCandidateEventId
        : null;
    _clearTapCandidate();
    _pressedPointers.remove(event.pointer);
    _resumeAfterInteraction();

    if (eventId != null) {
      scheduleMicrotask(() {
        if (!mounted) return;
        final index = widget.events.indexWhere((event) => event.id == eventId);
        if (index >= 0) _openEvent(widget.events[index]);
      });
    }
  }

  void _onPointerCanceled(PointerCancelEvent event) {
    if (_tapCandidatePointer == event.pointer) _clearTapCandidate();
    _pressedPointers.remove(event.pointer);
    _resumeAfterInteraction();
  }

  void _clearTapCandidate() {
    _tapCandidatePointer = null;
    _tapCandidatePosition = null;
    _tapCandidateEventId = null;
    _tapCandidateExpiry?.cancel();
    _tapCandidateExpiry = null;
  }

  void _openEvent(EventModel event) {
    final now = DateTime.now();
    if (_lastOpenedEventId == event.id &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastOpenedEventId = event.id;
    _lastOpenedAt = now;
    context.push('/events/${event.id}');
  }

  void _beginManualNavigation() {
    _advanceTimer?.cancel();
    _waitingAfterInteraction = true;
    if (!_isInteracting) _scheduleNext(_interactionResumeDelay);
  }

  void _previous() {
    if (!_carouselController.ready || widget.events.length < 2) return;
    _beginManualNavigation();
    unawaited(
      _carouselController.previousPage(
        duration: _animationDuration,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _next() {
    if (!_carouselController.ready || widget.events.length < 2) return;
    _beginManualNavigation();
    unawaited(
      _carouselController.nextPage(
        duration: _animationDuration,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _animateTo(int index) {
    if (!_carouselController.ready || widget.events.length < 2) return;
    _beginManualNavigation();
    if (index == _current) {
      return;
    }
    unawaited(
      _carouselController.animateToPage(
        index,
        duration: _animationDuration,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _onPageChanged(int index) {
    if (index != _current) setState(() => _current = index);
    if (!_waitingAfterInteraction && !_isInteracting) {
      _scheduleNext(_autoPlayInterval);
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _tapCandidateExpiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiplePages = widget.events.length > 1;
    return Column(
      children: [
        CallbackShortcuts(
          bindings: hasMultiplePages
              ? <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.arrowLeft):
                      _previous,
                  const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
                }
              : const <ShortcutActivator, VoidCallback>{},
          child: Focus(
            child: Semantics(
              container: true,
              label: hasMultiplePages
                  ? 'Sự kiện nổi bật, trang ${_current + 1} trên ${widget.events.length}'
                  : 'Sự kiện nổi bật',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: widget.narrow ? 490 : 340,
                child: MouseRegion(
                  onEnter: _onMouseEnter,
                  onExit: _onMouseExit,
                  child: Listener(
                    key: _carouselViewportKey,
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerReleased,
                    onPointerCancel: _onPointerCanceled,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CarouselSlider.builder(
                            key: const ValueKey('featured-carousel-pages'),
                            carouselController: _carouselController,
                            itemCount: widget.events.length,
                            itemBuilder: (context, index, _) {
                              final active = index == _current;
                              return AnimatedOpacity(
                                key: ValueKey(
                                  'featured-carousel-slide-opacity-$index',
                                ),
                                opacity: active ? 1 : .38,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                child: ExcludeSemantics(
                                  excluding: !active,
                                  child: IgnorePointer(
                                    ignoring: !active,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: widget.narrow ? 6 : 8,
                                        vertical: widget.narrow ? 8 : 12,
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          boxShadow: active
                                              ? const [
                                                  BoxShadow(
                                                    color: Color(0x33073D70),
                                                    blurRadius: 28,
                                                    offset: Offset(0, 10),
                                                  ),
                                                ]
                                              : const [
                                                  BoxShadow(
                                                    color: Color(0x0E073D70),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          child: _HeroBanner(
                                            event: widget.events[index],
                                            narrow: widget.narrow,
                                            onOpen: () => _openEvent(
                                              widget.events[index],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: widget.narrow ? 490 : 340,
                              viewportFraction: hasMultiplePages
                                  ? _viewportFraction(widget.narrow)
                                  : 1,
                              enableInfiniteScroll: hasMultiplePages,
                              autoPlay: false,
                              enlargeCenterPage: hasMultiplePages,
                              enlargeFactor: widget.narrow ? .16 : .18,
                              enlargeStrategy:
                                  CenterPageEnlargeStrategy.scale,
                              onPageChanged: (index, _) =>
                                  _onPageChanged(index),
                            ),
                          ),
                        ),
                        if (hasMultiplePages && !widget.narrow) ...[
                          _CarouselArrow(
                            key: const ValueKey('featured-carousel-previous'),
                            onLeft: true,
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Sự kiện trước',
                            onPressed: _previous,
                          ),
                          _CarouselArrow(
                            key: const ValueKey('featured-carousel-next'),
                            onLeft: false,
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Sự kiện tiếp theo',
                            onPressed: _next,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasMultiplePages)
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                widget.events.length,
                (index) => Semantics(
                  button: true,
                  selected: index == _current,
                  label: 'Hiển thị sự kiện nổi bật ${index + 1}',
                  child: Tooltip(
                    message: 'Sự kiện ${index + 1}',
                    child: InkWell(
                      key: ValueKey('featured-carousel-indicator-$index'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _animateTo(index),
                      child: SizedBox(
                        width: 34,
                        height: 30,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: index == _current ? 25 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: index == _current
                                  ? AppColors.blue
                                  : const Color(0xFFD4DEEA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    super.key,
    required this.onLeft,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final bool onLeft;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    left: onLeft ? 12 : null,
    right: onLeft ? null : 12,
    top: 0,
    bottom: 0,
    child: Center(
      child: Material(
        color: const Color(0xEFFFFFFF),
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          color: AppColors.navy,
          icon: Icon(icon),
        ),
      ),
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  final EventModel event;
  final bool narrow;
  final VoidCallback onOpen;
  const _HeroBanner({
    required this.event,
    required this.narrow,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final copy = Padding(
      padding: narrow
          ? const EdgeInsets.fromLTRB(20, 20, 20, 18)
          : const EdgeInsets.fromLTRB(36, 26, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'TRẢI NGHIỆM NỔI BẬT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFB8DDF4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: narrow ? 24 : 32,
              fontWeight: FontWeight.w800,
              height: 1.18,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC1DEEF),
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            key: const ValueKey('featured-carousel-cta'),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AppColors.navy,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Khám phá ngay',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final art = Stack(
      fit: StackFit.expand,
      children: [
        EventImage(event.image),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: narrow ? Alignment.topCenter : Alignment.centerLeft,
              end: narrow ? Alignment.bottomCenter : Alignment.centerRight,
              colors: [const Color(0xFF075A96), const Color(0x00075A96)],
              stops: const [0, .4],
            ),
          ),
        ),
        Positioned(
          bottom: 21,
          right: 21,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Text(
                  DateFormat('dd MMMM', 'vi_VN').format(event.start),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      label: 'Khám phá ngay: ${event.title}',
      onTap: onOpen,
      excludeSemantics: true,
      child: Tooltip(
        message: 'Xem chi tiết ${event.title}',
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF073D70), Color(0xFF075A96)],
              ),
            ),
            child: InkWell(
              key: ValueKey('featured-carousel-event-${event.id}'),
              onTap: onOpen,
              child: narrow
                  ? Column(
                      children: [
                        Expanded(flex: 3, child: copy),
                        Expanded(flex: 2, child: art),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 6, child: copy),
                        Expanded(flex: 5, child: art),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
