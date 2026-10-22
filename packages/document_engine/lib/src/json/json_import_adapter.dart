import 'dart:convert';

import '../failure/document_failure.dart';
import '../import/import_adapter.dart';
import '../import/import_definition.dart';
import '../import/import_plan.dart';
import '../import/table_import_processor.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'json_options.dart';

/// Import adapter for JSON-formatted tabular documents.
class JsonImportAdapter implements ImportAdapter {
  const JsonImportAdapter({
    this.options = const JsonImportOptions(),
    this.processor = const TableImportProcessor(),
  });

  /// Options controlling key discovery and extraction.
  final JsonImportOptions options;

  /// Underlying tabular validation processor.
  final TableImportProcessor processor;

  @override
  String get formatId => 'json';

  @override
  List<String> get supportedExtensions => const ['.json'];

  @override
  Future<List<String>> inspectHeaders(
    List<int> bytes, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    _validateDefaultFileSize(bytes.length);

    final text = _decodeUtf8(bytes);
    final decoded = _parseJson(text);
    final records = _extractRecords(decoded);

    if (records.isEmpty) {
      throw const DocumentParseFailure(
        'JSON document contains no records to inspect headers from.',
      );
    }

    final headers = <String>{};
    for (final rec in records) {
      if (rec is Map) {
        for (final k in rec.keys) {
          headers.add(k.toString());
        }
      }
    }

    return headers.toList(growable: false);
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
        message: 'Parsing JSON data...',
      ),
    );

    final text = _decodeUtf8(bytes);
    cancellationToken?.throwIfCancelled();

    final decoded = _parseJson(text);
    cancellationToken?.throwIfCancelled();

    final records = _extractRecords(decoded);
    if (records.isEmpty) {
      return const ImportPlan(
        totalInspected: 0,
        validRows: [],
        invalidRows: [],
        warnings: [],
        canCommit: false,
      );
    }

    final rawRowMaps = <Map<String, Object?>>[];
    for (final rec in records) {
      if (rec is Map) {
        final rowMap = <String, Object?>{};
        for (final entry in rec.entries) {
          rowMap[entry.key.toString()] = entry.value;
        }
        rawRowMaps.add(rowMap);
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

  String _decodeUtf8(List<int> bytes) {
    try {
      var decoded = utf8.decode(bytes, allowMalformed: false);
      if (decoded.startsWith('\uFEFF')) {
        decoded = decoded.substring(1);
      }
      return decoded;
    } on FormatException catch (e) {
      throw DocumentParseFailure(
        'JSON input is not valid UTF-8: ${e.message}',
      );
    }
  }

  Object? _parseJson(String input) {
    try {
      return jsonDecode(input);
    } on FormatException catch (e) {
      throw DocumentParseFailure(
        'Malformed JSON input: ${e.message}',
      );
    }
  }

  List<dynamic> _extractRecords(Object? decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map) {
      if (options.dataKey != null && decoded.containsKey(options.dataKey)) {
        final val = decoded[options.dataKey];
        if (val is List) return val;
      }
      for (final commonKey in const ['data', 'records', 'items', 'rows']) {
        if (decoded.containsKey(commonKey)) {
          final val = decoded[commonKey];
          if (val is List) return val;
        }
      }
      for (final val in decoded.values) {
        if (val is List) return val;
      }
    }
    return const [];
  }
}
