import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cozy_colors.dart';
import 'cozy_spacing.dart';
import 'cozy_typography.dart';

/// Construye el [ThemeData] global de la app siguiendo el design system
/// exportado desde Stitch (colores, tipografía, radios, sombras, tap targets).
class CozyTheme {
  const CozyTheme._();

  static ColorScheme get colorScheme => const ColorScheme.light(
    primary: CozyColors.primary,
    onPrimary: CozyColors.onPrimary,
    primaryContainer: CozyColors.primaryContainer,
    onPrimaryContainer: CozyColors.onPrimaryContainer,
    secondary: CozyColors.secondary,
    onSecondary: CozyColors.onSecondary,
    secondaryContainer: CozyColors.secondaryContainer,
    onSecondaryContainer: CozyColors.onSecondaryContainer,
    tertiary: CozyColors.tertiary,
    onTertiary: CozyColors.onTertiary,
    tertiaryContainer: CozyColors.tertiaryContainer,
    onTertiaryContainer: CozyColors.onTertiaryContainer,
    error: CozyColors.error,
    onError: CozyColors.onError,
    errorContainer: CozyColors.errorContainer,
    onErrorContainer: CozyColors.onErrorContainer,
    surface: CozyColors.surface,
    onSurface: CozyColors.onSurface,
    surfaceContainerLowest: CozyColors.surfaceContainerLowest,
    surfaceContainerLow: CozyColors.surfaceContainerLow,
    surfaceContainer: CozyColors.surfaceContainer,
    surfaceContainerHigh: CozyColors.surfaceContainerHigh,
    surfaceContainerHighest: CozyColors.surfaceContainerHighest,
    surfaceDim: CozyColors.surfaceDim,
    surfaceBright: CozyColors.surfaceBright,
    onSurfaceVariant: CozyColors.onSurfaceVariant,
    outline: CozyColors.outline,
    outlineVariant: CozyColors.outlineVariant,
    inverseSurface: CozyColors.inverseSurface,
    onInverseSurface: CozyColors.inverseOnSurface,
    inversePrimary: CozyColors.inversePrimary,
    surfaceTint: CozyColors.surfaceTint,
  );

  static ThemeData build() {
    final scheme = colorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: CozyTypography.bodyFamily,
      scaffoldBackgroundColor: CozyColors.background,
      textTheme: CozyTypography.textTheme,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: CozyTypography.headlineMd,
      ),
      iconTheme: const IconThemeData(color: CozyColors.onSurface),
      dividerTheme: const DividerThemeData(
        color: CozyColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CozyColors.secondaryFixed.withValues(alpha: 0.5),
        selectedColor: CozyColors.secondaryFixed,
        labelStyle: CozyTypography.labelSm.copyWith(
          color: CozyColors.onSecondaryFixed,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CozyRadius.full),
        ),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CozyColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
          borderSide: const BorderSide(
            color: CozyColors.primaryContainer,
            width: 2,
          ),
        ),
        hintStyle: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CozySpacing.stackGapMd - 8,
          vertical: 16,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: CozyColors.surfaceVariant.withValues(alpha: 0.4),
    );
  }
}
