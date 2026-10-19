import 'dart:convert';

import 'package:csv/csv.dart';

import '../failure/document_failure.dart';
import '../import/import_adapter.dart';
import '../import/import_definition.dart';
import '../import/import_plan.dart';
import '../import/table_import_processor.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'csv_options.dart';

/// Import adapter for comma-separated, semicolon-separated, or tab-separated text documents.
class CsvImportAdapter implements ImportAdapter {
  const CsvImportAdapter({
    this.options = const CsvImportOptions(),
    this.processor = const TableImportProcessor(),
  });

  /// Options controlling delimiter detection and parsing behavior.
  final CsvImportOptions options;

  /// Underlying tabular validation processor.
  final TableImportProcessor processor;

  @override
  String get formatId => 'csv';

  @override
  List<String> get supportedExtensions => const ['.csv', '.tsv', '.txt'];

  @override
  Future<List<String>> inspectHeaders(
    List<int> bytes, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    _validateDefaultFileSize(bytes.length);

    final text = _decodeUtf8(bytes);
    final rows = _parseCsv(text);

    if (rows.isEmpty) {
      throw const DocumentParseFailure(
        'CSV document is empty; no header row found.',
      );
    }

    final headerRow = rows.first;
    final headers = headerRow
        .map((cell) => cell?.toString().trim() ?? '')
        .toList(growable: false);
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
        phase: DocumentPhase.parsing,
        current: 0,
        total: 100,
        message: 'Decoding CSV content...',
      ),
    );

    final text = _decodeUtf8(bytes);
    cancellationToken?.throwIfCancelled();

    final rows = _parseCsv(text);
    cancellationToken?.throwIfCancelled();

    if (rows.isEmpty) {
      return const ImportPlan(
        totalInspected: 0,
        validRows: [],
        invalidRows: [],
        warnings: [],
        canCommit: false,
      );
    }

    final headers = rows.first
        .map((cell) => cell?.toString().trim() ?? '')
        .toList(growable: false);
    _validateHeaders(headers);

    final skipRows = definition.skipHeaderRows > 0
        ? definition.skipHeaderRows
        : 1;
    final dataRows = rows.length > skipRows
        ? rows.sublist(skipRows)
        : <List<dynamic>>[];

    final rawRowMaps = <Map<String, Object?>>[];
    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final map = <String, Object?>{};
      for (var colIdx = 0; colIdx < headers.length; colIdx++) {
        final header = headers[colIdx];
        if (colIdx < row.length) {
          final cellValue = row[colIdx];
          if (options.trimValues && cellValue is String) {
            map[header] = cellValue.trim();
          } else {
            map[header] = cellValue;
          }
        } else {
          map[header] = null;
        }
      }
      rawRowMaps.add(map);
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

  String _decodeUtf8(List<int> bytes) {
    try {
      var decoded = utf8.decode(bytes, allowMalformed: false);
      // Strip UTF-8 Byte Order Mark if present
      if (decoded.startsWith('\uFEFF')) {
        decoded = decoded.substring(1);
      }
      return decoded;
    } on FormatException catch (e) {
      throw DocumentParseFailure(
        'CSV input is not valid UTF-8: ${e.message}',
      );
    }
  }

  List<List<dynamic>> _parseCsv(String input) {
    try {
      final codec = Csv(
        autoDetect: options.autoDetect,
        fieldDelimiter: options.fieldDelimiter ?? ',',
        quoteCharacter: options.quoteCharacter,
        escapeCharacter: options.escapeCharacter,
        skipEmptyLines: options.skipEmptyLines,
      );
      return codec.decode(input);
    } on Exception catch (e) {
      throw DocumentParseFailure(
        'Failed to parse CSV structure: $e',
      );
    }
  }

  void _validateHeaders(List<String> headers) {
    final seen = <String>{};
    for (final header in headers) {
      if (header.isEmpty) {
        throw const DocumentParseFailure(
          'CSV headers cannot be empty.',
        );
      }
      if (!seen.add(header)) {
        throw DocumentParseFailure(
          'Duplicate CSV header "$header" would overwrite column data.',
        );
      }
    }
  }
}
