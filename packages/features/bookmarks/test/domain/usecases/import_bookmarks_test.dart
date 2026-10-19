import 'dart:convert';
import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:feature_bookmarks/feature_bookmarks.dart';
import 'package:feature_bookmarks/src/domain/repositories/bookmarks_repository.dart';
import 'package:feature_bookmarks/src/domain/usecases/import_bookmarks.dart';
import 'package:feature_collections/feature_collections.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBookmarksRepository implements BookmarksRepository {
  final Map<String, Bookmark> items = {};
  int idCounter = 1;
  bool shouldFailCreate = false;
  bool shouldFailListLocal = false;
  void Function()? afterCreate;

  @override
  Future<Result<List<Bookmark>>> list() async => Ok(items.values.toList());

  @override
  Future<Result<List<Bookmark>>> listLocal() async {
    if (shouldFailListLocal) {
      return const Err(UnknownFailure('Bookmark read failed'));
    }
    return Ok(items.values.toList());
  }

  @override
  Future<Result<Bookmark>> get(String id) async {
    final found = items[id];
    if (found == null) return const Err(NotFoundFailure('Not found'));
    return Ok(found);
  }

  @override
  Future<Result<Bookmark>> create(BookmarkInput input) async {
    if (shouldFailCreate) {
      return const Err(UnknownFailure('Bookmark save failed'));
    }
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
    afterCreate?.call();
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

class FakeCollectionsMembershipService implements CollectionsMembershipService {
  final Map<String, Collection> items = {};
  int idCounter = 1;
  bool shouldFailAdd = false;

  @override
  void beginImportBatch() {}

  @override
  void endImportBatch({required bool successful}) {}

  @override
  Future<Result<List<Collection>>> listCollections() async =>
      Ok(items.values.toList());

  @override
  Future<Result<Collection>> findOrCreate(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Collection name cannot be empty.'));
    }
    final normalized = trimmed.toLowerCase();
    for (final c in items.values) {
      if (c.name.trim().toLowerCase() == normalized) {
        return Ok(c);
      }
    }
    final now = DateTime.utc(2026, 1, 1);
    final id = 'col-${idCounter++}';
    final col = Collection(
      id: id,
      name: trimmed,
      icon: 'folder',
      color: 0xFF2196F3,
      bookmarkIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    items[id] = col;
    return Ok(col);
  }

  @override
  Future<Result<CollectionImportResolution>> resolveForImport(
    String name,
  ) async {
    final existingIds = items.keys.toSet();
    final result = await findOrCreate(name);
    return switch (result) {
      Ok(value: final collection) => Ok(
        CollectionImportResolution(
          collection: collection,
          wasCreated: !existingIds.contains(collection.id),
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<Collection>> addBookmark(
    String collectionId,
    String bookmarkId,
  ) async {
    if (shouldFailAdd) {
      return const Err(UnknownFailure('Collection link failed'));
    }
    final col = items[collectionId];
    if (col == null) return const Err(NotFoundFailure('Not found'));
    if (col.bookmarkIds.contains(bookmarkId)) return Ok(col);
    final updated = Collection(
      id: col.id,
      name: col.name,
      icon: col.icon,
      color: col.color,
      bookmarkIds: [...col.bookmarkIds, bookmarkId],
      createdAt: col.createdAt,
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    items[collectionId] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<Collection>> restoreForImport(Collection original) async {
    items[original.id] = original;
    return Ok(original);
  }

  @override
  Future<Result<void>> deleteForImport(String collectionId) async {
    items.remove(collectionId);
    return const Ok(null);
  }
}

void main() {
  late FakeBookmarksRepository bookmarksRepo;
  late FakeCollectionsMembershipService collectionsService;
  late BookmarksImportDelegate delegate;
  late ImportBookmarksUseCase useCase;

  setUp(() {
    bookmarksRepo = FakeBookmarksRepository();
    collectionsService = FakeCollectionsMembershipService();
    delegate = BookmarksImportDelegate(bookmarksRepo, collectionsService);
    useCase = ImportBookmarksUseCase(delegate);
  });

  group('Bookmarks Import & Relationship Integration', () {
    test('imports bookmarks without collections from CSV', () async {
      const csv = '''
title,url,description,tags
Flutter Official,https://flutter.dev,Fast apps,"dart,flutter"
Dart Lang,https://dart.dev,Client-optimized language,"dart"
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(
          bytes: bytes,
          format: 'csv',
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(2));
      expect(report.importedCount, equals(2));
      expect(report.createdIds.length, equals(2));

      final all = (await bookmarksRepo.listLocal() as Ok<List<Bookmark>>).value;
      expect(all.length, equals(2));
      expect(all[0].title, equals('Flutter Official'));
      expect(all[0].tags, equals(['dart', 'flutter']));
    });

    test('imports bookmarks and assigns to existing collection', () async {
      // Pre-seed collection
      final seededCol =
          (await collectionsService.findOrCreate(
                    'Mobile Development',
                  )
                  as Ok<Collection>)
              .value;

      const csv = '''
title,url,collection
Flutter Architecture,https://flutter.dev/arch,Mobile Development
Dart Concurrency,https://dart.dev/concurrency,Mobile Development
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(
          bytes: bytes,
          format: 'csv',
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, equals(2));

      // Verify relationship integrity in collection
      final col = collectionsService.items[seededCol.id]!;
      expect(col.bookmarkIds.length, equals(2));
      expect(col.bookmarkIds, containsAll(report.createdIds));
    });

    test('auto-creates missing collection when importing bookmarks', () async {
      const csv = '''
title,url,collection
VueJS Docs,https://vuejs.org,Frontend Frameworks
React Docs,https://react.dev,Frontend Frameworks
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(
          bytes: bytes,
          format: 'csv',
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, equals(2));

      // Verify collection was created and bookmarks assigned
      final cols = collectionsService.items.values.toList();
      expect(cols.length, equals(1));
      expect(cols.first.name, equals('Frontend Frameworks'));
      expect(cols.first.bookmarkIds.length, equals(2));
      expect(cols.first.bookmarkIds, containsAll(report.createdIds));
    });

    test('handles duplicate bookmarks with skip policy', () async {
      // Pre-seed bookmark
      await bookmarksRepo.create(
        const BookmarkInput(
          title: 'Google',
          url: 'https://google.com',
          description: 'Search engine',
          tags: ['search'],
        ),
      );

      const csv = '''
title,url,description
Google New,https://google.com,Different description
DuckDuckGo,https://duckduckgo.com,Privacy search
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(
          bytes: bytes,
          format: 'csv',
          duplicatePolicy: DuplicatePolicy.skip,
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(2));
      expect(report.duplicateCount, equals(1));
      expect(report.importedCount, equals(1)); // only DuckDuckGo

      final all = (await bookmarksRepo.listLocal() as Ok<List<Bookmark>>).value;
      expect(all.length, equals(2));
      final google = all.firstWhere((b) => b.url == 'https://google.com');
      expect(google.title, equals('Google')); // unchanged
    });

    test(
      'updates bookmark metadata and merges tags on duplicatePolicy update',
      () async {
        final seeded =
            (await bookmarksRepo.create(
                      const BookmarkInput(
                        title: 'GitHub',
                        url: 'https://github.com',
                        description: 'Code host',
                        tags: ['git'],
                      ),
                    )
                    as Ok<Bookmark>)
                .value;

        const csv = '''
title,url,description,tags
GitHub Enterprise,https://github.com,Updated desc,"git,devops"
''';
        final bytes = utf8.encode(csv);

        final result = await useCase(
          ImportBookmarksParams(
            bytes: bytes,
            format: 'csv',
            duplicatePolicy: DuplicatePolicy.update,
          ),
        );

        expect(result, isA<Ok<ImportResultReport>>());
        final report = (result as Ok<ImportResultReport>).value;
        expect(report.duplicateCount, equals(1));
        expect(report.importedCount, equals(1));
        expect(report.updatedIds, contains(seeded.id));

        final updated =
            (await bookmarksRepo.get(seeded.id) as Ok<Bookmark>).value;
        expect(updated.title, equals('GitHub Enterprise'));
        expect(updated.tags, containsAll(['git', 'devops']));
      },
    );

    test(
      'prevents duplicate relationships in collections on re-import',
      () async {
        const csv = '''
title,url,collection
Item 1,https://example.com/1,Saved Links
Item 2,https://example.com/2,Saved Links
''';
        final bytes = utf8.encode(csv);

        // First import
        final res1 = await useCase(
          ImportBookmarksParams(bytes: bytes, format: 'csv'),
        );
        expect(res1, isA<Ok<ImportResultReport>>());

        // Second import with skip policy
        final res2 = await useCase(
          ImportBookmarksParams(
            bytes: bytes,
            format: 'csv',
            duplicatePolicy: DuplicatePolicy.skip,
          ),
        );
        expect(res2, isA<Ok<ImportResultReport>>());

        // Verify Saved Links collection has exactly 2 items, no duplicate UUIDs
        final cols = collectionsService.items.values.toList();
        final savedLinks = cols.firstWhere((c) => c.name == 'Saved Links');
        expect(savedLinks.bookmarkIds.length, equals(2));
        expect(savedLinks.bookmarkIds.toSet().length, equals(2));
      },
    );

    test('handles Arabic titles and URLs safely', () async {
      const csv = '''
title,url,description,collection
موقع الجزيرة,https://aljazeera.net,أخبار عالمية,أخبار
موقع العربية,https://alarabiya.net,قناة إخبارية,أخبار
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(bytes: bytes, format: 'csv'),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, equals(2));

      final all = (await bookmarksRepo.listLocal() as Ok<List<Bookmark>>).value;
      expect(all.any((b) => b.title == 'موقع الجزيرة'), isTrue);
      expect(all.any((b) => b.title == 'موقع العربية'), isTrue);

      final cols = collectionsService.items.values.toList();
      expect(cols.first.name, equals('أخبار'));
      expect(cols.first.bookmarkIds.length, equals(2));
    });

    test('handles invalid bookmark row (missing title or url)', () async {
      const csv = '''
title,url
,https://missing-title.com
Missing URL,
Valid Bookmark,https://valid.com
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportBookmarksParams(bytes: bytes, format: 'csv'),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(3));
      expect(report.validCount, equals(1));
      expect(report.invalidCount, equals(2));
      expect(report.importedCount, equals(1));
    });

    test('rejects unsupported URL schemes during import', () async {
      const csv = '''
title,url
Unsafe,javascript:alert(1)
Safe,https://example.com
''';

      final result = await useCase(
        ImportBookmarksParams(bytes: utf8.encode(csv), format: 'csv'),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.invalidCount, equals(1));
      expect(report.importedCount, equals(1));
      expect(bookmarksRepo.items.values.single.url, 'https://example.com');
    });

    test('aborts when existing bookmarks cannot be read', () async {
      bookmarksRepo.shouldFailListLocal = true;
      const csv = '''
title,url
Potential duplicate,https://example.com
''';

      final result = await useCase(
        ImportBookmarksParams(bytes: utf8.encode(csv), format: 'csv'),
      );

      expect(result, isA<Err<ImportResultReport>>());
      expect(bookmarksRepo.items, isEmpty);
    });

    test(
      'rolls back bookmark and collection when relationship linking fails',
      () async {
        collectionsService.shouldFailAdd = true;
        const csv = '''
title,url,collection
Atomic bookmark,https://example.com/atomic,Atomic collection
''';

        final result = await useCase(
          ImportBookmarksParams(bytes: utf8.encode(csv), format: 'csv'),
        );

        expect(result, isA<Err<ImportResultReport>>());
        expect(bookmarksRepo.items, isEmpty);
        expect(collectionsService.items, isEmpty);
      },
    );

    test(
      'rolls back bookmarks and relationships when import is cancelled',
      () async {
        final token = CancellationToken();
        bookmarksRepo.afterCreate = token.cancel;
        const csv = '''
title,url,collection
First,https://example.com/first,Atomic collection
Second,https://example.com/second,Atomic collection
''';

        final result = await useCase(
          ImportBookmarksParams(
            bytes: utf8.encode(csv),
            format: 'csv',
            cancellationToken: token,
          ),
        );

        expect(result, isA<Err<ImportResultReport>>());
        expect(bookmarksRepo.items, isEmpty);
        expect(collectionsService.items, isEmpty);
      },
    );
  });
}
