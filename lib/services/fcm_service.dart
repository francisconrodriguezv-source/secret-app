import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio de Firebase Cloud Messaging (FCM).
///
/// Al iniciar, pide permiso (auto en Android <13, prompt en 13+ / iOS),
/// obtiene el token del dispositivo, lo guarda en `users/{uid}.fcmToken`
/// y escucha refreshes.
///
/// El envío de push notifications ocurre desde Cloud Functions
/// (`onDocumentCreated` en `couples/*/moments/*`, `notes/*`, `pokes/*`),
/// leyendo el token del destinatario desde su doc `users/{uid}`.
class FcmService {
  FcmService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  StreamSubscription<String>? _tokenSub;
  String? _boundUid;

  /// Configura FCM para el usuario [uid]. Idempotente: si ya está
  /// enlazado al mismo uid, no hace nada.
  Future<void> initialize({required String uid}) async {
    if (_boundUid == uid) return;
    _boundUid = uid;
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      await _writeToken(uid, token);
    }
    await _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) {
      unawaited(_writeToken(uid, newToken));
    });
  }

  /// Corta la suscripción al token refresh. Debe llamarse en logout.
  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    _boundUid = null;
  }

  Future<void> _writeToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
