// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: packages/design-tokens/tokens.json

import 'package:flutter/material.dart';

abstract final class AppDarkColors {
  static const Color background = Color(0xFF0B0E17);
  static const Color surface = Color(0xFF131826);
  static const Color surfaceElevated = Color(0xFF1A2138);
  static const Color surfaceMuted = Color(0xFF1C1F29);
  static const Color border = Color(0xFF262B3D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF7B8CA3);
  static const Color accent = Color(0xFF8A2BE2);
  static const Color accentHover = Color(0xFF7A22CC);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);
}

abstract final class AppLightColors {
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F4FA);
  static const Color surfaceMuted = Color(0xFFE9EEF7);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF526071);
  static const Color accent = Color(0xFF7C22CE);
  static const Color accentHover = Color(0xFF6B1BB5);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}

abstract final class AppTypography {
  static const String fontFamily = 'Roboto';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.250,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 1.231,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.273,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.333,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.375,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.467,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.385,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.333,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.273,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}

abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double s2xl = 32.0;
  static const double s3xl = 48.0;
  static const double touchTarget = 48.0;
}

abstract final class AppRadii {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

abstract final class AppElevation {
  static const List<BoxShadow> none = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0),
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.14),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.22),
      offset: Offset(0, 6),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -4,
    ),
  ];
}

abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}
