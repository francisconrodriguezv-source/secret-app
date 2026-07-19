import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Servicio de autenticación (Email/Password) construido sobre Firebase Auth.
///
/// - [currentUser] devuelve el usuario auth actual, o `null` si no hay
///   sesión.
/// - [authStateChanges] es un stream que emite cada vez que el usuario
///   hace login/logout. La `AuthGate` de la app lo consume para decidir
///   qué pantalla mostrar.
/// - Los métodos [signUpWithEmail] y [signInWithEmail] devuelven el
///   [AppUser] recién creado / recuperado.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream del perfil `AppUser` del usuario logueado. Emite `null` si
  /// no hay sesión. Si hay sesión pero el doc `users/{uid}` no existe
  /// todavía (race durante signup, o creado antes de que agregaramos la
  /// colección), sintetiza un [AppUser] con los datos que ya tenemos de
  /// Firebase Auth. Así el [AuthGate] avanza inmediatamente a
  /// `PairCoupleScreen` sin quedarse mostrando LoginScreen.
  Stream<AppUser?> get appUserStream {
    return authStateChanges.asyncExpand((user) {
      if (user == null) return Stream.value(null);
      final synthetic = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : synthetic);
    });
  }

  /// Crea la cuenta en Firebase Auth y el doc `users/{uid}` en Firestore.
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // IMPORTANTE: crear el doc en Firestore ANTES que otras llamadas
    // async, porque `authStateChanges` ya emitió al usuario y
    // `appUserStream` empieza a mirar `users/{uid}` de inmediato. Si
    // esperamos otra red-trip primero, hay una ventana donde el stream
    // emite el `synthetic` (que está bien) pero preferimos ir directo
    // al canonical.
    final user = AppUser(
      uid: uid,
      email: email.trim(),
      displayName: displayName.trim(),
    );
    await _firestore.collection('users').doc(uid).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Cosmético: setea displayName en Firebase Auth para que el
    // dashboard de la consola también lo muestre. No bloquea el flujo.
    unawaited(cred.user!.updateDisplayName(displayName.trim()));

    return user;
  }

  /// Inicia sesión con email + contraseña.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return AppUser.fromFirestore(doc);
    // Si el doc no existe (usuario creado antes de que agregáramos la
    // colección), lo creamos ahora con lo mínimo.
    final user = AppUser(
      uid: uid,
      email: email.trim(),
      displayName: cred.user!.displayName ?? '',
    );
    await _firestore.collection('users').doc(uid).set({
      ...user.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
