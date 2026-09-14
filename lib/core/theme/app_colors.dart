import 'package:flutter/material.dart';

abstract final class AppColors {
  // ============================================================
  // Brand & Action
  // ============================================================

  static const Color primary = Color(0xFF0C831F); // Carrier green
  static const Color primaryDark = Color(0xFF096517);
  static const Color primaryLight = Color(0xFFE6F5EC);
  static const Color primarySoft = Color(0xFFB9E3CA);

  // ============================================================
  // Navy Theme
  // ============================================================

  static const Color navy = Color(0xFF071630);
  static const Color navyLight = Color(0xFF0D2854);
  static const Color navyShadow = Color(0x2408163A);

  static const Color navySoft = Color(0xFFE8EEF8);
  static const Color navyText = Color(0xFF081A3A);

  // ============================================================
  // Stationery / Consignment Dockets
  // ============================================================

  static const Color ink = Color(0xFF0F172A); // Slate 900 / Carrier's dark copy

  static const Color inkSecondary = Color(0xFF4A5568); // Secondary text

  static const Color inkTertiary = Color(0xFF8A94A6); // Labels & metadata

  static const Color paper = Color(0xFFFFFFFF); // Note surface

  static const Color counter = Color(0xFFF1F5F9); // Slate 100 booking counter

  static const Color background = Color(0xFFF8FAFC); // App background

  static const Color card = Color(0xFFFFFFFF);

  // ============================================================
  // Borders & Perforations
  // ============================================================

  static const Color border = Color(0xFFE2E8F0);

  static const Color borderStrong = Color(0xFFCBD5E5);

  static const Color rule = Color(0x2E0F172A); // rgba(15,23,42,0.18)

  static const Color ruleLight = Color(0x38FFFFFF); // rgba(255,255,255,0.22)

  // ============================================================
  // Status Colors
  // ============================================================

  static const Color transit = Color(0xFF1D4ED8); // Blue

  static const Color transitSoft = Color(0xFFE5EDFF);

  static const Color done = Color(0xFF0F9D58); // Green

  static const Color doneSoft = Color(0xFFE6F5EC);

  static const Color alert = Color(0xFFB45309); // Amber / Over-limit / wrong OTP

  static const Color alertSoft = Color(0xFFFDF2E3);

  static const Color fail = Color(0xFFB3261E); // Destructive Red

  static const Color failSoft = Color(0xFFFDECEB);

  // ============================================================
  // Glassmorphic Nav & Surfaces
  // ============================================================

  static const Color navBar = Color(0xEEFFFFFF);

  static const Color navLens = Color(0x99FFFFFF);

  static const Color navRim = Color(0x380C831F);
}
