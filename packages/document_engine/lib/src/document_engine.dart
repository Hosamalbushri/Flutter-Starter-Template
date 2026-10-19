import 'export/export_definition.dart';
import 'import/import_definition.dart';
import 'import/import_persistence_adapter.dart';
import 'import/import_plan.dart';
import 'model/document_dataset.dart';
import 'progress/cancellation_token.dart';
import 'progress/document_progress.dart';
import 'registry/document_format_registry.dart';
import 'report/report_definition.dart';
import 'report/report_renderer.dart';

/// Public engine boundary managing document import, export, reporting, and format registration.
abstract interface class DocumentEngineService {
  /// The active format registry.
  DocumentFormatRegistry get registry;

  /// Initializes the document engine with standard or custom adapters.
  Future<void> initialize();

  /// Disposes of any resources held by the engine.
  Future<void> dispose();

  /// Inspects column headers from an input document using the appropriate format adapter.
  Future<List<String>> inspectHeaders(
    List<int> bytes,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
  });

  /// Prepares an [ImportPlan] validating [bytes] against [definition].
  Future<ImportPlan> prepareImportPlan(
    List<int> bytes,
    ImportDefinition definition,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });

  /// Executes an import plan committing valid rows through [persistenceAdapter].
  Future<int> executeImport(
    ImportPlan plan,
    ImportPersistenceAdapter persistenceAdapter, {
    int chunkSize = 100,
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });

  /// Exports a [dataset] into serialized document bytes.
  Future<List<int>> exportDocument(
    DocumentDataset dataset,
    ExportDefinition definition,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });

  /// Renders a [report] using the matching [ReportRenderer].
  Future<List<int>> renderReport(
    ReportDefinition report,
    DocumentDataset dataset,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });
}

/// Standard implementation of [DocumentEngineService].
class StandardDocumentEngineService implements DocumentEngineService {
  StandardDocumentEngineService({DocumentFormatRegistry? registry})
    : registry = registry ?? DocumentFormatRegistry.standard();

  @override
  final DocumentFormatRegistry registry;

  @override
  Future<void> initialize() async {
    // Default adapters can be registered here.
  }

  @override
  Future<void> dispose() async {
    // Cleanup hooks if required.
  }

  @override
  Future<List<String>> inspectHeaders(
    List<int> bytes,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final adapter = registry.getImportAdapter(formatOrExtension);
    return adapter.inspectHeaders(bytes, cancellationToken: cancellationToken);
  }

  @override
  Future<ImportPlan> prepareImportPlan(
    List<int> bytes,
    ImportDefinition definition,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    final adapter = registry.getImportAdapter(formatOrExtension);
    return adapter.preparePlan(
      bytes,
      definition,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<int> executeImport(
    ImportPlan plan,
    ImportPersistenceAdapter persistenceAdapter, {
    int chunkSize = 100,
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    if (chunkSize <= 0) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'Must be greater than zero.',
      );
    }
    cancellationToken?.throwIfCancelled();
    if (!plan.canCommit) {
      throw StateError(
        'Cannot commit import plan: validation errors present and partial import disabled',
      );
    }

    final rows = plan.validRows;
    if (rows.isEmpty) return 0;

    await persistenceAdapter.beginTransaction();
    var committedCount = 0;

    try {
      for (var i = 0; i < rows.length; i += chunkSize) {
        cancellationToken?.throwIfCancelled();
        final end = (i + chunkSize < rows.length) ? i + chunkSize : rows.length;
        final chunk = rows.sublist(i, end);

        final saved = await persistenceAdapter.saveChunk(
          chunk,
          cancellationToken: cancellationToken,
        );
        committedCount += saved;

        onProgress?.call(
          DocumentProgress(
            phase: DocumentPhase.committing,
            current: committedCount,
            total: rows.length,
            message: 'Committed $committedCount of ${rows.length} rows',
          ),
        );
      }

      await persistenceAdapter.commitTransaction();

      onProgress?.call(
        DocumentProgress(
          phase: DocumentPhase.completed,
          current: committedCount,
          total: rows.length,
          message: 'Import completed successfully',
        ),
      );

      return committedCount;
    } catch (e) {
      await persistenceAdapter.rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<List<int>> exportDocument(
    DocumentDataset dataset,
    ExportDefinition definition,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    final adapter = registry.getExportAdapter(formatOrExtension);
    return adapter.export(
      dataset,
      definition,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<int>> renderReport(
    ReportDefinition report,
    DocumentDataset dataset,
    String formatOrExtension, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    final renderer = registry.getReportRenderer(formatOrExtension);
    return renderer.render(
      report,
      dataset,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }
}
