import 'dart:math';

import 'package:flutter/material.dart';

import '../game/conveyor_drop_controller.dart';
import '../models/drop_color_type.dart';

class GamePainter extends CustomPainter {
  GamePainter(this.controller);

  final ConveyorDropController controller;

  static const Color darkBrown = Color(0xFF3A2A1C);
  static const Color cream = Color(0xFFFFF6E8);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawConveyor(canvas, size);
    _drawDropLine(canvas, size);
    _drawItems(canvas);
    _drawWheel(canvas, size);
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
    const top = 166.0;
    const height = 52.0;
    const holeY = top + 26;

    final shadowPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.20)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28, top + 12, size.width - 56, 48),
        const Radius.circular(24),
      ),
      shadowPaint,
    );

    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(24, top, size.width - 48, height),
      const Radius.circular(24),
    );

    final outerPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.fill;

    canvas.drawRRect(outerRect, outerPaint);

    final beltRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(32, top + 7, size.width - 64, height - 14),
      const Radius.circular(19),
    );

    canvas.save();
    canvas.clipRRect(beltRect);

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF6E8), Color(0xFFFFE6C8)],
      ).createShader(beltRect.outerRect);

    canvas.drawRRect(beltRect, basePaint);

    final beltColors = <Color>[
      const Color(0xFF3F86FF),
      const Color(0xFFFFC63D),
      const Color(0xFFFF4E55),
      const Color(0xFF58D68D),
    ];

    const segmentWidth = 54.0;
    const gap = 8.0;
    final step = segmentWidth + gap;
    final offset = controller.conveyorOffset;

    for (double x = -step * 2 - offset; x < size.width + step; x += step) {
      final colorIndex = ((x / step).floor().abs()) % beltColors.length;

      final segmentPaint = Paint()
        ..color = beltColors[colorIndex]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(x + 12, top + 7)
        ..lineTo(x + segmentWidth, top + 7)
        ..lineTo(x + segmentWidth - 12, top + height - 7)
        ..lineTo(x, top + height - 7)
        ..close();

      canvas.drawPath(path, segmentPaint);

      final shinePaint = Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 0.22)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + 12, top + 13),
        Offset(x + segmentWidth - 10, top + 13),
        shinePaint,
      );
    }

    final overlayPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.18),
          Color.fromRGBO(0, 0, 0, 0.08),
        ],
      ).createShader(beltRect.outerRect);

    canvas.drawRRect(beltRect, overlayPaint);

    canvas.restore();

    final borderPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(outerRect, borderPaint);

    final holeRingPaint = Paint()
      ..color = const Color.fromRGBO(255, 246, 232, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawCircle(Offset(size.width / 2, holeY), 31, holeRingPaint);

    final holeShadowPaint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(Offset(size.width / 2, holeY), 27, holeShadowPaint);

    final holePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, holeY), 24, holePaint);
  }

  void _drawDropLine(Canvas canvas, Size size) {
    final wheelCenterY =
        size.height - ConveyorDropController.wheelCenterBottomOffset;

    final linePaint = Paint()
      ..color = const Color.fromRGBO(58, 42, 28, 0.13)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 220),
      Offset(size.width / 2, wheelCenterY - ConveyorDropController.wheelRadius),
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
      size.height - ConveyorDropController.wheelCenterBottomOffset,
    );

    const radius = ConveyorDropController.wheelRadius;
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
