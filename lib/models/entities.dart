import 'package:flutter/material.dart';

/// Genera un id local basado en timestamp + contador. Suficiente para
/// mock/state en memoria; cuando agreguemos persistencia se puede sustituir
/// por UUID v4.
class IdGen {
  IdGen._();

  static int _counter = 0;

  static String next(String prefix) {
    _counter++;
    final ts = DateTime.now().microsecondsSinceEpoch;
    return '$prefix-$ts-$_counter';
  }
}

// -----------------------------------------------------------------------------
// Couple (info de la pareja)
// -----------------------------------------------------------------------------

class Couple {
  const Couple({
    required this.nameA,
    required this.nameB,
    required this.avatarUrlA,
    required this.avatarUrlB,
    required this.togetherSince,
    this.avatarUrlShared = '',
  });

  final String nameA;
  final String nameB;
  final String avatarUrlA;
  final String avatarUrlB;

  /// Foto de los dos juntos (opcional). Se muestra en el top bar como
  /// avatar de la pareja. Si está vacía, se usa `avatarUrlA` de fallback.
  final String avatarUrlShared;
  final DateTime togetherSince;

  String get combinedName {
    final a = nameA.trim();
    final b = nameB.trim();
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a & $b';
  }

  String get initialA =>
      nameA.trim().isNotEmpty ? nameA.trim()[0].toUpperCase() : '';
  String get initialB =>
      nameB.trim().isNotEmpty ? nameB.trim()[0].toUpperCase() : '';

  /// Etiqueta legible del tiempo juntos (ej. "3 Years, 2 Months").
  String get durationLabel {
    final now = DateTime.now();
    var years = now.year - togetherSince.year;
    var months = now.month - togetherSince.month;
    if (now.day < togetherSince.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'Year' : 'Years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'Month' : 'Months'}');
    if (parts.isEmpty) return 'Just Together';
    return parts.join(', ');
  }

  /// Descomposición del tiempo juntos en años + meses + días.
  ({int years, int months, int days}) get durationParts {
    final now = DateTime.now();
    var years = now.year - togetherSince.year;
    var months = now.month - togetherSince.month;
    var days = now.day - togetherSince.day;
    if (days < 0) {
      months--;
      // Días del mes anterior al actual.
      final prevMonth = DateTime(now.year, now.month, 0).day;
      days += prevMonth;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    return (years: years, months: months, days: days);
  }

  /// Total de días transcurridos desde [togetherSince].
  int get totalDays {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(togetherSince.year, togetherSince.month, togetherSince.day),
        )
        .inDays;
  }

  Couple copyWith({
    String? nameA,
    String? nameB,
    String? avatarUrlA,
    String? avatarUrlB,
    String? avatarUrlShared,
    DateTime? togetherSince,
  }) => Couple(
    nameA: nameA ?? this.nameA,
    nameB: nameB ?? this.nameB,
    avatarUrlA: avatarUrlA ?? this.avatarUrlA,
    avatarUrlB: avatarUrlB ?? this.avatarUrlB,
    avatarUrlShared: avatarUrlShared ?? this.avatarUrlShared,
    togetherSince: togetherSince ?? this.togetherSince,
  );
}

// -----------------------------------------------------------------------------
// Moment (photo o nota) — feed del Timeline
// -----------------------------------------------------------------------------

enum MomentKind { photo, note }

class Moment {
  Moment({
    required this.id,
    required this.kind,
    required this.date,
    this.imageUrl = '',
    this.caption = '',
    this.quote = '',
    this.tags = const [],
    this.likes = 0,
    this.likedByMe = false,
    this.aspectRatio = 4 / 3,
    this.author,
  });

  factory Moment.photo({
    required DateTime date,
    required String imageUrl,
    required String caption,
    List<String> tags = const [],
    int likes = 0,
    double aspectRatio = 4 / 3,
    String? author,
  }) => Moment(
    id: IdGen.next('mom'),
    kind: MomentKind.photo,
    date: date,
    imageUrl: imageUrl,
    caption: caption,
    tags: tags,
    likes: likes,
    aspectRatio: aspectRatio,
    author: author,
  );

  factory Moment.note({
    required DateTime date,
    required String quote,
    String? author,
  }) => Moment(
    id: IdGen.next('mom'),
    kind: MomentKind.note,
    date: date,
    quote: quote,
    author: author,
  );

  final String id;
  final MomentKind kind;
  final DateTime date;
  final String imageUrl;
  final String caption;
  final String quote;
  final List<String> tags;
  final int likes;
  final bool likedByMe;
  final double aspectRatio;
  final String? author;

  Moment copyWith({
    String? imageUrl,
    String? caption,
    String? quote,
    List<String>? tags,
    int? likes,
    bool? likedByMe,
    double? aspectRatio,
    DateTime? date,
    String? author,
  }) => Moment(
    id: id,
    kind: kind,
    date: date ?? this.date,
    imageUrl: imageUrl ?? this.imageUrl,
    caption: caption ?? this.caption,
    quote: quote ?? this.quote,
    tags: tags ?? this.tags,
    likes: likes ?? this.likes,
    likedByMe: likedByMe ?? this.likedByMe,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    author: author ?? this.author,
  );
}

// -----------------------------------------------------------------------------
// Photo — grid del Vault
// -----------------------------------------------------------------------------

class Photo {
  Photo({
    required this.id,
    required this.url,
    required this.category,
    this.title,
    this.date,
    this.aspectRatio = 1,
    this.badge,
    this.favorite = false,
  });

  factory Photo.create({
    required String url,
    required String category,
    String? title,
    String? date,
    double aspectRatio = 1,
    String? badge,
    bool favorite = false,
  }) => Photo(
    id: IdGen.next('photo'),
    url: url,
    category: category,
    title: title,
    date: date,
    aspectRatio: aspectRatio,
    badge: badge,
    favorite: favorite,
  );

  final String id;
  final String url;
  final String category;
  final String? title;
  final String? date;
  final double aspectRatio;
  final String? badge;
  final bool favorite;

  Photo copyWith({
    String? url,
    String? category,
    String? title,
    String? date,
    double? aspectRatio,
    String? badge,
    bool? favorite,
  }) => Photo(
    id: id,
    url: url ?? this.url,
    category: category ?? this.category,
    title: title ?? this.title,
    date: date ?? this.date,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    badge: badge ?? this.badge,
    favorite: favorite ?? this.favorite,
  );
}

// -----------------------------------------------------------------------------
// StickyNote — Message Board / Vault mode Notes
// -----------------------------------------------------------------------------

class StickyNote {
  StickyNote({
    required this.id,
    required this.text,
    required this.color,
    required this.timestamp,
    required this.author,
    required this.avatarBg,
    required this.avatarFg,
    this.tilt = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StickyNote.create({
    required String text,
    required Color color,
    required String timestamp,
    required String author,
    required Color avatarBg,
    required Color avatarFg,
    double tilt = 0,
  }) => StickyNote(
    id: IdGen.next('note'),
    text: text,
    color: color,
    timestamp: timestamp,
    author: author,
    avatarBg: avatarBg,
    avatarFg: avatarFg,
    tilt: tilt,
  );

  final String id;
  final String text;
  final Color color;
  final String timestamp;
  final String author;
  final Color avatarBg;
  final Color avatarFg;
  final double tilt;
  final DateTime createdAt;

  StickyNote copyWith({
    String? text,
    Color? color,
    String? timestamp,
    String? author,
    Color? avatarBg,
    Color? avatarFg,
    double? tilt,
  }) => StickyNote(
    id: id,
    text: text ?? this.text,
    color: color ?? this.color,
    timestamp: timestamp ?? this.timestamp,
    author: author ?? this.author,
    avatarBg: avatarBg ?? this.avatarBg,
    avatarFg: avatarFg ?? this.avatarFg,
    tilt: tilt ?? this.tilt,
    createdAt: createdAt,
  );
}

// -----------------------------------------------------------------------------
// CalendarEvent — Calendar
// -----------------------------------------------------------------------------

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startDate,
    this.endDate,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.thumbnailUrl = '',
  });

  factory CalendarEvent.create({
    required String title,
    required String subtitle,
    required DateTime startDate,
    DateTime? endDate,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String thumbnailUrl = '',
  }) => CalendarEvent(
    id: IdGen.next('evt'),
    title: title,
    subtitle: subtitle,
    startDate: startDate,
    endDate: endDate,
    icon: icon,
    iconColor: iconColor,
    iconBg: iconBg,
    thumbnailUrl: thumbnailUrl,
  );

  final String id;
  final String title;
  final String subtitle;
  final DateTime startDate;
  final DateTime? endDate;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String thumbnailUrl;

  bool get isRange => endDate != null && !_sameDay(startDate, endDate!);

  bool coversDay(DateTime day) {
    if (endDate == null) return _sameDay(startDate, day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  bool isRangeStart(DateTime day) => isRange && _sameDay(startDate, day);
  bool isRangeEnd(DateTime day) => isRange && _sameDay(endDate!, day);
  bool isRangeMiddle(DateTime day) =>
      isRange && coversDay(day) && !isRangeStart(day) && !isRangeEnd(day);

  /// Días desde hoy hasta [startDate]. Negativo si ya pasó.
  int daysUntil() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.difference(today).inDays;
  }

  /// Etiqueta compacta relativa a hoy ("Today", "Tomorrow", "in 5 days",
  /// "in 2 months", etc.).
  String get relativeLabel {
    final d = daysUntil();
    if (d < 0) return 'Past';
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    if (d < 7) return 'in $d days';
    if (d < 30) {
      final w = (d / 7).round();
      return 'in $w ${w == 1 ? 'week' : 'weeks'}';
    }
    final m = (d / 30).round();
    return 'in $m ${m == 1 ? 'month' : 'months'}';
  }

  CalendarEvent copyWith({
    String? title,
    String? subtitle,
    DateTime? startDate,
    DateTime? endDate,
    IconData? icon,
    Color? iconColor,
    Color? iconBg,
    String? thumbnailUrl,
  }) => CalendarEvent(
    id: id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    icon: icon ?? this.icon,
    iconColor: iconColor ?? this.iconColor,
    iconBg: iconBg ?? this.iconBg,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// -----------------------------------------------------------------------------
// Milestone — Profile
// -----------------------------------------------------------------------------

class Milestone {
  Milestone({
    required this.id,
    required this.title,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.place,
  });

  factory Milestone.create({
    required String title,
    required String date,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? place,
  }) => Milestone(
    id: IdGen.next('ms'),
    title: title,
    date: date,
    icon: icon,
    iconColor: iconColor,
    iconBg: iconBg,
    place: place,
  );

  final String id;
  final String title;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? place;

  Milestone copyWith({
    String? title,
    String? date,
    IconData? icon,
    Color? iconColor,
    Color? iconBg,
    String? place,
  }) => Milestone(
    id: id,
    title: title ?? this.title,
    date: date ?? this.date,
    icon: icon ?? this.icon,
    iconColor: iconColor ?? this.iconColor,
    iconBg: iconBg ?? this.iconBg,
    place: place ?? this.place,
  );
}

// -----------------------------------------------------------------------------
// Settings — Profile
// -----------------------------------------------------------------------------

class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.privacyEnabled = true,
    this.themeMode = ThemeMode.system,
    this.onboardingComplete = false,
  });

  final bool notificationsEnabled;
  final bool privacyEnabled;
  final ThemeMode themeMode;
  final bool onboardingComplete;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? privacyEnabled,
    ThemeMode? themeMode,
    bool? onboardingComplete,
  }) => AppSettings(
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    privacyEnabled: privacyEnabled ?? this.privacyEnabled,
    themeMode: themeMode ?? this.themeMode,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}
