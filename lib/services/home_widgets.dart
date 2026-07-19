import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/entities.dart';

/// Bridge Dart → nativo Android para sincronizar los home screen widgets.
///
/// Comunica con `WidgetsBridge.kt` vía [MethodChannel]. Cuando el usuario
/// edita el perfil, agrega/borra un evento o nota, la app llama a los
/// métodos correspondientes para persistir los datos en
/// `SharedPreferences` y forzar el rebuild de los widgets del launcher.
class HomeWidgets {
  const HomeWidgets._();

  static const _channel = MethodChannel('cozy_love/widgets');

  /// Actualiza los datos de la pareja usados por el widget "Together".
  static Future<void> updateCouple(Couple couple) async {
    try {
      await _channel.invokeMethod<void>('updateCouple', {
        'name': couple.combinedName,
        'sinceMs': couple.togetherSince.millisecondsSinceEpoch,
      });
    } on PlatformException {
      // Widgets sólo existen en Android. En otras plataformas se ignora.
    } on MissingPluginException {
      // Ídem cuando el método no está implementado (p.ej. tests).
    }
  }

  /// Actualiza la lista de próximos eventos usados por "Upcoming".
  /// Se envían máximo 2 (los que el widget puede mostrar).
  static Future<void> updateUpcoming(List<CalendarEvent> events) async {
    final payload = events
        .take(2)
        .map(
          (e) => {
            'title': e.title,
            'subtitle': e.subtitle,
            'startMs': e.startDate.millisecondsSinceEpoch,
          },
        )
        .toList();
    try {
      await _channel.invokeMethod<void>('updateUpcoming', {'events': payload});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  /// Últimas notas para el widget "Notes" (máximo 3, aunque el widget
  /// actualmente sólo renderiza la última).
  static Future<void> updateNotes(List<StickyNote> notes) async {
    final payload = notes
        .take(3)
        .map(
          (n) => {
            'text': n.text,
            'author': n.author,
            'color': _noteColorKey(n.color.toARGB32()),
            'addedAtMs': n.createdAt.millisecondsSinceEpoch,
          },
        )
        .toList();
    try {
      await _channel.invokeMethod<void>('updateNotes', {'notes': payload});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  /// Target para el widget "Countdown" (fecha importante más próxima).
  /// Si [title] está vacío o [target] es null, se limpia el widget.
  static Future<void> updateCountdown({
    required String title,
    required DateTime? target,
  }) async {
    try {
      await _channel.invokeMethod<void>('updateCountdown', {
        'title': title,
        'startMs': target?.millisecondsSinceEpoch ?? 0,
      });
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  /// Actualiza el idioma que usan los widgets nativos para renderizar
  /// etiquetas y formatos.
  static Future<void> updateLocale(AppLocale locale) async {
    try {
      await _channel.invokeMethod<void>('updateLocale', {'code': locale.code});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  /// Sincroniza pareja + próximos eventos + notas + countdown + locale en
  /// un solo call. Se llama al inicio de la app y después de cada
  /// mutación relevante.
  static Future<void> sync({
    required Couple couple,
    required List<CalendarEvent> upcoming,
    required List<StickyNote> notes,
    required String countdownTitle,
    required DateTime? countdownTarget,
    required AppLocale locale,
  }) async {
    await updateLocale(locale);
    await updateCouple(couple);
    await updateUpcoming(upcoming);
    await updateNotes(notes);
    await updateCountdown(title: countdownTitle, target: countdownTarget);
  }
}

/// Mapea el ARGB de una StickyNote a la clave de drawable del widget.
String _noteColorKey(int argb) {
  // Colores definidos en `CozyColors`: yellow FFF9C4, pink F8BBD0,
  // blue B3E5FC, purple E1BEE7. Comparamos por RGB (ignorando alpha).
  final rgb = argb & 0xFFFFFF;
  return switch (rgb) {
    0xFFF9C4 => 'yellow',
    0xF8BBD0 => 'pink',
    0xB3E5FC => 'blue',
    0xE1BEE7 => 'purple',
    _ => 'yellow',
  };
}
