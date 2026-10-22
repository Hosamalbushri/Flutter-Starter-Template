import 'package:meta/meta.dart';

import '../model/document_metadata.dart';

/// Configuration options for document data export.
@immutable
class ExportDefinition {
  const ExportDefinition({
    this.columns,
    this.includeHeaders = true,
    this.sheetName = 'Sheet1',
    this.protectFormulas = true,
    this.metadata,
    this.dateFormat,
    this.numberFormat,
  });

  /// Specific column IDs to export, in desired order. If `null`, all visible columns in schema are exported.
  final List<String>? columns;

  /// Whether to include header row with column labels.
  final bool includeHeaders;

  /// Sheet or table name (relevant for XLSX).
  final String sheetName;

  /// Whether to neutralize spreadsheet formula injection (cells starting with =, +, -, @, \t, \r).
  final bool protectFormulas;

  /// Document metadata.
  final DocumentMetadata? metadata;

  /// Date formatting pattern override.
  final String? dateFormat;

  /// Number formatting pattern override.
  final String? numberFormat;

  ExportDefinition copyWith({
    List<String>? columns,
    bool? includeHeaders,
    String? sheetName,
    bool? protectFormulas,
    DocumentMetadata? metadata,
    String? dateFormat,
    String? numberFormat,
  }) => ExportDefinition(
    columns: columns ?? this.columns,
    includeHeaders: includeHeaders ?? this.includeHeaders,
    sheetName: sheetName ?? this.sheetName,
    protectFormulas: protectFormulas ?? this.protectFormulas,
    metadata: metadata ?? this.metadata,
    dateFormat: dateFormat ?? this.dateFormat,
    numberFormat: numberFormat ?? this.numberFormat,
  );

  /// Sanitizes string value against formula injection attacks when [protectFormulas] is true.
  static String sanitizeFormula(String value) {
    if (value.isEmpty) return value;
    final trimmed = value.trimLeft();
    if (trimmed.isEmpty) return value;
    final leadingWhitespace = value.substring(0, value.length - trimmed.length);
    if (leadingWhitespace.contains('\t') || leadingWhitespace.contains('\r')) {
      return "'$value";
    }
    final first = trimmed[0];
    if (first == '=' || first == '+' || first == '-' || first == '@') {
      return "'$value";
    }
    return value;
  }
}
