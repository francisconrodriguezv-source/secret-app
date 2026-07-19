import 'package:flutter/services.dart';

/// Bridge Dart → nativo para lanzar notificaciones locales del sistema.
///
/// Sirve como reemplazo del package `flutter_local_notifications` que no
/// podemos instalar por el proxy corporativo. Todo se hace vía
/// `NotificationBridge.kt` y `MethodChannel('cozy_love/notifications')`.
class LocalNotifications {
  const LocalNotifications._();

  static const _channel = MethodChannel('cozy_love/notifications');

  /// Muestra una notificación con [title] y [body].
  /// Requiere que el usuario haya aceptado el permiso `POST_NOTIFICATIONS`
  /// en Android 13+ (se solicita con [requestPermission]).
  static Future<void> send({
    required String title,
    required String body,
  }) async {
    try {
      await _channel.invokeMethod<void>('send', {'title': title, 'body': body});
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }

  /// Solicita el permiso `POST_NOTIFICATIONS` (Android 13+). Retorna
  /// silenciosamente si el sistema no requiere permiso.
  static Future<bool> requestPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }
}
