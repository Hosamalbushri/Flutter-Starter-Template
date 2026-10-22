import '../failure/document_failure.dart';

/// Token used to request cooperative cancellation of document processing operations.
class CancellationToken {
  bool _isCancelled = false;
  String? _cancelReason;
  final List<void Function()> _listeners = [];

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Optional reason provided when cancelled.
  String? get cancelReason => _cancelReason;

  /// Requests cancellation.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _cancelReason = reason;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Throws [DocumentCancellationFailure] if cancellation was requested.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw DocumentCancellationFailure(
        _cancelReason ?? 'The operation was cancelled by the user',
      );
    }
  }

  /// Registers a callback to be invoked when cancellation is requested.
  void onCancelled(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }
}
