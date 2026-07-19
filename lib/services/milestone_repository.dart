import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/entities.dart';

/// Repositorio de [Milestone] respaldado por Firestore.
///
/// Ubicación: `couples/{coupleId}/milestones/{milestoneId}`.
class MilestoneRepository {
  MilestoneRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      _firestore.collection('couples').doc(coupleId).collection('milestones');

  Stream<List<Milestone>> watch(String coupleId) {
    return _col(coupleId)
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList(growable: false));
  }

  Future<void> add(String coupleId, Milestone milestone) {
    return _col(coupleId).doc(milestone.id).set({
      'title': milestone.title,
      'date': milestone.date,
      'iconCodePoint': milestone.icon.codePoint,
      'iconFontFamily': milestone.icon.fontFamily,
      'iconFontPackage': milestone.icon.fontPackage,
      'iconColor': milestone.iconColor.toARGB32(),
      'iconBg': milestone.iconBg.toARGB32(),
      'place': milestone.place,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String coupleId, String milestoneId) {
    return _col(coupleId).doc(milestoneId).delete();
  }

  Milestone _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Milestone(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: data['date'] as String? ?? '',
      icon: IconData(
        (data['iconCodePoint'] as num?)?.toInt() ?? Icons.favorite.codePoint,
        fontFamily: data['iconFontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: data['iconFontPackage'] as String?,
      ),
      iconColor: Color((data['iconColor'] as num?)?.toInt() ?? 0xFF000000),
      iconBg: Color((data['iconBg'] as num?)?.toInt() ?? 0xFFEEEEEE),
      place: data['place'] as String?,
    );
  }
}
