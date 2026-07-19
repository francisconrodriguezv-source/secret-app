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
import '../../widgets/glass_card.dart';

/// Pantalla "Me & You" conectada al [AppState].
///
/// - Hero con datos de la pareja (editable).
/// - Milestones dinámicos (agregar/borrar).
/// - Settings con switches funcionales + acceso a Message Board.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onMessageBoard});

  final VoidCallback? onMessageBoard;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;

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
          _CoupleHero(
            couple: state.couple,
            onEdit: () => _openEditCouple(context, state.couple),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          _MilestonesSection(
            milestones: state.milestones,
            onAdd: () => _openAddMilestone(context),
            onDelete: (id) => state.deleteMilestone(id),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          _SettingsSection(
            settings: state.settings,
            onToggleNotifications: state.toggleNotifications,
            onTogglePrivacy: state.togglePrivacy,
            onMessageBoard: onMessageBoard,
          ),
        ],
      ),
    );
  }

  Future<void> _openEditCouple(
    BuildContext context,
    entities.Couple couple,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCoupleSheet(couple: couple),
    );
  }

  Future<void> _openAddMilestone(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMilestoneSheet(),
    );
  }
}

class _CoupleHero extends StatelessWidget {
  const _CoupleHero({required this.couple, required this.onEdit});

  final entities.Couple couple;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 112,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: const Offset(-32, 0),
                  child: Transform.rotate(
                    angle: -5 * math.pi / 180,
                    child: _CircleAvatar(
                      url: couple.avatarUrlA,
                      initials: couple.initialA,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(32, 0),
                  child: Transform.rotate(
                    angle: 5 * math.pi / 180,
                    child: _CircleAvatar(
                      url: couple.avatarUrlB,
                      initials: couple.initialB,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CozySpacing.stackGapMd),
        Text(couple.combinedName, style: CozyTypography.headlineLgMobile),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: CozyColors.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(CozyRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                color: CozyColors.onSecondaryContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${context.l10n.profileTogetherFor} ${context.l10n.durationLabel(years: couple.durationParts.years, months: couple.durationParts.months)}',
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(context.l10n.profileEditProfile),
          style: OutlinedButton.styleFrom(
            foregroundColor: CozyColors.primary,
            side: const BorderSide(color: CozyColors.primaryContainer),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _CircleAvatar extends StatelessWidget {
  const _CircleAvatar({required this.url, required this.initials});

  final String url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: CozyColors.surface, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: CozyImage.network(url, initials: initials)),
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({
    required this.milestones,
    required this.onAdd,
    required this.onDelete,
  });

  final List<entities.Milestone> milestones;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.profileMilestones,
                style: CozyTypography.headlineMd,
              ),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle),
              color: CozyColors.primary,
              tooltip: l.profileAddMilestone,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (milestones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l.profileEmptyMilestones,
              style: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final m in milestones)
            Padding(
              padding: const EdgeInsets.only(bottom: CozySpacing.stackGapSm),
              child: _MilestoneCard(
                milestone: m,
                onDelete: () => onDelete(m.id),
              ),
            ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone, required this.onDelete});

  final entities.Milestone milestone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(CozyRadius.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: milestone.iconBg.withValues(alpha: 0.5),
              ),
              alignment: Alignment.center,
              child: Icon(milestone.icon, color: milestone.iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(milestone.title, style: CozyTypography.labelMd),
                  const SizedBox(height: 2),
                  Text(
                    milestone.place != null
                        ? '${milestone.date} • ${milestone.place}'
                        : milestone.date,
                    style: CozyTypography.labelSm.copyWith(
                      color: CozyColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline),
              color: CozyColors.outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profileDeleteMilestoneTitle),
        content: Text(milestone.title),
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
    if (ok == true) onDelete();
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.settings,
    required this.onToggleNotifications,
    required this.onTogglePrivacy,
    required this.onMessageBoard,
  });

  final entities.AppSettings settings;
  final VoidCallback onToggleNotifications;
  final VoidCallback onTogglePrivacy;
  final VoidCallback? onMessageBoard;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.profileSettings, style: CozyTypography.headlineMd),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(CozyRadius.md),
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.chat_bubble_outline,
                label: l.profileMessageBoard,
                onTap: onMessageBoard,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: CozyColors.outline,
                ),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.notifications_outlined,
                label: l.profileNotifications,
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (_) => onToggleNotifications(),
                  activeThumbColor: CozyColors.primary,
                ),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.lock_outline,
                label: l.profilePrivacy,
                trailing: Switch(
                  value: settings.privacyEnabled,
                  onChanged: (_) => onTogglePrivacy(),
                  activeThumbColor: CozyColors.primary,
                ),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.language_outlined,
                label: l.profileLanguage,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppScope.of(context).locale.flag}  ${AppScope.of(context).locale.label}',
                      style: CozyTypography.bodyMd.copyWith(
                        color: CozyColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: CozyColors.outline),
                  ],
                ),
                onTap: () => _openLanguagePicker(context),
              ),
              const _RowDivider(),
              _SettingsRow(
                icon: Icons.palette_outlined,
                label: l.profileTheme,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: CozyColors.outline,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.profileThemePlaceholder)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openLanguagePicker(BuildContext context) async {
    final state = AppScope.read(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CozyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CozyColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ctx.l10n.profileLanguage,
                  style: CozyTypography.headlineMd,
                ),
                const SizedBox(height: 12),
                for (final loc in AppLocale.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await state.setLocale(loc);
                      },
                      borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: state.locale == loc
                              ? CozyColors.primaryContainer.withValues(
                                  alpha: 0.6,
                                )
                              : CozyColors.surface,
                          borderRadius: BorderRadius.circular(
                            CozyRadius.mdLarge,
                          ),
                          border: Border.all(
                            color: state.locale == loc
                                ? CozyColors.primary
                                : CozyColors.outlineVariant,
                            width: state.locale == loc ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              loc.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                loc.label,
                                style: CozyTypography.bodyLg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (state.locale == loc)
                              const Icon(
                                Icons.check_circle,
                                color: CozyColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: CozyColors.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: CozyTypography.bodyMd)),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 1,
        color: CozyColors.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Edit Couple sheet
// -----------------------------------------------------------------------------

class _EditCoupleSheet extends StatefulWidget {
  const _EditCoupleSheet({required this.couple});
  final entities.Couple couple;

  @override
  State<_EditCoupleSheet> createState() => _EditCoupleSheetState();
}

class _EditCoupleSheetState extends State<_EditCoupleSheet> {
  late final TextEditingController _nameA;
  late final TextEditingController _nameB;
  late String _avatarA;
  late String _avatarB;
  late DateTime _since;
  String _avatarShared = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameA = TextEditingController(text: widget.couple.nameA);
    _nameB = TextEditingController(text: widget.couple.nameB);
    _avatarA = widget.couple.avatarUrlA;
    _avatarB = widget.couple.avatarUrlB;
    _avatarShared = widget.couple.avatarUrlShared;
    _since = widget.couple.togetherSince;
  }

  @override
  void dispose() {
    _nameA.dispose();
    _nameB.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(bool isA, {required bool fromCamera}) async {
    final path = fromCamera
        ? await PhotoPicker.takePhoto()
        : await PhotoPicker.pickFromGallery();
    if (!mounted) return;
    if (path == null) {
      if (fromCamera) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.cameraUnavailable)));
      }
      return;
    }
    setState(() {
      if (isA) {
        _avatarA = path;
      } else {
        _avatarB = path;
      }
    });
  }

  Future<void> _pickShared({required bool fromCamera}) async {
    final path = fromCamera
        ? await PhotoPicker.takePhoto()
        : await PhotoPicker.pickFromGallery();
    if (!mounted) return;
    if (path == null) {
      if (fromCamera) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.cameraUnavailable)));
      }
      return;
    }
    setState(() => _avatarShared = path);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _since,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _since = d);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = context.l10n;
    try {
      await AppScope.read(context).updateCouple(
        nameA: _nameA.text.trim(),
        nameB: _nameB.text.trim(),
        avatarUrlA: _avatarA.trim(),
        avatarUrlB: _avatarB.trim(),
        avatarUrlShared: _avatarShared.trim(),
        togetherSince: _since,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.authGenericError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                    context.l10n.profileEditProfile,
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameA,
                      decoration: InputDecoration(
                        labelText: context.l10n.profileNameA,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameB,
                      decoration: InputDecoration(
                        labelText: context.l10n.profileNameB,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Foto de la pareja juntos (aparece en el top bar).
              _SharedPhotoCard(
                imageUrl: _avatarShared,
                onGallery: () => _pickShared(fromCamera: false),
                onCamera: () => _pickShared(fromCamera: true),
                onClear: _avatarShared.isEmpty
                    ? null
                    : () => setState(() => _avatarShared = ''),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.obAvatarA
                        .replaceAll(context.l10n.obYourName, '')
                        .isEmpty
                    ? context.l10n.obAvatarA
                    : '${context.l10n.obAvatarA} / ${context.l10n.obAvatarB}',
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AvatarPickerTile(
                      label: _nameA.text.isEmpty
                          ? context.l10n.obYourName
                          : _nameA.text,
                      imageUrl: _avatarA,
                      initials: _nameA.text.trim().isNotEmpty
                          ? _nameA.text.trim()[0].toUpperCase()
                          : '?',
                      onGallery: () => _pickAvatar(true, fromCamera: false),
                      onCamera: () => _pickAvatar(true, fromCamera: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AvatarPickerTile(
                      label: _nameB.text.isEmpty
                          ? context.l10n.obPartnerName
                          : _nameB.text,
                      imageUrl: _avatarB,
                      initials: _nameB.text.trim().isNotEmpty
                          ? _nameB.text.trim()[0].toUpperCase()
                          : '?',
                      onGallery: () => _pickAvatar(false, fromCamera: false),
                      onCamera: () => _pickAvatar(false, fromCamera: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: CozyColors.primary,
                ),
                title: Text(context.l10n.profileAnniversary),
                subtitle: Text(context.l10n.formatShortDate(_since)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(context.l10n.change),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              CozyColors.onPrimaryContainer,
                            ),
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(context.l10n.profileSaveProfile),
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

// -----------------------------------------------------------------------------
// Add Milestone sheet
// -----------------------------------------------------------------------------

class _AddMilestoneSheet extends StatefulWidget {
  const _AddMilestoneSheet();

  @override
  State<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends State<_AddMilestoneSheet> {
  static const List<({String label, IconData icon, Color color, Color bg})>
  _presets = [
    (
      label: 'Heart',
      icon: Icons.favorite,
      color: CozyColors.primary,
      bg: CozyColors.primaryContainer,
    ),
    (
      label: 'Date',
      icon: Icons.restaurant,
      color: CozyColors.primary,
      bg: CozyColors.primaryContainer,
    ),
    (
      label: 'Home',
      icon: Icons.home_outlined,
      color: CozyColors.tertiary,
      bg: CozyColors.tertiaryContainer,
    ),
    (
      label: 'Travel',
      icon: Icons.flight,
      color: CozyColors.secondary,
      bg: CozyColors.secondaryContainer,
    ),
    (
      label: 'Pet',
      icon: Icons.pets,
      color: CozyColors.secondary,
      bg: CozyColors.secondaryContainer,
    ),
  ];

  final _titleCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  int _presetIdx = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (d != null) setState(() => _date = d);
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  void _save() {
    final p = _presets[_presetIdx];
    AppScope.read(context).addMilestone(
      entities.Milestone.create(
        title: _titleCtrl.text.trim(),
        date: _formatDate(_date),
        icon: p.icon,
        iconColor: p.color,
        iconBg: p.bg,
        place: _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim(),
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
                    context.l10n.profileAddMilestone,
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
              TextField(
                controller: _titleCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.l10n.profileMilestoneTitle,
                  hintText: context.l10n.profileMilestoneTitleHint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _placeCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.profileMilestonePlace,
                  hintText: context.l10n.profileMilestonePlaceHint,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Icon',
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final p = _presets[i];
                    final active = i == _presetIdx;
                    return GestureDetector(
                      onTap: () => setState(() => _presetIdx = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? CozyColors.primaryContainer
                              : CozyColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(CozyRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.icon,
                              size: 18,
                              color: active
                                  ? CozyColors.onPrimaryContainer
                                  : p.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.label,
                              style: CozyTypography.labelMd.copyWith(
                                color: active
                                    ? CozyColors.onPrimaryContainer
                                    : CozyColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: CozyColors.primary,
                ),
                title: Text(context.l10n.calendarChoose),
                subtitle: Text(context.l10n.formatShortDate(_date)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(context.l10n.change),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: const Icon(Icons.check),
                  label: Text(context.l10n.save),
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

String _formatDate(DateTime d) {
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

/// Card horizontal para elegir/cambiar la foto de la pareja juntos. Se
/// muestra en el top bar como avatar de la pareja.
class _SharedPhotoCard extends StatelessWidget {
  const _SharedPhotoCard({
    required this.imageUrl,
    required this.onGallery,
    required this.onCamera,
    this.onClear,
  });

  final String imageUrl;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasImage = imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CozyColors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(CozyRadius.md),
        border: Border.all(
          color: CozyColors.primaryContainer.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CozyColors.primaryContainer, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: hasImage
                  ? CozyImage.network(imageUrl, icon: Icons.favorite)
                  : Container(
                      color: CozyColors.primaryContainer.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: CozyColors.primary,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.obAvatarShared,
                  style: CozyTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.obAvatarSharedHint,
                  style: CozyTypography.labelSm.copyWith(
                    color: CozyColors.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      tooltip: l.profilePickGallery,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: onCamera,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      tooltip: l.profilePickCamera,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (onClear != null) ...[
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: l.remove,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(34, 34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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

/// Tile de selección de avatar dentro del sheet "Edit profile": preview
/// circular + label + botones galería/cámara.
class _AvatarPickerTile extends StatelessWidget {
  const _AvatarPickerTile({
    required this.label,
    required this.imageUrl,
    required this.initials,
    required this.onGallery,
    required this.onCamera,
  });

  final String label;
  final String imageUrl;
  final String initials;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CozyColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(CozyRadius.md),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CozyColors.primaryContainer, width: 2),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: CozyImage.network(imageUrl, initials: initials),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CozyTypography.labelSm.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: IconButton.filledTonal(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  tooltip: context.l10n.profilePickGallery,
                  style: IconButton.styleFrom(
                    backgroundColor: CozyColors.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    foregroundColor: CozyColors.primary,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: IconButton.filledTonal(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  tooltip: context.l10n.profilePickCamera,
                  style: IconButton.styleFrom(
                    backgroundColor: CozyColors.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    foregroundColor: CozyColors.primary,
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
