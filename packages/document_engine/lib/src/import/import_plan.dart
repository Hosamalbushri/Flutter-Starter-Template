import 'package:meta/meta.dart';

import '../model/document_row.dart';
import 'import_validation.dart';

/// Pre-commit plan resulting from parsing and validating an imported document.
@immutable
class ImportPlan {
  const ImportPlan({
    required this.totalInspected,
    required this.validRows,
    required this.invalidRows,
    required this.warnings,
    required this.canCommit,
  });

  /// Total count of data rows read from the source.
  final int totalInspected;

  /// Rows that passed all validation rules.
  final List<DocumentRow> validRows;

  /// Rows that failed one or more validation rules.
  final List<RowValidationResult> invalidRows;

  /// Non-fatal warnings encountered.
  final List<CellValidationIssue> warnings;

  /// Whether the plan is eligible for commit (based on validation and allowPartial policy).
  final bool canCommit;

  int get validCount => validRows.length;
  int get invalidCount => invalidRows.length;
  int get warningCount => warnings.length;

  /// Brief human-readable summary.
  String get summary =>
      'Inspected $totalInspected rows: $validCount valid, $invalidCount invalid, $warningCount warnings.';
}
