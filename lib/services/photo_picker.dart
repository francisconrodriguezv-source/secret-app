import 'package:flutter/services.dart';

/// Servicio para seleccionar imágenes desde galería o cámara vía
/// [MethodChannel] hacia código nativo Android
/// (`MainActivity.kt` maneja los intents SAF y `ACTION_IMAGE_CAPTURE`).
///
/// Ambos métodos retornan la ruta ABSOLUTA a un archivo copiado en el
/// cache del app (no `content://` URIs) para que Flutter pueda mostrarlo
/// con `Image.file`. Cuando quieras persistencia definitiva, copia estos
/// archivos a un directorio propio de la app.
class PhotoPicker {
  const PhotoPicker._();

  static const _channel = MethodChannel('cozy_love/photo');

  /// Abre el picker de galería (Storage Access Framework). Retorna la ruta
  /// absoluta de una copia local, o `null` si el usuario cancela.
  static Future<String?> pickFromGallery() async {
    try {
      final result = await _channel.invokeMethod<String>('pickFromGallery');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Abre la app de cámara. La foto se guarda en el cache externo del app
  /// y se devuelve como ruta absoluta. Retorna `null` si el usuario
  /// cancela o no hay cámara disponible.
  static Future<String?> takePhoto() async {
    try {
      final result = await _channel.invokeMethod<String>('takePhoto');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }
}
