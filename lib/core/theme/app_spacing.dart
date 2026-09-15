import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusCard = 28.0;
  static const double radiusPill = 999.0;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x2E0F172A),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -14,
    ),
  ];

  static const List<BoxShadow> liftHigh = [
    BoxShadow(
      color: Color(0x0F0F172A),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Color(0x400F172A),
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -18,
    ),
  ];
}
