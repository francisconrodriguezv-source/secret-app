import 'package:flutter/material.dart';

import 'cozy_colors.dart';

/// Constantes de espaciado del design system Cozy Love.
class CozySpacing {
  const CozySpacing._();

  static const double unit = 8;
  static const double stackGapSm = 12;
  static const double stackGapMd = 24;
  static const double stackGapLg = 48;
  static const double containerPaddingMobile = 24;
  static const double containerPaddingDesktop = 64;
}

/// Radios de border. Definidos en `rem` en Stitch, convertidos a px asumiendo
/// 16px = 1rem.
class CozyRadius {
  const CozyRadius._();

  static const double sm = 8; // 0.5rem
  static const double md = 16; // 1rem — default
  static const double mdLarge = 24; // 1.5rem
  static const double lg = 32; // 2rem
  static const double xl = 48; // 3rem
  static const double full = 9999;
}

/// Sombras suaves y difusas usadas por los cards flotantes ("glass").
class CozyShadows {
  const CozyShadows._();

  /// Sombra suave del design system (Blur 30, Y 10, Opacity 4%).
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A000000), // 4% negro
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  /// Sombra sutil para stickers/post-its.
  static const List<BoxShadow> note = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(2, 4)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Sombra del FAB primario.
  static List<BoxShadow> fab = const [
    BoxShadow(
      color: Color(0x4DFF9E8C), // primaryContainer @ 30%
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Sombra hacia arriba del bottom nav.
  static const List<BoxShadow> bottomNav = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, -4)),
  ];
}

/// Breakpoints responsive.
class CozyBreakpoints {
  const CozyBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// Helper para pintar el fondo con textura sutil de "papel"/"wood".
///
/// Reproduce el `wood-texture` del Message Board con un color base cálido más
/// una capa translúcida con ruido dibujado por `CustomPaint`.
class CozyBackgrounds {
  const CozyBackgrounds._();

  static const BoxDecoration wood = BoxDecoration(color: CozyColors.woodBase);
  static const BoxDecoration warmLavender = BoxDecoration(
    gradient: CozyColors.warmLavenderGradient,
  );
  static const BoxDecoration calendar = BoxDecoration(
    gradient: CozyColors.calendarBackgroundGradient,
  );
}
