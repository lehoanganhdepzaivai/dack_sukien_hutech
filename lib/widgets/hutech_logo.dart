import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// A crisp, code-drawn HUTECH shield for compact UI placements.
///
/// The former bitmap included the full horizontal wordmark, so its shield and
/// lettering became unreadable when squeezed into the sidebar and login card.
/// This painter keeps the mark transparent and sharp at every display scale.
class HutechLogoMark extends StatelessWidget {
  final double size;

  const HutechLogoMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Logo HUTECH University',
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(painter: _HutechLogoPainter()),
        ),
      ),
    ),
  );
}

class _HutechLogoPainter extends CustomPainter {
  const _HutechLogoPainter();

  static const _designSize = 320.0;
  static const _red = Color(0xFFE51C2A);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _designSize;
    final dx = (size.width - _designSize * scale) / 2;
    final dy = (size.height - _designSize * scale) / 2;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final shield = Path()
      ..moveTo(54, 42)
      ..quadraticBezierTo(160, 3, 266, 42)
      ..lineTo(266, 190)
      ..cubicTo(266, 248, 229, 282, 160, 316)
      ..cubicTo(91, 282, 54, 248, 54, 190)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.blue);

    final yellowField = Path()
      ..moveTo(66, 139)
      ..quadraticBezierTo(160, 107, 254, 139)
      ..lineTo(254, 190)
      ..cubicTo(254, 239, 223, 269, 160, 301)
      ..cubicTo(97, 269, 66, 239, 66, 190)
      ..close();
    canvas.drawPath(yellowField, Paint()..color = const Color(0xFFFFED00));

    final divider = Path()
      ..moveTo(65, 139)
      ..quadraticBezierTo(160, 106, 255, 139);
    canvas.drawPath(
      divider,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    _drawCenteredText(
      canvas,
      'HUTECH',
      const TextStyle(
        color: Colors.white,
        fontSize: 32,
        height: 1,
        fontWeight: FontWeight.w900,
        letterSpacing: -.6,
      ),
      55,
    );
    _drawCenteredText(
      canvas,
      'University',
      const TextStyle(
        color: Colors.white,
        fontSize: 25,
        height: 1,
        fontWeight: FontWeight.w400,
        letterSpacing: -.7,
      ),
      87,
    );

    final flamePaint = Paint()
      ..color = _red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer torch flame.
    final outerFlame = Path()
      ..moveTo(161, 246)
      ..cubicTo(130, 243, 116, 229, 120, 211)
      ..cubicTo(123, 196, 136, 190, 141, 176)
      ..cubicTo(145, 165, 143, 155, 144, 148)
      ..cubicTo(158, 161, 161, 178, 153, 193)
      ..cubicTo(147, 204, 142, 213, 149, 221)
      ..cubicTo(156, 229, 169, 225, 175, 216)
      ..cubicTo(182, 204, 175, 192, 174, 181)
      ..cubicTo(172, 167, 180, 153, 194, 141)
      ..cubicTo(187, 160, 201, 173, 202, 193)
      ..cubicTo(204, 220, 186, 242, 161, 246);
    canvas.drawPath(outerFlame, flamePaint);

    // Inner lick gives the hand-drawn torch its recognizable rhythm.
    final innerFlame = Path()
      ..moveTo(152, 225)
      ..cubicTo(145, 215, 151, 205, 160, 197)
      ..cubicTo(168, 189, 170, 180, 168, 171)
      ..cubicTo(181, 184, 184, 199, 176, 211)
      ..cubicTo(170, 220, 162, 225, 152, 225);
    canvas.drawPath(innerFlame, flamePaint);

    final bowl = Path()
      ..moveTo(126, 229)
      ..cubicTo(134, 244, 145, 251, 160, 252)
      ..cubicTo(177, 252, 189, 244, 196, 229)
      ..moveTo(133, 250)
      ..quadraticBezierTo(160, 263, 187, 250);
    canvas.drawPath(bowl, flamePaint);

    final handle = Path()
      ..moveTo(148, 259)
      ..lineTo(155, 288)
      ..lineTo(181, 276)
      ..lineTo(171, 257);
    canvas.drawPath(handle, flamePaint);

    canvas.restore();
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    double top,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(canvas, Offset(160 - painter.width / 2, top));
  }

  @override
  bool shouldRepaint(covariant _HutechLogoPainter oldDelegate) => false;
}
