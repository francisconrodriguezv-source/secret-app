import 'package:flutter/material.dart';

import 'app_state.dart';

/// Scope raíz que expone [AppState] a toda la app y hace rebuild
/// automáticamente a los widgets descendientes que dependan de él.
///
/// Uso:
/// - Wrap la app en [AppScope] (una sola vez en `app.dart`).
/// - En cualquier widget: `AppScope.of(context)` para leer el state y
///   suscribirse a cambios; `AppScope.read(context)` para solo leer sin
///   suscribirse (ideal desde callbacks).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Obtiene el [AppState] y suscribe el widget al notifier.
  /// El widget que lo llame se reconstruirá cuando el state cambie.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Obtiene el [AppState] sin suscribirse (ideal para callbacks).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
