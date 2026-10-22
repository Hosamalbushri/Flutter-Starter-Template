import 'dart:async';

import 'package:injectable/injectable.dart';

/// Broadcasts a genuine server-side session rejection to the application.
///
/// The notifier deliberately lives in the network package: token refresh can
/// report expiration without depending on the authentication feature. A
/// termination generation is emitted at most once until [reset] is called by
/// a successful refresh or sign-in.
@lazySingleton
class SessionTerminationNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast(
    sync: true,
  );
  bool _terminated = false;

  Stream<void> get terminations => _controller.stream;

  bool get isTerminated => _terminated;

  void notifyTerminated() {
    if (_terminated) return;
    _terminated = true;
    _controller.add(null);
  }

  void reset() => _terminated = false;
}
