import 'package:meta/meta.dart';

import '../model/document_dataset.dart';
import '../model/document_row.dart';
import '../model/document_value.dart';
import '../numerics/decimal_number.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'evaluated_report.dart';
import 'report_definition.dart';

/// Calculation engine that evaluates a [ReportDefinition] over a [DocumentDataset],
/// applying filtering, multi-column sorting, grouping, subtotals, and grand totals.
@immutable
class ReportEngine {
  const ReportEngine();

  /// Evaluates [definition] over [dataset], yielding a structured [EvaluatedReport].
  EvaluatedReport evaluate(
    ReportDefinition definition,
    DocumentDataset dataset, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) {
    cancellationToken?.throwIfCancelled();

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.transforming,
        current: 0,
        total: 100,
        message: 'Filtering and sorting report data...',
      ),
    );

    // 1. Filter
    var processedRows = <DocumentRow>[];
    if (definition.filter != null) {
      for (var i = 0; i < dataset.length; i++) {
        final row = dataset[i];
        if (definition.filter!(row)) {
          processedRows.add(row);
        }
      }
    } else {
      processedRows = dataset.rows.toList();
    }

    cancellationToken?.throwIfCancelled();

    // 2. Sort
    if (definition.sortDescriptors.isNotEmpty) {
      processedRows.sort((a, b) {
        for (final descriptor in definition.sortDescriptors) {
          final valA = a[descriptor.columnId];
          final valB = b[descriptor.columnId];
          final cmp = _compareValues(valA, valB);
          if (cmp != 0) {
            return descriptor.direction == ReportSortDirection.ascending
                ? cmp
                : -cmp;
          }
        }
        return 0;
      });
    }

    cancellationToken?.throwIfCancelled();

    // 3. Grouping and Subtotals
    final groupSections = <ReportGroupSection>[];

    if (definition.groupings.isNotEmpty) {
      final primaryGrouping = definition.groupings.first;
      final groupMap = <String, List<DocumentRow>>{};
      final groupValueMap = <String, DocumentValue>{};

      for (final row in processedRows) {
        final groupVal = row[primaryGrouping.columnId];
        final groupKey = groupVal.displayValue;
        groupMap.putIfAbsent(groupKey, () => <DocumentRow>[]).add(row);
        groupValueMap.putIfAbsent(groupKey, () => groupVal);
      }

      for (final entry in groupMap.entries) {
        final key = entry.key;
        final rowsInGroup = entry.value;
        final groupVal = groupValueMap[key]!;

        final subtotals = <String, DocumentValue>{};
        if (primaryGrouping.showSubtotals) {
          for (final summary in definition.summaries) {
            subtotals[summary.columnId] = _calculateSummary(
              rowsInGroup,
              summary,
            );
          }
        }

        groupSections.add(
          ReportGroupSection(
            groupColumnId: primaryGrouping.columnId,
            groupValue: groupVal,
            groupLabel: key,
            rows: rowsInGroup,
            subtotals: subtotals,
          ),
        );
      }
    } else {
      // Single ungrouped partition
      groupSections.add(
        ReportGroupSection(
          groupColumnId: '',
          groupValue: const NullDocumentValue(),
          groupLabel: '',
          rows: processedRows,
          subtotals: const {},
        ),
      );
    }

    // 4. Grand Totals
    final grandTotals = <String, DocumentValue>{};
    for (final summary in definition.summaries) {
      grandTotals[summary.columnId] = _calculateSummary(
        processedRows,
        summary,
      );
    }

    cancellationToken?.throwIfCancelled();

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.completed,
        current: 100,
        total: 100,
        message: 'Report evaluation complete.',
      ),
    );

    return EvaluatedReport(
      definition: definition,
      groups: groupSections,
      grandTotals: grandTotals,
      totalRowCount: processedRows.length,
    );
  }

  int _compareValues(DocumentValue a, DocumentValue b) {
    if (a.isNull && b.isNull) return 0;
    if (a.isNull) return -1;
    if (b.isNull) return 1;

    // Numeric comparison
    final decA = a.asDecimal;
    final decB = b.asDecimal;
    if (decA != null && decB != null) {
      return decA.compareTo(decB);
    }

    // Date comparison
    final dtA = a.asDateTime;
    final dtB = b.asDateTime;
    if (dtA != null && dtB != null) {
      return dtA.compareTo(dtB);
    }

    // Text comparison
    return a.displayValue.compareTo(b.displayValue);
  }

  DocumentValue _calculateSummary(
    List<DocumentRow> rows,
    ReportSummary summary,
  ) {
    if (summary.function == SummaryFunction.count) {
      return IntDocumentValue(rows.length);
    }

    if (rows.isEmpty) {
      return const NullDocumentValue();
    }

    switch (summary.function) {
      case SummaryFunction.sum:
        var isAllInt = true;
        var intSum = 0;
        var decimalSum = DecimalNumber.zero;

        for (final row in rows) {
          final val = row[summary.columnId];
          if (val.isNull) continue;

          if (val is IntDocumentValue && isAllInt) {
            intSum += val.value;
            decimalSum += DecimalNumber.fromInt(val.value);
          } else {
            isAllInt = false;
            final d = val.asDecimal;
            if (d != null) {
              decimalSum += d;
            }
          }
        }
        return isAllInt
            ? IntDocumentValue(intSum)
            : DecimalDocumentValue(decimalSum);

      case SummaryFunction.average:
        var total = DecimalNumber.zero;
        var count = 0;
        for (final row in rows) {
          final val = row[summary.columnId];
          if (val.isNull) continue;
          final d = val.asDecimal;
          if (d != null) {
            total += d;
            count++;
          }
        }
        if (count == 0) return const NullDocumentValue();
        final avg = total.divide(
          DecimalNumber.fromInt(count),
          targetScale: 4,
          rounding: RoundingMode.halfEven,
        );
        return DecimalDocumentValue(avg);

      case SummaryFunction.min:
        DocumentValue? minVal;
        for (final row in rows) {
          final val = row[summary.columnId];
          if (val.isNull) continue;
          if (minVal == null || _compareValues(val, minVal) < 0) {
            minVal = val;
          }
        }
        return minVal ?? const NullDocumentValue();

      case SummaryFunction.max:
        DocumentValue? maxVal;
        for (final row in rows) {
          final val = row[summary.columnId];
          if (val.isNull) continue;
          if (maxVal == null || _compareValues(val, maxVal) > 0) {
            maxVal = val;
          }
        }
        return maxVal ?? const NullDocumentValue();

      case SummaryFunction.count:
        return IntDocumentValue(rows.length);
    }
  }
}
