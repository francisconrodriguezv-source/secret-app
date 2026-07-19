import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para el "thinking of you" (corazón del top bar).
///
/// Escribe un doc en `couples/{coupleId}/pokes/{autoId}` con el uid +
/// nombre del emisor. Una Cloud Function `onPokeCreated` mira esa
/// colección, envía FCM push al otro miembro y borra el doc (no se
/// preserva historial de pokes).
class PokeService {
  PokeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> send({
    required String coupleId,
    required String fromUid,
    required String fromName,
  }) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('pokes')
        .add({
          'fromUid': fromUid,
          'fromName': fromName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
