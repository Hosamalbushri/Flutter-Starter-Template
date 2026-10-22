import 'dart:async';

import '../objectbox.g.dart';

/// Coordinates a staged unit of work and commits it in one native database
/// transaction. Nested calls join the current unit; independent calls are
/// serialized so read-modify-write operations cannot overtake one another.
abstract interface class AtomicWriteCoordinator {
  bool get isActive;

  Future<T> run<T>(Future<T> Function() action);

  void stage({
    required void Function() sync,
    required Future<void> Function() async,
  });

  void afterCommit(void Function() callback);

  void afterCompletion(void Function() callback);
}

class ObjectBoxAtomicWriteCoordinator implements AtomicWriteCoordinator {
  ObjectBoxAtomicWriteCoordinator(
    Store store, {
    void Function(void Function())? transactionRunner,
  }) : _transactionRunner =
           transactionRunner ??
           ((action) => store.runInTransaction(TxMode.write, action));

  final void Function(void Function()) _transactionRunner;
  final Object _zoneKey = Object();
  Future<void> _tail = Future<void>.value();

  _WriteContext? get _context => Zone.current[_zoneKey] as _WriteContext?;

  @override
  bool get isActive {
    final context = _context;
    return context != null && !context.committed;
  }

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    if (isActive) return action();

    final previous = _tail;
    final released = Completer<void>();
    _tail = released.future;
    await previous;

    final context = _WriteContext();
    try {
      final result = await runZoned(
        action,
        zoneValues: <Object, Object>{_zoneKey: context},
      );
      Object? writeError;
      StackTrace? writeStack;
      try {
        _transactionRunner(() {
          for (final operation in context.operations) {
            try {
              operation.sync();
            } on Object catch (error, stackTrace) {
              writeError = error;
              writeStack = stackTrace;
              rethrow;
            }
          }
        });
      } on Object {
        final error = writeError;
        if (error != null) {
          Error.throwWithStackTrace(error, writeStack!);
        }
        rethrow;
      }
      context.committed = true;
      for (final callback in context.afterCommit) {
        callback();
      }
      return result;
    } finally {
      for (final callback in context.afterCompletion) {
        try {
          callback();
        } on Object {
          // Completion hooks only discard in-memory staging state. They must
          // never replace the write/action error being propagated.
        }
      }
      released.complete();
    }
  }

  @override
  void stage({
    required void Function() sync,
    required Future<void> Function() async,
  }) {
    final context = _context;
    if (context == null || context.committed) {
      throw StateError('A database write must be staged inside run().');
    }
    context.operations.add((sync: sync, async: async));
  }

  @override
  void afterCommit(void Function() callback) {
    final context = _context;
    if (context == null) {
      callback();
      return;
    }
    context.afterCommit.add(callback);
  }

  @override
  void afterCompletion(void Function() callback) {
    final context = _context;
    if (context == null) {
      callback();
      return;
    }
    context.afterCompletion.add(callback);
  }
}

typedef _StagedOperation = ({
  void Function() sync,
  Future<void> Function() async,
});

class _WriteContext {
  bool committed = false;
  final List<_StagedOperation> operations = [];
  final List<void Function()> afterCommit = [];
  final List<void Function()> afterCompletion = [];
}
