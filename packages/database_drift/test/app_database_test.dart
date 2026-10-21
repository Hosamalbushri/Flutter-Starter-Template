// Guards the database's opening contract: a fresh install must land on the
// schema the generated bindings expect, and every connection must enforce
// foreign keys. Both are silent failures otherwise — a drifted schema only
// surfaces as a query error in production, and SQLite happily ignores foreign
// keys when the pragma is left at its default.

import 'package:database_drift/database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a fresh database matches the schema drift generated', () async {
    // Fails if a table was edited without regenerating the bindings, or if a
    // hand-written migration step drifted from the table definitions.
    await db.validateDatabaseSchema();
  });

  test('foreign key enforcement is on for the connection', () async {
    final result = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(result.data.values.first, 1);
  });

  // fst:feature:bookmarks:start
  test(
    'atomic coordinator rolls back earlier writes when commit fails',
    () async {
      final atomic = DriftAtomicWriteCoordinator(db);
      final now = DateTime.utc(2026).microsecondsSinceEpoch;
      BookmarksCompanion row(String uuid) => BookmarksCompanion.insert(
        uuid: uuid,
        title: uuid,
        url: 'https://example.com/$uuid',
        description: '',
        createdAtUs: now,
        updatedAtUs: now,
      );

      await expectLater(
        atomic.run(() async {
          atomic
            ..stage(
              sync: () => throw UnsupportedError('async only'),
              async: () async => db.into(db.bookmarks).insert(row('duplicate')),
            )
            ..stage(
              sync: () => throw UnsupportedError('async only'),
              async: () async => db.into(db.bookmarks).insert(row('duplicate')),
            );
        }),
        throwsA(anything),
      );

      expect(await db.select(db.bookmarks).get(), isEmpty);
    },
  );

  test(
    'failed atomic batch is retryable and sync callback waits for commit',
    () async {
      final atomic = DriftAtomicWriteCoordinator(db);
      var afterCommitCalls = 0;

      await expectLater(
        atomic.run(() async {
          atomic
            ..afterCommit(() => afterCommitCalls++)
            ..stage(
              sync: () => throw UnsupportedError('async only'),
              async: () async => throw StateError('injected write failure'),
            );
        }),
        throwsStateError,
      );
      expect(afterCommitCalls, 0);

      final now = DateTime.utc(2026).microsecondsSinceEpoch;
      await atomic.run(() async {
        atomic
          ..stage(
            sync: () => throw UnsupportedError('async only'),
            async: () async {
              await db
                  .into(db.bookmarks)
                  .insert(
                    BookmarksCompanion.insert(
                      uuid: 'retry',
                      title: 'Retry',
                      url: 'https://example.com/retry',
                      description: '',
                      createdAtUs: now,
                      updatedAtUs: now,
                    ),
                  );
            },
          )
          ..afterCommit(() => afterCommitCalls++);
      });

      expect(afterCommitCalls, 1);
      expect(await db.select(db.bookmarks).get(), hasLength(1));
    },
  );

  test('an interruption before commit leaves no staged rows', () async {
    final atomic = DriftAtomicWriteCoordinator(db);
    final now = DateTime.utc(2026).microsecondsSinceEpoch;

    await expectLater(
      atomic.run(() async {
        atomic.stage(
          sync: () => throw UnsupportedError('async only'),
          async: () async {
            await db
                .into(db.bookmarks)
                .insert(
                  BookmarksCompanion.insert(
                    uuid: 'interrupted',
                    title: 'Interrupted',
                    url: 'https://example.com/interrupted',
                    description: '',
                    createdAtUs: now,
                    updatedAtUs: now,
                  ),
                );
          },
        );
        throw StateError('simulated import interruption');
      }),
      throwsStateError,
    );

    expect(await db.select(db.bookmarks).get(), isEmpty);
  });

  test('nested units join the ambient transaction without deadlock', () async {
    final atomic = DriftAtomicWriteCoordinator(db);
    final now = DateTime.utc(2026).microsecondsSinceEpoch;
    await atomic
        .run(() async {
          await atomic.run(() async {
            atomic.stage(
              sync: () => throw UnsupportedError('async only'),
              async: () async {
                await db
                    .into(db.bookmarks)
                    .insert(
                      BookmarksCompanion.insert(
                        uuid: 'nested',
                        title: 'Nested',
                        url: 'https://example.com/nested',
                        description: '',
                        createdAtUs: now,
                        updatedAtUs: now,
                      ),
                    );
              },
            );
          });
        })
        .timeout(const Duration(seconds: 2));

    expect(await db.select(db.bookmarks).get(), hasLength(1));
  });
  // fst:feature:bookmarks:end

  test('completion failure cannot hide the original write error', () async {
    final atomic = DriftAtomicWriteCoordinator(db);
    await expectLater(
      atomic.run(() async {
        atomic
          ..stage(
            sync: () => throw UnsupportedError('async only'),
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
    final atomic = DriftAtomicWriteCoordinator(
      db,
      transactionRunner: (action) async {
        try {
          await action();
        } on Object {
          throw StateError('injected rollback failure');
        }
      },
    );

    await expectLater(
      atomic.run(() async {
        atomic.stage(
          sync: () => throw UnsupportedError('async only'),
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
