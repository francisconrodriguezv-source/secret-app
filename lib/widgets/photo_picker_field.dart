import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/cozy_colors.dart';
import '../theme/cozy_spacing.dart';
import '../theme/cozy_typography.dart';
import 'cozy_image.dart';

/// Panel reutilizable de selección de imagen:
/// - Sin imagen: 2 botones grandes (Gallery / Camera).
/// - Con imagen: preview con overlay para cambiar / retomar / eliminar.
///
/// Los callbacks [onGallery] y [onCamera] usualmente invocan
/// `PhotoPicker.pickFromGallery()` / `PhotoPicker.takePhoto()`.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.imagePath,
    required this.onGallery,
    required this.onCamera,
    this.onClear,
    this.aspectRatio = 4 / 3,
    this.emptyHeight = 180,
  });

  final String? imagePath;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback? onClear;
  final double aspectRatio;
  final double emptyHeight;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(CozyRadius.lg),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: CozyImage.network(imagePath!),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayButton(
                    icon: Icons.photo_library_outlined,
                    tooltip: l.change,
                    onTap: onGallery,
                  ),
                  const SizedBox(width: 8),
                  _OverlayButton(
                    icon: Icons.camera_alt_outlined,
                    tooltip: l.retake,
                    onTap: onCamera,
                  ),
                  if (onClear != null) ...[
                    const SizedBox(width: 8),
                    _OverlayButton(
                      icon: Icons.delete_outline,
                      tooltip: l.remove,
                      onTap: onClear!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: emptyHeight,
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerLowest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(CozyRadius.lg),
        border: Border.all(color: CozyColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _PickerAction(
              icon: Icons.photo_library_outlined,
              label: l.profilePickGallery,
              onTap: onGallery,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PickerAction(
              icon: Icons.camera_alt_outlined,
              label: l.profilePickCamera,
              onTap: onCamera,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerAction extends StatelessWidget {
  const _PickerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CozyColors.primaryContainer.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(CozyRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CozyRadius.md),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CozyColors.primaryContainer.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(CozyRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: CozyColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
