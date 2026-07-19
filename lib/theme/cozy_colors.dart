import 'package:flutter/material.dart';

/// Paleta de colores del design system Cozy Love (exportada desde Stitch).
///
/// Los tokens siguen la nomenclatura de Material 3 (primary, secondary,
/// surface, container, etc.) con la variante `fixed` para superficies que no
/// cambian entre light/dark.
class CozyColors {
  const CozyColors._();

  // Primary — Muted Peach
  static const Color primary = Color(0xFF94483A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFF9E8C);
  static const Color onPrimaryContainer = Color(0xFF793326);
  static const Color primaryFixed = Color(0xFFFFDAD4);
  static const Color primaryFixedDim = Color(0xFFFFB4A6);
  static const Color onPrimaryFixed = Color(0xFF3D0602);
  static const Color onPrimaryFixedVariant = Color(0xFF773125);
  static const Color inversePrimary = Color(0xFFFFB4A6);

  // Secondary — Soft Lavender
  static const Color secondary = Color(0xFF69548D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD7BEFF);
  static const Color onSecondaryContainer = Color(0xFF5F4A82);
  static const Color secondaryFixed = Color(0xFFECDCFF);
  static const Color secondaryFixedDim = Color(0xFFD4BBFC);
  static const Color onSecondaryFixed = Color(0xFF240E45);
  static const Color onSecondaryFixedVariant = Color(0xFF513C74);

  // Tertiary — Warm Sand
  static const Color tertiary = Color(0xFF635E55);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFBEB7AD);
  static const Color onTertiaryContainer = Color(0xFF4C4840);
  static const Color tertiaryFixed = Color(0xFFE9E1D7);
  static const Color tertiaryFixedDim = Color(0xFFCDC6BB);
  static const Color onTertiaryFixed = Color(0xFF1E1B15);
  static const Color onTertiaryFixedVariant = Color(0xFF4A463E);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface / Background
  static const Color background = Color(0xFFFFF8F6);
  static const Color onBackground = Color(0xFF211A18);
  static const Color surface = Color(0xFFFFF8F6);
  static const Color surfaceBright = Color(0xFFFFF8F6);
  static const Color surfaceDim = Color(0xFFE4D7D3);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF1EC);
  static const Color surfaceContainer = Color(0xFFF9EBE7);
  static const Color surfaceContainerHigh = Color(0xFFF3E5E1);
  static const Color surfaceContainerHighest = Color(0xFFEDE0DB);
  static const Color surfaceVariant = Color(0xFFEDE0DB);
  static const Color onSurface = Color(0xFF211A18);
  static const Color onSurfaceVariant = Color(0xFF54433F);
  static const Color inverseSurface = Color(0xFF362F2C);
  static const Color inverseOnSurface = Color(0xFFFCEEEA);
  static const Color surfaceTint = Color(0xFF94483A);
  static const Color outline = Color(0xFF87726F);
  static const Color outlineVariant = Color(0xFFDAC1BC);

  // Fondos con textura (Message Board wood, warm sand del Vault)
  static const Color woodBase = Color(0xFFFCEEEA);
  static const Color warmSand = Color(0xFFF9F1E6);

  // Colores auxiliares para las notas del Message Board (post-its).
  static const Color noteYellow = Color(0xFFFFF9C4);
  static const Color notePink = Color(0xFFF8BBD0);
  static const Color noteBlue = Color(0xFFB3E5FC);
  static const Color notePurple = Color(0xFFE1BEE7);

  /// Gradiente hero (peach → lavender) usado en Timeline y botones primarios.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryFixed, secondaryContainer],
  );

  /// Gradiente para el botón primario (peach vibrante → lavender).
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, secondaryContainer],
  );

  /// Gradiente del día activo en el calendario.
  static const LinearGradient activeDayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, secondaryContainer],
  );

  /// Gradiente warm-lavender (Create screen background).
  static const LinearGradient warmLavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmSand, surfaceContainerHighest, secondaryFixed],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradiente vertical warm-sand → surface (Calendar background).
  static const LinearGradient calendarBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [warmSand, surface],
  );
}
