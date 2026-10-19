import 'package:excel_plus/excel_plus.dart';

import '../export/export_adapter.dart';
import '../export/export_definition.dart';
import '../failure/document_failure.dart';
import '../model/document_column.dart';
import '../model/document_dataset.dart';
import '../model/document_value.dart';
import '../numerics/decimal_number.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'xlsx_options.dart';

/// Export adapter that serializes a [DocumentDataset] to an Excel (.xlsx) workbook.
class XlsxExportAdapter implements ExportAdapter {
  const XlsxExportAdapter({
    this.options = const XlsxExportOptions(),
  });

  /// Options governing sheet naming, RTL layout, and formula sanitization.
  final XlsxExportOptions options;

  @override
  String get formatId => 'xlsx';

  @override
  String get primaryExtension => 'xlsx';

  @override
  String get mimeType =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

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

    final excel = Excel.createExcel();
    final sheetName = definition.sheetName.isNotEmpty
        ? definition.sheetName
        : options.defaultSheetName;

    final sheet = excel[sheetName];

    // Remove the default 'Sheet1' if our custom sheet is named differently
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null &&
        defaultSheet != sheetName &&
        sheetName != 'Sheet1') {
      excel.delete(defaultSheet);
    }

    if (options.isRtl) {
      sheet.isRTL = true;
    }

    var currentRow = 0;

    // 1. Headers
    if (definition.includeHeaders) {
      for (var cIdx = 0; cIdx < targetColumns.length; cIdx++) {
        final col = targetColumns[cIdx];
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: cIdx, rowIndex: currentRow),
          TextCellValue(col.label),
        );
      }
      currentRow++;
    }

    // 2. Data rows
    for (var r = 0; r < totalRows; r++) {
      if (r % 100 == 0) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(
          DocumentProgress(
            phase: DocumentPhase.writing,
            current: r,
            total: totalRows,
            message: 'Writing Excel row ${r + 1} of $totalRows...',
          ),
        );
      }

      final row = dataset[r];
      for (var cIdx = 0; cIdx < targetColumns.length; cIdx++) {
        final col = targetColumns[cIdx];
        final docVal = row[col.id];
        final cellValue = _toCellValue(docVal, col.type, definition);

        if (cellValue != null) {
          sheet.updateCell(
            CellIndex.indexByColumnRow(
              columnIndex: cIdx,
              rowIndex: currentRow,
            ),
            cellValue,
          );
        }
      }
      currentRow++;
    }

    cancellationToken?.throwIfCancelled();

    final bytes = excel.save();
    if (bytes == null) {
      throw const DocumentOutputFailure(
        'Failed to generate Excel XLSX binary output.',
      );
    }

    return bytes;
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

  CellValue? _toCellValue(
    DocumentValue val,
    ColumnType columnType,
    ExportDefinition definition,
  ) {
    if (val.isNull) return null;

    switch (val) {
      case TextDocumentValue(:final value):
        final sanitized =
            definition.protectFormulas || options.sanitizeFormulaInjection
            ? ExportDefinition.sanitizeFormula(value)
            : value;
        return TextCellValue(sanitized);

      case IntDocumentValue(:final value):
        return IntCellValue(value);

      case DecimalDocumentValue(:final value):
        final doubleValue = value.toDouble();
        return DecimalNumber.fromDouble(doubleValue) == value
            ? DoubleCellValue(doubleValue)
            : TextCellValue(value.toString());

      case DateDocumentValue(:final value):
        return DateCellValue(
          year: value.year,
          month: value.month,
          day: value.day,
        );

      case DateTimeDocumentValue(:final value):
        if (columnType == ColumnType.date) {
          return DateCellValue(
            year: value.year,
            month: value.month,
            day: value.day,
          );
        }
        return DateTimeCellValue.fromDateTime(value);

      case BoolDocumentValue(:final value):
        return BoolCellValue(value);

      case NullDocumentValue():
        return null;
    }
  }
}
