import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ConsignmentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool inverse;
  final VoidCallback? onTap;

  const ConsignmentCard({
    super.key,
    required this.child,
    this.padding,
    this.inverse = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: inverse ? AppColors.ink : AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: inverse ? Colors.transparent : AppColors.border,
          width: 1.0,
        ),
        boxShadow: AppShadows.card,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: content,
        ),
      );
    }

    return content;
  }
}
