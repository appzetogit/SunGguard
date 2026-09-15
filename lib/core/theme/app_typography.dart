import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  // Prose & Display Styles (Outfit / Sans)
  static TextStyle get headingLarge => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
      );

  static TextStyle get headingSmall => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get bodyRegular => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
        height: 1.4,
      );

  static TextStyle get bodyBold => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.inkTertiary,
      );

  // Mono Docket & Waybill Styles (JetBrains Mono)
  static TextStyle get monoTitle => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.5,
      );

  static TextStyle get monoLabel => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.inkTertiary,
        letterSpacing: 1.8,
      );

  static TextStyle get monoLabelLight => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white70,
        letterSpacing: 1.8,
      );

  static TextStyle get monoData => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get monoDataSmall => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.inkTertiary,
      );

  static TextStyle get monoButton => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 2.0,
      );

  static TextStyle get stampText => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.2,
      );
}
