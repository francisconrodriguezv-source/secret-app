import 'package:flutter/services.dart';

/// Bridge Dart → Kotlin para persistir preferencias en
/// `SharedPreferences` sin depender de packages externos (proxy corporativo
/// bloquea `shared_preferences`).
///
/// Métodos disponibles en el channel `cozy_love/prefs`:
/// - `read(key: String) → String?`
/// - `write(key: String, value: String)`
/// - `remove(key: String)`
class PrefsBridge {
  const PrefsBridge._();

  static const _channel = MethodChannel('cozy_love/prefs');

  static Future<String?> read(String key) async {
    try {
      final result = await _channel.invokeMethod<String?>('read', {'key': key});
      return result;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('write', {'key': key, 'value': value});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  static Future<void> remove(String key) async {
    try {
      await _channel.invokeMethod<void>('remove', {'key': key});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }
}
