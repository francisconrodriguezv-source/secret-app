import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/cozy_spacing.dart';

/// Card "glass" con fondo blanco translúcido, borde sutil y sombra difusa.
///
/// Reproduce la clase `glass-card` del HTML (blur 12px, white 80% opacity,
/// borde 1px white 50%, sombra 0 10 30 rgba(0,0,0,0.04)).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.opacity = 0.8,
    this.blurSigma = 12,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blurSigma;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(CozyRadius.md);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: CozyShadows.soft,
          ),
          child: child,
        ),
      ),
    );
  }
}
