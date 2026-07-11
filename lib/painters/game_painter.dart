import 'dart:math';

import 'package:flutter/material.dart';

import '../game/conveyor_drop_controller.dart';
import '../models/drop_color_type.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.controller);

  final ColorMatchSpinRushController controller;

  static const Color darkBrown = Color(0xFF3A2A1C);
  static const Color cream = Color(0xFFFFF6E8);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawConveyor(canvas, size);
    _drawDropLine(canvas, size);
    _drawItems(canvas);
    _drawWheel(canvas, size);

    if (controller.isReverseSwipeActive) {
      _drawReverseSwipeWarning(canvas, size);
    }

    if (controller.catchPointEffectActive) {
      _drawCatchPointEffect(canvas, size);
    }

    if (controller.isReverseSwipeActive) {
      _drawReverseWheelGlow(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF3DE), Color(0xFFFFE7C8), Color(0xFFEAF7F1)],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final greenBlob = Paint()
      ..color = const Color.fromRGBO(139, 195, 180, 0.14)
      ..style = PaintingStyle.fill;

    final purpleBlob = Paint()
      ..color = const Color.fromRGBO(120, 95, 170, 0.10)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.34),
      95,
      greenBlob,
    );

    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.45),
      130,
      purpleBlob,
    );

    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.84),
      115,
      purpleBlob,
    );
  }

  void _drawConveyor(Canvas canvas, Size size) {
    final conveyorRect = Rect.fromLTWH(18, 166, size.width - 36, 52);

    final conveyorRRect = RRect.fromRectAndRadius(
      conveyorRect,
      const Radius.circular(24),
    );

    final shadowPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.16)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(conveyorRRect.shift(const Offset(0, 5)), shadowPaint);

    final basePaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.fill;

    canvas.drawRRect(conveyorRRect, basePaint);

    final innerRect = conveyorRect.deflate(6);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(18),
    );

    canvas.save();
    canvas.clipRRect(innerRRect);

    const segmentWidth = 48.0;
    const patternColors = <Color>[
      Color(0xFF44A8FF),
      Color(0xFFFFC83D),
      Color(0xFFE94B4B),
      Color(0xFF37C96B),
    ];

    final patternWidth = segmentWidth * patternColors.length;
    final offset = controller.conveyorOffset % patternWidth;

    var x = innerRect.left - offset - patternWidth;

    while (x < innerRect.right + patternWidth) {
      for (final color in patternColors) {
        final segmentRect = Rect.fromLTWH(
          x,
          innerRect.top,
          segmentWidth,
          innerRect.height,
        );

        final segmentPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRect(segmentRect, segmentPaint);

        final shinePaint = Paint()
          ..color = const Color.fromRGBO(255, 255, 255, 0.20)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            x,
            innerRect.top,
            segmentWidth,
            innerRect.height * 0.34,
          ),
          shinePaint,
        );

        final dividerPaint = Paint()
          ..color = const Color.fromRGBO(58, 42, 28, 0.14)
          ..strokeWidth = 2;

        canvas.drawLine(
          Offset(x, innerRect.top),
          Offset(x, innerRect.bottom),
          dividerPaint,
        );

        x += segmentWidth;
      }
    }

    canvas.restore();

    final borderPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(conveyorRRect, borderPaint);

    final holeCenter = Offset(size.width / 2, conveyorRect.center.dy);

    final holeShadowPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.26)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(holeCenter.translate(0, 3), 19, holeShadowPaint);

    final holePaint = Paint()
      ..color = const Color(0xFF1F1712)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(holeCenter, 18, holePaint);

    final holeRingPaint = Paint()
      ..color = cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(holeCenter, 20, holeRingPaint);
  }

  void _drawDropLine(Canvas canvas, Size size) {
    final wheelCenterY =
        size.height - ColorMatchSpinRushController.wheelCenterBottomOffset;

    final linePaint = Paint()
      ..color = const Color.fromRGBO(58, 42, 28, 0.13)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 220),
      Offset(
        size.width / 2,
        wheelCenterY - ColorMatchSpinRushController.wheelRadius,
      ),
      linePaint,
    );
  }

  void _drawItems(Canvas canvas) {
    for (final item in controller.items) {
      final shadowPaint = Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(item.x, item.y + 5), item.radius, shadowPaint);

      final paint = Paint()
        ..color = item.colorType.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(item.x, item.y), item.radius, paint);

      final highlightPaint = Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.55)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(item.x - 6, item.y - 7),
        item.radius * 0.32,
        highlightPaint,
      );

      final borderPaint = Paint()
        ..color = darkBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6;

      canvas.drawCircle(Offset(item.x, item.y), item.radius, borderPaint);
    }
  }

  void _drawWheel(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height - ColorMatchSpinRushController.wheelCenterBottomOffset,
    );

    const radius = ColorMatchSpinRushController.wheelRadius;
    const outerRadius = 104.0;
    const pieceRadius = 27.0;

    final positions = <Offset>[
      const Offset(0, -radius),
      const Offset(radius, 0),
      const Offset(0, radius),
      const Offset(-radius, 0),
    ];

    final shadowPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.16)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx, center.dy + 10),
      outerRadius,
      shadowPaint,
    );

    final basePaint = Paint()
      ..color = const Color.fromRGBO(255, 246, 232, 0.58)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, outerRadius, basePaint);

    final ringPaint = Paint()
      ..color = const Color.fromRGBO(58, 42, 28, 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, outerRadius, ringPaint);

    _drawCatchArrow(canvas, center);

    // Only the colored holes rotate.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(controller.visualRotation);

    for (int i = 0; i < controller.wheelColors.length; i++) {
      final colorType = controller.wheelColors[i];
      final position = positions[i];

      final pieceShadowPaint = Paint()
        ..color = const Color.fromRGBO(0, 0, 0, 0.20)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(position.dx, position.dy + 5),
        pieceRadius,
        pieceShadowPaint,
      );

      final piecePaint = Paint()
        ..color = colorType.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, pieceRadius, piecePaint);

      final borderPaint = Paint()
        ..color = darkBrown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(position, pieceRadius, borderPaint);

      final count = controller.bins[colorType] ?? 0;
      _drawCountBubble(canvas, position, '$count/3');
    }

    canvas.restore();

    // Lives indicator is drawn after restore, so it never rotates.
    _drawCenterLives(canvas, center);
  }

  void _drawCenterLives(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cream, Color(0xFFFFD7A1)],
      ).createShader(Rect.fromCircle(center: center, radius: 32));

    canvas.drawCircle(center, 32, centerPaint);

    final centerBorderPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, 32, centerBorderPaint);

    _drawText(
      canvas: canvas,
      text: '${controller.lives}',
      position: center,
      fontSize: 22,
      weight: FontWeight.w900,
      color: darkBrown,
    );
  }

  void _drawCatchArrow(Canvas canvas, Offset center) {
    final arrowPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - 119)
      ..lineTo(center.dx - 12, center.dy - 96)
      ..lineTo(center.dx + 12, center.dy - 96)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  void _drawCountBubble(Canvas canvas, Offset position, String text) {
    final bubblePaint = Paint()
      ..color = const Color.fromRGBO(255, 246, 232, 0.90)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: position, width: 38, height: 22),
        const Radius.circular(11),
      ),
      bubblePaint,
    );

    _drawText(
      canvas: canvas,
      text: text,
      position: position,
      fontSize: 11,
      weight: FontWeight.w900,
      color: darkBrown,
    );
  }

  void _drawCatchPointEffect(Canvas canvas, Size size) {
    final colorType = controller.catchPointEffectColor;
    if (colorType == null) return;

    final progress = controller.catchPointEffectProgress.clamp(0.0, 1.0);
    final effectColor = controller.catchPointEffectSuccess
        ? colorType.color
        : const Color(0xFFE53935);

    final wheelCenter = Offset(size.width / 2, size.height - 135);

    final catchPoint = Offset(size.width / 2, wheelCenter.dy - 88);

    final fade = progress;
    final radius = 18 + ((1 - progress) * 34);

    final ringPaint = Paint()
      ..color = effectColor.withOpacity(0.58 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(catchPoint, radius, ringPaint);

    final innerPaint = Paint()
      ..color = effectColor.withOpacity(0.24 * fade)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(catchPoint, radius * 0.55, innerPaint);

    if (controller.catchPointEffectSuccess) {
      final sparkPaint = Paint()
        ..color = Colors.white.withOpacity(0.82 * fade)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 8; i++) {
        final angle = (pi * 2 / 8) * i;
        final start = Offset(
          catchPoint.dx + cos(angle) * (radius * 0.50),
          catchPoint.dy + sin(angle) * (radius * 0.50),
        );
        final end = Offset(
          catchPoint.dx + cos(angle) * (radius * 0.86),
          catchPoint.dy + sin(angle) * (radius * 0.86),
        );

        canvas.drawLine(start, end, sparkPaint);
      }
    } else {
      final impactPaint = Paint()
        ..color = const Color(0xFFE53935).withOpacity(0.92 * fade)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      const xSize = 18.0;

      canvas.drawLine(
        catchPoint.translate(-xSize, -xSize),
        catchPoint.translate(xSize, xSize),
        impactPaint,
      );

      canvas.drawLine(
        catchPoint.translate(xSize, -xSize),
        catchPoint.translate(-xSize, xSize),
        impactPaint,
      );
    }
  }

  void _drawReverseWheelGlow(Canvas canvas, Size size) {
    final wheelCenter = Offset(size.width / 2, size.height - 135);

    final pulse =
        0.5 + (sin(controller.reverseSwipeRemainingSeconds * pi * 3) * 0.5);

    final glowPaint = Paint()
      ..color = const Color(0xFF9B5CFF).withOpacity(0.24 + pulse * 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 + pulse * 4;

    canvas.drawCircle(wheelCenter, 112 + pulse * 4, glowPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF9B5CFF).withOpacity(0.75)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final angle = (pi / 2 * i) + (pi / 4);
      final start = Offset(
        wheelCenter.dx + cos(angle) * 34,
        wheelCenter.dy + sin(angle) * 34,
      );
      final end = Offset(
        wheelCenter.dx + cos(angle) * 106,
        wheelCenter.dy + sin(angle) * 106,
      );

      canvas.drawLine(start, end, linePaint);
    }
  }

  void _drawReverseSwipeWarning(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, 292),
      width: min(size.width - 48, 310),
      height: 54,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    final bgPaint = Paint()
      ..color = const Color(0xFF9B5CFF)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, borderPaint);

    _drawText(
      canvas: canvas,
      text: 'REVERSE SWIPE ${controller.reverseSwipeRemainingSeconds.ceil()}s',
      position: rect.center,
      fontSize: 17,
      weight: FontWeight.w900,
      color: cream,
    );
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required double fontSize,
    required FontWeight weight,
    required Color color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
