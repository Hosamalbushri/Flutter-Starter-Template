import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

class _FakeCsvImportAdapter implements ImportAdapter {
  @override
  String get formatId => 'csv';

  @override
  List<String> get supportedExtensions => ['csv', 'txt'];

  @override
  Future<List<String>> inspectHeaders(
    List<int> bytes, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    return ['id', 'name', 'price'];
  }

  @override
  Future<ImportPlan> preparePlan(
    List<int> bytes,
    ImportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    final row = DocumentRow.fromRaw(
      index: 0,
      rawCells: const {'id': 1, 'name': 'Item A', 'price': '10.50'},
    );
    return ImportPlan(
      totalInspected: 1,
      validRows: [row],
      invalidRows: const [],
      warnings: const [],
      canCommit: true,
    );
  }
}

class _FakeCsvExportAdapter implements ExportAdapter {
  @override
  String get formatId => 'csv';

  @override
  String get primaryExtension => 'csv';

  @override
  String get mimeType => 'text/csv';

  @override
  Future<List<int>> export(
    DocumentDataset dataset,
    ExportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    return [1, 2, 3];
  }
}

void main() {
  group('DocumentFormatRegistry', () {
    test('registers and retrieves adapters by format and extension', () {
      final registry = DocumentFormatRegistry();
      registry.registerImportAdapter(_FakeCsvImportAdapter());
      registry.registerExportAdapter(_FakeCsvExportAdapter());

      expect(registry.getImportAdapter('csv'), isA<ImportAdapter>());
      expect(registry.getImportAdapter('.txt'), isA<ImportAdapter>());
      expect(registry.getExportAdapter('csv'), isA<ExportAdapter>());

      expect(
        () => registry.getImportAdapter('unsupported'),
        throwsA(isA<DocumentFormatNotSupportedFailure>()),
      );
    });
  });

  group('StandardDocumentEngineService', () {
    test('executes import workflow with transactional persistence', () async {
      final registry = DocumentFormatRegistry();
      registry.registerImportAdapter(_FakeCsvImportAdapter());
      final service = StandardDocumentEngineService(registry: registry);

      final schema = DocumentDefinition(
        id: 'items',
        title: 'Items',
        columns: [
          DocumentColumn.integer(id: 'id', label: 'ID'),
          DocumentColumn.text(id: 'name', label: 'Name'),
          DocumentColumn.decimal(id: 'price', label: 'Price'),
        ],
      );

      final headers = await service.inspectHeaders([0, 1], 'csv');
      expect(headers, ['id', 'name', 'price']);

      final plan = await service.prepareImportPlan(
        [0, 1],
        ImportDefinition(targetDefinition: schema),
        'csv',
      );
      expect(plan.canCommit, isTrue);
      expect(plan.validCount, 1);

      final persistence = MemoryImportPersistenceAdapter();
      final count = await service.executeImport(plan, persistence);

      expect(count, 1);
      expect(persistence.committedRows.length, 1);
      expect(persistence.inTransaction, isFalse);
    });

    test('handles rollback on persistence failure', () async {
      final registry = DocumentFormatRegistry();
      registry.registerImportAdapter(_FakeCsvImportAdapter());
      final service = StandardDocumentEngineService(registry: registry);

      final plan = ImportPlan(
        totalInspected: 1,
        validRows: [
          DocumentRow.fromRaw(index: 0, rawCells: const {'col': 'val'}),
        ],
        invalidRows: const [],
        warnings: const [],
        canCommit: true,
      );

      final failingPersistence = _FailingPersistenceAdapter();

      await expectLater(
        service.executeImport(plan, failingPersistence),
        throwsA(isA<Exception>()),
      );
      expect(failingPersistence.wasRolledBack, isTrue);
    });

    test('rolls back when persistence reports a partial chunk write', () async {
      final service = StandardDocumentEngineService();
      final persistence = _PartialWritePersistenceAdapter();
      final plan = ImportPlan(
        totalInspected: 2,
        validRows: [
          DocumentRow.fromRaw(index: 0, rawCells: const {'col': 'first'}),
          DocumentRow.fromRaw(index: 1, rawCells: const {'col': 'second'}),
        ],
        invalidRows: const [],
        warnings: const [],
        canCommit: true,
      );

      await expectLater(
        service.executeImport(plan, persistence),
        throwsA(
          isA<DocumentPersistenceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('saving 1 of 2 rows'),
          ),
        ),
      );
      expect(persistence.wasCommitted, isFalse);
      expect(persistence.wasRolledBack, isTrue);
    });

    test(
      'rejects a non-positive chunk size before opening a transaction',
      () async {
        final service = StandardDocumentEngineService();
        final persistence = MemoryImportPersistenceAdapter();
        final plan = ImportPlan(
          totalInspected: 1,
          validRows: [
            DocumentRow.fromRaw(index: 0, rawCells: const {'col': 'value'}),
          ],
          invalidRows: const [],
          warnings: const [],
          canCommit: true,
        );

        await expectLater(
          service.executeImport(plan, persistence, chunkSize: 0),
          throwsA(isA<ArgumentError>()),
        );
        expect(persistence.inTransaction, isFalse);
      },
    );
  });
}

class _FailingPersistenceAdapter implements ImportPersistenceAdapter {
  bool wasRolledBack = false;

  @override
  Future<void> beginTransaction() async {}

  @override
  Future<int> saveChunk(
    List<DocumentRow> rows, {
    CancellationToken? cancellationToken,
  }) async {
    throw Exception('Simulated database error');
  }

  @override
  Future<void> commitTransaction() async {}

  @override
  Future<void> rollbackTransaction() async {
    wasRolledBack = true;
  }
}

class _PartialWritePersistenceAdapter implements ImportPersistenceAdapter {
  bool wasCommitted = false;
  bool wasRolledBack = false;

  @override
  Future<void> beginTransaction() async {}

  @override
  Future<int> saveChunk(
    List<DocumentRow> rows, {
    CancellationToken? cancellationToken,
  }) async => rows.length - 1;

  @override
  Future<void> commitTransaction() async => wasCommitted = true;

  @override
  Future<void> rollbackTransaction() async => wasRolledBack = true;
}
