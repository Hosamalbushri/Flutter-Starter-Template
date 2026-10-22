import 'package:meta/meta.dart';

import 'document_definition.dart';
import 'document_row.dart';
import 'document_value.dart';

/// An in-memory tabular dataset adhering to a [DocumentDefinition].
@immutable
class DocumentDataset {
  DocumentDataset({
    required this.definition,
    required List<DocumentRow> rows,
  }) : rows = List.unmodifiable(rows);

  /// Empty dataset factory for a given definition.
  factory DocumentDataset.empty(DocumentDefinition definition) =>
      DocumentDataset(definition: definition, rows: const []);

  final DocumentDefinition definition;
  final List<DocumentRow> rows;

  /// Row count.
  int get length => rows.length;

  /// Whether the dataset has no rows.
  bool get isEmpty => rows.isEmpty;

  /// Whether the dataset has at least one row.
  bool get isNotEmpty => rows.isNotEmpty;

  /// Gets row by index.
  DocumentRow operator [](int index) => rows[index];

  /// Extracts all values for a column across all rows.
  List<DocumentValue> getColumnValues(String columnId) =>
      rows.map((row) => row.getValue(columnId)).toList();

  /// Creates a new dataset with additional rows.
  DocumentDataset addRows(Iterable<DocumentRow> newRows) => DocumentDataset(
    definition: definition,
    rows: [...rows, ...newRows],
  );

  DocumentDataset copyWith({
    DocumentDefinition? definition,
    List<DocumentRow>? rows,
  }) => DocumentDataset(
    definition: definition ?? this.definition,
    rows: rows ?? this.rows,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentDataset &&
          other.definition == definition &&
          _listEquals(other.rows, rows));

  @override
  int get hashCode => Object.hash(definition, Object.hashAll(rows));

  @override
  String toString() =>
      'DocumentDataset(title: ${definition.title}, rows: ${rows.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
