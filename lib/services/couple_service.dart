import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Manejo del "couple space" compartido entre dos usuarios.
///
/// Modelo Firestore:
/// - `couples/{coupleId}` — doc con metadatos del couple (nombres,
///   avatares, fecha de aniversario, etc.).
/// - `couples/{coupleId}/members/{uid}` — un doc por cada miembro; sirve
///   para las Security Rules (`isMember(coupleId)`).
/// - `invite_codes/{code6}` — código de invitación temporal con TTL 10
///   minutos; consumido de una sola vez.
///
/// Todas las subcolecciones de datos compartidos (`moments`, `notes`,
/// `events`, `milestones`) cuelgan bajo `couples/{coupleId}/...` — así
/// las security rules garantizan que sólo miembros del couple leen/
/// escriben.
class CoupleService {
  CoupleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Crea un couple nuevo con [creatorUid] como primer miembro. Retorna
  /// el `coupleId` recién generado.
  ///
  /// **Importante**: este método NO escribe `users/{creatorUid}.coupleId`.
  /// Ese write se hace más tarde, cuando el creador confirma el
  /// emparejamiento (via [finalizeCoupleForCreator], típicamente al
  /// detectar que su código de invitación fue consumido). De ese modo
  /// mientras el creador espera a su pareja permanece en la pantalla
  /// de emparejamiento (el `AuthGate` no lo saca prematuramente).
  Future<String> createCouple({
    required String creatorUid,
    required String creatorDisplayName,
  }) async {
    final coupleRef = _firestore.collection('couples').doc();
    final batch = _firestore.batch();
    batch.set(coupleRef, {
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': creatorUid,
      // Perfil compartido (se completa desde la app):
      'nameA': creatorDisplayName,
      'nameB': '',
      'avatarUrlA': '',
      'avatarUrlB': '',
      'avatarUrlShared': '',
      'togetherSinceMs': DateTime.now().millisecondsSinceEpoch,
    });
    batch.set(coupleRef.collection('members').doc(creatorUid), {
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'A', // Miembro A = quien creó el couple.
    });
    await batch.commit();
    return coupleRef.id;
  }

  /// Escribe `users/{creatorUid}.coupleId` para marcar al creador como
  /// ya emparejado. Debe llamarse una sola vez cuando el creador detecta
  /// que su código de invitación fue consumido por la pareja (via
  /// snapshot listener a `invite_codes/{code}`).
  Future<void> finalizeCoupleForCreator({
    required String creatorUid,
    required String coupleId,
  }) {
    return _firestore.collection('users').doc(creatorUid).update({
      'coupleId': coupleId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Genera un código de invitación de 6 dígitos con TTL de 10 minutos.
  /// Reintenta hasta 5 veces si el código generado ya existe.
  Future<String> generateInviteCode(String coupleId) async {
    final rnd = math.Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(6, (_) => rnd.nextInt(10)).join();
      final ref = _firestore.collection('invite_codes').doc(code);
      final doc = await ref.get();
      if (doc.exists) continue; // colisión, reintenta.
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await ref.set({
        'coupleId': coupleId,
        'expiresAtMs': expiresAt.millisecondsSinceEpoch,
        'consumedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    }
    throw StateError('Could not generate a unique invite code');
  }

  /// Une al [joinerUid] al couple asociado al [code]. Falla si:
  /// - El código no existe.
  /// - Expiró (> 10 min desde su creación).
  /// - Ya fue consumido.
  ///
  /// El update del `nameB` en el doc del couple se hace **fuera** de
  /// la transacción, porque las Firestore rules requieren `isMember()`
  /// para escribir en `couples/{coupleId}`, y dentro de la transacción
  /// el joiner aún no cuenta como miembro (las rules ven el snapshot
  /// pre-transaction). Una vez que la transacción termina, el joiner ya
  /// es miembro y el segundo update pasa las rules.
  Future<String> joinCoupleWithCode({
    required String code,
    required String joinerUid,
    required String joinerDisplayName,
  }) async {
    final inviteRef = _firestore.collection('invite_codes').doc(code.trim());
    final coupleId = await _firestore.runTransaction<String>((tx) async {
      final invite = await tx.get(inviteRef);
      if (!invite.exists) {
        throw const _CoupleException('invite_not_found');
      }
      final data = invite.data()!;
      final expiresAtMs = (data['expiresAtMs'] as num?)?.toInt() ?? 0;
      if (expiresAtMs < DateTime.now().millisecondsSinceEpoch) {
        throw const _CoupleException('invite_expired');
      }
      if (data['consumedBy'] != null) {
        throw const _CoupleException('invite_already_used');
      }
      final coupleId = data['coupleId'] as String;
      final coupleRef = _firestore.collection('couples').doc(coupleId);
      // Alta del miembro B.
      tx.set(coupleRef.collection('members').doc(joinerUid), {
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'B',
      });
      // Actualiza el user doc del joiner con el coupleId.
      tx.update(_firestore.collection('users').doc(joinerUid), {
        'coupleId': coupleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Marca el código como consumido.
      tx.update(inviteRef, {
        'consumedBy': joinerUid,
        'consumedAt': FieldValue.serverTimestamp(),
      });
      return coupleId;
    });
    // Ya somos miembro (la transacción confirmó `members/{joinerUid}`).
    // Ahora sí podemos escribir `nameB` en el doc del couple sin que las
    // rules rechacen (isMember ya pasa).
    await _firestore.collection('couples').doc(coupleId).update({
      'nameB': joinerDisplayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return coupleId;
  }

  /// Stream del doc `couples/{coupleId}` (nombres, avatares, aniversario).
  Stream<DocumentSnapshot<Map<String, dynamic>>> coupleStream(String coupleId) {
    return _firestore.collection('couples').doc(coupleId).snapshots();
  }

  /// Actualiza campos parciales del doc del couple. Los que no se pasan
  /// no se tocan.
  Future<void> updateCoupleInfo({
    required String coupleId,
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
    return _firestore.collection('couples').doc(coupleId).update(payload);
  }
}

/// Errores conocidos del flujo de emparejamiento. La UI los traduce
/// con `context.l10n.pair_...` según el `code`.
class _CoupleException implements Exception {
  const _CoupleException(this.code);
  final String code;
  @override
  String toString() => 'CoupleException($code)';
}
