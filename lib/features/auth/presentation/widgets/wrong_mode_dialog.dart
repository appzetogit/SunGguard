import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';

class WrongModeDialog extends StatelessWidget {
  final String targetMode; // 'signup' | 'login'
  final String phone;
  final VoidCallback onSwitch;
  final VoidCallback onCancel;

  const WrongModeDialog({
    super.key,
    required this.targetMode,
    required this.phone,
    required this.onSwitch,
    required this.onCancel,
  });

  String _formatPhone(String raw) {
    if (raw.length > 5) {
      return '${raw.substring(0, 5)} ${raw.substring(5)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isTargetSignup = targetMode == 'signup';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTargetSignup
                  ? 'This number is not registered'
                  : 'This number already has an account',
              style: AppTypography.headingLarge.copyWith(fontSize: 19.0),
            ),
            const SizedBox(height: AppSpacing.sm),
            RichText(
              text: TextSpan(
                style: AppTypography.bodyRegular.copyWith(fontSize: 14.0),
                children: isTargetSignup
                    ? [
                        const TextSpan(text: 'We have no account for '),
                        TextSpan(
                          text: '+91 ${_formatPhone(phone)}',
                          style: AppTypography.bodyBold,
                        ),
                        const TextSpan(
                          text: '. Open one and you can send your first parcel in a minute.',
                        ),
                      ]
                    : [
                        TextSpan(
                          text: '+91 ${_formatPhone(phone)}',
                          style: AppTypography.bodyBold,
                        ),
                        const TextSpan(
                          text: ' is already registered. Sign in instead — we will keep your number.',
                        ),
                      ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: isTargetSignup ? 'Create an account' : 'Sign in',
              onPressed: onSwitch,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: onCancel,
                child: Text(
                  'Use a different number',
                  style: AppTypography.bodyRegular.copyWith(
                    color: AppColors.inkTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
