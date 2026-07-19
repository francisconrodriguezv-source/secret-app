import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Servicio de subida/lectura de archivos a Firebase Storage.
///
/// Layout en el bucket:
/// - `couples/{coupleId}/moments/{momentId}.jpg` — foto de un `Moment`.
/// - `couples/{coupleId}/avatars/{role}-{timestamp}.jpg` — foto de
///   perfil (role ∈ `a`, `b`, `shared`). El timestamp evita que la URL
///   quede cacheada tras un cambio de foto.
///
/// Este servicio nunca guarda referencias fuera del bucket: quien
/// consulta la lista de URLs vive en Firestore (`imageUrl` en el doc
/// del moment, o `avatarUrlA/B/Shared` en el doc del couple).
class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Sube la foto local en [localPath] a la ruta canónica del moment y
  /// retorna la URL de descarga (HTTPS) que se puede persistir en el
  /// campo `imageUrl` del doc de Firestore.
  Future<String> uploadMomentPhoto({
    required String coupleId,
    required String momentId,
    required String localPath,
  }) async {
    final file = File(localPath);
    final ref = _storage.ref('couples/$coupleId/moments/$momentId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Sube un avatar (individual `a`/`b` o compartido `shared`). Usa un
  /// nombre único por timestamp para que la URL nueva sea distinta a la
  /// vieja (evita problemas de cache tras el cambio).
  Future<String> uploadAvatar({
    required String coupleId,
    required String role,
    required String localPath,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('couples/$coupleId/avatars/$role-$ts.jpg');
    await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
