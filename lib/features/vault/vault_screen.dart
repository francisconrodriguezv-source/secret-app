import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/entities.dart' as entities;
import '../../services/photo_picker.dart';
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/cozy_image.dart';
import '../../widgets/note_composer_sheet.dart';
import '../../widgets/photo_picker_field.dart';

/// Modos de visualización del Vault.
enum VaultViewMode { photos, notes }

/// Galería "Memory Vault" conectada al state.
///
/// - Toggle Photos / Notes.
/// - Muestra fotos del Vault + fotos publicadas en el Timeline (unificadas
///   vía [AppState.combinedPhotos]).
/// - Search + chips de categoría (modo photos). Categorías dinámicas.
/// - Long-press para eliminar foto/nota.
/// - FAB para agregar foto (picker galería/cámara) o crear una nota.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key, this.onUploadTap});

  final VoidCallback? onUploadTap;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchCtrl = TextEditingController();
  String _activeCategory = 'All';
  VaultViewMode _mode = VaultViewMode.photos;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<entities.Photo> _filteredPhotos(List<entities.Photo> source) {
    var list = source;
    if (_activeCategory != 'All') {
      list = list.where((p) => p.category == _activeCategory).toList();
    }
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((p) {
      return (p.title?.toLowerCase().contains(q) ?? false) ||
          (p.date?.toLowerCase().contains(q) ?? false) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final photos = _filteredPhotos(state.combinedPhotos);
    final notes = state.notes;
    final categories = state.vaultCategories;
    // Si la categoría activa dejó de existir, resetea a 'All'.
    if (!categories.contains(_activeCategory)) {
      _activeCategory = 'All';
    }

    return Stack(
      children: [
        MediaQuery.removePadding(
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
                context.l10n.vaultTitle,
                style: CozyTypography.headlineLgMobile,
              ),
              const SizedBox(height: 12),
              Text(
                _mode == VaultViewMode.photos
                    ? context.l10n.vaultPhotosSubtitle
                    : context.l10n.vaultNotesSubtitle,
                style: CozyTypography.bodyMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _ViewModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 16),
              if (_mode == VaultViewMode.photos) ...[
                _SearchField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: CozySpacing.stackGapMd),
                _CategoryChips(
                  categories: categories,
                  active: _activeCategory,
                  onSelect: (c) => setState(() => _activeCategory = c),
                ),
                const SizedBox(height: CozySpacing.stackGapMd),
                if (photos.isEmpty)
                  _EmptyState(
                    icon: Icons.photo_library_outlined,
                    text: context.l10n.vaultPhotosEmpty,
                  )
                else
                  _MasonryGrid(photos: photos),
              ] else if (notes.isEmpty)
                _EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  text: context.l10n.vaultNotesEmpty,
                )
              else
                _NotesGrid(notes: notes),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 140,
          child: _VaultFab(mode: _mode, onTap: () => _handleFab(context)),
        ),
      ],
    );
  }

  Future<void> _handleFab(BuildContext context) async {
    if (_mode == VaultViewMode.photos) {
      await _addPhotoSheet(context);
    } else {
      await showNoteComposerSheet(context);
    }
  }

  Future<void> _addPhotoSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddPhotoSheet(),
    );
  }
}

/// Bottom sheet para agregar una foto al Vault. Usa [PhotoPickerField]
/// para seleccionar de galería o cámara.
class _AddPhotoSheet extends StatefulWidget {
  const _AddPhotoSheet();

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  final _titleCtrl = TextEditingController();
  String? _imagePath;
  String _category = 'Trips';

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGallery() async {
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

  bool get _canSave => _imagePath != null && _imagePath!.trim().isNotEmpty;

  void _save() {
    final now = DateTime.now();
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
    AppScope.read(context).addPhoto(
      entities.Photo.create(
        url: _imagePath!,
        category: _category,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        date: '${months[now.month - 1]} ${now.year}',
        aspectRatio: 4 / 3,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.vaultAddPhoto,
                    style: CozyTypography.headlineMd,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PhotoPickerField(
                imagePath: _imagePath,
                onGallery: _pickGallery,
                onCamera: _takePhoto,
                onClear: _imagePath == null
                    ? null
                    : () => setState(() => _imagePath = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.vaultTitleOptional,
                  hintText: context.l10n.vaultTitleHint,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: context.l10n.vaultCategory,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Trips',
                    child: Text(context.l10n.categoryTrips),
                  ),
                  DropdownMenuItem(
                    value: 'Dates',
                    child: Text(context.l10n.categoryDates),
                  ),
                  DropdownMenuItem(
                    value: 'Firsts',
                    child: Text(context.l10n.categoryFirsts),
                  ),
                  DropdownMenuItem(
                    value: 'Family',
                    child: Text(context.l10n.categoryFamily),
                  ),
                  DropdownMenuItem(
                    value: 'Pets',
                    child: Text(context.l10n.categoryPets),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Trips'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.vaultAddToVault),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: CozyColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CozyRadius.full),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: context.l10n.vaultSearchHint,
          hintStyle: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(Icons.search, color: CozyColors.outline),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CozyRadius.full),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.active,
    required this.onSelect,
  });

  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isActive = cat == active;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? CozyColors.primaryContainer
                    : CozyColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(CozyRadius.full),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                context.l10n.translateCategory(cat),
                style: CozyTypography.labelMd.copyWith(
                  color: isActive
                      ? CozyColors.onPrimaryContainer
                      : CozyColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final VaultViewMode mode;
  final ValueChanged<VaultViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CozyRadius.full),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: context.l10n.vaultPhotos,
              icon: Icons.photo_library_outlined,
              active: mode == VaultViewMode.photos,
              onTap: () => onChanged(VaultViewMode.photos),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: context.l10n.vaultNotes,
              icon: Icons.sticky_note_2_outlined,
              active: mode == VaultViewMode.notes,
              onTap: () => onChanged(VaultViewMode.notes),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
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
    return Material(
      color: active ? CozyColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(CozyRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CozyRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
    );
  }
}

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({required this.photos});

  final List<entities.Photo> photos;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 900 ? 3 : 2;
    const gutter = 16.0;
    final colWidth =
        (width - (CozySpacing.stackGapMd * 2) - gutter * (columns - 1)) /
        columns;

    final columnHeights = List<double>.filled(columns, 0);
    final columnItems = List<List<Widget>>.generate(columns, (_) => []);

    for (final photo in photos) {
      var minIdx = 0;
      for (var i = 1; i < columns; i++) {
        if (columnHeights[i] < columnHeights[minIdx]) minIdx = i;
      }
      final tileHeight = colWidth / photo.aspectRatio + 4;
      columnHeights[minIdx] += tileHeight + gutter;
      columnItems[minIdx].add(_PhotoTile(photo: photo));
      columnItems[minIdx].add(const SizedBox(height: gutter));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: columnItems[i],
            ),
          ),
          if (i != columns - 1) const SizedBox(width: gutter),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final entities.Photo photo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppScope.read(context).toggleVaultFavorite(photo.id),
      onLongPress: () => _confirmDelete(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CozyRadius.md),
        child: Container(
          decoration: BoxDecoration(
            color: CozyColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(CozyRadius.md),
            boxShadow: CozyShadows.soft,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              AspectRatio(
                aspectRatio: photo.aspectRatio,
                child: CozyImage.network(photo.url),
              ),
              if (photo.badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CozyColors.secondary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(CozyRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          photo.badge!,
                          style: CozyTypography.labelSm.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (photo.favorite)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: CozyColors.primary,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from your vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CozyColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).deleteVaultItem(photo.id);
    }
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes});

  final List<entities.StickyNote> notes;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 900 ? 3 : 2;
    const gutter = 16.0;

    final columnItems = List<List<Widget>>.generate(columns, (_) => []);
    for (var i = 0; i < notes.length; i++) {
      columnItems[i % columns].add(_NoteTile(note: notes[i]));
      columnItems[i % columns].add(const SizedBox(height: gutter));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: columnItems[i],
            ),
          ),
          if (i != columns - 1) const SizedBox(width: gutter),
        ],
      ],
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final entities.StickyNote note;

  @override
  Widget build(BuildContext context) {
    final tilt = note.tilt.clamp(-1.5, 1.5);
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: Transform.rotate(
        angle: tilt * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: note.color,
            borderRadius: BorderRadius.circular(CozyRadius.sm),
            boxShadow: CozyShadows.note,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note.text,
                style: TextStyle(
                  fontFamily: CozyTypography.handwritingFamily,
                  fontSize: 18,
                  height: 24 / 18,
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    note.timestamp,
                    style: CozyTypography.labelSm.copyWith(
                      color: CozyColors.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: note.avatarBg,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      note.author,
                      style: CozyTypography.labelSm.copyWith(
                        color: note.avatarFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This sticky note will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CozyColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).deleteNote(note.id);
    }
  }
}

class _VaultFab extends StatelessWidget {
  const _VaultFab({required this.mode, this.onTap});

  final VaultViewMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isNotes = mode == VaultViewMode.notes;
    return Material(
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CozyColors.primary, CozyColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: CozyColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isNotes ? Icons.edit_note : Icons.add,
            color: Colors.white,
            size: isNotes ? 30 : 28,
          ),
        ),
      ),
    );
  }
}
