import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/photo_picker.dart';
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/cozy_image.dart';
import '../../widgets/gradient_button.dart';

/// Onboarding en 5 pasos:
///   0. Bienvenida.
///   1. Nombres y fotos de la pareja.
///   2. Fecha de aniversario.
///   3. Fechas importantes (opcional, se pueden agregar N).
///   4. Confirmación / entrada a la app.
///
/// El idioma se auto-detecta desde el sistema (ver `AppState.bootstrap`)
/// y se puede cambiar después en Perfil → Ajustes → Idioma.
///
/// Al terminar, llama a `AppState.completeOnboarding(...)` con los datos
/// recolectados. El scope superior (`_AppShell`) detecta el flag
/// `settings.onboardingComplete` y reemplaza esta pantalla por `HomeShell`.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _stepCount = 5;

  final PageController _pageCtl = PageController();
  int _index = 0;

  // Form state.
  final _nameACtl = TextEditingController();
  final _nameBCtl = TextEditingController();
  String? _avatarA;
  String? _avatarB;
  String? _avatarShared;
  DateTime _anniversary = DateTime(
    DateTime.now().year - 1,
    DateTime.now().month,
    DateTime.now().day,
  );
  final List<({String title, DateTime date})> _events = [];

  @override
  void initState() {
    super.initState();
    // Idioma inicial toma el actualmente elegido en el AppState (por si el
    // usuario navega hacia atrás y vuelve a onboarding en dev).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.read(context);
      _nameACtl.text = state.couple.nameA;
      _nameBCtl.text = state.couple.nameB;
      _avatarA = state.couple.avatarUrlA;
      _avatarB = state.couple.avatarUrlB;
      _avatarShared = state.couple.avatarUrlShared;
      _anniversary = state.couple.togetherSince;
    });
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _nameACtl.dispose();
    _nameBCtl.dispose();
    super.dispose();
  }

  void _goto(int index) {
    setState(() => _index = index);
    _pageCtl.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  bool get _canAdvance {
    switch (_index) {
      case 1: // Names (antes era 2).
        return _nameACtl.text.trim().isNotEmpty &&
            _nameBCtl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    final state = AppScope.read(context);
    await state.completeOnboarding(
      nameA: _nameACtl.text.trim(),
      nameB: _nameBCtl.text.trim(),
      avatarUrlA: _avatarA,
      avatarUrlB: _avatarB,
      avatarUrlShared: _avatarShared,
      anniversary: _anniversary,
      importantDates: _events,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _ProgressBar(step: _index, total: _stepCount),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageCtl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onStart: () => _goto(1)),
                  _CoupleStep(
                    nameACtl: _nameACtl,
                    nameBCtl: _nameBCtl,
                    avatarA: _avatarA,
                    avatarB: _avatarB,
                    avatarShared: _avatarShared,
                    onAvatarAChanged: (v) => setState(() => _avatarA = v),
                    onAvatarBChanged: (v) => setState(() => _avatarB = v),
                    onAvatarSharedChanged: (v) =>
                        setState(() => _avatarShared = v),
                    onFieldChange: () => setState(() {}),
                  ),
                  _DateStep(
                    date: _anniversary,
                    onPickDate: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _anniversary,
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now(),
                        helpText: l.obPickDate,
                      );
                      if (d != null) setState(() => _anniversary = d);
                    },
                  ),
                  _EventsStep(
                    events: _events,
                    onAdd: (item) => setState(() => _events.add(item)),
                    onRemove: (idx) => setState(() => _events.removeAt(idx)),
                  ),
                  _DoneStep(onFinish: _finish),
                ],
              ),
            ),
            _Nav(
              step: _index,
              total: _stepCount,
              canAdvance: _canAdvance,
              onBack: _index == 0 ? null : () => _goto(_index - 1),
              onNext: _index == _stepCount - 1 ? null : () => _goto(_index + 1),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Reusable helpers
// -----------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CozySpacing.stackGapMd),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= step;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? CozyColors.primary
                      : CozyColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.step,
    required this.total,
    required this.canAdvance,
    this.onBack,
    this.onNext,
  });

  final int step;
  final int total;
  final bool canAdvance;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // El paso "Done" (último) tiene su propio botón dentro del contenido.
    if (step == total - 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CozySpacing.stackGapMd,
        vertical: 4,
      ),
      child: Row(
        children: [
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: CozyColors.onSurfaceVariant,
              ),
              child: Text(l.back),
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          Expanded(
            flex: 2,
            child: GradientButton(
              label: step == 0 ? l.obStartButton : l.next,
              onPressed: canAdvance ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 0 — Welcome
// -----------------------------------------------------------------------------

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(CozySpacing.stackGapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CozyColors.primaryContainer,
                    CozyColors.secondaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                size: 68,
                color: CozyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          Text(
            l.obWelcomeTitle,
            textAlign: TextAlign.center,
            style: CozyTypography.headlineLgMobile.copyWith(
              color: CozyColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.obWelcomeBody,
            textAlign: TextAlign.center,
            style: CozyTypography.bodyLg.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Step 1 — Couple names + avatars
// -----------------------------------------------------------------------------

class _CoupleStep extends StatelessWidget {
  const _CoupleStep({
    required this.nameACtl,
    required this.nameBCtl,
    required this.avatarA,
    required this.avatarB,
    required this.avatarShared,
    required this.onAvatarAChanged,
    required this.onAvatarBChanged,
    required this.onAvatarSharedChanged,
    required this.onFieldChange,
  });

  final TextEditingController nameACtl;
  final TextEditingController nameBCtl;
  final String? avatarA;
  final String? avatarB;
  final String? avatarShared;
  final ValueChanged<String?> onAvatarAChanged;
  final ValueChanged<String?> onAvatarBChanged;
  final ValueChanged<String?> onAvatarSharedChanged;
  final VoidCallback onFieldChange;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CozySpacing.stackGapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(l.obCoupleTitle, style: CozyTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text(
            l.obCoupleBody,
            style: CozyTypography.bodyMd.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapMd),
          // Foto de los dos juntos (opcional pero recomendado).
          _SharedAvatarPicker(
            imageUrl: avatarShared,
            onChanged: onAvatarSharedChanged,
          ),
          const SizedBox(height: CozySpacing.stackGapMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AvatarPickerBig(
                  imageUrl: avatarA,
                  label: l.obAvatarA,
                  onChanged: onAvatarAChanged,
                  initials: nameACtl.text.trim().isEmpty
                      ? '?'
                      : nameACtl.text.trim()[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AvatarPickerBig(
                  imageUrl: avatarB,
                  label: l.obAvatarB,
                  onChanged: onAvatarBChanged,
                  initials: nameBCtl.text.trim().isEmpty
                      ? '?'
                      : nameBCtl.text.trim()[0].toUpperCase(),
                ),
              ),
            ],
          ),
          const SizedBox(height: CozySpacing.stackGapMd),
          TextField(
            controller: nameACtl,
            onChanged: (_) => onFieldChange(),
            decoration: InputDecoration(
              labelText: l.obYourName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameBCtl,
            onChanged: (_) => onFieldChange(),
            decoration: InputDecoration(
              labelText: l.obPartnerName,
              prefixIcon: const Icon(Icons.favorite_outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picker único para la foto compartida (la pareja en una foto).
/// Se muestra como un card horizontal con avatar + label + botones.
class _SharedAvatarPicker extends StatelessWidget {
  const _SharedAvatarPicker({required this.imageUrl, required this.onChanged});

  final String? imageUrl;
  final ValueChanged<String?> onChanged;

  Future<void> _fromGallery() async {
    final path = await PhotoPicker.pickFromGallery();
    if (path != null) onChanged(path);
  }

  Future<void> _fromCamera() async {
    final path = await PhotoPicker.takePhoto();
    if (path != null) onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CozyColors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
        border: Border.all(
          color: CozyColors.primaryContainer.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CozyColors.primaryContainer, width: 3),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: hasImage
                  ? CozyImage.network(imageUrl!, icon: Icons.favorite)
                  : Container(
                      color: CozyColors.primaryContainer.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: CozyColors.primary,
                        size: 30,
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
                    color: CozyColors.onSurface,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _fromGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      tooltip: l.profilePickGallery,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: _fromCamera,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      tooltip: l.profilePickCamera,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        onPressed: () => onChanged(''),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: l.remove,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
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

class _AvatarPickerBig extends StatelessWidget {
  const _AvatarPickerBig({
    required this.imageUrl,
    required this.label,
    required this.onChanged,
    required this.initials,
  });

  final String? imageUrl;
  final String label;
  final ValueChanged<String?> onChanged;
  final String initials;

  Future<void> _fromGallery() async {
    final path = await PhotoPicker.pickFromGallery();
    if (path != null) onChanged(path);
  }

  Future<void> _fromCamera() async {
    final path = await PhotoPicker.takePhoto();
    if (path != null) onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CozyColors.primaryContainer, width: 3),
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? CozyImage.network(imageUrl!, initials: initials)
                : Container(
                    color: CozyColors.primaryContainer,
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: CozyTypography.headlineLg.copyWith(
                        color: CozyColors.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: CozyTypography.labelMd.copyWith(
            color: CozyColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _fromGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              tooltip: l.profilePickGallery,
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              onPressed: _fromCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              tooltip: l.profilePickCamera,
              style: IconButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step 3 — Anniversary date
// -----------------------------------------------------------------------------

class _DateStep extends StatelessWidget {
  const _DateStep({required this.date, required this.onPickDate});

  final DateTime date;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(CozySpacing.stackGapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(l.obDateTitle, style: CozyTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text(
            l.obDateBody,
            style: CozyTypography.bodyMd.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          Center(
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(CozyRadius.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CozyColors.primaryContainer,
                      CozyColors.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(CozyRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _monthOf(context, date),
                      style: CozyTypography.labelMd.copyWith(
                        color: CozyColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date.day.toString(),
                      style: CozyTypography.displayLg.copyWith(
                        color: CozyColors.primary,
                        fontSize: 88,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date.year.toString(),
                      style: CozyTypography.headlineMd.copyWith(
                        color: CozyColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l.obPickDate),
            ),
          ),
        ],
      ),
    );
  }

  static const _monthsEn = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  static const _monthsEs = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  String _monthOf(BuildContext context, DateTime d) {
    final locale = AppScope.of(context).locale;
    return (locale == AppLocale.es ? _monthsEs : _monthsEn)[d.month - 1];
  }
}

// -----------------------------------------------------------------------------
// Step 4 — Important dates
// -----------------------------------------------------------------------------

class _EventsStep extends StatefulWidget {
  const _EventsStep({
    required this.events,
    required this.onAdd,
    required this.onRemove,
  });

  final List<({String title, DateTime date})> events;
  final ValueChanged<({String title, DateTime date})> onAdd;
  final ValueChanged<int> onRemove;

  @override
  State<_EventsStep> createState() => _EventsStepState();
}

class _EventsStepState extends State<_EventsStep> {
  final _titleCtl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CozySpacing.stackGapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(l.obEventsTitle, style: CozyTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text(
            l.obEventsBody,
            style: CozyTypography.bodyMd.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapMd),
          TextField(
            controller: _titleCtl,
            decoration: InputDecoration(
              hintText: l.obEventsHint,
              prefixIcon: const Icon(Icons.event_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_fmt(_date)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final title = _titleCtl.text.trim();
                  if (title.isEmpty) return;
                  widget.onAdd((title: title, date: _date));
                  _titleCtl.clear();
                  setState(() {});
                },
                child: Text(l.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  l.timelineEmpty,
                  style: CozyTypography.bodyMd.copyWith(
                    color: CozyColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...List.generate(widget.events.length, (i) {
              final e = widget.events[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CozyColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(CozyRadius.md),
                    border: Border.all(color: CozyColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CozyColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.event,
                          size: 20,
                          color: CozyColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: CozyTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _fmt(e.date),
                              style: CozyTypography.labelSm.copyWith(
                                color: CozyColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => widget.onRemove(i),
                        icon: const Icon(Icons.close, size: 18),
                        color: CozyColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  static const _monthsEn = [
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
  static const _monthsEs = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  String _fmt(DateTime d) {
    final locale = AppScope.of(context).locale;
    final months = locale == AppLocale.es ? _monthsEs : _monthsEn;
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// -----------------------------------------------------------------------------
// Step 5 — Done
// -----------------------------------------------------------------------------

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(CozySpacing.stackGapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Transform.rotate(
              angle: -6 * math.pi / 180,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CozyColors.primary, CozyColors.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 76,
                ),
              ),
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          Text(
            l.obDoneTitle,
            textAlign: TextAlign.center,
            style: CozyTypography.headlineLgMobile.copyWith(
              color: CozyColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.obDoneBody,
            textAlign: TextAlign.center,
            style: CozyTypography.bodyLg.copyWith(
              color: CozyColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: CozySpacing.stackGapLg),
          GradientButton(label: l.obFinish, onPressed: onFinish),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
