import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common.dart';

Future<void> showEventImageViewer(
  BuildContext context, {
  required String source,
  required String title,
}) => showDialog<void>(
  context: context,
  useSafeArea: false,
  builder: (_) => EventImageViewer(source: source, title: title),
);

class EventImageViewer extends StatefulWidget {
  const EventImageViewer({
    super.key,
    required this.source,
    required this.title,
  });

  final String source;
  final String title;

  @override
  State<EventImageViewer> createState() => _EventImageViewerState();
}

class _EventImageViewerState extends State<EventImageViewer> {
  final _transformation = TransformationController();
  Size _viewport = Size.zero;

  void _zoom(double factor) {
    final scale = _transformation.value.getMaxScaleOnAxis();
    final target = (scale * factor).clamp(1.0, 5.0);
    if (target == 1) {
      _reset();
      return;
    }
    final center = _viewport.center(Offset.zero);
    _transformation.value = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(target / scale, target / scale, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1)
      ..multiply(_transformation.value);
  }

  void _reset() => _transformation.value = Matrix4.identity();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: const Color(0xFF101B2B),
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.equal): () => _zoom(1.25),
        const SingleActivator(LogicalKeyboardKey.equal, shift: true): () =>
            _zoom(1.25),
        const SingleActivator(LogicalKeyboardKey.minus): () => _zoom(.8),
        const SingleActivator(LogicalKeyboardKey.digit0): _reset,
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Đóng ảnh (Esc)',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _viewport = constraints.biggest;
                    return InteractiveViewer(
                      transformationController: _transformation,
                      minScale: 1,
                      maxScale: 5,
                      trackpadScrollCausesScale: true,
                      child: SizedBox.expand(
                        child: Semantics(
                          label: 'Ảnh sự kiện ${widget.title}',
                          image: true,
                          child: EventImage(widget.source, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _transformation,
                  builder: (context, matrix, _) {
                    final scale = matrix.getMaxScaleOnAxis();
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Thu nhỏ ảnh',
                              onPressed: scale <= 1 ? null : () => _zoom(.8),
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            SizedBox(
                              width: 53,
                              child: Text(
                                '${(scale * 100).round()}%',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Phóng to ảnh',
                              onPressed: scale >= 5 ? null : () => _zoom(1.25),
                              icon: const Icon(Icons.add_rounded),
                            ),
                            IconButton(
                              tooltip: 'Khôi phục kích thước ảnh',
                              onPressed: _reset,
                              icon: const Icon(Icons.fit_screen_rounded),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  'Chụm hai ngón để phóng to · Kéo để xem ảnh',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
