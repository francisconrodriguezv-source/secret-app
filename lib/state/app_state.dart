import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/entities.dart';
import '../services/couple_repository.dart';
import '../services/event_repository.dart';
import '../services/home_widgets.dart';
import '../services/milestone_repository.dart';
import '../services/moment_repository.dart';
import '../services/note_repository.dart';
import '../services/prefs_bridge.dart';
import '../services/storage_service.dart';
import '../theme/cozy_colors.dart';

/// Fuente única de verdad de la app (in-memory + persistencia mínima).
///
/// Cada sección expone un getter que devuelve una copia inmutable de la
/// lista subyacente, más métodos para agregar / actualizar / eliminar.
/// Todas las mutaciones llaman `notifyListeners()` para que la UI se
/// reconstruya vía [ListenableBuilder] / [AppScope].
///
/// La persistencia se apoya en `PrefsBridge` (SharedPreferences nativo).
/// Sólo persistimos lo crítico: pareja, idioma, flag de onboarding,
/// switches de settings y las fechas importantes agregadas durante el
/// setup inicial. El resto (moments, photos, milestones, notes) sigue en
/// memoria — se re-siembran desde `MockData` en cada arranque.
class AppState extends ChangeNotifier {
  AppState({
    MomentRepository? momentRepository,
    NoteRepository? noteRepository,
    EventRepository? eventRepository,
    MilestoneRepository? milestoneRepository,
    CoupleRepository? coupleRepository,
    StorageService? storageService,
  }) : _momentRepo = momentRepository ?? MomentRepository(),
       _noteRepo = noteRepository ?? NoteRepository(),
       _eventRepo = eventRepository ?? EventRepository(),
       _milestoneRepo = milestoneRepository ?? MilestoneRepository(),
       _coupleRepo = coupleRepository ?? CoupleRepository(),
       _storage = storageService ?? StorageService();

  /// Claves de SharedPreferences.
  static const _kCouple = 'app_couple';
  static const _kLocale = 'app_locale';
  static const _kOnboarding = 'app_onboarding_complete';
  static const _kNotifications = 'app_notifications';
  static const _kPrivacy = 'app_privacy';
  static const _kOnbEvents = 'app_onboarding_events';

  bool _initialized = false;
  bool get initialized => _initialized;

  // ------ Firestore bindings ------
  final MomentRepository _momentRepo;
  final NoteRepository _noteRepo;
  final EventRepository _eventRepo;
  final MilestoneRepository _milestoneRepo;
  final CoupleRepository _coupleRepo;
  final StorageService _storage;
  String? _coupleId;
  String? _currentUid;
  StreamSubscription<List<Moment>>? _momentsSub;
  StreamSubscription<List<StickyNote>>? _notesSub;
  StreamSubscription<List<CalendarEvent>>? _eventsSub;
  StreamSubscription<List<Milestone>>? _milestonesSub;
  StreamSubscription<Couple>? _coupleSub;

  /// coupleId al que el estado está actualmente enlazado, o `null` si
  /// aún no hay pareja activa (usuario sin login o sin emparejar).
  String? get coupleId => _coupleId;

  /// uid del usuario actualmente logueado. Se usa para computar
  /// `Moment.likedByMe` y para atribuir autoría a nuevos moments.
  String? get currentUid => _currentUid;

  /// Enlaza el estado a las colecciones remotas del [coupleId] indicado.
  /// Idempotente: si ya está enlazado al mismo couple/usuario, no hace
  /// nada. Cuando el coupleId o el uid cambian, cancela la suscripción
  /// anterior y arma una nueva.
  void bindCouple({required String coupleId, required String currentUid}) {
    if (_coupleId == coupleId && _currentUid == currentUid) return;
    _cancelAllSubs();
    _coupleId = coupleId;
    _currentUid = currentUid;
    // Limpiamos listas locales para no mostrar datos de otro couple
    // mientras esperamos los primeros snapshots.
    _moments.clear();
    _notes.clear();
    _events.clear();
    _milestones.clear();

    _momentsSub = _momentRepo.watch(coupleId, currentUid: currentUid).listen((
      list,
    ) {
      _moments
        ..clear()
        ..addAll(list);
      notifyListeners();
      _syncHomeWidgets();
    });
    _notesSub = _noteRepo.watch(coupleId).listen((list) {
      _notes
        ..clear()
        ..addAll(list);
      notifyListeners();
      _syncHomeWidgets();
    });
    _eventsSub = _eventRepo.watch(coupleId).listen((list) {
      _events
        ..clear()
        ..addAll(list);
      notifyListeners();
      _syncHomeWidgets();
    });
    _milestonesSub = _milestoneRepo.watch(coupleId).listen((list) {
      _milestones
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
    _coupleSub = _coupleRepo.watch(coupleId).listen((c) {
      // Preservamos localmente los strings vacíos de couple.avatarUrl*
      // como `''`. El widget CozyImage detecta empty y muestra placeholder.
      _couple = c;
      notifyListeners();
      _syncHomeWidgets();
    });
  }

  /// Corta todas las suscripciones a Firestore. Debe llamarse en
  /// logout, o cuando el usuario se desempareje.
  void unbindCouple() {
    _cancelAllSubs();
    _coupleId = null;
    _currentUid = null;
    _moments.clear();
    _notes.clear();
    _events.clear();
    _milestones.clear();
    notifyListeners();
  }

  void _cancelAllSubs() {
    _momentsSub?.cancel();
    _momentsSub = null;
    _notesSub?.cancel();
    _notesSub = null;
    _eventsSub?.cancel();
    _eventsSub = null;
    _milestonesSub?.cancel();
    _milestonesSub = null;
    _coupleSub?.cancel();
    _coupleSub = null;
  }

  @override
  void dispose() {
    _cancelAllSubs();
    super.dispose();
  }

  // ------ Locale (idioma de la app) ------
  AppLocale _locale = AppLocale.en;
  AppLocale get locale => _locale;

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await PrefsBridge.write(_kLocale, locale.code);
    notifyListeners();
    await _syncHomeWidgets();
  }

  /// Carga desde SharedPreferences y sincroniza los home widgets.
  /// Debe llamarse una vez, después de construir la instancia.
  Future<void> bootstrap() async {
    // Locale: usa el persistido; si no existe, detecta el del dispositivo.
    final localeCode = await PrefsBridge.read(_kLocale);
    if (localeCode != null) {
      _locale = localeFromCode(localeCode);
    } else {
      // Detecta idioma del sistema; fallback a inglés si no es soportado.
      final systemCode = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase();
      _locale = localeFromCode(systemCode);
    }

    // Onboarding flag.
    final onbStr = await PrefsBridge.read(_kOnboarding);
    final onbDone = onbStr == 'true';

    // Settings.
    final notifStr = await PrefsBridge.read(_kNotifications);
    final privStr = await PrefsBridge.read(_kPrivacy);
    _settings = _settings.copyWith(
      onboardingComplete: onbDone,
      notificationsEnabled: notifStr == null ? true : notifStr == 'true',
      privacyEnabled: privStr == null ? true : privStr == 'true',
    );

    // Couple.
    final coupleJson = await PrefsBridge.read(_kCouple);
    if (coupleJson != null) {
      try {
        final m = jsonDecode(coupleJson) as Map<String, dynamic>;
        _couple = Couple(
          nameA: (m['nameA'] as String?) ?? _couple.nameA,
          nameB: (m['nameB'] as String?) ?? _couple.nameB,
          avatarUrlA: (m['avatarA'] as String?) ?? _couple.avatarUrlA,
          avatarUrlB: (m['avatarB'] as String?) ?? _couple.avatarUrlB,
          avatarUrlShared:
              (m['avatarShared'] as String?) ?? _couple.avatarUrlShared,
          togetherSince: DateTime.fromMillisecondsSinceEpoch(
            ((m['sinceMs'] as num?) ??
                    _couple.togetherSince.millisecondsSinceEpoch)
                .toInt(),
          ),
        );
      } catch (_) {
        // Ignorar payload corrupto.
      }
    }

    // Fechas importantes agregadas durante el onboarding.
    final onbEventsJson = await PrefsBridge.read(_kOnbEvents);
    if (onbEventsJson != null && onbEventsJson.isNotEmpty) {
      try {
        final list = jsonDecode(onbEventsJson) as List<dynamic>;
        for (final raw in list) {
          final m = raw as Map<String, dynamic>;
          final title = m['title'] as String? ?? '';
          final startMs = (m['startMs'] as num?)?.toInt() ?? 0;
          if (title.isEmpty || startMs <= 0) continue;
          _events.add(
            CalendarEvent.create(
              title: title,
              subtitle: '',
              startDate: DateTime.fromMillisecondsSinceEpoch(startMs),
              icon: Icons.event,
              iconColor: CozyColors.secondary,
              iconBg: CozyColors.secondaryContainer,
            ),
          );
        }
      } catch (_) {}
    }

    _initialized = true;
    notifyListeners();
    await _syncHomeWidgets();
  }

  /// Marca el onboarding como completo persistiendo pareja + fechas.
  Future<void> completeOnboarding({
    required String nameA,
    required String nameB,
    String? avatarUrlA,
    String? avatarUrlB,
    String? avatarUrlShared,
    required DateTime anniversary,
    List<({String title, DateTime date})> importantDates = const [],
  }) async {
    _couple = _couple.copyWith(
      nameA: nameA,
      nameB: nameB,
      avatarUrlA: avatarUrlA ?? _couple.avatarUrlA,
      avatarUrlB: avatarUrlB ?? _couple.avatarUrlB,
      avatarUrlShared: avatarUrlShared ?? _couple.avatarUrlShared,
      togetherSince: anniversary,
    );
    for (final e in importantDates) {
      _events.add(
        CalendarEvent.create(
          title: e.title,
          subtitle: '',
          startDate: e.date,
          icon: Icons.event,
          iconColor: CozyColors.secondary,
          iconBg: CozyColors.secondaryContainer,
        ),
      );
    }
    _settings = _settings.copyWith(onboardingComplete: true);

    await _persistCouple();
    await PrefsBridge.write(_kOnboarding, 'true');
    await _persistOnboardingEvents(importantDates);

    notifyListeners();
    await _syncHomeWidgets();
  }

  Future<void> _persistCouple() async {
    final m = {
      'nameA': _couple.nameA,
      'nameB': _couple.nameB,
      'avatarA': _couple.avatarUrlA,
      'avatarB': _couple.avatarUrlB,
      'avatarShared': _couple.avatarUrlShared,
      'sinceMs': _couple.togetherSince.millisecondsSinceEpoch,
    };
    await PrefsBridge.write(_kCouple, jsonEncode(m));
  }

  Future<void> _persistOnboardingEvents(
    List<({String title, DateTime date})> events,
  ) async {
    if (events.isEmpty) {
      await PrefsBridge.remove(_kOnbEvents);
      return;
    }
    final json = jsonEncode(
      events
          .map(
            (e) => {'title': e.title, 'startMs': e.date.millisecondsSinceEpoch},
          )
          .toList(),
    );
    await PrefsBridge.write(_kOnbEvents, json);
  }

  /// Sincroniza los datos que consumen los home screen widgets de Android
  /// (pareja + próximos eventos + notas + countdown + locale). Se llama
  /// tras cada mutación relevante.
  Future<void> _syncHomeWidgets() async {
    final target = _countdownTarget();
    await HomeWidgets.sync(
      couple: _couple,
      upcoming: upcomingEvents(limit: 2),
      notes: _notes,
      countdownTitle: target?.title ?? '',
      countdownTarget: target?.date,
      locale: _locale,
    );
  }

  /// Encuentra la próxima fecha importante para el widget "Countdown":
  /// el evento futuro más cercano. Si no hay eventos futuros, retorna
  /// null (el widget mostrará empty state).
  ({String title, DateTime date})? _countdownTarget() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? bestDate;
    String? bestTitle;
    for (final e in _events) {
      final d = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
      if (d.isBefore(today)) continue;
      if (bestDate == null || d.isBefore(bestDate)) {
        bestDate = d;
        bestTitle = e.title;
      }
    }
    if (bestDate == null || bestTitle == null) return null;
    return (title: bestTitle, date: bestDate);
  }

  // ------ Couple ------
  /// Por defecto vacía — se llena en el onboarding.
  Couple _couple = Couple(
    nameA: '',
    nameB: '',
    avatarUrlA: '',
    avatarUrlB: '',
    togetherSince: DateTime.now(),
  );
  Couple get couple => _couple;

  Future<void> updateCouple({
    String? nameA,
    String? nameB,
    String? avatarUrlA,
    String? avatarUrlB,
    String? avatarUrlShared,
    DateTime? togetherSince,
  }) async {
    final coupleId = _coupleId;
    if (coupleId == null) {
      // Sin coupleId (usuario sin emparejar) — modo memoria local.
      _couple = _couple.copyWith(
        nameA: nameA,
        nameB: nameB,
        avatarUrlA: avatarUrlA,
        avatarUrlB: avatarUrlB,
        avatarUrlShared: avatarUrlShared,
        togetherSince: togetherSince,
      );
      await _persistCouple();
      notifyListeners();
      await _syncHomeWidgets();
      return;
    }
    // Si los avatares vienen como rutas locales, primero se suben a
    // Storage y se reemplazan por su URL de descarga HTTPS.
    var finalAvatarA = avatarUrlA;
    var finalAvatarB = avatarUrlB;
    var finalAvatarShared = avatarUrlShared;
    if (finalAvatarA != null &&
        finalAvatarA.isNotEmpty &&
        !finalAvatarA.startsWith('http')) {
      finalAvatarA = await _storage.uploadAvatar(
        coupleId: coupleId,
        role: 'a',
        localPath: finalAvatarA,
      );
    }
    if (finalAvatarB != null &&
        finalAvatarB.isNotEmpty &&
        !finalAvatarB.startsWith('http')) {
      finalAvatarB = await _storage.uploadAvatar(
        coupleId: coupleId,
        role: 'b',
        localPath: finalAvatarB,
      );
    }
    if (finalAvatarShared != null &&
        finalAvatarShared.isNotEmpty &&
        !finalAvatarShared.startsWith('http')) {
      finalAvatarShared = await _storage.uploadAvatar(
        coupleId: coupleId,
        role: 'shared',
        localPath: finalAvatarShared,
      );
    }
    await _coupleRepo.update(
      coupleId,
      nameA: nameA,
      nameB: nameB,
      avatarUrlA: finalAvatarA,
      avatarUrlB: finalAvatarB,
      avatarUrlShared: finalAvatarShared,
      togetherSince: togetherSince,
    );
    // El stream del couple emitir\u00e1 el nuevo valor y ejecutar\u00e1
    // notifyListeners + syncHomeWidgets autom\u00e1ticamente.
  }

  // ------ Timeline (moments = photo o note) ------
  //
  // Fuente de verdad: subcolección `couples/{coupleId}/moments`. La
  // lista `_moments` es una caché local alimentada por el stream de
  // [_momentRepo]. Los mutators (`addMoment`, `deleteMoment`,
  // `toggleLike`) escriben a Firestore; el stream refleja los cambios
  // y llama a `notifyListeners()`.
  //
  // Si por algún motivo la app se usa sin coupleId (bootstrapping,
  // tests, logout), las mutaciones aplican sólo a memoria local.
  final List<Moment> _moments = [];
  List<Moment> get moments {
    final list = List<Moment>.of(_moments);
    list.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(list);
  }

  /// Publica un moment. Cuando hay `coupleId`, escribe a Firestore
  /// (via [MomentRepository]) y espera la subida completa (si trae
  /// foto local, primero pasa por Firebase Storage). Retorna un future
  /// para que la UI muestre feedback (spinner) mientras dura la
  /// operación.
  Future<void> addMoment(Moment m) async {
    final coupleId = _coupleId;
    final uid = _currentUid;
    if (coupleId == null || uid == null) {
      _moments.add(m);
      notifyListeners();
      return;
    }
    await _momentRepo.add(coupleId, moment: m, authorUid: uid);
  }

  void deleteMoment(String id) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _moments.removeWhere((m) => m.id == id);
      notifyListeners();
      return;
    }
    unawaited(_momentRepo.delete(coupleId, id));
  }

  void toggleLike(String id) {
    final coupleId = _coupleId;
    final uid = _currentUid;
    if (coupleId == null || uid == null) {
      final idx = _moments.indexWhere((m) => m.id == id);
      if (idx == -1) return;
      final m = _moments[idx];
      final liked = !m.likedByMe;
      _moments[idx] = m.copyWith(
        likedByMe: liked,
        likes: (m.likes + (liked ? 1 : -1)).clamp(0, 1 << 30),
      );
      notifyListeners();
      return;
    }
    final current = _moments.firstWhere(
      (m) => m.id == id,
      orElse: () => throw StateError('Moment not found: $id'),
    );
    final nowLiked = !current.likedByMe;
    unawaited(
      _momentRepo.toggleLike(coupleId, id, uid: uid, nowLiked: nowLiked),
    );
  }

  /// Agrupa momentos por mes (más recientes primero). Retorna lista de
  /// pares `(monthLabel, moments-del-mes)`.
  List<({String label, List<Moment> moments})> groupedByMonth() {
    final grouped = <String, List<Moment>>{};
    for (final m in moments) {
      final key = _monthKey(m.date);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    return grouped.entries
        .map((e) => (label: e.key, moments: e.value))
        .toList();
  }

  String _monthKey(DateTime d) {
    final l = stringsFor(_locale);
    return '${l.monthNameFull(d.month).toUpperCase()} ${d.year}';
  }

  // ------ Vault (photos) ------
  final List<Photo> _photos = [];
  List<Photo> get photos => List.unmodifiable(_photos);

  /// Prefijo aplicado al `id` de las [Photo] derivadas de un [Moment].
  /// Permite distinguirlas de las [Photo] "sueltas" al eliminar / favear.
  static const String _momentPhotoPrefix = 'moment_';

  /// Fotos unificadas para el Vault: [Photo] sueltas + [Moment.photo] con
  /// URL válida. Los momentos se convierten a [Photo] "virtuales" para
  /// mostrarse en el grid sin duplicar datos en memoria.
  List<Photo> get combinedPhotos {
    final momentPhotos = _moments
        .where(
          (m) => m.kind == MomentKind.photo && m.imageUrl.trim().isNotEmpty,
        )
        .map(
          (m) => Photo(
            id: '$_momentPhotoPrefix${m.id}',
            url: m.imageUrl,
            category: m.tags.isNotEmpty ? m.tags.first : 'Timeline',
            title: m.caption.isNotEmpty ? m.caption : null,
            date: _shortDate(m.date),
            aspectRatio: m.aspectRatio,
            favorite: m.likedByMe,
          ),
        );
    // Ordena por fecha descendente (última publicada primero).
    return [...momentPhotos, ..._photos];
  }

  List<Photo> photosByCategory(String category) {
    if (category == 'All') return combinedPhotos;
    return combinedPhotos.where((p) => p.category == category).toList();
  }

  List<Photo> searchPhotos(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return combinedPhotos;
    return combinedPhotos.where((p) {
      return (p.title?.toLowerCase().contains(q) ?? false) ||
          (p.date?.toLowerCase().contains(q) ?? false) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  /// Categorías disponibles en el Vault (fijas + las derivadas del contenido).
  List<String> get vaultCategories {
    final base = <String>{'Trips', 'Dates', 'Firsts', 'Family', 'Pets'};
    for (final p in _photos) {
      base.add(p.category);
    }
    for (final m in _moments) {
      if (m.kind == MomentKind.photo) {
        base.addAll(m.tags);
        if (m.tags.isEmpty) base.add('Timeline');
      }
    }
    return ['All', ...base];
  }

  void addPhoto(Photo p) {
    _photos.insert(0, p);
    notifyListeners();
  }

  void deletePhoto(String id) {
    _photos.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final idx = _photos.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _photos[idx] = _photos[idx].copyWith(favorite: !_photos[idx].favorite);
    notifyListeners();
  }

  /// Elimina una foto del Vault sin importar su origen (foto suelta o
  /// derivada de un Moment). Si es derivada, elimina el Moment completo.
  void deleteVaultItem(String id) {
    if (id.startsWith(_momentPhotoPrefix)) {
      deleteMoment(id.substring(_momentPhotoPrefix.length));
    } else {
      deletePhoto(id);
    }
  }

  /// Toggle favorito unificado. Para fotos derivadas de un Moment usa el
  /// mismo mecanismo que "like" del timeline.
  void toggleVaultFavorite(String id) {
    if (id.startsWith(_momentPhotoPrefix)) {
      toggleLike(id.substring(_momentPhotoPrefix.length));
    } else {
      toggleFavorite(id);
    }
  }

  static const _shortMonthNames = [
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

  String _shortDate(DateTime d) =>
      '${_shortMonthNames[d.month - 1]} ${d.day}, ${d.year}';

  // ------ Sticky Notes (Message Board / Vault Notes) ------
  //
  // Fuente de verdad: subcolección `couples/{coupleId}/notes`. Los
  // mutators escriben a Firestore; el stream alimenta la lista local.
  final List<StickyNote> _notes = [];
  List<StickyNote> get notes => List.unmodifiable(_notes);

  void addNote(StickyNote n) {
    final coupleId = _coupleId;
    final uid = _currentUid;
    if (coupleId == null || uid == null) {
      _notes.insert(0, n);
      notifyListeners();
      _syncHomeWidgets();
      return;
    }
    unawaited(_noteRepo.add(coupleId, note: n, authorUid: uid));
  }

  void deleteNote(String id) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
      _syncHomeWidgets();
      return;
    }
    unawaited(_noteRepo.delete(coupleId, id));
  }

  /// Paleta de colores disponibles para nuevas notas.
  static const List<Color> notePalette = [
    CozyColors.noteYellow,
    CozyColors.notePink,
    CozyColors.noteBlue,
    CozyColors.notePurple,
  ];

  // ------ Calendar Events ------
  final List<CalendarEvent> _events = [];
  List<CalendarEvent> get events {
    final list = List<CalendarEvent>.of(_events);
    list.sort((a, b) => a.startDate.compareTo(b.startDate));
    return List.unmodifiable(list);
  }

  List<CalendarEvent> eventsForMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    return events.where((e) {
      final end = e.endDate ?? e.startDate;
      // Un evento pertenece al mes si su rango [start, end] intersecta
      // el mes visible, incluso si comenzó/termina en otro mes.
      return !e.startDate.isAfter(lastOfMonth) && !end.isBefore(firstOfMonth);
    }).toList();
  }

  List<CalendarEvent> eventsForDay(DateTime day) =>
      events.where((e) => e.coversDay(day)).toList();

  List<CalendarEvent> upcomingEvents({int limit = 5}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = events
        .where(
          (e) =>
              !e.startDate.isBefore(today) ||
              (e.endDate != null && !e.endDate!.isBefore(today)),
        )
        .toList();
    if (upcoming.length > limit) return upcoming.sublist(0, limit);
    return upcoming;
  }

  void addEvent(CalendarEvent e) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _events.add(e);
      notifyListeners();
      _syncHomeWidgets();
      return;
    }
    unawaited(_eventRepo.add(coupleId, e));
  }

  void deleteEvent(String id) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _events.removeWhere((e) => e.id == id);
      notifyListeners();
      _syncHomeWidgets();
      return;
    }
    unawaited(_eventRepo.delete(coupleId, id));
  }

  // ------ Milestones ------
  final List<Milestone> _milestones = [];
  List<Milestone> get milestones => List.unmodifiable(_milestones);

  void addMilestone(Milestone m) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _milestones.add(m);
      notifyListeners();
      return;
    }
    unawaited(_milestoneRepo.add(coupleId, m));
  }

  void deleteMilestone(String id) {
    final coupleId = _coupleId;
    if (coupleId == null) {
      _milestones.removeWhere((m) => m.id == id);
      notifyListeners();
      return;
    }
    unawaited(_milestoneRepo.delete(coupleId, id));
  }

  // ------ Settings ------
  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  void toggleNotifications() {
    _settings = _settings.copyWith(
      notificationsEnabled: !_settings.notificationsEnabled,
    );
    PrefsBridge.write(
      _kNotifications,
      _settings.notificationsEnabled.toString(),
    );
    notifyListeners();
  }

  void togglePrivacy() {
    _settings = _settings.copyWith(privacyEnabled: !_settings.privacyEnabled);
    PrefsBridge.write(_kPrivacy, _settings.privacyEnabled.toString());
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
  }

  // ------ Seed ------
  /// No-op: la app arranca vacía. Los datos se persisten en prefs
  /// (couple + fechas del onboarding) o los agrega el usuario en la app.
  // ignore: unused_element
  void _seedFromMockData() {}
}
