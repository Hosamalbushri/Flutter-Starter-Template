import 'package:meta/meta.dart';

/// Configuration options for JSON document import.
@immutable
class JsonImportOptions {
  const JsonImportOptions({
    this.dataKey,
  });

  /// Specific top-level object property containing the array of records.
  /// If `null`, auto-detects root list or common wrapper keys ('data', 'records', 'items', 'rows').
  final String? dataKey;
}

/// Configuration options for JSON document export.
@immutable
class JsonExportOptions {
  const JsonExportOptions({
    this.prettyPrint = true,
    this.indent = '  ',
    this.useColumnLabelsAsKeys = false,
    this.includeMetadata = false,
  });

  /// Whether output should be indented with newlines for human readability.
  final bool prettyPrint;

  /// Indentation string when [prettyPrint] is true.
  final String indent;

  /// If `true`, keys in JSON objects use column labels instead of column IDs.
  final bool useColumnLabelsAsKeys;

  /// Whether to wrap the exported records in a structure containing document metadata:
  /// `{"metadata": {...}, "rows": [...]}`.
  final bool includeMetadata;
}
