import 'dart:convert';
import 'package:architecture/architecture.dart';
import 'package:feature_collections/feature_collections.dart';
import 'package:feature_collections/src/domain/repositories/collections_repository.dart';
import 'package:feature_collections/src/domain/usecases/import_collections.dart';
import 'package:feature_collections/src/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:shared_contracts/shared_contracts.dart';

import '../../atomic.dart';

class EmptyBookmarkSummariesReader extends BookmarkSummariesReader {
  @override
  Future<Result<List<BookmarkSummary>>> call([
    NoParams param = noParams,
  ]) async => const Ok([]);
}

class FakeCollectionsRepo implements CollectionsRepository {
  final Map<String, Collection> items = {};
  int idCounter = 1;
  int createCalls = 0;

  @override
  Future<Result<List<Collection>>> list() async => Ok(items.values.toList());

  @override
  Future<Result<List<Collection>>> listLocal() async =>
      Ok(items.values.toList());

  @override
  Future<Result<Collection>> get(String id) async {
    final found = items[id];
    if (found == null) return const Err(NotFoundFailure('Not found'));
    return Ok(found);
  }

  @override
  Future<Result<Collection>> create(CollectionInput input) async {
    createCalls++;
    final now = DateTime.utc(2026, 1, 1);
    final id = 'col-${idCounter++}';
    final collection = Collection(
      id: id,
      name: input.name,
      icon: input.icon,
      color: input.color,
      bookmarkIds: List.of(input.bookmarkIds),
      createdAt: now,
      updatedAt: now,
    );
    items[id] = collection;
    return Ok(collection);
  }

  @override
  Future<Result<Collection>> update(String id, CollectionInput input) async {
    final existing = items[id];
    if (existing == null) return const Err(NotFoundFailure('Not found'));
    final updated = Collection(
      id: id,
      name: input.name,
      icon: input.icon,
      color: input.color,
      bookmarkIds: List.of(input.bookmarkIds),
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    items[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<void>> delete(String id) async {
    items.remove(id);
    return const Ok(null);
  }
}

void main() {
  late FakeCollectionsRepo repository;
  late CollectionsImportDelegate delegate;
  late ImportCollectionsUseCase useCase;

  setUp(() {
    repository = FakeCollectionsRepo();
    delegate = CollectionsImportDelegate(
      repository,
      EmptyBookmarkSummariesReader(),
      TestAtomicWriteCoordinator(),
    );
    useCase = ImportCollectionsUseCase(delegate);

    getIt.registerLazySingleton<CollectionsImportDelegate>(() => delegate);
    getIt.registerLazySingleton<ImportCollectionsUseCase>(() => useCase);
  });

  tearDown(getIt.reset);

  Widget createSubject({
    List<int>? bytes,
    String? fileName,
    VoidCallback? onCompleted,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CollectionsImportSheet(
          initialBytes: bytes,
          initialFileName: fileName,
          onImportCompleted: onCompleted,
        ),
      ),
    );
  }

  group('CollectionsImportSheet Widget Tests', () {
    testWidgets('renders initial empty state with file select button', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Import Collections'), findsOneWidget);
      expect(find.text('Select File'), findsOneWidget);
    });

    testWidgets('previews valid rows and commits import successfully', (
      tester,
    ) async {
      const csv = '''
name,icon,color
Work,briefcase,0xFF2196F3
Personal,user,0xFF4CAF50
''';
      final bytes = utf8.encode(csv);
      var completedCalled = false;

      await tester.pumpWidget(
        createSubject(
          bytes: bytes,
          fileName: 'collections.csv',
          onCompleted: () => completedCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Previews valid rows
      expect(find.text('Validation Preview'), findsOneWidget);
      expect(find.text('Valid rows: 2'), findsOneWidget);
      expect(find.text('Invalid rows: 0'), findsOneWidget);

      // Verify duplicate policy options
      expect(find.text('Skip Duplicates'), findsOneWidget);
      expect(find.text('Update Existing'), findsOneWidget);
      expect(find.text('Create New Copies'), findsOneWidget);

      // Tap Commit Import
      await tester.tap(find.text('Commit Import'));
      await tester.pumpAndSettle();

      // Summary is displayed
      expect(find.text('Successfully imported 2 records'), findsOneWidget);
      expect(find.text('Created: 2'), findsOneWidget);
      expect(completedCalled, isTrue);

      // Repository contains the records
      expect(repository.items.length, equals(2));
      expect(repository.items.values.any((c) => c.name == 'Work'), isTrue);
    });

    testWidgets('ignores a repeated commit tap while import is running', (
      tester,
    ) async {
      final bytes = utf8.encode('name,icon\nWork,briefcase');
      var completedCalls = 0;

      await tester.pumpWidget(
        createSubject(
          bytes: bytes,
          fileName: 'collections.csv',
          onCompleted: () => completedCalls++,
        ),
      );
      await tester.pumpAndSettle();

      final commitButton = find.text('Commit Import');
      await tester.tap(commitButton);
      await tester.tap(commitButton);
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(repository.items, hasLength(1));
      expect(completedCalls, 1);
    });

    testWidgets(
      'displays invalid rows notice when rows fail schema validation',
      (tester) async {
        const csv = '''
name,icon
,folder
''';
        final bytes = utf8.encode(csv);

        await tester.pumpWidget(
          createSubject(
            bytes: bytes,
            fileName: 'invalid.csv',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Valid rows: 0'), findsOneWidget);
        expect(find.text('Invalid rows: 1'), findsOneWidget);
      },
    );
  });
}
