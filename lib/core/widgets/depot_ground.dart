import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'perforation_line.dart';

class DepotGround extends StatelessWidget {
  final Widget child;

  const DepotGround({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.counter,
      child: Stack(
        children: [
          // Background dot grid
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          // Subtle dashed route line
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.18,
            child: Opacity(
              opacity: 0.6,
              child: PerforationLine(color: AppColors.ink.withValues(alpha: 0.08), dashWidth: 6.0, dashGap: 8.0),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.16,
            child: Opacity(
              opacity: 0.6,
              child: PerforationLine(color: AppColors.ink.withValues(alpha: 0.08), dashWidth: 6.0, dashGap: 8.0),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
