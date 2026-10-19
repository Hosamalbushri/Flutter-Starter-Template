import 'package:meta/meta.dart';

import 'document_column.dart';
import 'document_metadata.dart';

/// Schema definition for a document, containing columns and metadata.
@immutable
class DocumentDefinition {
  DocumentDefinition({
    required this.id,
    required this.title,
    required List<DocumentColumn> columns,
    this.metadata = const DocumentMetadata(),
  }) : columns = List.unmodifiable(columns) {
    if (columns.isEmpty) {
      throw ArgumentError.value(
        columns,
        'columns',
        'DocumentDefinition must have at least one column',
      );
    }
    final ids = <String>{};
    for (final col in columns) {
      if (!ids.add(col.id)) {
        throw ArgumentError(
          'Duplicate column id "${col.id}" in DocumentDefinition "$id"',
        );
      }
    }
  }

  final String id;
  final String title;
  final List<DocumentColumn> columns;
  final DocumentMetadata metadata;

  /// Retrieves a column by its unique identifier.
  DocumentColumn? getColumn(String columnId) {
    for (final col in columns) {
      if (col.id == columnId) return col;
    }
    return null;
  }

  /// Whether a column exists with the specified identifier.
  bool hasColumn(String columnId) => getColumn(columnId) != null;

  /// Ordered list of column identifiers.
  List<String> get columnIds => columns.map((c) => c.id).toList();

  /// Columns that are marked as visible.
  List<DocumentColumn> get visibleColumns =>
      columns.where((c) => !c.isHidden).toList();

  DocumentDefinition copyWith({
    String? id,
    String? title,
    List<DocumentColumn>? columns,
    DocumentMetadata? metadata,
  }) => DocumentDefinition(
    id: id ?? this.id,
    title: title ?? this.title,
    columns: columns ?? this.columns,
    metadata: metadata ?? this.metadata,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentDefinition &&
          other.id == id &&
          other.title == title &&
          other.metadata == metadata &&
          _listEquals(other.columns, columns));

  @override
  int get hashCode => Object.hash(id, title, metadata, Object.hashAll(columns));

  @override
  String toString() =>
      'DocumentDefinition(id: $id, title: $title, columns: ${columns.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
