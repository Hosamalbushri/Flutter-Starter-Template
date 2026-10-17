import 'package:flutter/widgets.dart';
import 'package:shared_contracts/shared_contracts.dart';

/// Exposes the app-wide [Session] to the widget tree.
///
/// Read it with `SessionScope.of(context)`. Rebuild on session changes with a
/// `ListenableBuilder` listening to the returned [Session].
class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.session,
    required super.child,
  });

  final Session session;

  static Session of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope found in context.');
    return scope!.session;
  }

  /// Returns the nearest session when one is available.
  ///
  /// Useful for reusable previews and isolated widget tests that render
  /// identity-aware chrome without constructing the full authenticated app.
  static Session? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.session;

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      session != oldWidget.session;
}
