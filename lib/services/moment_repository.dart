import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/entities.dart';
import 'storage_service.dart';

/// Repositorio de [Moment] respaldado por Firestore.
///
/// Ubicación en Firestore: `couples/{coupleId}/moments/{momentId}`.
///
/// El campo `likedBy` es un array de `uid`s (Set semántico). El getter
/// `likedByMe` del modelo se computa localmente comparando con el `uid`
/// del usuario actual. `likes` es simplemente `likedBy.length`.
///
/// Fotos: si el `Moment.imageUrl` es una **ruta local** (no comienza
/// por `http`), se sube a Firebase Storage antes de escribir el doc.
/// El campo `imageUrl` que se persiste es siempre una URL HTTPS que
/// ambos dispositivos del couple pueden cargar.
class MomentRepository {
  MomentRepository({FirebaseFirestore? firestore, StorageService? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      _firestore.collection('couples').doc(coupleId).collection('moments');

  /// Stream de todos los moments del couple, ordenados por fecha (más
  /// recientes primero). El `likedByMe` de cada `Moment` se computa
  /// contra [currentUid].
  Stream<List<Moment>> watch(String coupleId, {required String currentUid}) {
    return _col(coupleId)
        .orderBy('dateMs', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => _fromDoc(d, currentUid))
              .toList(growable: false),
        );
  }

  /// Escribe un moment al couple. Usa el `moment.id` como docId para
  /// que la UI local pueda referenciarlo (delete, toggleLike) con el
  /// mismo id sin esperar el round-trip.
  ///
  /// Si `moment.imageUrl` es una ruta local (no HTTP), primero sube el
  /// archivo a Firebase Storage y persiste la URL de descarga.
  Future<void> add(
    String coupleId, {
    required Moment moment,
    required String authorUid,
  }) async {
    var imageUrl = moment.imageUrl;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = await _storage.uploadMomentPhoto(
        coupleId: coupleId,
        momentId: moment.id,
        localPath: imageUrl,
      );
    }
    await _col(coupleId).doc(moment.id).set({
      'kind': moment.kind == MomentKind.photo ? 'photo' : 'note',
      'dateMs': moment.date.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'caption': moment.caption,
      'quote': moment.quote,
      'tags': moment.tags,
      'aspectRatio': moment.aspectRatio,
      'authorId': authorUid,
      'authorName': moment.author ?? '',
      'likedBy': const <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String coupleId, String momentId) {
    return _col(coupleId).doc(momentId).delete();
  }

  /// Agrega o quita el `uid` del array `likedBy`. Usa operaciones
  /// atómicas de Firestore (`arrayUnion` / `arrayRemove`) para evitar
  /// race conditions entre los dos miembros dándose like a la vez.
  Future<void> toggleLike(
    String coupleId,
    String momentId, {
    required String uid,
    required bool nowLiked,
  }) {
    return _col(coupleId).doc(momentId).update({
      'likedBy': nowLiked
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  Moment _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUid,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final kindStr = data['kind'] as String? ?? 'note';
    final kind = kindStr == 'photo' ? MomentKind.photo : MomentKind.note;
    final likedByList = ((data['likedBy'] as List<dynamic>?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final rawAuthorName = data['authorName'] as String?;
    return Moment(
      id: doc.id,
      kind: kind,
      date: DateTime.fromMillisecondsSinceEpoch(
        (data['dateMs'] as num?)?.toInt() ?? 0,
      ),
      imageUrl: data['imageUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      quote: data['quote'] as String? ?? '',
      tags: ((data['tags'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      likes: likedByList.length,
      likedByMe: likedByList.contains(currentUid),
      aspectRatio: (data['aspectRatio'] as num?)?.toDouble() ?? (4 / 3),
      author: (rawAuthorName != null && rawAuthorName.isNotEmpty)
          ? rawAuthorName
          : null,
    );
  }
}
