import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PerforationLine extends StatelessWidget {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double height;

  const PerforationLine({
    super.key,
    this.color = AppColors.rule,
    this.dashWidth = 5.0,
    this.dashGap = 5.0,
    this.height = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return SizedBox(
          width: boxWidth,
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
