import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/entities.dart' as entities;
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/cozy_image.dart';
import '../../widgets/glass_card.dart';

/// Feed principal "Shared Timeline" conectado al [AppState].
///
/// - Hero con datos de la pareja + momentos agrupados por mes.
/// - Cada tarjeta se puede likear (toggle) y eliminar (long-press).
/// - Pull-to-refresh disponible.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final groups = state.groupedByMonth();

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: RefreshIndicator(
        color: CozyColors.primary,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            CozySpacing.stackGapMd,
            topInset + CozySpacing.stackGapMd,
            CozySpacing.stackGapMd,
            160,
          ),
          children: [
            _HeroHeader(couple: state.couple),
            const SizedBox(height: CozySpacing.stackGapLg),
            if (groups.isEmpty)
              _EmptyState(message: context.l10n.timelineEmpty)
            else
              ..._buildGroups(context, groups),
            const SizedBox(height: 32),
            if (groups.isNotEmpty)
              const Center(
                child: Icon(
                  Icons.expand_more,
                  color: CozyColors.outlineVariant,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    List<({String label, List<entities.Moment> moments})> groups,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      widgets.add(_MonthDivider(label: group.label));
      widgets.add(const SizedBox(height: CozySpacing.stackGapMd));
      for (final m in group.moments) {
        widgets.add(
          _MomentCard(moment: m, onDelete: () => _confirmDelete(context, m)),
        );
        widgets.add(const SizedBox(height: CozySpacing.stackGapMd));
      }
      if (i != groups.length - 1) {
        widgets.add(const SizedBox(height: CozySpacing.stackGapMd));
      }
    }
    return widgets;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    entities.Moment moment,
  ) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.timelineDeleteMomentTitle),
        content: Text(
          moment.kind == entities.MomentKind.photo
              ? l.timelineDeletePhotoBody
              : l.timelineDeleteNoteBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CozyColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).deleteMoment(moment.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_motion_outlined,
            size: 48,
            color: CozyColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
          ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.moment, required this.onDelete});

  final entities.Moment moment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
      child: moment.kind == entities.MomentKind.photo
          ? _PhotoCard(moment: moment)
          : _NoteCard(moment: moment),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.couple});

  final entities.Couple couple;

  @override
  Widget build(BuildContext context) {
    final sinceYear = couple.togetherSince.year;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        gradient: CozyColors.heroGradient,
        borderRadius: BorderRadius.circular(CozyRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroAvatar(url: couple.avatarUrlA, initials: couple.initialA),
              Transform.translate(
                offset: const Offset(-20, 0),
                child: _HeroAvatar(
                  url: couple.avatarUrlB,
                  initials: couple.initialB,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            couple.combinedName,
            style: CozyTypography.displayLg.copyWith(
              color: CozyColors.onPrimaryFixed,
              fontSize: 48,
              height: 56 / 48,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${l.timelineWritingSince} $sinceYear',
            style: CozyTypography.bodyLg.copyWith(
              color: CozyColors.onPrimaryFixedVariant.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.url, required this.initials});

  final String url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: CozyImage.network(url, initials: initials)),
    );
  }
}

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: CozyColors.outlineVariant, thickness: 1),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: CozyColors.surfaceContainer,
            borderRadius: BorderRadius.circular(CozyRadius.full),
          ),
          child: Text(
            label,
            style: CozyTypography.labelMd.copyWith(
              color: CozyColors.outline,
              letterSpacing: 2,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: CozyColors.outlineVariant, thickness: 1),
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.moment});

  final entities.Moment moment;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(CozyRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CozyRadius.md),
            child: AspectRatio(
              aspectRatio: moment.aspectRatio,
              child: CozyImage.network(moment.imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.caption,
                  style: CozyTypography.bodyLg.copyWith(
                    color: CozyColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _formatShortDate(moment.date),
                      style: CozyTypography.labelSm.copyWith(
                        color: CozyColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    _LikeButton(moment: moment),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.moment});

  final entities.Moment moment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(CozyRadius.lg),
        border: Border.all(color: CozyColors.surfaceDim.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 40,
            color: CozyColors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            moment.quote,
            style: CozyTypography.bodyLg.copyWith(
              color: CozyColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _formatShortDate(moment.date),
            style: CozyTypography.labelSm.copyWith(color: CozyColors.outline),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.moment});

  final entities.Moment moment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(CozyRadius.full),
      onTap: () => AppScope.read(context).toggleLike(moment.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              moment.likedByMe ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: moment.likedByMe
                  ? CozyColors.primary
                  : CozyColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${moment.likes}',
              style: CozyTypography.labelSm.copyWith(
                color: moment.likedByMe
                    ? CozyColors.primary
                    : CozyColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
