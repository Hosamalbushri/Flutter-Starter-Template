import 'dart:convert';
import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:feature_collections/src/domain/entities/collection.dart';
import 'package:feature_collections/src/domain/repositories/collections_repository.dart';
import 'package:feature_collections/src/domain/services/collections_import_delegate.dart';
import 'package:feature_collections/src/domain/usecases/import_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_contracts/shared_contracts.dart';

class FakeBookmarkSummariesReader extends BookmarkSummariesReader {
  FakeBookmarkSummariesReader(this.ids);

  final Set<String> ids;

  @override
  Future<Result<List<BookmarkSummary>>> call([
    NoParams param = noParams,
  ]) async => Ok(
    ids
        .map(
          (id) => BookmarkSummary(
            id: id,
            title: id,
            url: 'https://example.com/$id',
            description: '',
            tags: const [],
          ),
        )
        .toList(),
  );
}

class FakeCollectionRepository implements CollectionsRepository {
  final Map<String, Collection> items = {};
  int idCounter = 1;
  bool shouldFailCreate = false;
  bool shouldFailListLocal = false;
  int? failCreateOnCall;
  int createCalls = 0;
  void Function()? afterCreate;

  @override
  Future<Result<List<Collection>>> list() async => Ok(items.values.toList());

  @override
  Future<Result<List<Collection>>> listLocal() async {
    if (shouldFailListLocal) {
      return const Err(UnknownFailure('Database read error'));
    }
    return Ok(items.values.toList());
  }

  @override
  Future<Result<Collection>> get(String id) async {
    final found = items[id];
    if (found == null) return const Err(NotFoundFailure('Not found'));
    return Ok(found);
  }

  @override
  Future<Result<Collection>> create(CollectionInput input) async {
    createCalls++;
    if (shouldFailCreate || createCalls == failCreateOnCall) {
      return const Err(UnknownFailure('Database write error'));
    }
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
    afterCreate?.call();
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
  late FakeCollectionRepository repository;
  late CollectionsImportDelegate delegate;
  late ImportCollectionsUseCase useCase;

  setUp(() {
    repository = FakeCollectionRepository();
    delegate = CollectionsImportDelegate(
      repository,
      FakeBookmarkSummariesReader({
        'b-1',
        'b-2',
        'b-3',
        'b-existing',
        'b-new',
        'b-web',
      }),
    );
    useCase = ImportCollectionsUseCase(delegate);
  });

  group('Collections Import Integration', () {
    test('imports multiple collections from valid CSV bytes', () async {
      const csv = '''
name,icon,color,bookmarkIds
Flutter Dev,code,4280391411,"b-1,b-2"
مشاريع الذكاء الاصطناعي,brain,4294924032,"b-3"
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
          duplicatePolicy: DuplicatePolicy.skip,
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(2));
      expect(report.importedCount, equals(2));
      expect(report.failedCount, equals(0));
      expect(report.duplicateCount, equals(0));
      expect(report.createdIds.length, equals(2));

      final all = (await repository.listLocal() as Ok<List<Collection>>).value;
      expect(all.length, equals(2));
      expect(all[0].name, equals('Flutter Dev'));
      expect(all[0].bookmarkIds, equals(['b-1', 'b-2']));
      expect(all[1].name, equals('مشاريع الذكاء الاصطناعي'));
      expect(all[1].bookmarkIds, equals(['b-3']));
    });

    test('imports collections from JSON array', () async {
      final jsonStr = jsonEncode([
        {'name': 'Design Systems', 'icon': 'palette', 'color': 4280391411},
        {'name': 'Backend', 'icon': 'server', 'color': 4282345678},
      ]);
      final bytes = utf8.encode(jsonStr);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'json',
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, equals(2));
      expect(report.createdIds.length, equals(2));
    });

    test('skips duplicates by default when duplicatePolicy is skip', () async {
      // Pre-seed repository with existing collection
      await repository.create(
        const CollectionInput(
          name: 'Mobile Apps',
          icon: 'mobile',
          color: 0xFF2196F3,
          bookmarkIds: ['b-existing'],
        ),
      );

      const csv = '''
name,icon,color,bookmarkIds
Mobile Apps,mobile_alt,4280391411,"b-new"
Web Dev,globe,4294924032,"b-web"
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
          duplicatePolicy: DuplicatePolicy.skip,
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(2));
      expect(report.importedCount, equals(1)); // only Web Dev
      expect(report.duplicateCount, equals(1));
      expect(report.skippedIds.length, equals(1));

      final all = (await repository.listLocal() as Ok<List<Collection>>).value;
      expect(all.length, equals(2));
      final mobile = all.firstWhere((c) => c.name == 'Mobile Apps');
      expect(mobile.bookmarkIds, equals(['b-existing'])); // untouched
    });

    test(
      'merges and updates existing collections when duplicatePolicy is update',
      () async {
        final seeded =
            (await repository.create(
                      const CollectionInput(
                        name: 'DevOps',
                        icon: 'cloud',
                        color: 0xFF2196F3,
                        bookmarkIds: ['b-1'],
                      ),
                    )
                    as Ok<Collection>)
                .value;

        const csv = '''
name,icon,color,bookmarkIds
DevOps,cloud_upload,4294967295,"b-2,b-1"
''';
        final bytes = utf8.encode(csv);

        final result = await useCase(
          ImportCollectionsParams(
            bytes: bytes,
            format: 'csv',
            duplicatePolicy: DuplicatePolicy.update,
          ),
        );

        expect(result, isA<Ok<ImportResultReport>>());
        final report = (result as Ok<ImportResultReport>).value;
        expect(report.importedCount, equals(1));
        expect(report.duplicateCount, equals(1));
        expect(report.updatedIds, contains(seeded.id));

        final updated =
            (await repository.get(seeded.id) as Ok<Collection>).value;
        expect(updated.bookmarkIds, containsAll(['b-1', 'b-2']));
        expect(updated.bookmarkIds.length, equals(2)); // deduped
      },
    );

    test('creates new instance when duplicatePolicy is create', () async {
      await repository.create(
        const CollectionInput(
          name: 'Testing',
          icon: 'vial',
          color: 0xFF2196F3,
        ),
      );

      const csv = '''
name,icon,color
Testing,vial,4280391411
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
          duplicatePolicy: DuplicatePolicy.create,
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, equals(1));
      expect(report.duplicateCount, equals(1));
      expect(report.createdIds.length, equals(1));

      final all = (await repository.listLocal() as Ok<List<Collection>>).value;
      expect(all.length, equals(2));
    });

    test('handles invalid rows (missing required name)', () async {
      const csv = '''
name,icon,color
,folder,4280391411
Valid Collection,folder,4280391411
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
        ),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.totalRead, equals(2));
      expect(report.validCount, equals(1));
      expect(report.invalidCount, equals(1));
      expect(report.importedCount, equals(1));
      expect(report.errors, isNotEmpty);
    });

    test('returns failure when persistence fails', () async {
      repository.shouldFailCreate = true;
      const csv = '''
name,icon,color
Broken Collection,folder,4280391411
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
        ),
      );

      expect(result, isA<Err<ImportResultReport>>());
      expect(repository.items, isEmpty);
    });

    test(
      'rolls back earlier rows when a later persistence write fails',
      () async {
        repository.failCreateOnCall = 2;
        const csv = '''
name,icon,color
First,folder,4280391411
Second,folder,4280391411
''';

        final result = await useCase(
          ImportCollectionsParams(bytes: utf8.encode(csv), format: 'csv'),
        );

        expect(result, isA<Err<ImportResultReport>>());
        expect(repository.items, isEmpty);
      },
    );

    test('aborts when existing collections cannot be read', () async {
      repository.shouldFailListLocal = true;
      const csv = '''
name,icon,color
Unsafe duplicate,folder,4280391411
''';

      final result = await useCase(
        ImportCollectionsParams(bytes: utf8.encode(csv), format: 'csv'),
      );

      expect(result, isA<Err<ImportResultReport>>());
      expect(repository.items, isEmpty);
    });

    test('rejects collection rows that reference unknown bookmarks', () async {
      const csv = '''
name,icon,color,bookmarkIds
Broken relation,folder,4280391411,"b-1,missing-bookmark"
''';

      final result = await useCase(
        ImportCollectionsParams(bytes: utf8.encode(csv), format: 'csv'),
      );

      expect(result, isA<Ok<ImportResultReport>>());
      final report = (result as Ok<ImportResultReport>).value;
      expect(report.importedCount, 0);
      expect(report.failedCount, 1);
      expect(report.errors.single, contains('missing-bookmark'));
      expect(repository.items, isEmpty);
    });

    test('respects cooperative cancellation token', () async {
      final token = CancellationToken()..cancel('Cancelled by user');
      const csv = '''
name,icon,color
Col 1,folder,4280391411
''';
      final bytes = utf8.encode(csv);

      final result = await useCase(
        ImportCollectionsParams(
          bytes: bytes,
          format: 'csv',
          cancellationToken: token,
        ),
      );

      expect(result, isA<Err<ImportResultReport>>());
    });

    test('rolls back rows created before cooperative cancellation', () async {
      final token = CancellationToken();
      repository.afterCreate = token.cancel;
      const csv = '''
name,icon,color
Col 1,folder,4280391411
Col 2,folder,4280391411
''';

      final result = await useCase(
        ImportCollectionsParams(
          bytes: utf8.encode(csv),
          format: 'csv',
          cancellationToken: token,
        ),
      );

      expect(result, isA<Err<ImportResultReport>>());
      expect(repository.items, isEmpty);
    });
  });
}
