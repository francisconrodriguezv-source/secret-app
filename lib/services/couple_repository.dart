import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/entities.dart';

/// Repositorio de la metadata del couple (nombres, avatares, aniversario).
///
/// Se apoya en el doc `couples/{coupleId}` — el mismo que crea
/// `CoupleService.createCouple`. Aquí solo exponemos un stream/watcher
/// tipado a [Couple].
class CoupleRepository {
  CoupleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String coupleId) =>
      _firestore.collection('couples').doc(coupleId);

  Stream<Couple> watch(String coupleId) {
    return _ref(coupleId).snapshots().map(_fromSnap);
  }

  /// Actualiza campos parciales del doc del couple. Los que no se
  /// pasan (null) no se tocan.
  Future<void> update(
    String coupleId, {
    String? nameA,
    String? nameB,
    String? avatarUrlA,
    String? avatarUrlB,
    String? avatarUrlShared,
    DateTime? togetherSince,
  }) {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (nameA != null) payload['nameA'] = nameA;
    if (nameB != null) payload['nameB'] = nameB;
    if (avatarUrlA != null) payload['avatarUrlA'] = avatarUrlA;
    if (avatarUrlB != null) payload['avatarUrlB'] = avatarUrlB;
    if (avatarUrlShared != null) payload['avatarUrlShared'] = avatarUrlShared;
    if (togetherSince != null) {
      payload['togetherSinceMs'] = togetherSince.millisecondsSinceEpoch;
    }
    return _ref(coupleId).update(payload);
  }

  Couple _fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const <String, dynamic>{};
    final togetherMs = (data['togetherSinceMs'] as num?)?.toInt();
    return Couple(
      nameA: data['nameA'] as String? ?? '',
      nameB: data['nameB'] as String? ?? '',
      avatarUrlA: data['avatarUrlA'] as String? ?? '',
      avatarUrlB: data['avatarUrlB'] as String? ?? '',
      avatarUrlShared: data['avatarUrlShared'] as String? ?? '',
      togetherSince: togetherMs != null
          ? DateTime.fromMillisecondsSinceEpoch(togetherMs)
          : DateTime.now(),
    );
  }
}
