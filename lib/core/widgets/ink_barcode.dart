import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class InkBarcode extends StatelessWidget {
  final String seed;
  final double height;
  final Color color;
  final double ratio; // Progress ratio (0.0 to 1.0)

  const InkBarcode({super.key, required this.seed, this.height = 28.0, this.color = AppColors.ink, this.ratio = 1.0});

  @override
  Widget build(BuildContext context) {
    final effectiveSeed = seed.isEmpty ? 'SUNGUARD' : seed;
    final bars = <int>[];
    for (int i = 0; i < 42; i++) {
      final code = effectiveSeed.codeUnitAt(i % effectiveSeed.length) + i * 7;
      bars.add(1 + (code % 3));
    }

    final inkedCount = (bars.length * ratio.clamp(0.0, 1.0)).round();

    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars.length, (index) {
          final width = bars[index].toDouble();
          final isInked = index < inkedCount;
          return Container(
            margin: const EdgeInsets.only(right: 2.0),
            width: width,
            height: height * (isInked ? 1.0 : 0.55),
            decoration: BoxDecoration(
              color: isInked
                  ? color.withValues(alpha: index % 5 == 0 ? 0.35 : 0.85)
                  : AppColors.inkTertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1.0),
            ),
          );
        }),
      ),
    );
  }
}
