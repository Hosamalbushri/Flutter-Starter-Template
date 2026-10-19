import 'package:meta/meta.dart';

/// Configuration options for CSV document import.
@immutable
class CsvImportOptions {
  const CsvImportOptions({
    this.fieldDelimiter,
    this.quoteCharacter = '"',
    this.escapeCharacter,
    this.autoDetect = true,
    this.skipEmptyLines = true,
    this.trimValues = true,
  });

  /// The character separating columns (e.g. ',', ';', '\t').
  /// If `null` and [autoDetect] is true, the delimiter is automatically determined.
  final String? fieldDelimiter;

  /// The character used to enclose field values containing delimiters or newlines.
  final String quoteCharacter;

  /// The character used to escape quotes inside quoted fields.
  final String? escapeCharacter;

  /// Whether to auto-detect the field delimiter from the first row.
  final bool autoDetect;

  /// Whether to skip empty lines in the CSV input.
  final bool skipEmptyLines;

  /// Whether to trim leading/trailing whitespace from text values.
  final bool trimValues;
}

/// Configuration options for CSV document export.
@immutable
class CsvExportOptions {
  const CsvExportOptions({
    this.fieldDelimiter = ',',
    this.lineDelimiter = '\r\n',
    this.quoteCharacter = '"',
    this.escapeCharacter,
    this.addUtf8Bom = false,
    this.nullRepresentation = '',
    this.sanitizeFormulaInjection = true,
  });

  /// Standard CSV export options with Excel compatibility (semicolon and UTF-8 BOM).
  const CsvExportOptions.excel()
    : fieldDelimiter = ';',
      lineDelimiter = '\r\n',
      quoteCharacter = '"',
      escapeCharacter = null,
      addUtf8Bom = true,
      nullRepresentation = '',
      sanitizeFormulaInjection = true;

  /// The character separating columns (default ',').
  final String fieldDelimiter;

  /// The newline sequence terminating rows (default '\r\n').
  final String lineDelimiter;

  /// The quote character (default '"').
  final String quoteCharacter;

  /// The escape character for quotes.
  final String? escapeCharacter;

  /// Whether to prepend UTF-8 Byte Order Mark (BOM: `0xEF, 0xBB, 0xBF`) to bytes.
  /// Recommended when exporting non-ASCII (e.g. Arabic) text to Microsoft Excel.
  final bool addUtf8Bom;

  /// String representation for null or empty values.
  final String nullRepresentation;

  /// Neutralizes formula injection by prefixing '=', '+', '-', '@', '\t', '\r' with '\''.
  final bool sanitizeFormulaInjection;
}
