import 'package:excel_plus/excel_plus.dart';

import '../failure/document_failure.dart';
import '../import/import_adapter.dart';
import '../import/import_definition.dart';
import '../import/import_plan.dart';
import '../import/table_import_processor.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'xlsx_options.dart';

/// Import adapter for reading Excel (.xlsx and .xls) workbooks.
class XlsxImportAdapter implements ImportAdapter {
  const XlsxImportAdapter({
    this.options = const XlsxImportOptions(),
    this.processor = const TableImportProcessor(),
  });

  /// Options controlling sheet selection, trimming, and empty row skipping.
  final XlsxImportOptions options;

  /// Underlying tabular validation processor.
  final TableImportProcessor processor;

  @override
  String get formatId => 'xlsx';

  @override
  List<String> get supportedExtensions => const ['.xlsx', '.xls'];

  @override
  Future<List<String>> inspectHeaders(
    List<int> bytes, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    _validateDefaultFileSize(bytes.length);

    final excel = _decodeWorkbook(bytes);
    final sheet = _resolveSheet(excel);
    final rows = sheet.rows;

    if (rows.isEmpty) {
      throw const DocumentParseFailure(
        'Excel workbook sheet contains no rows to inspect headers from.',
      );
    }

    final headerRow = rows.first;
    final headers = <String>[];
    for (final cell in headerRow) {
      final raw = _extractCellValue(cell?.value);
      headers.add(raw?.toString().trim() ?? '');
    }
    _validateHeaders(headers);
    return headers;
  }

  @override
  Future<ImportPlan> preparePlan(
    List<int> bytes,
    ImportDefinition definition, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    definition.validateFileSize(bytes.length);

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.reading,
        current: 0,
        total: 100,
        message: 'Opening Excel workbook...',
      ),
    );

    final excel = _decodeWorkbook(bytes);
    cancellationToken?.throwIfCancelled();

    final sheet = _resolveSheet(excel);
    final rows = sheet.rows;

    if (rows.isEmpty) {
      return const ImportPlan(
        totalInspected: 0,
        validRows: [],
        invalidRows: [],
        warnings: [],
        canCommit: false,
      );
    }

    final headerRow = rows.first;
    final headers = <String>[];
    for (final cell in headerRow) {
      final raw = _extractCellValue(cell?.value);
      headers.add(raw?.toString().trim() ?? '');
    }
    _validateHeaders(headers);

    final skipRows = definition.skipHeaderRows > 0
        ? definition.skipHeaderRows
        : 1;
    final dataRows = rows.length > skipRows
        ? rows.sublist(skipRows)
        : <List<Data?>>[];

    final rawRowMaps = <Map<String, Object?>>[];
    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final map = <String, Object?>{};
      var hasAnyValue = false;

      for (var colIdx = 0; colIdx < headers.length; colIdx++) {
        final header = headers[colIdx];
        if (colIdx < row.length) {
          final cellValue = _extractCellValue(row[colIdx]?.value);
          if (cellValue != null) hasAnyValue = true;
          map[header] = cellValue;
        } else {
          map[header] = null;
        }
      }

      if (!options.skipEmptyRows || hasAnyValue) {
        rawRowMaps.add(map);
      }
    }

    return processor.processRows(
      rawRows: rawRowMaps,
      definition: definition,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }

  void _validateDefaultFileSize(int byteLength) {
    if (byteLength > ImportDefinition.defaultMaxFileBytes) {
      throw DocumentValidationFailure(
        'Document is too large ($byteLength bytes); maximum is '
        '${ImportDefinition.defaultMaxFileBytes} bytes.',
      );
    }
  }

  Excel _decodeWorkbook(List<int> bytes) {
    try {
      return Excel.decodeBytes(bytes);
    } on Exception catch (e) {
      throw DocumentParseFailure(
        'Failed to parse Excel workbook: $e',
      );
    }
  }

  Sheet _resolveSheet(Excel excel) {
    if (options.sheetName != null &&
        excel.tables.containsKey(options.sheetName)) {
      return excel.tables[options.sheetName]!;
    }
    if (excel.tables.isNotEmpty) {
      return excel.tables.values.first;
    }
    throw const DocumentParseFailure(
      'Excel workbook contains no readable sheets.',
    );
  }

  Object? _extractCellValue(CellValue? val) {
    if (val == null) return null;
    switch (val) {
      case TextCellValue(:final value):
        final text = value.toString();
        return options.trimText ? text.trim() : text;
      case IntCellValue(:final value):
        return value;
      case DoubleCellValue(:final value):
        return value;
      case DateCellValue():
        return val.asDateTimeUtc();
      case DateTimeCellValue():
        return val.asDateTimeUtc();
      case BoolCellValue(:final value):
        return value;
      case FormulaCellValue(:final cachedValue):
        return cachedValue ?? val.toString();
      case TimeCellValue():
        return val.toString();
      case CellErrorValue():
        return null;
    }
  }

  void _validateHeaders(List<String> headers) {
    final seen = <String>{};
    for (final header in headers) {
      if (header.isEmpty) {
        throw const DocumentParseFailure(
          'Excel headers cannot be empty.',
        );
      }
      if (!seen.add(header)) {
        throw DocumentParseFailure(
          'Duplicate Excel header "$header" would overwrite column data.',
        );
      }
    }
  }
}
