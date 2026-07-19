import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/app_scope.dart';
import '../theme/cozy_colors.dart';
import '../theme/cozy_spacing.dart';
import '../theme/cozy_typography.dart';
import 'cozy_image.dart';

/// Barra superior fija con avatar de la pareja, wordmark "Cozy Love" y
/// botón de corazón a la derecha. Reproduce el TopAppBar de todas las
/// pantallas del design de Stitch (fondo `surface/80` + `backdrop-blur-xl`).
///
/// La altura declarada en [preferredSize] incluye el `topPadding` recibido
/// como parámetro para que el [Scaffold] reserve espacio suficiente cuando
/// se usa como `appBar` con `extendBodyBehindAppBar: true`. `topPadding`
/// debe ser `MediaQuery.of(context).padding.top` calculado en el `Scaffold`
/// contenedor (se pasa manualmente porque `preferredSize` es un getter sin
/// acceso a [BuildContext]).
class CozyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CozyTopBar({
    super.key,
    this.avatarUrl,
    this.onHeartTap,
    this.leading,
    this.showHeart = true,
    this.title,
    this.topPadding = 0,
  });

  /// Altura del contenido sin contar el status bar.
  static const double kContentHeight = 64;

  final String? avatarUrl;
  final VoidCallback? onHeartTap;
  final Widget? leading;
  final bool showHeart;
  final String? title;
  final double topPadding;

  @override
  Size get preferredSize => Size.fromHeight(kContentHeight + topPadding);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            color: CozyColors.surface.withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(color: CozyColors.outlineVariant, width: 0.5),
            ),
          ),
          child: SizedBox(
            height: kContentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CozySpacing.stackGapMd,
              ),
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else
                    _CoupleAvatar(url: avatarUrl),
                  const SizedBox(width: 12),
                  Text(
                    title ?? context.l10n.appName,
                    style: CozyTypography.headlineMd.copyWith(
                      color: CozyColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (showHeart)
                    IconButton(
                      onPressed: onHeartTap,
                      icon: const Icon(
                        Icons.favorite,
                        color: CozyColors.primary,
                        size: 26,
                      ),
                      splashRadius: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoupleAvatar extends StatelessWidget {
  const _CoupleAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    // Prefiere la URL explícita; si no viene, usa la foto compartida de la
    // pareja (foto de ambos juntos). Si tampoco existe, usa la de A.
    // Fallback final: inicial del nombre sobre peach.
    final couple = AppScope.of(context).couple;
    final effective = (url != null && url!.isNotEmpty)
        ? url
        : (couple.avatarUrlShared.isNotEmpty
              ? couple.avatarUrlShared
              : (couple.avatarUrlA.isNotEmpty ? couple.avatarUrlA : null));
    final initials = couple.initialA;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: CozyColors.primaryContainer, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: effective != null
            ? CozyImage.network(effective, initials: initials)
            : Container(
                color: CozyColors.primaryContainer,
                alignment: Alignment.center,
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: CozyTypography.labelMd.copyWith(
                          color: CozyColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Icon(
                        Icons.favorite,
                        size: 20,
                        color: CozyColors.primary,
                      ),
              ),
      ),
    );
  }
}
