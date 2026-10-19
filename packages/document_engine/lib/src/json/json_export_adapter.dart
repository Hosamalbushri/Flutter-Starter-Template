import 'dart:convert';

import '../export/export_adapter.dart';
import '../export/export_definition.dart';
import '../model/document_column.dart';
import '../model/document_dataset.dart';
import '../model/document_value.dart';
import '../numerics/decimal_number.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'json_options.dart';

/// Export adapter that serializes a [DocumentDataset] to structured JSON.
class JsonExportAdapter implements ExportAdapter {
  const JsonExportAdapter({
    this.options = const JsonExportOptions(),
  });

  /// Options governing indentation, keys, and metadata wrapping.
  final JsonExportOptions options;

  @override
  String get formatId => 'json';

  @override
  String get primaryExtension => 'json';

  @override
  String get mimeType => 'application/json';

  @override
  Future<List<int>> export(
    DocumentDataset dataset,
    ExportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();

    final targetColumns = _resolveColumns(dataset, definition);
    final totalRows = dataset.length;
    final records = <Map<String, dynamic>>[];

    for (var i = 0; i < totalRows; i++) {
      if (i % 100 == 0) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(
          DocumentProgress(
            phase: DocumentPhase.writing,
            current: i,
            total: totalRows,
            message: 'Exporting JSON row ${i + 1} of $totalRows...',
          ),
        );
      }

      final row = dataset[i];
      final record = <String, dynamic>{};

      for (final col in targetColumns) {
        final key = options.useColumnLabelsAsKeys ? col.label : col.id;
        final docVal = row[col.id];
        record[key] = _serializeValue(docVal, col.type);
      }

      records.add(record);
    }

    cancellationToken?.throwIfCancelled();

    final Object? payload;
    if (options.includeMetadata) {
      payload = <String, dynamic>{
        'metadata': <String, dynamic>{
          'title': dataset.definition.title,
          'id': dataset.definition.id,
          'totalRows': totalRows,
          if (dataset.definition.metadata.author != null)
            'author': dataset.definition.metadata.author,
          if (dataset.definition.metadata.customAttributes.isNotEmpty)
            'attributes': dataset.definition.metadata.customAttributes,
        },
        'rows': records,
      };
    } else {
      payload = records;
    }

    final encoder = options.prettyPrint
        ? JsonEncoder.withIndent(options.indent)
        : const JsonEncoder();

    final jsonString = encoder.convert(payload);
    return utf8.encode(jsonString);
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

  dynamic _serializeValue(DocumentValue val, ColumnType columnType) {
    if (val.isNull) return null;

    switch (val) {
      case TextDocumentValue(:final value):
        return value;

      case IntDocumentValue(:final value):
        return value;

      case DecimalDocumentValue(:final value):
        final doubleValue = value.toDouble();
        return DecimalNumber.fromDouble(doubleValue) == value
            ? doubleValue
            : value.toString();

      case DateDocumentValue(:final value):
        final y = value.year.toString().padLeft(4, '0');
        final m = value.month.toString().padLeft(2, '0');
        final d = value.day.toString().padLeft(2, '0');
        return '$y-$m-$d';

      case DateTimeDocumentValue(:final value):
        if (columnType == ColumnType.date) {
          final y = value.year.toString().padLeft(4, '0');
          final m = value.month.toString().padLeft(2, '0');
          final d = value.day.toString().padLeft(2, '0');
          return '$y-$m-$d';
        }
        return value.toIso8601String();

      case BoolDocumentValue(:final value):
        return value;

      case NullDocumentValue():
        return null;
    }
  }
}
