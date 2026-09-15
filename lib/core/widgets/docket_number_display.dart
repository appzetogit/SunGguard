import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class DocketNumberDisplay extends StatelessWidget {
  final String digits;
  final int totalSlots;

  const DocketNumberDisplay({super.key, required this.digits, this.totalSlots = 10});

  @override
  Widget build(BuildContext context) {
    final cleanDigits = digits.replaceAll(RegExp(r'\D'), '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(totalSlots, (index) {
        final hasChar = index < cleanDigits.length;
        final char = hasChar ? cleanDigits[index] : '•';

        return Container(
          width: 26.0,
          height: 36.0,
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasChar ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              color: hasChar ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            char,
            style: AppTypography.monoTitle.copyWith(
              color: hasChar ? Colors.white : Colors.white38,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }),
    );
  }
}
