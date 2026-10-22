import 'dart:convert';

import 'package:csv/csv.dart';

import '../model/document_dataset.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'report_definition.dart';
import 'report_engine.dart';
import 'report_renderer.dart';

/// Renders business reports as CSV text tables with group headers, subtotals, and grand totals.
class CsvReportRenderer implements ReportRenderer {
  const CsvReportRenderer({
    this.engine = const ReportEngine(),
    this.delimiter = ',',
  });

  final ReportEngine engine;
  final String delimiter;

  @override
  String get formatId => 'csv';

  @override
  String get primaryExtension => 'csv';

  @override
  Future<List<int>> render(
    ReportDefinition definition,
    DocumentDataset dataset, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();

    final evaluated = engine.evaluate(
      definition,
      dataset,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );

    final matrix = <List<dynamic>>[];

    // 1. Report Title
    matrix.add([definition.title]);
    if (definition.subtitle case final subtitle? when subtitle.isNotEmpty) {
      matrix.add([subtitle]);
    }
    matrix.add([]); // blank separator

    // 2. Table Column Headers
    final headers = definition.columns.map((c) => c.label).toList();
    matrix.add(headers);

    // 3. Groups & Rows
    for (final group in evaluated.groups) {
      cancellationToken?.throwIfCancelled();

      if (group.groupLabel.isNotEmpty) {
        matrix.add(['--- ${group.groupLabel} ---']);
      }

      for (final row in group.rows) {
        final rowCells = definition.columns.map((col) {
          final val = row[col.id];
          return val.isNull ? '' : val.displayValue;
        }).toList();
        matrix.add(rowCells);
      }

      if (group.subtotals.isNotEmpty) {
        final subtotalRow = definition.columns.map((col) {
          if (group.subtotals.containsKey(col.id)) {
            return group.subtotals[col.id]!.displayValue;
          }
          if (col == definition.columns.first) {
            return 'Subtotal (${group.groupLabel})';
          }
          return '';
        }).toList();
        matrix.add(subtotalRow);
      }
    }

    // 4. Grand Totals
    if (evaluated.grandTotals.isNotEmpty) {
      matrix.add([]); // blank line
      final totalRow = definition.columns.map((col) {
        if (evaluated.grandTotals.containsKey(col.id)) {
          return evaluated.grandTotals[col.id]!.displayValue;
        }
        if (col == definition.columns.first) {
          return 'Grand Total';
        }
        return '';
      }).toList();
      matrix.add(totalRow);
    }

    final codec = Csv(fieldDelimiter: delimiter);
    final csvString = codec.encode(matrix);
    return utf8.encode(csvString);
  }
}
