// Smoke test aislado: verifica que el TopAppBar del design system se renderiza
// correctamente y muestra el wordmark "Cozy Love". No monta el HomeShell
// completo porque las Image.network no resuelven en el entorno de test.

import 'package:cozy_love/theme/cozy_theme.dart';
import 'package:cozy_love/widgets/cozy_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CozyTopBar renders wordmark', (WidgetTester tester) async {
    // avatarUrl vacío para forzar el placeholder local (sin llamadas de red).
    await tester.pumpWidget(
      MaterialApp(
        theme: CozyTheme.build(),
        home: const Scaffold(appBar: CozyTopBar(avatarUrl: '')),
      ),
    );
    await tester.pump();

    expect(find.text('Cozy Love'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsWidgets);
  });
}
