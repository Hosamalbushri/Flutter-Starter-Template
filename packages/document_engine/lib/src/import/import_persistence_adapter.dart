import '../model/document_row.dart';
import '../progress/cancellation_token.dart';

/// Transactional adapter provided by the host application to commit imported rows.
abstract interface class ImportPersistenceAdapter {
  /// Opens a transaction or staging context.
  Future<void> beginTransaction();

  /// Persists a chunk of validated [rows]. Returns count of rows persisted.
  Future<int> saveChunk(
    List<DocumentRow> rows, {
    CancellationToken? cancellationToken,
  });

  /// Commits the active transaction permanently.
  Future<void> commitTransaction();

  /// Rolls back any changes written in the current transaction.
  Future<void> rollbackTransaction();
}

/// An in-memory persistence adapter useful for tests and staging buffers.
class MemoryImportPersistenceAdapter implements ImportPersistenceAdapter {
  final List<DocumentRow> _committedRows = [];
  final List<DocumentRow> _stagingRows = [];
  bool _inTransaction = false;

  List<DocumentRow> get committedRows => List.unmodifiable(_committedRows);
  bool get inTransaction => _inTransaction;

  @override
  Future<void> beginTransaction() async {
    _inTransaction = true;
    _stagingRows.clear();
  }

  @override
  Future<int> saveChunk(
    List<DocumentRow> rows, {
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    if (!_inTransaction) {
      throw StateError('Cannot save chunk outside an active transaction');
    }
    _stagingRows.addAll(rows);
    return rows.length;
  }

  @override
  Future<void> commitTransaction() async {
    if (!_inTransaction) {
      throw StateError('Cannot commit without an active transaction');
    }
    _committedRows.addAll(_stagingRows);
    _stagingRows.clear();
    _inTransaction = false;
  }

  @override
  Future<void> rollbackTransaction() async {
    _stagingRows.clear();
    _inTransaction = false;
  }
}
