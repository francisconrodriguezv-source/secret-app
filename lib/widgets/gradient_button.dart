import 'package:flutter/material.dart';

import '../theme/cozy_colors.dart';
import '../theme/cozy_spacing.dart';
import '../theme/cozy_typography.dart';

/// Botón primario "pill" con gradiente peach → lavender.
///
/// Usado como CTA principal (ej. "Post Moment" en Create).
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: CozyColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(CozyRadius.full),
          boxShadow: [
            BoxShadow(
              color: CozyColors.primaryContainer.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: CozyColors.onPrimary, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: CozyTypography.labelMd.copyWith(
                color: CozyColors.onPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: widget.expanded ? child : IntrinsicWidth(child: child),
    );
  }
}
