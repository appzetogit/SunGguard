import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

abstract final class AppSnackBar {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF059669),
      bgColor: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFA7F3D0),
      textColor: const Color(0xFF065F46),
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFDC2626),
      bgColor: const Color(0xFFFEF2F2),
      borderColor: const Color(0xFFFECACA),
      textColor: const Color(0xFF991B1B),
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF2563EB),
      bgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFBFDBFE),
      textColor: const Color(0xFF1E40AF),
      duration: duration,
    );
  }

  static void showOffline(
    BuildContext context, {
    String? message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message ?? 'No Internet Connection. Please check your network.',
      icon: Icons.wifi_off_rounded,
      iconColor: const Color(0xFFF59E0B),
      bgColor: const Color(0xFF1F2937),
      borderColor: const Color(0xFF374151),
      textColor: const Color(0xFFF9FAFB),
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFD97706),
      bgColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      textColor: const Color(0xFF92400E),
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 92.0),
        duration: duration,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
