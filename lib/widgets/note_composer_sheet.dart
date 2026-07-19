import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/entities.dart' as entities;
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/cozy_colors.dart';
import '../theme/cozy_spacing.dart';
import '../theme/cozy_typography.dart';

/// Muestra un [showModalBottomSheet] para crear una nueva sticky note.
///
/// Al guardar, agrega la nota al [AppState] vía `addNote`. El sheet se
/// utiliza tanto desde el Message Board (FAB de la pantalla dedicada) como
/// desde el modo Notes del Vault.
Future<void> showNoteComposerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NoteComposerSheet(),
  );
}

class _NoteComposerSheet extends StatefulWidget {
  const _NoteComposerSheet();

  @override
  State<_NoteComposerSheet> createState() => _NoteComposerSheetState();
}

class _NoteComposerSheetState extends State<_NoteComposerSheet> {
  final _textCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  Color _color = AppState.notePalette.first;

  @override
  void dispose() {
    _textCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _textCtrl.text.trim().isNotEmpty;

  void _post() {
    final couple = AppScope.read(context).couple;
    final l = context.l10n;
    final author = _authorCtrl.text.trim().isNotEmpty
        ? _authorCtrl.text.trim().substring(0, 1).toUpperCase()
        : (couple.initialA.isNotEmpty ? couple.initialA : '?');
    final tilt = (math.Random().nextDouble() * 6) - 3; // ±3°
    AppScope.read(context).addNote(
      entities.StickyNote.create(
        text: _textCtrl.text.trim(),
        color: _color,
        timestamp: l.today,
        author: author,
        avatarBg: CozyColors.secondaryContainer,
        avatarFg: CozyColors.onSecondaryContainer,
        tilt: tilt,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: CozyColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CozyRadius.mdLarge),
          ),
        ),
        padding: EdgeInsets.only(
          left: CozySpacing.stackGapMd,
          right: CozySpacing.stackGapMd,
          top: CozySpacing.stackGapMd,
          bottom:
              CozySpacing.stackGapMd + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.noteComposerTitle,
                  style: CozyTypography.headlineMd,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(CozyRadius.sm),
                boxShadow: CozyShadows.note,
              ),
              child: TextField(
                controller: _textCtrl,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontFamily: CozyTypography.handwritingFamily,
                  fontSize: 22,
                  height: 1.4,
                  color: CozyColors.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: context.l10n.noteComposerHint,
                  hintStyle: TextStyle(
                    fontFamily: CozyTypography.handwritingFamily,
                    fontSize: 22,
                    color: CozyColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: CozySpacing.stackGapMd),
            Text(
              context.l10n.noteColor,
              style: CozyTypography.labelMd.copyWith(
                color: CozyColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final c in AppState.notePalette) ...[
                  _ColorSwatch(
                    color: c,
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: CozySpacing.stackGapMd),
            Text(
              context.l10n.noteComposerAuthor,
              style: CozyTypography.labelMd.copyWith(
                color: CozyColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorCtrl,
              maxLength: 2,
              decoration: InputDecoration(
                hintText: context.l10n.obYourName.substring(0, 1),
                counterText: '',
              ),
            ),
            const SizedBox(height: CozySpacing.stackGapMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canPost ? _post : null,
                icon: const Icon(Icons.push_pin),
                label: Text(context.l10n.noteComposerPin),
                style: FilledButton.styleFrom(
                  backgroundColor: CozyColors.primaryContainer,
                  foregroundColor: CozyColors.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? CozyColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
