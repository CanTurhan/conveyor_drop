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

    final conveyorRect = Rect.fromLTWH(24, top, size.width - 48, height);

    final conveyorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E3E3E), Color(0xFF181818)],
      ).createShader(conveyorRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(conveyorRect, const Radius.circular(24)),
      conveyorPaint,
    );

    final stripePaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.26)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    for (double x = 42; x < size.width - 42; x += 36) {
      canvas.drawLine(
        Offset(x, top + 10),
        Offset(x + 18, top + 42),
        stripePaint,
      );
    }

    final holeRingPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(size.width / 2, holeY), 29, holeRingPaint);

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

    final centerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cream, Color(0xFFFFD7A1)],
      ).createShader(const Rect.fromLTWH(-33, -33, 66, 66));

    canvas.drawCircle(Offset.zero, 32, centerPaint);

    final centerBorderPaint = Paint()
      ..color = darkBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, 32, centerBorderPaint);

    _drawText(
      canvas: canvas,
      text: '3',
      position: Offset.zero,
      fontSize: 22,
      weight: FontWeight.w900,
      color: darkBrown,
    );

    canvas.restore();
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
