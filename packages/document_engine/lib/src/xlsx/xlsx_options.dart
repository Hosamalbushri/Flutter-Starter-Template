import 'package:meta/meta.dart';

/// Configuration options for Excel (.xlsx / .xls) document import.
@immutable
class XlsxImportOptions {
  const XlsxImportOptions({
    this.sheetName,
    this.skipEmptyRows = true,
    this.trimText = true,
  });

  /// Specific sheet name to read data from.
  /// If `null`, reads the first available sheet in the workbook.
  final String? sheetName;

  /// Whether to skip completely empty rows.
  final bool skipEmptyRows;

  /// Whether to trim whitespace from text cells.
  final bool trimText;
}

/// Configuration options for Excel (.xlsx) document export.
@immutable
class XlsxExportOptions {
  const XlsxExportOptions({
    this.defaultSheetName = 'Sheet1',
    this.isRtl = false,
    this.sanitizeFormulaInjection = true,
  });

  /// Default sheet name to use when not specified in .
  final String defaultSheetName;

  /// Whether the sheet view direction should be Right-to-Left (for Arabic/Hebrew).
  final bool isRtl;

  /// Whether to neutralize spreadsheet formula injection by prepending '\''.
  final bool sanitizeFormulaInjection;
}
