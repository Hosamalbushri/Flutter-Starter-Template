import 'package:meta/meta.dart';

import 'document_value.dart';

/// A single row of data inside a document dataset.
@immutable
class DocumentRow {
  DocumentRow({
    required this.index,
    required Map<String, DocumentValue> cells,
  }) : cells = Map.unmodifiable(cells);

  /// Convenient factory to construct a row from raw map entries.
  factory DocumentRow.fromRaw({
    required int index,
    required Map<String, Object?> rawCells,
  }) {
    final parsed = <String, DocumentValue>{
      for (final entry in rawCells.entries)
        entry.key: DocumentValue.from(entry.value),
    };
    return DocumentRow(index: index, cells: parsed);
  }

  /// 0-indexed row position in the dataset.
  final int index;

  /// Cell values keyed by column identifier.
  final Map<String, DocumentValue> cells;

  /// Retrieves the value for the given [columnId], or [NullDocumentValue] if not present.
  DocumentValue getValue(String columnId) =>
      cells[columnId] ?? const NullDocumentValue();

  /// Map-style bracket operator for [getValue].
  DocumentValue operator [](String columnId) => getValue(columnId);

  /// Map of raw Dart objects.
  Map<String, Object?> get rawValues =>
      cells.map((key, value) => MapEntry(key, value.raw));

  /// Creates a copy of this row with updated index or cells.
  DocumentRow copyWith({
    int? index,
    Map<String, DocumentValue>? cells,
  }) => DocumentRow(
    index: index ?? this.index,
    cells: cells ?? this.cells,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.index == index &&
          _mapEquals(other.cells, cells));

  @override
  int get hashCode => Object.hash(index, Object.hashAll(cells.entries));

  @override
  String toString() => 'DocumentRow(index: $index, cells: ${cells.length})';

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}
