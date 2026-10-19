import 'dart:convert';

import 'package:csv/csv.dart';

import '../export/export_adapter.dart';
import '../export/export_definition.dart';
import '../model/document_column.dart';
import '../model/document_dataset.dart';
import '../model/document_value.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'csv_options.dart';

/// Export adapter that serializes a [DocumentDataset] to CSV format.
class CsvExportAdapter implements ExportAdapter {
  const CsvExportAdapter({
    this.options = const CsvExportOptions(),
  });

  /// Options governing delimiters, UTF-8 BOM, and formula sanitization.
  final CsvExportOptions options;

  @override
  String get formatId => 'csv';

  @override
  String get primaryExtension => 'csv';

  @override
  String get mimeType => 'text/csv';

  @override
  Future<List<int>> export(
    DocumentDataset dataset,
    ExportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();

    final targetColumns = _resolveColumns(dataset, definition);
    final rowsMatrix = <List<dynamic>>[];

    // 1. Headers
    if (definition.includeHeaders) {
      final headerRow = targetColumns.map((col) => col.label).toList();
      rowsMatrix.add(headerRow);
    }

    // 2. Data rows
    final totalRows = dataset.length;
    for (var i = 0; i < totalRows; i++) {
      if (i % 100 == 0) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(
          DocumentProgress(
            phase: DocumentPhase.writing,
            current: i,
            total: totalRows,
            message: 'Exporting row ${i + 1} of $totalRows...',
          ),
        );
      }

      final row = dataset[i];
      final rowCells = <dynamic>[];

      for (final col in targetColumns) {
        final docVal = row[col.id];
        rowCells.add(_serializeValue(docVal, definition));
      }

      rowsMatrix.add(rowCells);
    }

    cancellationToken?.throwIfCancelled();

    final codec = Csv(
      fieldDelimiter: options.fieldDelimiter,
      lineDelimiter: options.lineDelimiter,
      quoteCharacter: options.quoteCharacter,
      escapeCharacter: options.escapeCharacter,
    );

    final encodedCsv = codec.encode(rowsMatrix);
    final utf8Bytes = utf8.encode(encodedCsv);

    if (options.addUtf8Bom) {
      // UTF-8 BOM: 0xEF, 0xBB, 0xBF
      return <int>[0xEF, 0xBB, 0xBF, ...utf8Bytes];
    }

    return utf8Bytes;
  }

  List<DocumentColumn> _resolveColumns(
    DocumentDataset dataset,
    ExportDefinition definition,
  ) {
    if (definition.columns == null) {
      return dataset.definition.visibleColumns;
    }
    final result = <DocumentColumn>[];
    for (final colId in definition.columns!) {
      final col = dataset.definition.getColumn(colId);
      if (col != null) {
        result.add(col);
      }
    }
    return result;
  }

  dynamic _serializeValue(
    DocumentValue val,
    ExportDefinition definition,
  ) {
    if (val.isNull) {
      return options.nullRepresentation;
    }

    switch (val) {
      case TextDocumentValue(:final value):
        if (definition.protectFormulas || options.sanitizeFormulaInjection) {
          return ExportDefinition.sanitizeFormula(value);
        }
        return value;

      case IntDocumentValue(:final value):
        return value;

      case DecimalDocumentValue(:final value):
        return value.toString();

      case DateDocumentValue(:final value):
        final y = value.year.toString().padLeft(4, '0');
        final m = value.month.toString().padLeft(2, '0');
        final d = value.day.toString().padLeft(2, '0');
        return '$y-$m-$d';

      case DateTimeDocumentValue(:final value):
        return value.toIso8601String();

      case BoolDocumentValue(:final value):
        return value ? 'true' : 'false';

      case NullDocumentValue():
        return options.nullRepresentation;
    }
  }
}
