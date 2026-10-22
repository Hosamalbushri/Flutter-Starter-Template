import 'package:meta/meta.dart';

import '../model/document_row.dart';
import '../model/document_value.dart';
import 'report_definition.dart';

/// Evaluated group partition containing header information, rows, and group subtotals.
@immutable
class ReportGroupSection {
  ReportGroupSection({
    required this.groupColumnId,
    required this.groupValue,
    required this.groupLabel,
    required List<DocumentRow> rows,
    required Map<String, DocumentValue> subtotals,
  }) : rows = List.unmodifiable(rows),
       subtotals = Map.unmodifiable(subtotals);

  final String groupColumnId;
  final DocumentValue groupValue;
  final String groupLabel;
  final List<DocumentRow> rows;
  final Map<String, DocumentValue> subtotals;

  int get rowCount => rows.length;
}

/// Evaluated, fully processed business report containing ordered groups, subtotals, and grand totals.
@immutable
class EvaluatedReport {
  EvaluatedReport({
    required this.definition,
    required List<ReportGroupSection> groups,
    required Map<String, DocumentValue> grandTotals,
    required this.totalRowCount,
  }) : groups = List.unmodifiable(groups),
       grandTotals = Map.unmodifiable(grandTotals);

  final ReportDefinition definition;
  final List<ReportGroupSection> groups;
  final Map<String, DocumentValue> grandTotals;
  final int totalRowCount;

  /// Convenience getter for all rows across all groups.
  List<DocumentRow> get allRows => [
    for (final group in groups) ...group.rows,
  ];

  /// Whether the report contains any data rows.
  bool get isEmpty => totalRowCount == 0;
  bool get isNotEmpty => totalRowCount > 0;
}
