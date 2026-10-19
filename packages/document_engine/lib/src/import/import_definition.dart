import 'package:meta/meta.dart';

import '../failure/document_failure.dart';
import '../model/document_definition.dart';

/// Configuration driving the tabular data import process.
@immutable
class ImportDefinition {
  const ImportDefinition({
    required this.targetDefinition,
    this.columnMappings = const {},
    this.skipHeaderRows = 1,
    this.maxRows,
    this.maxFileBytes = defaultMaxFileBytes,
    this.allowPartial = false,
    this.strictTypes = false,
    this.dateFormats = const [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
    ],
  });

  /// Conservative default that prevents adapters from decoding arbitrarily
  /// large in-memory inputs.
  static const int defaultMaxFileBytes = 10 * 1024 * 1024;

  /// Target schema that rows will be mapped and validated against.
  final DocumentDefinition targetDefinition;

  /// Mapping from input file header/index string to [targetDefinition] column id.
  final Map<String, String> columnMappings;

  /// Number of header rows to skip before data rows begin (default 1).
  final int skipHeaderRows;

  /// Maximum number of data rows to process (null for unlimited).
  final int? maxRows;

  /// Maximum accepted encoded input size. Set to `null` only when the caller
  /// provides an equivalent bounded streaming or storage layer.
  final int? maxFileBytes;

  /// Whether to allow importing valid rows even if some rows fail validation.
  final bool allowPartial;

  /// If true, type mismatches fail immediately without fallback coercion.
  final bool strictTypes;

  /// Supported date format patterns to attempt when parsing strings.
  final List<String> dateFormats;

  /// Rejects input before an adapter allocates decoded text/workbook objects.
  void validateFileSize(int byteLength) {
    final limit = maxFileBytes;
    if (limit != null && byteLength > limit) {
      throw DocumentValidationFailure(
        'Document is too large ($byteLength bytes); maximum is $limit bytes.',
      );
    }
  }

  /// Resolves the target column ID for a given source header name.
  String? resolveTargetColumnId(String sourceHeader) {
    if (columnMappings.containsKey(sourceHeader)) {
      return columnMappings[sourceHeader];
    }
    // Default fallback: direct match by id or label (case-insensitive)
    final trimmed = sourceHeader.trim().toLowerCase();
    for (final col in targetDefinition.columns) {
      if (col.id.toLowerCase() == trimmed ||
          col.label.toLowerCase() == trimmed) {
        return col.id;
      }
    }
    return null;
  }

  ImportDefinition copyWith({
    DocumentDefinition? targetDefinition,
    Map<String, String>? columnMappings,
    int? skipHeaderRows,
    int? maxRows,
    int? maxFileBytes,
    bool? allowPartial,
    bool? strictTypes,
    List<String>? dateFormats,
  }) => ImportDefinition(
    targetDefinition: targetDefinition ?? this.targetDefinition,
    columnMappings: columnMappings ?? this.columnMappings,
    skipHeaderRows: skipHeaderRows ?? this.skipHeaderRows,
    maxRows: maxRows ?? this.maxRows,
    maxFileBytes: maxFileBytes ?? this.maxFileBytes,
    allowPartial: allowPartial ?? this.allowPartial,
    strictTypes: strictTypes ?? this.strictTypes,
    dateFormats: dateFormats ?? this.dateFormats,
  );
}
