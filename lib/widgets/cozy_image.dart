import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/cozy_colors.dart';
import '../theme/cozy_typography.dart';

/// Wrapper de [Image] con placeholders visibles siempre. Soporta 3 fuentes:
///
/// - HTTP/HTTPS → [Image.network].
/// - Path absoluto local (ej. `/data/user/0/.../cozy_...jpg`) → [Image.file].
/// - URL vacía → placeholder decorado con iniciales o icono.
///
/// Optimización de performance: se pasa `cacheWidth` a [Image] para que
/// las fotos grandes (JPEG de 4K de la cámara) se decodifiquen a la
/// resolución máxima que el layout necesita. Esto evita que el scroll se
/// congele al llegar a una imagen no cacheada aún.
class CozyImage extends StatelessWidget {
  const CozyImage.network(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_outlined,
    this.gradient,
    this.initials,
  });

  final String url;
  final BoxFit fit;
  final IconData icon;
  final Gradient? gradient;

  /// Iniciales para mostrar si la imagen no carga (típicamente un avatar).
  /// Si se define, se ignora [icon].
  final String? initials;

  bool get _isLocalFile => url.isNotEmpty && !url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final placeholderGradient = gradient ?? _defaultGradient;

    Widget placeholder({bool withDecoration = false}) {
      Widget? child;
      if (withDecoration) {
        if (initials != null && initials!.isNotEmpty) {
          child = FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                initials!,
                style: CozyTypography.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        } else {
          child = Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 32,
          );
        }
      }
      return Container(
        decoration: BoxDecoration(gradient: placeholderGradient),
        alignment: Alignment.center,
        child: child,
      );
    }

    if (url.isEmpty) return placeholder(withDecoration: true);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula un `cacheWidth` razonable a partir del ancho disponible
        // y el device pixel ratio, con un techo de 1080 px para no
        // decodificar imágenes gigantes.
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final maxLogicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final targetPx = (maxLogicalWidth * dpr).round().clamp(64, 1080);

        if (_isLocalFile) {
          return Image.file(
            File(url),
            fit: fit,
            gaplessPlayback: true,
            cacheWidth: targetPx,
            filterQuality: FilterQuality.medium,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) return placeholder(withDecoration: true);
              return child;
            },
            errorBuilder: (_, _, _) => placeholder(withDecoration: true),
          );
        }

        return Image.network(
          url,
          fit: fit,
          gaplessPlayback: true,
          cacheWidth: targetPx,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) return placeholder(withDecoration: true);
            return child;
          },
          errorBuilder: (_, _, _) => placeholder(withDecoration: true),
        );
      },
    );
  }

  static const LinearGradient _defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [CozyColors.primary, CozyColors.secondary],
  );
}
