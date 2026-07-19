import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/entities.dart' as entities;
import '../../services/photo_picker.dart';
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/photo_picker_field.dart';

/// Modal "Capture a Memory" — permite crear un [entities.Moment] tipo
/// foto o nota y lo publica en el timeline vía [AppState.addMoment].
///
/// Sin `image_picker` (por proxy corporativo), se pide una URL de imagen o
/// se puede dejar vacía para crear un momento sin foto (nota de texto).
class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

enum _MomentKindTab { photo, note }

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  static const _tags = ['Trips', 'Dates', 'Firsts', 'Family', 'Pets'];

  _MomentKindTab _kind = _MomentKindTab.photo;
  String? _imagePath; // ruta local absoluta o url http
  final _captionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customTagCtrl = TextEditingController();
  final _customTags = <String>[];
  final _selectedTags = <String>{'Dates'};
  bool _asMilestone = false;
  bool _posting = false;
  DateTime _when = DateTime.now();

  @override
  void dispose() {
    _captionCtrl.dispose();
    _noteCtrl.dispose();
    _customTagCtrl.dispose();
    super.dispose();
  }

  bool get _canPost {
    if (_kind == _MomentKindTab.photo) {
      return _captionCtrl.text.trim().isNotEmpty;
    }
    return _noteCtrl.text.trim().isNotEmpty;
  }

  Future<void> _pickFromGallery() async {
    final path = await PhotoPicker.pickFromGallery();
    if (!mounted) return;
    if (path != null) setState(() => _imagePath = path);
  }

  Future<void> _takePhoto() async {
    final path = await PhotoPicker.takePhoto();
    if (!mounted) return;
    if (path != null) {
      setState(() => _imagePath = path);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cameraUnavailable)));
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _post() async {
    if (_posting) return;
    setState(() => _posting = true);
    final state = AppScope.read(context);
    final l = context.l10n;
    try {
      if (_kind == _MomentKindTab.photo) {
        await state.addMoment(
          entities.Moment.photo(
            date: _when,
            imageUrl: _imagePath ?? '',
            caption: _captionCtrl.text.trim(),
            tags: _selectedTags.toList(),
          ),
        );
        // Si el usuario marcó el toggle "marcar como hito", agrega un
        // Milestone al perfil con la misma fecha y caption.
        if (_asMilestone && _captionCtrl.text.trim().isNotEmpty) {
          state.addMilestone(
            entities.Milestone.create(
              title: _captionCtrl.text.trim(),
              date: l.formatShortDate(_when),
              icon: Icons.favorite,
              iconColor: CozyColors.primary,
              iconBg: CozyColors.primaryContainer,
            ),
          );
        }
      } else {
        await state.addMoment(
          entities.Moment.note(
            date: _when,
            quote: '"${_noteCtrl.text.trim()}"',
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.authGenericError)));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: CozyColors.warmLavenderGradient,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CozySpacing.stackGapMd,
                  CozySpacing.stackGapLg + 24,
                  CozySpacing.stackGapMd,
                  120,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _kind == _MomentKindTab.photo
                              ? context.l10n.createCaptureMemory
                              : context.l10n.createLeaveNote,
                          style: CozyTypography.headlineLgMobile,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kind == _MomentKindTab.photo
                              ? context.l10n.createCaptureSubtitle
                              : context.l10n.createNoteSubtitle,
                          style: CozyTypography.bodyMd.copyWith(
                            color: CozyColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CozySpacing.stackGapLg),
                  _KindTabs(
                    kind: _kind,
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                  const SizedBox(height: CozySpacing.stackGapMd),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      boxShadow: CozyShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_kind == _MomentKindTab.photo) ...[
                          _FieldLabel(context.l10n.createPhoto),
                          const SizedBox(height: 8),
                          PhotoPickerField(
                            imagePath: _imagePath,
                            onGallery: _pickFromGallery,
                            onCamera: _takePhoto,
                            onClear: _imagePath == null
                                ? null
                                : () => setState(() => _imagePath = null),
                          ),
                          const SizedBox(height: CozySpacing.stackGapMd),
                          _FieldLabel(context.l10n.createWhenPhoto),
                          const SizedBox(height: 8),
                          _DateTimeField(text: _formatWhen(), onTap: _pickDate),
                          const SizedBox(height: CozySpacing.stackGapMd),
                          _FieldLabel(context.l10n.createStory),
                          const SizedBox(height: 8),
                          _captionField(),
                          const SizedBox(height: CozySpacing.stackGapMd),
                          _FieldLabel(context.l10n.createTagsLabel),
                          const SizedBox(height: 12),
                          _TagRow(
                            tags: [..._tags, ..._customTags],
                            selected: _selectedTags,
                            onToggle: (t) => setState(() {
                              if (_selectedTags.contains(t)) {
                                _selectedTags.remove(t);
                              } else {
                                _selectedTags.add(t);
                              }
                            }),
                            onCustom: () => _addCustomTag(),
                          ),
                          const SizedBox(height: CozySpacing.stackGapMd),
                          _MilestoneToggle(
                            value: _asMilestone,
                            onChanged: (v) => setState(() => _asMilestone = v),
                          ),
                        ] else ...[
                          _FieldLabel(context.l10n.createYourMessage),
                          const SizedBox(height: 8),
                          _noteField(),
                          const SizedBox(height: CozySpacing.stackGapMd),
                          _FieldLabel(context.l10n.createWhenNote),
                          const SizedBox(height: 8),
                          _DateTimeField(text: _formatWhen(), onTap: _pickDate),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _Header(onClose: () => Navigator.of(context).maybePop()),
            _FooterCta(enabled: _canPost && !_posting, onPost: _post),
          ],
        ),
      ),
    );
  }

  Widget _captionField() => _StyledField(
    controller: _captionCtrl,
    hint: context.l10n.createCaptionHint,
    minLines: 3,
    maxLines: 5,
    onChanged: (_) => setState(() {}),
  );

  Widget _noteField() => _StyledField(
    controller: _noteCtrl,
    hint: context.l10n.createNoteHint,
    minLines: 3,
    maxLines: 6,
    onChanged: (_) => setState(() {}),
  );

  String _formatWhen() {
    String two(int v) => v.toString().padLeft(2, '0');
    final month = two(_when.month);
    final day = two(_when.day);
    final year = _when.year;
    var hour = _when.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12;
    return '$month/$day/$year, $hour:${two(_when.minute)} $period';
  }

  Future<void> _addCustomTag() async {
    _customTagCtrl.clear();
    final l = context.l10n;
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.createCustomTag),
        content: TextField(
          controller: _customTagCtrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l.createCustomTagHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _customTagCtrl.text.trim()),
            child: Text(l.add),
          ),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() {
        _customTags.add(tag);
        _selectedTags.add(tag);
      });
    }
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.kind, required this.onChanged});

  final _MomentKindTab kind;
  final ValueChanged<_MomentKindTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(CozyRadius.full),
      ),
      child: Row(
        children: [
          _KindTab(
            label: context.l10n.createPhoto,
            icon: Icons.image_outlined,
            active: kind == _MomentKindTab.photo,
            onTap: () => onChanged(_MomentKindTab.photo),
          ),
          _KindTab(
            label: context.l10n.createNote,
            icon: Icons.edit_note,
            active: kind == _MomentKindTab.note,
            onTap: () => onChanged(_MomentKindTab.note),
          ),
        ],
      ),
    );
  }
}

class _KindTab extends StatelessWidget {
  const _KindTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? CozyColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(CozyRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CozyRadius.full),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active
                      ? CozyColors.onPrimaryContainer
                      : CozyColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: CozyTypography.labelMd.copyWith(
                    color: active
                        ? CozyColors.onPrimaryContainer
                        : CozyColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topInset,
          left: CozySpacing.stackGapMd,
          right: CozySpacing.stackGapMd,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              color: CozyColors.onSurfaceVariant,
            ),
            Expanded(
              child: Center(
                child: Text(
                  context.l10n.appName,
                  style: CozyTypography.headlineMd.copyWith(
                    color: CozyColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Text(
      text,
      style: CozyTypography.labelMd.copyWith(
        color: CozyColors.onSurfaceVariant,
      ),
    ),
  );
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        onChanged: onChanged,
        style: CozyTypography.bodyMd,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: hint,
          hintStyle: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
          filled: false,
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CozyColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: CozyColors.outline,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: CozyTypography.bodyMd)),
              const Icon(
                Icons.calendar_month_outlined,
                color: CozyColors.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.onCustom,
  });

  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          _TagChip(
            label: tag,
            selected: selected.contains(tag),
            onTap: () => onToggle(tag),
          ),
        _CustomTagChip(onTap: onCustom),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? CozyColors.secondaryFixed
          : CozyColors.secondaryFixed.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(CozyRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CozyRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CozyRadius.full),
            border: Border.all(
              color: selected
                  ? CozyColors.secondaryFixedDim
                  : Colors.transparent,
            ),
          ),
          child: Text(
            context.l10n.translateCategory(label),
            style: CozyTypography.labelSm.copyWith(
              color: CozyColors.onSecondaryFixed,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTagChip extends StatelessWidget {
  const _CustomTagChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CozyColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(CozyRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CozyRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CozyRadius.full),
            border: Border.all(
              color: CozyColors.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: 16,
                color: CozyColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.add,
                style: CozyTypography.labelSm.copyWith(
                  color: CozyColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle "Marcar como hito" — cuando se activa, al publicar se agrega
/// también un [entities.Milestone] al perfil.
class _MilestoneToggle extends StatelessWidget {
  const _MilestoneToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? CozyColors.primaryContainer.withValues(alpha: 0.4)
            : CozyColors.surfaceContainerLowest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(CozyRadius.md),
        border: Border.all(
          color: value
              ? CozyColors.primary.withValues(alpha: 0.6)
              : CozyColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? CozyColors.primary
                  : CozyColors.primaryContainer.withValues(alpha: 0.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star_rounded,
              color: value ? Colors.white : CozyColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.createMarkAsMilestone,
                  style: CozyTypography.labelMd.copyWith(
                    color: CozyColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.createMilestoneHint,
                  style: CozyTypography.labelSm.copyWith(
                    color: CozyColors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CozyColors.primary,
          ),
        ],
      ),
    );
  }
}

class _FooterCta extends StatelessWidget {
  const _FooterCta({required this.enabled, required this.onPost});

  final bool enabled;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: CozySpacing.stackGapMd,
          right: CozySpacing.stackGapMd,
          top: 16,
          bottom: bottomInset > 0 ? bottomInset : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 30,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: GradientButton(
            label: context.l10n.createPost,
            icon: Icons.favorite,
            onPressed: enabled ? onPost : null,
          ),
        ),
      ),
    );
  }
}
