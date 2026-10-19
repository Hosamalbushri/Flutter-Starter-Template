import '../model/document_row.dart';
import '../progress/cancellation_token.dart';
import 'import_definition.dart';
import 'import_report.dart';

/// Contract for a feature or domain delegate that persists imported tabular rows.
///
/// Implementations handle:
/// 1. Mapping generic [DocumentRow] fields to strongly-typed domain inputs/entities.
/// 2. Checking for duplicate records according to feature rules.
/// 3. Applying the chosen [DuplicatePolicy] (`skip`, `update`, `create`).
/// 4. Persisting entities via repositories or use cases, preserving sync tracking.
/// 5. Returning an [ImportResultReport] containing metrics, created IDs, and errors.
abstract interface class DocumentImportDelegate {
  /// Unique identifier of the dataset (e.g. 'collections', 'bookmarks').
  String get datasetId;

  /// Human-readable label for this dataset.
  String get datasetLabel;

  /// Schema and column definitions used by the import engine to validate input files.
  ImportDefinition get importDefinition;

  /// Executes the persistence phase for [validRows] using the selected [duplicatePolicy].
  Future<ImportResultReport> executeImport({
    required List<DocumentRow> validRows,
    required DuplicatePolicy duplicatePolicy,
    CancellationToken? cancellationToken,
  });
}
