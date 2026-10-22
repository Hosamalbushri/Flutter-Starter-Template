import 'package:meta/meta.dart';

import '../numerics/decimal_number.dart';
import 'document_value.dart';

/// Textual and visual alignment for table columns.
enum ColumnAlignment {
  start,
  center,
  end,
}

/// A validation function for a document cell value.
/// Returns an error message if invalid, or `null` if valid.
typedef ColumnValidator = String? Function(DocumentValue value);

/// Definition of a single tabular column in a document.
@immutable
class DocumentColumn {
  const DocumentColumn({
    required this.id,
    required this.label,
    required this.type,
    this.alignment = ColumnAlignment.start,
    this.formatPattern,
    this.isRequired = false,
    this.isHidden = false,
    this.width,
    this.validator,
  });

  /// Factory for text column.
  factory DocumentColumn.text({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.start,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.text,
    alignment: alignment,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  /// Factory for integer column.
  factory DocumentColumn.integer({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.end,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.integer,
    alignment: alignment,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  /// Factory for decimal column.
  factory DocumentColumn.decimal({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.end,
    String? formatPattern,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.decimal,
    alignment: alignment,
    formatPattern: formatPattern,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  /// Factory for date column.
  factory DocumentColumn.date({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.center,
    String? formatPattern,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.date,
    alignment: alignment,
    formatPattern: formatPattern,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  /// Factory for dateTime column.
  factory DocumentColumn.dateTime({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.center,
    String? formatPattern,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.dateTime,
    alignment: alignment,
    formatPattern: formatPattern,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  /// Factory for boolean column.
  factory DocumentColumn.boolean({
    required String id,
    required String label,
    ColumnAlignment alignment = ColumnAlignment.center,
    bool isRequired = false,
    bool isHidden = false,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id,
    label: label,
    type: ColumnType.boolean,
    alignment: alignment,
    isRequired: isRequired,
    isHidden: isHidden,
    width: width,
    validator: validator,
  );

  final String id;
  final String label;
  final ColumnType type;
  final ColumnAlignment alignment;
  final String? formatPattern;
  final bool isRequired;
  final bool isHidden;
  final double? width;
  final ColumnValidator? validator;

  /// Coerces a raw value into a [DocumentValue] adhering to this column's type.
  DocumentValue parseValue(Object? raw) {
    if (raw == null) {
      return NullDocumentValue(type);
    }
    if (raw is DocumentValue) {
      if (raw.type == type || raw.isNull) {
        return raw;
      }
      return parseValue(raw.raw);
    }

    final rawStr = raw.toString().trim();
    if (rawStr.isEmpty) {
      return NullDocumentValue(type);
    }

    switch (type) {
      case ColumnType.text:
        return TextDocumentValue(rawStr);
      case ColumnType.integer:
        if (raw is int) return IntDocumentValue(raw);
        final parsed = int.tryParse(rawStr);
        if (parsed != null) return IntDocumentValue(parsed);
        // Fallback: double to int
        final d = double.tryParse(rawStr);
        if (d != null) return IntDocumentValue(d.toInt());
        throw FormatException(
          'Cannot parse "$rawStr" as integer for column "$id"',
        );
      case ColumnType.decimal:
        if (raw is DecimalNumber) return DecimalDocumentValue(raw);
        if (raw is int) return DecimalDocumentValue(DecimalNumber.fromInt(raw));
        if (raw is double) {
          return DecimalDocumentValue(DecimalNumber.fromDouble(raw));
        }
        final dec = DecimalNumber.tryParse(rawStr);
        if (dec != null) return DecimalDocumentValue(dec);
        throw FormatException(
          'Cannot parse "$rawStr" as decimal for column "$id"',
        );
      case ColumnType.date:
        if (raw is DateTime) return DateDocumentValue(raw);
        final dt = DateTime.tryParse(rawStr);
        if (dt != null) return DateDocumentValue(dt);
        throw FormatException(
          'Cannot parse "$rawStr" as date for column "$id"',
        );
      case ColumnType.dateTime:
        if (raw is DateTime) return DateTimeDocumentValue(raw);
        final dt = DateTime.tryParse(rawStr);
        if (dt != null) return DateTimeDocumentValue(dt);
        throw FormatException(
          'Cannot parse "$rawStr" as dateTime for column "$id"',
        );
      case ColumnType.boolean:
        if (raw is bool) return BoolDocumentValue(value: raw);
        final lower = rawStr.toLowerCase();
        if (lower == 'true' ||
            lower == '1' ||
            lower == 'yes' ||
            lower == 'y' ||
            lower == 'نعم') {
          return const BoolDocumentValue(value: true);
        }
        if (lower == 'false' ||
            lower == '0' ||
            lower == 'no' ||
            lower == 'n' ||
            lower == 'لا') {
          return const BoolDocumentValue(value: false);
        }
        throw FormatException(
          'Cannot parse "$rawStr" as boolean for column "$id"',
        );
    }
  }

  /// Copies this column definition with modified fields.
  DocumentColumn copyWith({
    String? id,
    String? label,
    ColumnType? type,
    ColumnAlignment? alignment,
    String? formatPattern,
    bool? isRequired,
    bool? isHidden,
    double? width,
    ColumnValidator? validator,
  }) => DocumentColumn(
    id: id ?? this.id,
    label: label ?? this.label,
    type: type ?? this.type,
    alignment: alignment ?? this.alignment,
    formatPattern: formatPattern ?? this.formatPattern,
    isRequired: isRequired ?? this.isRequired,
    isHidden: isHidden ?? this.isHidden,
    width: width ?? this.width,
    validator: validator ?? this.validator,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentColumn &&
          other.id == id &&
          other.label == label &&
          other.type == type &&
          other.alignment == alignment &&
          other.formatPattern == formatPattern &&
          other.isRequired == isRequired &&
          other.isHidden == isHidden &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
    id,
    label,
    type,
    alignment,
    formatPattern,
    isRequired,
    isHidden,
    width,
  );

  @override
  String toString() => 'DocumentColumn(id: $id, label: $label, type: $type)';
}
