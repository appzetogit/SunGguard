import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AcceptedStamp extends StatelessWidget {
  final String label;
  final Color color;

  const AcceptedStamp({
    super.key,
    this.label = 'ACCEPTED',
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -7 * (math.pi / 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.0),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.stampText.copyWith(
            color: color,
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
