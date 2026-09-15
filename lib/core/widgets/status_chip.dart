import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.idle,
    this.icon,
  });

  Color get _backgroundColor {
    switch (tone) {
      case StatusTone.transit:
        return AppColors.transitSoft;
      case StatusTone.done:
        return AppColors.doneSoft;
      case StatusTone.warn:
        return AppColors.alertSoft;
      case StatusTone.fail:
        return AppColors.failSoft;
      case StatusTone.idle:
        return AppColors.counter;
    }
  }

  Color get _textColor {
    switch (tone) {
      case StatusTone.transit:
        return AppColors.transit;
      case StatusTone.done:
        return AppColors.done;
      case StatusTone.warn:
        return AppColors.alert;
      case StatusTone.fail:
        return AppColors.fail;
      case StatusTone.idle:
        return AppColors.inkSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: _textColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.monoLabel.copyWith(
              color: _textColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
