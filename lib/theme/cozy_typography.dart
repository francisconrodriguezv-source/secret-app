import 'package:flutter/material.dart';

import 'cozy_colors.dart';

/// Tipografía del design system Cozy Love.
///
/// Basada en Plus Jakarta Sans (headlines) y Be Vietnam Pro (body/labels).
/// Los tamaños/pesos/interlineado coinciden con los tokens de Stitch.
class CozyTypography {
  const CozyTypography._();

  static const String headlineFamily = 'Plus Jakarta Sans';
  static const String bodyFamily = 'Be Vietnam Pro';
  static const String handwritingFamily = 'Indie Flower';

  // ---- Display / Headline ----

  static const TextStyle displayLg = TextStyle(
    fontFamily: headlineFamily,
    fontSize: 48,
    height: 56 / 48,
    letterSpacing: -0.02 * 48, // -0.02em
    fontWeight: FontWeight.w700,
    color: CozyColors.onSurface,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: headlineFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
    color: CozyColors.onSurface,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: headlineFamily,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    color: CozyColors.onSurface,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: headlineFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
    color: CozyColors.onSurface,
  );

  // ---- Body ----

  static const TextStyle bodyLg = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
    color: CozyColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: CozyColors.onSurface,
  );

  // ---- Labels ----

  static const TextStyle labelMd = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0.01 * 14, // 0.01em
    fontWeight: FontWeight.w600,
    color: CozyColors.onSurface,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: CozyColors.onSurfaceVariant,
  );

  // ---- Handwriting (Message Board) ----

  static const TextStyle handwritingMd = TextStyle(
    fontFamily: handwritingFamily,
    fontSize: 22,
    height: 32 / 22,
    fontWeight: FontWeight.w400,
    color: CozyColors.onSurfaceVariant,
  );

  static const TextStyle handwritingLg = TextStyle(
    fontFamily: handwritingFamily,
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w400,
    color: CozyColors.onSurfaceVariant,
  );

  /// Devuelve un [TextTheme] Material 3 usando los estilos anteriores como
  /// mapa aproximado. Esto permite que widgets Material (AppBar, Chip, etc.)
  /// tomen la tipografía correcta cuando no se estiliza manualmente.
  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLg,
    displayMedium: headlineLg,
    displaySmall: headlineMd,
    headlineLarge: headlineLg,
    headlineMedium: headlineLgMobile,
    headlineSmall: headlineMd,
    titleLarge: headlineMd,
    titleMedium: labelMd,
    titleSmall: labelSm,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: labelSm,
    labelLarge: labelMd,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
