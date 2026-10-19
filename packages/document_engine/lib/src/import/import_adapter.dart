import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'import_definition.dart';
import 'import_plan.dart';

/// Contract implemented by format-specific import adapters (CSV, XLSX, JSON).
abstract interface class ImportAdapter {
  /// Unique identifier of the supported format (e.g. 'csv', 'xlsx', 'json').
  String get formatId;

  /// File extensions supported by this adapter (e.g. ['csv']).
  List<String> get supportedExtensions;

  /// Inspects the input and returns the detected column headers.
  Future<List<String>> inspectHeaders(
    List<int> bytes, {
    CancellationToken? cancellationToken,
  });

  /// Parses and validates [bytes] against [definition], generating an [ImportPlan].
  Future<ImportPlan> preparePlan(
    List<int> bytes,
    ImportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });
}
