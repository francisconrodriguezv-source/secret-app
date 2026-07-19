import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/auth/auth_gate.dart';
import 'l10n/app_strings.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/cozy_colors.dart';
import 'theme/cozy_theme.dart';

class CozyLoveApp extends StatefulWidget {
  const CozyLoveApp({super.key});

  @override
  State<CozyLoveApp> createState() => _CozyLoveAppState();
}

class _CozyLoveAppState extends State<CozyLoveApp> {
  late final AppState _state;
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _bootstrap = _state.bootstrap();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          // Convierte el `AppLocale` seleccionado en `Locale` para
          // propagar la traducción de los pickers nativos (fecha/hora).
          final locale = _state.locale == AppLocale.es
              ? const Locale('es')
              : const Locale('en');
          return MaterialApp(
            title: 'Tandem',
            debugShowCheckedModeBanner: false,
            theme: CozyTheme.build(),
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FutureBuilder<void>(
              future: _bootstrap,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _SplashScreen();
                }
                // Con Firebase, el flujo de auth + emparejamiento se
                // encarga de todo lo que antes hacía el onboarding local
                // (nombres, avatar, fecha, hitos se editan desde el
                // perfil una vez emparejados).
                return const AuthGate();
              },
            ),
          );
        },
      ),
    );
  }
}

/// Splash mientras bootstrap termina de leer prefs.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CozyColors.primaryContainer,
                CozyColors.secondaryContainer,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite,
            size: 48,
            color: CozyColors.primary,
          ),
        ),
      ),
    );
  }
}
