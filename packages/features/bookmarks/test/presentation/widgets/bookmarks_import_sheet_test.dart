import 'dart:convert';
import 'package:architecture/architecture.dart';
import 'package:feature_bookmarks/feature_bookmarks.dart';
import 'package:feature_bookmarks/src/domain/repositories/bookmarks_repository.dart';
import 'package:feature_bookmarks/src/domain/usecases/import_bookmarks.dart';
import 'package:feature_bookmarks/src/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

import '../../atomic.dart';

class FakeBookmarksRepo implements BookmarksRepository {
  final Map<String, Bookmark> items = {};
  int idCounter = 1;
  int createCalls = 0;

  @override
  Future<Result<List<Bookmark>>> list() async => Ok(items.values.toList());

  @override
  Future<Result<List<Bookmark>>> listLocal() async => Ok(items.values.toList());

  @override
  Future<Result<Bookmark>> get(String id) async {
    final found = items[id];
    if (found == null) return const Err(NotFoundFailure('Not found'));
    return Ok(found);
  }

  @override
  Future<Result<Bookmark>> create(BookmarkInput input) async {
    createCalls++;
    final now = DateTime.utc(2026, 1, 1);
    final id = 'bm-${idCounter++}';
    final bookmark = Bookmark(
      id: id,
      title: input.title,
      url: input.url,
      description: input.description,
      tags: List.of(input.tags),
      imageUrls: List.of(input.imageUrls),
      videoUrl: input.videoUrl,
      createdAt: now,
      updatedAt: now,
    );
    items[id] = bookmark;
    return Ok(bookmark);
  }

  @override
  Future<Result<Bookmark>> update(String id, BookmarkInput input) async {
    final existing = items[id];
    if (existing == null) return const Err(NotFoundFailure('Not found'));
    final updated = Bookmark(
      id: id,
      title: input.title,
      url: input.url,
      description: input.description,
      tags: List.of(input.tags),
      imageUrls: List.of(input.imageUrls),
      videoUrl: input.videoUrl,
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
  late FakeBookmarksRepo repository;
  late BookmarksImportDelegate delegate;
  late ImportBookmarksUseCase useCase;

  setUp(() {
    repository = FakeBookmarksRepo();
    delegate = BookmarksImportDelegate(
      repository,
      TestAtomicWriteCoordinator(),
    );
    useCase = ImportBookmarksUseCase(delegate);

    getIt.registerLazySingleton<BookmarksImportDelegate>(() => delegate);
    getIt.registerLazySingleton<ImportBookmarksUseCase>(() => useCase);
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
        body: BookmarksImportSheet(
          initialBytes: bytes,
          initialFileName: fileName,
          onImportCompleted: onCompleted,
        ),
      ),
    );
  }

  group('BookmarksImportSheet Widget Tests', () {
    testWidgets('renders initial empty state with file select button', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Import Bookmarks'), findsOneWidget);
      expect(find.text('Select File'), findsOneWidget);
    });

    testWidgets('previews valid rows and commits import successfully', (
      tester,
    ) async {
      const csv = '''
title,url,tags
Flutter Dev,https://flutter.dev,dart
Dart Dev,https://dart.dev,cli
''';
      final bytes = utf8.encode(csv);
      var completedCalled = false;

      await tester.pumpWidget(
        createSubject(
          bytes: bytes,
          fileName: 'bookmarks.csv',
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
      expect(
        repository.items.values.any((b) => b.title == 'Flutter Dev'),
        isTrue,
      );
    });

    testWidgets('ignores a repeated commit tap while import is running', (
      tester,
    ) async {
      final bytes = utf8.encode('title,url\nOne,https://example.com/one');
      var completedCalls = 0;

      await tester.pumpWidget(
        createSubject(
          bytes: bytes,
          fileName: 'bookmarks.csv',
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
title,url
,https://missing-title.com
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
