import 'package:meta/meta.dart';

import '../numerics/decimal_number.dart';

/// Supported scalar types for document values and table columns.
enum ColumnType {
  text,
  integer,
  decimal,
  date,
  dateTime,
  boolean,
}

/// A strongly-typed cell value in a document.
@immutable
sealed class DocumentValue {
  const DocumentValue();

  /// Creates a [DocumentValue] by inspecting the runtime type of [value].
  factory DocumentValue.from(Object? value) {
    if (value == null) {
      return const NullDocumentValue();
    }
    if (value is DocumentValue) {
      return value;
    }
    if (value is int) {
      return IntDocumentValue(value);
    }
    if (value is BigInt) {
      return DecimalDocumentValue(DecimalNumber.fromBigInt(value));
    }
    if (value is DecimalNumber) {
      return DecimalDocumentValue(value);
    }
    if (value is double) {
      return DecimalDocumentValue(DecimalNumber.fromDouble(value));
    }
    if (value is bool) {
      return BoolDocumentValue(value: value);
    }
    if (value is DateTime) {
      return DateTimeDocumentValue(value);
    }
    return TextDocumentValue(value.toString());
  }

  /// The raw Dart object representation.
  Object? get raw;

  /// The corresponding schema [ColumnType].
  ColumnType get type;

  /// Whether this value is null.
  bool get isNull => this is NullDocumentValue;

  /// Formatted string representation for display or generic text exports.
  String get displayValue;

  /// Safe cast to string.
  String? get asString => switch (this) {
    final TextDocumentValue t => t.value,
    NullDocumentValue() => null,
    _ => displayValue,
  };

  /// Safe cast to int.
  int? get asInt =>
      this is IntDocumentValue ? (this as IntDocumentValue).value : null;

  /// Safe cast to decimal.
  DecimalNumber? get asDecimal => switch (this) {
    final DecimalDocumentValue d => d.value,
    final IntDocumentValue i => DecimalNumber.fromInt(i.value),
    _ => null,
  };

  /// Safe cast to date.
  DateTime? get asDate => asDateTime;

  /// Safe cast to DateTime.
  DateTime? get asDateTime => switch (this) {
    final DateTimeDocumentValue dt => dt.value,
    final DateDocumentValue d => d.value,
    _ => null,
  };

  /// Safe cast to bool.
  bool? get asBool =>
      this is BoolDocumentValue ? (this as BoolDocumentValue).value : null;
}

/// Textual document value.
final class TextDocumentValue extends DocumentValue {
  const TextDocumentValue(this.value);

  final String value;

  @override
  String get raw => value;

  @override
  ColumnType get type => ColumnType.text;

  @override
  String get displayValue => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TextDocumentValue($value)';
}

/// Integer document value.
final class IntDocumentValue extends DocumentValue {
  const IntDocumentValue(this.value);

  final int value;

  @override
  int get raw => value;

  @override
  ColumnType get type => ColumnType.integer;

  @override
  String get displayValue => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IntDocumentValue($value)';
}

/// Exact decimal document value (financials, measurements, arbitrary precision).
final class DecimalDocumentValue extends DocumentValue {
  const DecimalDocumentValue(this.value);

  final DecimalNumber value;

  @override
  DecimalNumber get raw => value;

  @override
  ColumnType get type => ColumnType.decimal;

  @override
  String get displayValue => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecimalDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DecimalDocumentValue($value)';
}

/// Date-only document value (without time component).
final class DateDocumentValue extends DocumentValue {
  DateDocumentValue(DateTime date)
    : value = DateTime.utc(date.year, date.month, date.day);

  final DateTime value;

  @override
  DateTime get raw => value;

  @override
  ColumnType get type => ColumnType.date;

  @override
  String get displayValue {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DateDocumentValue($displayValue)';
}

/// Date and time document value.
final class DateTimeDocumentValue extends DocumentValue {
  const DateTimeDocumentValue(this.value);

  final DateTime value;

  @override
  DateTime get raw => value;

  @override
  ColumnType get type => ColumnType.dateTime;

  @override
  String get displayValue => value.toIso8601String();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateTimeDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DateTimeDocumentValue($displayValue)';
}

/// Boolean document value.
final class BoolDocumentValue extends DocumentValue {
  const BoolDocumentValue({required this.value});

  final bool value;

  @override
  bool get raw => value;

  @override
  ColumnType get type => ColumnType.boolean;

  @override
  String get displayValue => value ? 'true' : 'false';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoolDocumentValue && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BoolDocumentValue($value)';
}

/// Null document value.
final class NullDocumentValue extends DocumentValue {
  const NullDocumentValue([this.columnType = ColumnType.text]);

  final ColumnType columnType;

  @override
  Object? get raw => null;

  @override
  ColumnType get type => columnType;

  @override
  String get displayValue => '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NullDocumentValue;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NullDocumentValue()';
}
