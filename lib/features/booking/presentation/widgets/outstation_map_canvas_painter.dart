import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class OutstationMapCanvasPainter extends CustomPainter {
  final Offset offset;
  final double zoom;

  const OutstationMapCanvasPainter({
    required this.offset,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF3F4F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // River / Water body
    final waterPaint = Paint()..color = const Color(0xFFBAE6FD);
    final waterPath = Path();
    waterPath.moveTo(0, size.height * 0.2 + offset.dy * 0.5);
    waterPath.quadraticBezierTo(
      size.width * 0.4 + offset.dx * 0.5,
      size.height * 0.15 + offset.dy * 0.5,
      size.width,
      size.height * 0.35 + offset.dy * 0.5,
    );
    waterPath.lineTo(size.width, size.height * 0.3 + offset.dy * 0.5);
    waterPath.quadraticBezierTo(
      size.width * 0.4 + offset.dx * 0.5,
      size.height * 0.1 + offset.dy * 0.5,
      0,
      size.height * 0.15 + offset.dy * 0.5,
    );
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);

    // Green / Sector Areas
    final parkPaint = Paint()..color = const Color(0xFFDCFCE7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.5 + offset.dx,
          size.height * 0.1 + offset.dy,
          80,
          50,
        ),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Roads (Main highways & secondary streets)
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    // Highway 1
    final p1 = Offset(0, size.height * 0.6 + offset.dy);
    final p2 = Offset(size.width, size.height * 0.2 + offset.dy);
    canvas.drawLine(p1, p2, roadBorderPaint);
    canvas.drawLine(p1, p2, roadPaint);

    // Street 2
    final p3 = Offset(size.width * 0.3 + offset.dx, 0);
    final p4 = Offset(size.width * 0.7 + offset.dx, size.height);
    canvas.drawLine(p3, p4, roadBorderPaint);
    canvas.drawLine(p3, p4, roadPaint);

    // Street 3
    final p5 = Offset(0, size.height * 0.85 + offset.dy);
    final p6 = Offset(size.width, size.height * 0.85 + offset.dy);
    canvas.drawLine(p5, p6, roadBorderPaint);
    canvas.drawLine(p5, p6, roadPaint);

    // Area Text Labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    void drawLabel(String text, double x, double y, {bool isBold = false}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isBold ? 11.0 : 9.5,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + offset.dx, y + offset.dy));
    }

    drawLabel('SUKHLIYA', size.width * 0.4, size.height * 0.68, isBold: true);
    drawLabel('KASHIPURI COLONY', size.width * 0.38, size.height * 0.48);
    drawLabel('MAA SHARDA NAGAR', size.width * 0.58, size.height * 0.44);
  }

  @override
  bool shouldRepaint(covariant OutstationMapCanvasPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.zoom != zoom;
  }
}
