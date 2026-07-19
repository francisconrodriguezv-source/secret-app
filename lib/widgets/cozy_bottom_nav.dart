import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/cozy_colors.dart';
import '../theme/cozy_spacing.dart';

/// Destinos del bottom nav principal.
enum CozyNavDestination { timeline, vault, create, calendar, profile }

/// Bottom navigation "Together bar" flotante estilo pill.
///
/// La barra ya no ocupa el ancho completo: es una cápsula translúcida con
/// margen alrededor, flotando encima del contenido. El item activo se
/// destaca con el chip `primary-container` (peach) y el destino
/// [CozyNavDestination.create] es un círculo peach dentro de la barra
/// (no sobresale para evitar que se recorte).
class CozyBottomNav extends StatelessWidget {
  const CozyBottomNav({
    super.key,
    required this.current,
    required this.onDestinationSelected,
  });

  final CozyNavDestination current;
  final ValueChanged<CozyNavDestination> onDestinationSelected;

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: PhysicalModel(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(CozyRadius.full),
          elevation: 0,
          shadowColor: Colors.transparent,
          child: Container(
            height: _barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CozyRadius.full),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CozyRadius.full),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: CozyColors.surface.withValues(alpha: 0.9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(CozyRadius.full),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sección izquierda: Timeline + Vault.
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Flexible(
                              child: _NavItem(
                                destination: CozyNavDestination.timeline,
                                icon: Icons.auto_awesome_motion_outlined,
                                activeIcon: Icons.auto_awesome_motion,
                                label: l.navTimeline,
                                active: current == CozyNavDestination.timeline,
                                onTap: () => onDestinationSelected(
                                  CozyNavDestination.timeline,
                                ),
                              ),
                            ),
                            Flexible(
                              child: _NavItem(
                                destination: CozyNavDestination.vault,
                                icon: Icons.photo_library_outlined,
                                activeIcon: Icons.photo_library,
                                label: l.navVault,
                                active: current == CozyNavDestination.vault,
                                onTap: () => onDestinationSelected(
                                  CozyNavDestination.vault,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Slot central FIJO para el botón "+".
                      SizedBox(
                        width: 56,
                        child: Center(
                          child: _CreateButton(
                            onTap: () => onDestinationSelected(
                              CozyNavDestination.create,
                            ),
                          ),
                        ),
                      ),
                      // Sección derecha: Calendar + Profile.
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Flexible(
                              child: _NavItem(
                                destination: CozyNavDestination.calendar,
                                icon: Icons.calendar_month_outlined,
                                activeIcon: Icons.calendar_month,
                                label: l.navCalendar,
                                active: current == CozyNavDestination.calendar,
                                onTap: () => onDestinationSelected(
                                  CozyNavDestination.calendar,
                                ),
                              ),
                            ),
                            Flexible(
                              child: _NavItem(
                                destination: CozyNavDestination.profile,
                                icon: Icons.favorite_border,
                                activeIcon: Icons.favorite,
                                label: l.navProfile,
                                active: current == CozyNavDestination.profile,
                                onTap: () => onDestinationSelected(
                                  CozyNavDestination.profile,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final CozyNavDestination destination;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? CozyColors.onPrimaryContainer
        : CozyColors.onSurfaceVariant;
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? CozyColors.primaryContainer : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(active ? activeIcon : icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Círculo peach compacto dentro de la barra pill (no sobresale para
    // evitar clipping). Tamaño levemente más grande que un icono normal
    // para diferenciarlo como CTA principal.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CozyColors.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: CozyColors.primaryContainer.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: CozyColors.onPrimaryContainer,
            size: 24,
          ),
        ),
      ),
    );
  }
}
