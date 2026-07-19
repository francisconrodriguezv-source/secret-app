import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/entities.dart';

/// Repositorio de [CalendarEvent] respaldado por Firestore.
///
/// Ubicación: `couples/{coupleId}/events/{eventId}`.
///
/// Serialización de [IconData]: se guarda `codePoint`, `fontFamily` y
/// `fontPackage`. Como todos los iconos usados en la app vienen del
/// pack `MaterialIcons` (font family por default), esto es suficiente
/// para reconstruir el icono en el otro dispositivo.
class EventRepository {
  EventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String coupleId) =>
      _firestore.collection('couples').doc(coupleId).collection('events');

  Stream<List<CalendarEvent>> watch(String coupleId) {
    return _col(coupleId)
        .orderBy('startMs')
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList(growable: false));
  }

  Future<void> add(String coupleId, CalendarEvent event) {
    return _col(coupleId).doc(event.id).set({
      'title': event.title,
      'subtitle': event.subtitle,
      'startMs': event.startDate.millisecondsSinceEpoch,
      'endMs': event.endDate?.millisecondsSinceEpoch,
      'iconCodePoint': event.icon.codePoint,
      'iconFontFamily': event.icon.fontFamily,
      'iconFontPackage': event.icon.fontPackage,
      'iconColor': event.iconColor.toARGB32(),
      'iconBg': event.iconBg.toARGB32(),
      'thumbnailUrl': event.thumbnailUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String coupleId, String eventId) {
    return _col(coupleId).doc(eventId).delete();
  }

  CalendarEvent _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final endMs = (data['endMs'] as num?)?.toInt();
    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(
        (data['startMs'] as num?)?.toInt() ?? 0,
      ),
      endDate: endMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endMs),
      icon: IconData(
        (data['iconCodePoint'] as num?)?.toInt() ?? Icons.event.codePoint,
        fontFamily: data['iconFontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: data['iconFontPackage'] as String?,
      ),
      iconColor: Color((data['iconColor'] as num?)?.toInt() ?? 0xFF000000),
      iconBg: Color((data['iconBg'] as num?)?.toInt() ?? 0xFFEEEEEE),
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
    );
  }
}
