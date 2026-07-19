import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/entities.dart' as entities;
import '../../state/app_scope.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/cozy_image.dart';
import '../../widgets/glass_card.dart';

/// Shared Calendar conectado al [AppState].
///
/// - Grid mensual con navegación prev/next.
/// - Días con eventos marcados con badge (heart/flight/star).
/// - Tap en día → detalle de eventos.
/// - Lista de próximos eventos + "Add Event" (bottom sheet).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final upcoming = state.upcomingEvents();
    final eventsThisMonth = state.eventsForMonth(_visibleMonth);

    return Container(
      decoration: const BoxDecoration(
        gradient: CozyColors.calendarBackgroundGradient,
      ),
      child: MediaQuery.removePadding(
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
            _CalendarHeader(
              month: _visibleMonth,
              onPrev: _prevMonth,
              onNext: _nextMonth,
            ),
            const SizedBox(height: CozySpacing.stackGapMd),
            _MonthGrid(
              month: _visibleMonth,
              events: eventsThisMonth,
              selectedDay: _selectedDay,
              onDayTap: (day) => _showDayDetail(day, eventsThisMonth),
            ),
            const SizedBox(height: CozySpacing.stackGapLg),
            _UpcomingEventsSection(
              events: upcoming,
              onAdd: _openAddEventSheet,
              onDelete: (id) => AppScope.read(context).deleteEvent(id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDayDetail(
    DateTime day,
    List<entities.CalendarEvent> monthEvents,
  ) async {
    // Marca visualmente el día tapeado mientras se abre el sheet.
    setState(() => _selectedDay = day);
    try {
      final events = monthEvents.where((e) => e.coversDay(day)).toList();
      if (events.isEmpty) {
        // Ofrece agregar evento nuevo directamente.
        await _openAddEventSheet(initialDate: day);
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _DayDetailSheet(day: day, events: events),
      );
    } finally {
      if (mounted) setState(() => _selectedDay = null);
    }
  }

  Future<void> _openAddEventSheet({DateTime? initialDate}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(initialDate: initialDate ?? _visibleMonth),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${l.monthNameFull(month.month)} ${month.year}',
            style: CozyTypography.headlineLgMobile,
          ),
        ),
        _CircleButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 8),
        _CircleButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(CozyRadius.full),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: CozyColors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.events,
    required this.onDayTap,
    this.selectedDay,
  });

  final DateTime month;
  final List<entities.CalendarEvent> events;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7; // Sunday=0, Monday=1, ...

    final today = DateTime.now();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;

    // Compone las celdas: leading días del mes previo (mutados), días
    // actuales, trailing días del mes siguiente para completar la semana.
    final prevMonthDays = DateTime(
      month.year,
      month.month,
      0,
    ).day; // último día del mes anterior
    final cells = <_DayCellData>[];

    for (var i = leadingBlanks; i > 0; i--) {
      cells.add(
        _DayCellData(
          date: DateTime(month.year, month.month - 1, prevMonthDays - i + 1),
          muted: true,
          today: false,
        ),
      );
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final coveringEvents = events.where((e) => e.coversDay(date)).toList();
      final isToday = isCurrentMonth && today.day == d;
      final isSelected = selectedDay != null && _sameDate(date, selectedDay!);
      cells.add(
        _DayCellData(
          date: date,
          muted: false,
          today: isToday,
          selected: isSelected,
          events: coveringEvents,
        ),
      );
    }
    while (cells.length % 7 != 0) {
      final next = cells.length - leadingBlanks - daysInMonth + 1;
      cells.add(
        _DayCellData(
          date: DateTime(month.year, month.month + 1, next),
          muted: true,
          today: false,
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(CozyRadius.mdLarge),
      child: Column(
        children: [
          Row(
            children: [
              for (var wd = 0; wd < 7; wd++)
                Expanded(
                  child: Center(
                    child: Text(
                      context.l10n.weekdayNameShort(wd),
                      style: CozyTypography.labelMd.copyWith(
                        color: CozyColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < cells.length; i += 7)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (final c in cells.sublist(i, i + 7))
                    Expanded(
                      child: _DayCell(
                        data: c,
                        onTap: c.muted ? null : () => onDayTap(c.date),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCellData {
  const _DayCellData({
    required this.date,
    required this.muted,
    required this.today,
    this.selected = false,
    this.events = const [],
  });

  final DateTime date;
  final bool muted;
  final bool today;
  final bool selected;
  final List<entities.CalendarEvent> events;
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayCell extends StatelessWidget {
  const _DayCell({required this.data, required this.onTap});

  final _DayCellData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final events = data.events;
    final hasEvents = events.isNotEmpty;

    // ¿Está la fecha dentro de un evento con rango (>1 día)?
    // Sólo consideramos el primer evento con rango que la cubra.
    final rangeMatches = events.where(
      (e) => e.isRange && e.coversDay(data.date),
    );
    final entities.CalendarEvent? rangeEvent = rangeMatches.isEmpty
        ? null
        : rangeMatches.first;
    final isRangeStart = rangeEvent?.isRangeStart(data.date) ?? false;
    final isRangeEnd = rangeEvent?.isRangeEnd(data.date) ?? false;
    final isRangeMiddle = rangeEvent != null && !isRangeStart && !isRangeEnd;

    // Contenido central: hoy, día en rango start/end (círculo enfatizado)
    // o número normal. Los días "middle" de un rango sólo muestran el
    // número — la barra continua se encarga del énfasis visual.
    Widget content;
    if (data.today) {
      content = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: CozyColors.activeDayGradient,
          boxShadow: [
            BoxShadow(
              color: CozyColors.primaryContainer.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${data.date.day}',
            style: CozyTypography.bodyMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else if (isRangeStart || isRangeEnd) {
      // Círculo enfatizado en los extremos del rango.
      final bg = rangeEvent!.iconBg.withValues(alpha: 0.9);
      content = Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Center(
          child: Text(
            '${data.date.day}',
            style: CozyTypography.bodyMd.copyWith(
              color: rangeEvent.iconColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      // Fecha normal o "middle" del rango.
      content = Container(
        alignment: Alignment.center,
        child: Text(
          '${data.date.day}',
          style: CozyTypography.bodyMd.copyWith(
            color: data.muted
                ? CozyColors.outline.withValues(alpha: 0.4)
                : (isRangeMiddle ? CozyColors.onSecondaryContainer : null),
            fontWeight: isRangeMiddle ? FontWeight.w600 : null,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            // Barra continua de rango (detrás de todo).
            if (rangeEvent != null)
              _RangeBar(
                isStart: isRangeStart,
                isEnd: isRangeEnd,
                color: rangeEvent.iconBg.withValues(alpha: 0.35),
              ),
            // Highlight del día seleccionado (tapeado).
            if (data.selected && !data.today)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: CozyColors.primary, width: 2),
                  ),
                ),
              ),
            Positioned.fill(child: content),
            if (hasEvents && !data.today && rangeEvent == null)
              Positioned(
                top: 0,
                right: 4,
                child: _DayBadge(
                  icon: events.first.icon,
                  color: events.first.iconColor,
                ),
              )
            else if (data.today && hasEvents)
              Positioned(
                top: 0,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    events.first.icon,
                    size: 8,
                    color: events.first.iconColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barra horizontal continua que representa el rango de un evento con
/// duración mayor a un día. En una fila del calendario los bordes de
/// celdas contiguas se conectan (no hay gap entre celdas), así que basta
/// con ajustar `left`/`right` según la posición dentro del rango.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.isStart,
    required this.isEnd,
    required this.color,
  });

  final bool isStart;
  final bool isEnd;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        // Altura de la barra ≈ 65% del alto de la celda (queda debajo del
        // número, con márgenes verticales para no tocar los badges).
        final barHeight = cons.maxHeight * 0.66;
        final vMargin = (cons.maxHeight - barHeight) / 2;
        // Extremos:
        //   - Start: desde el centro hacia la derecha.
        //   - End:   desde la izquierda hasta el centro.
        //   - Middle (ninguno): full width para conectar celdas contiguas.
        //   - Start && End (rango de un solo día): full width — no debería
        //     ocurrir porque `isRange` filtra eso, pero por seguridad.
        final left = isStart && !isEnd ? cons.maxWidth / 2 : 0.0;
        final right = isEnd && !isStart ? cons.maxWidth / 2 : 0.0;
        return Positioned(
          left: left,
          right: right,
          top: vMargin,
          height: barHeight,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.horizontal(
                left: isStart ? const Radius.circular(999) : Radius.zero,
                right: isEnd ? const Radius.circular(999) : Radius.zero,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 10, color: color),
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection({
    required this.events,
    required this.onAdd,
    required this.onDelete,
  });

  final List<entities.CalendarEvent> events;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.calendarUpcomingEvents,
                style: CozyTypography.headlineMd,
              ),
            ),
            _AddEventButton(onTap: onAdd),
          ],
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.calendarNoEvents,
              style: CozyTypography.bodyMd.copyWith(color: CozyColors.outline),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final event in events) ...[
            _EventCard(event: event, onDelete: () => onDelete(event.id)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _AddEventButton extends StatelessWidget {
  const _AddEventButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CozyColors.primaryContainer,
      borderRadius: BorderRadius.circular(CozyRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(CozyRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                color: CozyColors.onPrimaryContainer,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.calendarAddEvent,
                style: CozyTypography.labelMd.copyWith(
                  color: CozyColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onDelete});

  final entities.CalendarEvent event;
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
                color: event.iconBg.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(CozyRadius.md),
              ),
              child: Icon(event.icon, color: event.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: CozyTypography.labelMd),
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: CozyTypography.bodyMd.copyWith(
                      color: CozyColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (event.thumbnailUrl.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: CozyColors.surfaceVariant),
                ),
                child: ClipOval(child: CozyImage.network(event.thumbnailUrl)),
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
        title: Text(l.calendarDeleteEventTitle),
        content: Text('${event.title} —'),
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

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({required this.day, required this.events});

  final DateTime day;
  final List<entities.CalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
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
        bottom: CozySpacing.stackGapMd + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${l.monthNameFull(day.month)} ${day.day}, ${day.year}',
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
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: e.iconBg.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(CozyRadius.md),
                ),
                child: Icon(e.icon, color: e.iconColor),
              ),
              title: Text(e.title, style: CozyTypography.labelMd),
              subtitle: Text(
                e.subtitle,
                style: CozyTypography.bodyMd.copyWith(
                  color: CozyColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: CozyColors.error,
                onPressed: () {
                  AppScope.read(context).deleteEvent(e.id);
                  Navigator.pop(context);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  static const List<({String label, IconData icon, Color color, Color bg})>
  _presets = [
    (
      label: 'Anniversary',
      icon: Icons.favorite,
      color: CozyColors.primary,
      bg: CozyColors.primaryContainer,
    ),
    (
      label: 'Trip',
      icon: Icons.flight,
      color: CozyColors.secondary,
      bg: CozyColors.secondaryContainer,
    ),
    (
      label: 'Date Night',
      icon: Icons.restaurant,
      color: CozyColors.primary,
      bg: CozyColors.primaryContainer,
    ),
    (
      label: 'Movie',
      icon: Icons.movie,
      color: CozyColors.secondary,
      bg: CozyColors.secondaryContainer,
    ),
    (
      label: 'Home',
      icon: Icons.home,
      color: CozyColors.tertiary,
      bg: CozyColors.tertiaryContainer,
    ),
  ];

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  late DateTime _start;
  DateTime? _end;
  int _presetIdx = 0;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _titleCtrl.text.trim().isNotEmpty;

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? _start.add(const Duration(days: 1)),
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _end = d);
  }

  void _save() {
    final preset = _presets[_presetIdx];
    AppScope.read(context).addEvent(
      entities.CalendarEvent.create(
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty
            ? _formatDate(_start)
            : _subtitleCtrl.text.trim(),
        startDate: _start,
        endDate: _end,
        icon: preset.icon,
        iconColor: preset.color,
        iconBg: preset.bg,
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
                  context.l10n.calendarAddEvent,
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
                labelText: context.l10n.calendarEventTitle,
                hintText: context.l10n.calendarTitleHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.calendarEventSubtitle,
                hintText: context.l10n.calendarSubtitleHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.vaultCategory,
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
                itemBuilder: (context, i) {
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
                            _presetLabel(context, p.label),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: context.l10n.calendarStartDate,
                    value: _start,
                    onTap: _pickStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: context.l10n.calendarOptionalEndDate,
                    value: _end,
                    onTap: _pickEnd,
                    onClear: _end != null
                        ? () => setState(() => _end = null)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSave ? _save : null,
                icon: const Icon(Icons.event_available),
                label: Text(context.l10n.calendarSaveEvent),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CozyTypography.labelMd.copyWith(
            color: CozyColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: CozyColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(CozyRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CozyRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: CozyColors.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value == null ? '—' : _formatDate(value!),
                      style: CozyTypography.bodyMd,
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: CozyColors.outline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// Traduce el label de un preset (Anniversary, Trip, ...) al idioma actual.
String _presetLabel(BuildContext context, String raw) {
  final l = context.l10n;
  switch (raw) {
    case 'Anniversary':
      return l.calendarEventPresetAnniversary;
    case 'Trip':
      return l.calendarEventPresetTrip;
    case 'Date Night':
      return l.calendarEventPresetDate;
    case 'Movie':
      return l.calendarEventPresetMovie;
    case 'Home':
      return l.calendarEventPresetHome;
    default:
      return raw;
  }
}
