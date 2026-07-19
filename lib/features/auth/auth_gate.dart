import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/cozy_colors.dart';
import '../home_shell.dart';
import 'auth_screens.dart';
import 'pair_couple_screen.dart';

/// Router raíz que decide qué pantalla mostrar según el estado de auth
/// y de emparejamiento (couple) del usuario:
///
/// - Sin sesión iniciada  → [LoginScreen] (con link a [SignUpScreen]).
/// - Sesión iniciada pero sin `coupleId` → [PairCoupleScreen].
/// - Sesión con couple    → [HomeShell] (la app completa).
///
/// Nota: `users/{uid}.coupleId` sólo se escribe cuando el couple ya
/// tiene 2 miembros (el join, o el consumo del código de invitación
/// visto desde el creador). Mientras el creador espera a su pareja, su
/// `coupleId` sigue null y por eso permanece en [PairCoupleScreen]
/// mostrando/regenerando el código sin que el árbol de widgets se
/// reconstruya y pierda estado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authService});

  /// Permite inyectar un mock en tests. En prod usamos la instancia
  /// singleton default de [AuthService].
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();
    return StreamBuilder<AppUser?>(
      stream: auth.appUserStream,
      builder: (context, snapshot) {
        // Mientras Firebase resuelve el estado inicial (~1 frame).
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthSplash();
        }
        final appUser = snapshot.data;
        if (appUser == null) {
          return const LoginScreen();
        }
        if (!appUser.hasCouple) {
          return PairCoupleScreen(appUser: appUser);
        }
        // Autenticado + emparejado → HomeShell.
        return HomeShell(appUser: appUser);
      },
    );
  }
}

/// Splash local del AuthGate (distinto del splash de bootstrap del
/// [AppState]). Aparece durante el primer frame de resolución del stream
/// de Firebase.
class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CozyColors.primaryContainer,
                CozyColors.secondaryContainer,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.favorite,
            color: CozyColors.primary,
            size: 36,
          ),
        ),
      ),
    );
  }
}
