import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

import '../entities/collection.dart';
import '../repositories/collections_repository.dart';

/// Result of resolving a collection during an import operation.
class CollectionImportResolution {
  const CollectionImportResolution({
    required this.collection,
    required this.wasCreated,
  });

  final Collection collection;
  final bool wasCreated;
}

/// Domain service allowing consumers to resolve collections and link bookmark IDs
/// through the collection feature's repository, preserving sync and validation.
@lazySingleton
class CollectionsMembershipService {
  const CollectionsMembershipService(this._repository);

  final CollectionsRepository _repository;

  /// Defers collection synchronization while an import is mutating relations.
  void beginImportBatch() {
    final repository = _repository;
    if (repository case CollectionsImportBatchRepository batch) {
      batch.beginImportBatch();
    }
  }

  /// Completes the deferred synchronization scope.
  void endImportBatch({required bool successful}) {
    final repository = _repository;
    if (repository case CollectionsImportBatchRepository batch) {
      batch.endImportBatch(successful: successful);
    }
  }

  /// Lists all visible local collections.
  Future<Result<List<Collection>>> listCollections() => _repository.listLocal();

  /// Finds an existing collection by case-insensitive name or creates a new one.
  Future<Result<Collection>> findOrCreate(String name) async {
    final result = await resolveForImport(name);
    return switch (result) {
      Ok(value: final resolution) => Ok(resolution.collection),
      Err(:final failure) => Err(failure),
    };
  }

  /// Resolves a collection and reports whether this call created it, allowing
  /// import orchestration to compensate safely if a later write fails.
  Future<Result<CollectionImportResolution>> resolveForImport(
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Collection name cannot be empty.'));
    }

    final listResult = await _repository.listLocal();
    if (listResult case Ok(value: final list)) {
      final normalized = trimmed.toLowerCase();
      for (final c in list) {
        if (c.name.trim().toLowerCase() == normalized) {
          return Ok(
            CollectionImportResolution(collection: c, wasCreated: false),
          );
        }
      }
    } else if (listResult case Err(:final failure)) {
      return Err(failure);
    }

    final createResult = await _repository.create(
      CollectionInput(
        name: trimmed,
        icon: Collection.defaultIcon,
        color: Collection.defaultColor,
      ),
    );
    return switch (createResult) {
      Ok(value: final collection) => Ok(
        CollectionImportResolution(
          collection: collection,
          wasCreated: true,
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  /// Appends [bookmarkId] to the collection's bookmarkIds if not already present.
  Future<Result<Collection>> addBookmark(
    String collectionId,
    String bookmarkId,
  ) async {
    final colResult = await _repository.get(collectionId);
    if (colResult is! Ok<Collection>) return colResult;
    final col = colResult.value;

    if (col.bookmarkIds.contains(bookmarkId)) {
      return Ok(col);
    }

    final nextIds = [...col.bookmarkIds, bookmarkId];
    return _repository.update(
      col.id,
      CollectionInput(
        name: col.name,
        icon: col.icon,
        color: col.color,
        bookmarkIds: nextIds,
      ),
    );
  }

  /// Restores collection domain data captured before an import mutation.
  Future<Result<Collection>> restoreForImport(Collection original) =>
      _repository.update(
        original.id,
        CollectionInput(
          name: original.name,
          icon: original.icon,
          color: original.color,
          bookmarkIds: original.bookmarkIds,
        ),
      );

  /// Removes a collection created solely by an import that is being rolled back.
  Future<Result<void>> deleteForImport(String collectionId) =>
      _repository.delete(collectionId);
}
