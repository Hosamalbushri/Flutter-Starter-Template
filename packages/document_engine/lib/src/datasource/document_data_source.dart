import 'dart:async';

import '../model/document_dataset.dart';
import '../model/document_definition.dart';
import '../model/document_row.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';

/// Abstract tabular data source that can stream rows on demand.
abstract interface class DocumentDataSource {
  /// Schema definition describing columns and types.
  DocumentDefinition get definition;

  /// Opens a stream of rows.
  Stream<DocumentRow> openStream({CancellationToken? cancellationToken});

  /// Total count of rows in the data source, if known.
  Future<int?> getRowCount({CancellationToken? cancellationToken});

  /// Materializes rows into an in-memory [DocumentDataset].
  Future<DocumentDataset> toDataset({
    int? limit,
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  });
}

/// An in-memory data source backed directly by a [DocumentDataset].
class MemoryDocumentDataSource implements DocumentDataSource {
  const MemoryDocumentDataSource(this.dataset);

  final DocumentDataset dataset;

  @override
  DocumentDefinition get definition => dataset.definition;

  @override
  Stream<DocumentRow> openStream({
    CancellationToken? cancellationToken,
  }) async* {
    for (var i = 0; i < dataset.rows.length; i++) {
      cancellationToken?.throwIfCancelled();
      yield dataset.rows[i];
    }
  }

  @override
  Future<int> getRowCount({CancellationToken? cancellationToken}) async {
    cancellationToken?.throwIfCancelled();
    return dataset.length;
  }

  @override
  Future<DocumentDataset> toDataset({
    int? limit,
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    final total = dataset.length;
    final effectiveLimit = limit != null && limit < total ? limit : total;

    onProgress?.call(
      DocumentProgress(
        phase: DocumentPhase.reading,
        current: 0,
        total: effectiveLimit,
      ),
    );

    final selected = dataset.rows.take(effectiveLimit).toList();

    onProgress?.call(
      DocumentProgress(
        phase: DocumentPhase.completed,
        current: selected.length,
        total: effectiveLimit,
      ),
    );

    return DocumentDataset(definition: definition, rows: selected);
  }
}
