import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:injectable/injectable.dart';

import '../services/collections_import_delegate.dart';

/// Parameters for [ImportCollectionsUseCase].
class ImportCollectionsParams {
  const ImportCollectionsParams({
    required this.bytes,
    required this.format,
    this.duplicatePolicy = DuplicatePolicy.skip,
    this.cancellationToken,
    this.onProgress,
    this.registry,
  });

  final List<int> bytes;
  final String format;
  final DuplicatePolicy duplicatePolicy;
  final CancellationToken? cancellationToken;
  final DocumentProgressCallback? onProgress;
  final DocumentFormatRegistry? registry;
}

/// Orchestrates parsing, validating, and persisting Collections from external document bytes.
@injectable
class ImportCollectionsUseCase
    extends UseCase<ImportCollectionsParams, ImportResultReport> {
  const ImportCollectionsUseCase(this._delegate);

  final CollectionsImportDelegate _delegate;

  @override
  Future<Result<ImportResultReport>> call(ImportCollectionsParams param) {
    return runGuarded(() async {
      final registry = param.registry ?? DocumentFormatRegistry.standard();
      final adapter = registry.getImportAdapter(param.format);

      final plan = await adapter.preparePlan(
        param.bytes,
        _delegate.importDefinition,
        cancellationToken: param.cancellationToken,
        onProgress: param.onProgress,
      );

      final invalidErrors = plan.invalidRows
          .expand(
            (r) => r.issues.map((i) => 'Row ${r.rowNumber}: ${i.message}'),
          )
          .toList();

      if (!plan.canCommit && plan.validRows.isEmpty) {
        return ImportResultReport(
          totalRead: plan.totalInspected,
          validCount: plan.validCount,
          invalidCount: plan.invalidCount,
          duplicateCount: 0,
          importedCount: 0,
          failedCount: plan.invalidCount,
          errors: invalidErrors,
          warnings: plan.warnings.map((w) => w.message).toList(),
        );
      }

      param.onProgress?.call(
        DocumentProgress(
          phase: DocumentPhase.committing,
          current: 0,
          total: plan.validCount,
          message: 'Saving collections...',
        ),
      );
      final report = await _delegate.executeImport(
        validRows: plan.validRows,
        duplicatePolicy: param.duplicatePolicy,
        cancellationToken: param.cancellationToken,
      );
      param.onProgress?.call(
        DocumentProgress(
          phase: DocumentPhase.completed,
          current: plan.validCount,
          total: plan.validCount,
          message: 'Collections import completed.',
        ),
      );

      return ImportResultReport(
        totalRead: plan.totalInspected,
        validCount: plan.validCount,
        invalidCount: plan.invalidCount,
        duplicateCount: report.duplicateCount,
        importedCount: report.importedCount,
        failedCount: report.failedCount + plan.invalidCount,
        errors: [...invalidErrors, ...report.errors],
        warnings: [
          ...plan.warnings.map((w) => w.message),
          ...report.warnings,
        ],
        createdIds: report.createdIds,
        updatedIds: report.updatedIds,
        skippedIds: report.skippedIds,
      );
    });
  }
}
