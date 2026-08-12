import 'dart:math' as math;

import 'package:flutter/material.dart';

class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * 2,
      child: CustomPaint(
        painter: _OrnamentPainter(color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double centerX = size.width / 2;
    final double diamond = size.height * 0.32;
    final double gap = diamond * 2.4;

    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(math.max(0, centerX - gap), centerY),
      linePaint,
    );
    canvas.drawLine(
      Offset(math.min(size.width, centerX + gap), centerY),
      Offset(size.width, centerY),
      linePaint,
    );

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void drawDiamond(double dx, double scale) {
      final double r = diamond * scale;
      final Path path = Path()
        ..moveTo(dx, centerY - r)
        ..lineTo(dx + r, centerY)
        ..lineTo(dx, centerY + r)
        ..lineTo(dx - r, centerY)
        ..close();
      canvas.drawPath(path, fillPaint);
    }

    drawDiamond(centerX, 1);
    drawDiamond(centerX - diamond * 1.7, 0.55);
    drawDiamond(centerX + diamond * 1.7, 0.55);
  }

  @override
  bool shouldRepaint(_OrnamentPainter oldDelegate) => oldDelegate.color != color;
}
