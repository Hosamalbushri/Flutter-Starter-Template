import 'package:database/database.dart';

class TestAtomicWriteCoordinator implements AtomicWriteCoordinator {
  TestAtomicWriteCoordinator({this.takeSnapshot, this.restoreSnapshot});

  final Object? Function()? takeSnapshot;
  final void Function(Object? snapshot)? restoreSnapshot;
  bool _active = false;
  final List<void Function()> _operations = [];
  final List<void Function()> _afterCommit = [];
  final List<void Function()> _afterCompletion = [];

  @override
  bool get isActive => _active;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    if (_active) return action();
    _active = true;
    final snapshot = takeSnapshot?.call();
    try {
      final result = await action();
      for (final operation in _operations) {
        operation();
      }
      _active = false;
      for (final callback in _afterCommit) {
        callback();
      }
      return result;
    } on Object {
      restoreSnapshot?.call(snapshot);
      rethrow;
    } finally {
      for (final callback in _afterCompletion) {
        callback();
      }
      _operations.clear();
      _afterCommit.clear();
      _afterCompletion.clear();
      _active = false;
    }
  }

  @override
  void stage({
    required void Function() sync,
    required Future<void> Function() async,
  }) => _operations.add(sync);

  @override
  void afterCommit(void Function() callback) => _afterCommit.add(callback);

  @override
  void afterCompletion(void Function() callback) =>
      _afterCompletion.add(callback);
}
