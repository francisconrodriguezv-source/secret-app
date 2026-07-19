import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/entities.dart' as entities;
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/cozy_top_bar.dart';
import '../../widgets/note_composer_sheet.dart';

/// Tablero de mensajes ("Our Little Notes") conectado al state:
/// - Grid de sticky notes obtenido de [AppState.notes].
/// - FAB abre modal para crear una nueva nota.
/// - Long-press sobre una nota permite eliminarla.
class MessageBoardScreen extends StatelessWidget {
  const MessageBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CozyTopBar(topPadding: MediaQuery.of(context).padding.top),
      body: Container(
        decoration: const BoxDecoration(color: CozyColors.woodBase),
        child: CustomPaint(
          painter: const _NoiseTexturePainter(),
          child: Stack(
            children: [
              const _NotesGrid(),
              _NoteFab(onTap: () => showNoteComposerSheet(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid();

  @override
  Widget build(BuildContext context) {
    final notes = AppScope.of(context).notes;
    final width = MediaQuery.of(context).size.width;
    final topInset = MediaQuery.of(context).padding.top;
    final columns = width > 900 ? 3 : (width > 600 ? 2 : 1);
    const gutter = 24.0;

    final colChildren = List<List<Widget>>.generate(columns, (_) => []);
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      colChildren[i % columns].add(_NoteCard(note: note, index: i));
      colChildren[i % columns].add(const SizedBox(height: gutter));
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          CozySpacing.stackGapMd,
          topInset + CozySpacing.stackGapMd,
          CozySpacing.stackGapMd,
          160,
        ),
        children: [
          Text(
            context.l10n.messageBoardTitle,
            style: CozyTypography.headlineLgMobile.copyWith(
              color: CozyColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.l10n.messageBoardSubtitle,
              style: CozyTypography.bodyMd.copyWith(
                color: CozyColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 48,
                    color: CozyColors.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.messageBoardEmpty,
                    style: CozyTypography.bodyMd.copyWith(
                      color: CozyColors.outline,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: colChildren[i],
                    ),
                  ),
                  if (i != columns - 1) const SizedBox(width: gutter),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.index});

  final entities.StickyNote note;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tiltRad = note.tilt * math.pi / 180;
    final topOffset = index.isEven ? 0.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: GestureDetector(
        onLongPress: () => _confirmDelete(context, note),
        child: Transform.rotate(
          angle: tiltRad,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: note.color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: CozyShadows.note,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            note.text,
                            style: CozyTypography.handwritingLg.copyWith(
                              color: CozyColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            note.timestamp,
                            style: CozyTypography.labelSm.copyWith(
                              color: CozyColors.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: note.avatarBg,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              note.author,
                              style: CozyTypography.labelMd.copyWith(
                                color: note.avatarFg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -8,
                child: Transform.rotate(
                  angle: (index.isEven ? -2 : 3) * math.pi / 180,
                  child: Container(
                    width: 44,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    entities.StickyNote note,
  ) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.messageBoardDeleteTitle),
        content: Text(l.messageBoardDeleteBody),
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
      AppScope.read(context).deleteNote(note.id);
    }
  }
}

class _NoteFab extends StatelessWidget {
  const _NoteFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 32,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CozyColors.primary, CozyColors.secondary],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CozyColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

/// Pinta un ruido/textura sutil sobre el fondo wood-color.
class _NoiseTexturePainter extends CustomPainter {
  const _NoiseTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.03);
    const step = 3.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if (rng.nextDouble() < 0.35) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
