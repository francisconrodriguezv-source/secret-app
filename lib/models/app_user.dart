import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil de un usuario autenticado. Persiste en `users/{uid}`.
///
/// - [uid] es el UID de Firebase Auth (nunca cambia).
/// - [email] el correo con el que se registró (puede editarse desde
///   Firebase Auth, aquí sólo lo cacheamos para display).
/// - [displayName] el nombre que usa dentro del couple (ej. "Emma"). Se
///   propaga al perfil compartido pero cada usuario tiene el suyo.
/// - [avatarUrl] URL del avatar personal (subida a Firebase Storage).
/// - [coupleId] el ID del couple al que pertenece; null si aún no se
///   emparejó con nadie.
/// - [fcmToken] token del dispositivo actual para push notifications.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.coupleId,
    this.fcmToken,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      coupleId: data['coupleId'] as String?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  final String uid;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String? coupleId;
  final String? fcmToken;

  bool get hasCouple => coupleId != null && coupleId!.isNotEmpty;

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    if (coupleId != null) 'coupleId': coupleId,
    if (fcmToken != null) 'fcmToken': fcmToken,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  AppUser copyWith({
    String? email,
    String? displayName,
    String? avatarUrl,
    String? coupleId,
    String? fcmToken,
  }) => AppUser(
    uid: uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coupleId: coupleId ?? this.coupleId,
    fcmToken: fcmToken ?? this.fcmToken,
  );
}
