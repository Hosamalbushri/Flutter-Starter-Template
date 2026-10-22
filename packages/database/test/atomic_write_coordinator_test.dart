import 'dart:async';
import 'dart:io';

import 'package:database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rev_sync/rev_sync.dart';

void main() {
  late Directory directory;
  late Store store;
  late ObjectBoxAtomicWriteCoordinator atomic;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fst-objectbox-atomic-');
    store = await openStore(directory: directory.path);
    atomic = ObjectBoxAtomicWriteCoordinator(store);
  });

  tearDown(() async {
    store.close();
    await directory.delete(recursive: true);
  });

  BookmarkEntity bookmark(String uuid) {
    final now = DateTime.utc(2026);
    return BookmarkEntity(
      uuid: uuid,
      title: uuid,
      url: 'https://example.com/$uuid',
      description: '',
      tags: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  test(
    'rolls back every staged row when commit fails after an earlier put',
    () async {
      final box = store.box<BookmarkEntity>();
      final first = bookmark('duplicate');
      final second = bookmark('duplicate');

      await expectLater(
        atomic.run(() async {
          atomic
            ..stage(
              sync: () => box.put(first),
              async: () async => box.put(first),
            )
            ..stage(
              sync: () => box.put(second),
              async: () async => box.put(second),
            );
        }),
        throwsA(isA<UniqueViolationException>()),
      );

      expect(box.count(), 0);
    },
  );

  test('an aborted batch can be retried successfully', () async {
    final box = store.box<BookmarkEntity>();
    await expectLater(
      atomic.run(() async {
        atomic.stage(
          sync: () => throw StateError('injected failure'),
          async: () async => throw StateError('injected failure'),
        );
      }),
      throwsStateError,
    );

    await atomic.run(() async {
      final entity = bookmark('retry');
      atomic.stage(
        sync: () => box.put(entity),
        async: () async => box.put(entity),
      );
    });

    expect(box.count(), 1);
  });

  test('an interruption before commit leaves no staged rows', () async {
    final box = store.box<BookmarkEntity>();

    await expectLater(
      atomic.run(() async {
        final entity = bookmark('interrupted');
        atomic.stage(
          sync: () => box.put(entity),
          async: () async => box.put(entity),
        );
        throw StateError('simulated import interruption');
      }),
      throwsStateError,
    );

    expect(box.count(), 0);
  });

  test('serializes concurrent read-modify-write transactions', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final order = <String>[];

    final first = atomic.run(() async {
      order.add('first-start');
      entered.complete();
      await release.future;
      order.add('first-end');
    });
    await entered.future;
    final second = atomic.run(() async => order.add('second'));
    await Future<void>.delayed(Duration.zero);
    expect(order, ['first-start']);

    release.complete();
    await Future.wait([first, second]);
    expect(order, ['first-start', 'first-end', 'second']);
  });

  test('nested units join the ambient transaction without deadlock', () async {
    final box = store.box<BookmarkEntity>();
    await atomic
        .run(() async {
          await atomic.run(() async {
            final entity = bookmark('nested');
            atomic.stage(
              sync: () => box.put(entity),
              async: () async => box.put(entity),
            );
          });
        })
        .timeout(const Duration(seconds: 2));

    expect(box.count(), 1);
  });

  test('pending sync state survives a database restart after commit', () async {
    final path = directory.path;
    final entity = bookmark('restart')..syncState = SyncState.pendingCreate;
    await atomic.run(() async {
      atomic.stage(
        sync: () => store.box<BookmarkEntity>().put(entity),
        async: () async => store.box<BookmarkEntity>().put(entity),
      );
    });

    store.close();
    store = await openStore(directory: path);
    atomic = ObjectBoxAtomicWriteCoordinator(store);

    final restored = store.box<BookmarkEntity>().getAll().single;
    expect(restored.syncState, SyncState.pendingCreate);
    expect(restored.syncState.isPending, isTrue);
  });

  test('completion failure cannot hide the original write error', () async {
    await expectLater(
      atomic.run(() async {
        atomic
          ..stage(
            sync: () => throw StateError('original write failure'),
            async: () async => throw StateError('original write failure'),
          )
          ..afterCompletion(() => throw StateError('cleanup failure'));
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'original write failure',
        ),
      ),
    );
  });

  test('rollback failure cannot hide the original write error', () async {
    final rollbackFailingAtomic = ObjectBoxAtomicWriteCoordinator(
      store,
      transactionRunner: (action) {
        try {
          action();
        } on Object {
          throw StateError('injected rollback failure');
        }
      },
    );

    await expectLater(
      rollbackFailingAtomic.run(() async {
        rollbackFailingAtomic.stage(
          sync: () => throw StateError('original write failure'),
          async: () async => throw StateError('original write failure'),
        );
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'original write failure',
        ),
      ),
    );
  });
}
