import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/entities.dart';

/// Repositorio de [StickyNote] respaldado por Firestore.
///
/// Ubicación: `couples/{coupleId}/notes/{noteId}`.
///
/// Serialización de colores: [Color.toARGB32] → int. En el reverso
/// reconstruimos con `Color(int)`. `createdAt` viaja como milliseconds.
class NoteRepository {
  NoteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      _firestore.collection('couples').doc(coupleId).collection('notes');

  Stream<List<StickyNote>> watch(String coupleId) {
    return _col(coupleId)
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList(growable: false));
  }

  Future<void> add(
    String coupleId, {
    required StickyNote note,
    required String authorUid,
  }) {
    return _col(coupleId).doc(note.id).set({
      'authorId': authorUid,
      'author': note.author,
      'text': note.text,
      'timestamp': note.timestamp,
      'color': note.color.toARGB32(),
      'avatarBg': note.avatarBg.toARGB32(),
      'avatarFg': note.avatarFg.toARGB32(),
      'tilt': note.tilt,
      'createdAtMs': note.createdAt.millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String coupleId, String noteId) {
    return _col(coupleId).doc(noteId).delete();
  }

  StickyNote _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return StickyNote(
      id: doc.id,
      text: data['text'] as String? ?? '',
      color: Color((data['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      timestamp: data['timestamp'] as String? ?? '',
      author: data['author'] as String? ?? '',
      avatarBg: Color((data['avatarBg'] as num?)?.toInt() ?? 0xFFEEEEEE),
      avatarFg: Color((data['avatarFg'] as num?)?.toInt() ?? 0xFF000000),
      tilt: (data['tilt'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAtMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
