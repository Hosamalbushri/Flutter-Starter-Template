import 'package:meta/meta.dart';

import '../model/document_row.dart';

/// Severity level of a validation finding.
enum ValidationSeverity {
  info,
  warning,
  error,
}

/// Standardized error codes for validation issues.
enum ValidationErrorCode {
  missingRequired,
  invalidType,
  duplicateValue,
  outOfRange,
  customRuleFailed,
  unknownColumn,
}

/// A specific validation issue found in a cell or row during import.
@immutable
class CellValidationIssue {
  const CellValidationIssue({
    required this.rowNumber,
    required this.severity,
    required this.code,
    required this.message,
    this.columnId,
    this.sourceHeader,
    this.rawValue,
  });

  /// 1-indexed row number in the source file.
  final int rowNumber;

  /// Target column id, if resolved.
  final String? columnId;

  /// Source column header or index.
  final String? sourceHeader;

  /// Raw value that caused the issue.
  final Object? rawValue;

  /// Issue severity.
  final ValidationSeverity severity;

  /// Error code for programmatic handling.
  final ValidationErrorCode code;

  /// Human-readable explanation.
  final String message;

  @override
  String toString() =>
      '[$severity] Row $rowNumber, Col "${columnId ?? sourceHeader}": $message ($code)';
}

/// Validation evaluation of a single row.
@immutable
class RowValidationResult {
  const RowValidationResult({
    required this.rowNumber,
    required this.issues,
    this.parsedRow,
  });

  final int rowNumber;
  final List<CellValidationIssue> issues;
  final DocumentRow? parsedRow;

  /// Whether this row contains any [ValidationSeverity.error] findings.
  bool get isValid =>
      !issues.any((i) => i.severity == ValidationSeverity.error);

  /// Whether this row has warnings.
  bool get hasWarnings =>
      issues.any((i) => i.severity == ValidationSeverity.warning);
}

/// Summary validation result across an entire import dataset.
@immutable
class ImportValidationResult {
  const ImportValidationResult({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.issues,
  });

  final int totalRows;
  final List<DocumentRow> validRows;
  final List<RowValidationResult> invalidRows;
  final List<CellValidationIssue> issues;

  /// Whether all rows are completely valid.
  bool get isValid => invalidRows.isEmpty;

  /// Total count of errors.
  int get errorCount =>
      issues.where((i) => i.severity == ValidationSeverity.error).length;

  /// Total count of warnings.
  int get warningCount =>
      issues.where((i) => i.severity == ValidationSeverity.warning).length;
}
