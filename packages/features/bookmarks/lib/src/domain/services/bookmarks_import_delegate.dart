import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:feature_collections/feature_collections.dart';
import 'package:injectable/injectable.dart';

import '../entities/bookmark.dart';
import '../repositories/bookmarks_repository.dart';
import 'bookmarks_import_definition.dart';

/// Importer delegate that converts validated [DocumentRow]s into Bookmarks,
/// optionally wires relationships with Collections, and commits via
/// [BookmarksRepository] and [CollectionsMembershipService], preserving sync and domain rules.
@lazySingleton
class BookmarksImportDelegate implements DocumentImportDelegate {
  BookmarksImportDelegate(this._repository, [this._collectionsService]);

  final BookmarksRepository _repository;
  final CollectionsMembershipService? _collectionsService;

  @override
  String get datasetId => 'bookmarks';

  @override
  String get datasetLabel => 'Bookmarks';

  @override
  ImportDefinition get importDefinition => createBookmarksImportDefinition();

  @override
  Future<ImportResultReport> executeImport({
    required List<DocumentRow> validRows,
    required DuplicatePolicy duplicatePolicy,
    CancellationToken? cancellationToken,
  }) async {
    final existingResult = await _repository.listLocal();
    final existingList = switch (existingResult) {
      Ok(value: final items) => items,
      Err(:final failure) => throw DocumentPersistenceFailure(
        'Could not read existing bookmarks: ${failure.message}',
        rolledBack: false,
        cause: failure,
      ),
    };

    final existingByUrl = <String, Bookmark>{
      for (final b in existingList) b.url.trim().toLowerCase(): b,
    };
    final existingById = <String, Bookmark>{
      for (final b in existingList) b.id: b,
    };

    // Index collections for relationship wiring if service is provided
    final collectionsByName = <String, Collection>{};
    final collectionsById = <String, Collection>{};
    final externalToInternalCollectionIdMap = <String, String>{};

    if (_collectionsService != null) {
      final collectionsResult = await _collectionsService.listCollections();
      if (collectionsResult case Ok(value: final cols)) {
        for (final c in cols) {
          collectionsByName[c.name.trim().toLowerCase()] = c;
          collectionsById[c.id] = c;
        }
      } else if (collectionsResult case Err(:final failure)) {
        throw DocumentPersistenceFailure(
          'Could not read existing collections: ${failure.message}',
          rolledBack: false,
          cause: failure,
        );
      }
    }

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final skippedIds = <String>[];
    final errors = <String>[];
    final warnings = <String>[];
    final originalBookmarksById = <String, Bookmark>{};
    final originalCollectionsById = <String, Collection>{};
    final createdCollectionIds = <String>[];

    var duplicateCount = 0;
    var importedCount = 0;
    var failedCount = 0;
    final batchRepository = _repository is BookmarksImportBatchRepository
        ? _repository as BookmarksImportBatchRepository
        : null;
    var batchSuccessful = false;
    batchRepository?.beginImportBatch();
    _collectionsService?.beginImportBatch();

    try {
      for (var i = 0; i < validRows.length; i++) {
        cancellationToken?.throwIfCancelled();
        final row = validRows[i];

        final title = _extractString(row, 'title').trim();
        final rawUrl = _extractString(row, 'url').trim();

        if (title.isEmpty) {
          failedCount++;
          errors.add('Row ${i + 1}: Title cannot be empty.');
          continue;
        }

        if (rawUrl.isEmpty) {
          failedCount++;
          errors.add('Row ${i + 1}: URL cannot be empty.');
          continue;
        }

        final description = _extractString(row, 'description').trim();
        final tags = _extractList(row, 'tags');
        final imageUrls = _extractList(row, 'imageUrls');
        final videoUrl = _extractString(row, 'videoUrl').trim();
        final collectionRef = _extractString(row, 'collection').trim();

        final normalizedUrl = rawUrl.toLowerCase();
        final match = existingByUrl[normalizedUrl];

        String? targetBookmarkId;

        if (match != null) {
          duplicateCount++;
          switch (duplicatePolicy) {
            case DuplicatePolicy.skip:
              skippedIds.add(match.id);
              targetBookmarkId = match.id;

            case DuplicatePolicy.update:
              originalBookmarksById.putIfAbsent(match.id, () => match);
              final mergedTags = <String>{...match.tags, ...tags}.toList();
              final mergedImages = <String>{
                ...match.imageUrls,
                ...imageUrls,
              }.toList();

              final updateResult = await _repository.update(
                match.id,
                BookmarkInput(
                  title: title.isNotEmpty ? title : match.title,
                  url: match.url,
                  description: description.isNotEmpty
                      ? description
                      : match.description,
                  tags: mergedTags,
                  imageUrls: mergedImages,
                  videoUrl: videoUrl.isNotEmpty ? videoUrl : match.videoUrl,
                ),
              );

              switch (updateResult) {
                case Ok(value: final updated):
                  updatedIds.add(updated.id);
                  importedCount++;
                  existingByUrl[normalizedUrl] = updated;
                  existingById[updated.id] = updated;
                  targetBookmarkId = updated.id;
                case Err(:final failure):
                  throw DocumentPersistenceFailure(
                    'Could not update bookmark on row ${i + 1}: ${failure.message}',
                    cause: failure,
                  );
              }

            case DuplicatePolicy.create:
              final createResult = await _repository.create(
                BookmarkInput(
                  title: title,
                  url: rawUrl,
                  description: description,
                  tags: tags,
                  imageUrls: imageUrls,
                  videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
                ),
              );

              switch (createResult) {
                case Ok(value: final created):
                  createdIds.add(created.id);
                  importedCount++;
                  existingById[created.id] = created;
                  targetBookmarkId = created.id;
                case Err(:final failure):
                  throw DocumentPersistenceFailure(
                    'Could not create bookmark on row ${i + 1}: ${failure.message}',
                    cause: failure,
                  );
              }
          }
        } else {
          // Brand new bookmark
          final createResult = await _repository.create(
            BookmarkInput(
              title: title,
              url: rawUrl,
              description: description,
              tags: tags,
              imageUrls: imageUrls,
              videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
            ),
          );

          switch (createResult) {
            case Ok(value: final created):
              createdIds.add(created.id);
              importedCount++;
              existingByUrl[normalizedUrl] = created;
              existingById[created.id] = created;
              targetBookmarkId = created.id;
            case Err(:final failure):
              throw DocumentPersistenceFailure(
                'Could not create bookmark on row ${i + 1}: ${failure.message}',
                cause: failure,
              );
          }
        }

        // Relationship wiring: Assign bookmark to collection if requested
        if (collectionRef.isNotEmpty && _collectionsService != null) {
          final colKey = collectionRef.toLowerCase();
          var targetCol =
              collectionsByName[colKey] ??
              collectionsById[collectionRef] ??
              (externalToInternalCollectionIdMap.containsKey(collectionRef)
                  ? collectionsById[externalToInternalCollectionIdMap[collectionRef]!]
                  : null);

          if (targetCol == null) {
            // Auto-create missing collection via CollectionsMembershipService
            final newColResult = await _collectionsService.resolveForImport(
              collectionRef,
            );

            if (newColResult case Ok(value: final resolution)) {
              final newCol = resolution.collection;
              if (resolution.wasCreated) {
                createdCollectionIds.add(newCol.id);
              } else {
                originalCollectionsById.putIfAbsent(newCol.id, () => newCol);
              }
              // Now add bookmark to the new collection
              final linkResult = await _collectionsService.addBookmark(
                newCol.id,
                targetBookmarkId,
              );
              if (linkResult case Ok(value: final linkedCol)) {
                targetCol = linkedCol;
                collectionsByName[colKey] = linkedCol;
                collectionsById[linkedCol.id] = linkedCol;
                externalToInternalCollectionIdMap[collectionRef] = linkedCol.id;
              } else if (linkResult case Err(:final failure)) {
                throw DocumentPersistenceFailure(
                  'Could not link bookmark "$title" to collection '
                  '"${newCol.name}": ${failure.message}',
                  cause: failure,
                );
              }
            } else if (newColResult case Err(:final failure)) {
              throw DocumentPersistenceFailure(
                'Could not resolve collection "$collectionRef": ${failure.message}',
                cause: failure,
              );
            }
          } else {
            // Link bookmark to existing collection if not already linked
            if (!targetCol.bookmarkIds.contains(targetBookmarkId)) {
              originalCollectionsById.putIfAbsent(
                targetCol.id,
                () => targetCol!,
              );
              final linkResult = await _collectionsService.addBookmark(
                targetCol.id,
                targetBookmarkId,
              );

              if (linkResult case Ok(value: final updatedCol)) {
                collectionsByName[colKey] = updatedCol;
                collectionsById[updatedCol.id] = updatedCol;
              } else if (linkResult case Err(:final failure)) {
                throw DocumentPersistenceFailure(
                  'Could not link bookmark "$title" to collection '
                  '"${targetCol.name}": ${failure.message}',
                  cause: failure,
                );
              }
            }
          }
        } else if (collectionRef.isNotEmpty) {
          throw const DocumentPersistenceFailure(
            'Collections service is unavailable for a bookmark relationship.',
            rolledBack: false,
          );
        }
      }
      cancellationToken?.throwIfCancelled();
      batchSuccessful = true;
    } on Object catch (error) {
      try {
        await _rollbackImport(
          createdBookmarkIds: createdIds,
          originalBookmarksById: originalBookmarksById,
          createdCollectionIds: createdCollectionIds,
          originalCollectionsById: originalCollectionsById,
        );
      } on Object catch (rollbackError) {
        throw DocumentPersistenceFailure(
          'Import failed and rollback was incomplete: $rollbackError',
          rolledBack: false,
          cause: error,
        );
      }
      rethrow;
    } finally {
      _collectionsService?.endImportBatch(successful: batchSuccessful);
      batchRepository?.endImportBatch(successful: batchSuccessful);
    }

    return ImportResultReport(
      totalRead: validRows.length,
      validCount: validRows.length,
      invalidCount: 0,
      duplicateCount: duplicateCount,
      importedCount: importedCount,
      failedCount: failedCount,
      createdIds: createdIds,
      updatedIds: updatedIds,
      skippedIds: skippedIds,
      errors: errors,
      warnings: warnings,
    );
  }

  String _extractString(DocumentRow row, String key) {
    final val = row.getValue(key);
    if (val is NullDocumentValue) return '';
    if (val is TextDocumentValue) return val.value;
    if (val is IntDocumentValue) return val.value.toString();
    if (val is DecimalDocumentValue) return val.value.toString();
    return val.displayValue;
  }

  List<String> _extractList(DocumentRow row, String key) {
    final raw = _extractString(row, key).trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp('[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _rollbackImport({
    required List<String> createdBookmarkIds,
    required Map<String, Bookmark> originalBookmarksById,
    required List<String> createdCollectionIds,
    required Map<String, Collection> originalCollectionsById,
  }) async {
    final collectionsService = _collectionsService;
    if (collectionsService != null) {
      for (final original in originalCollectionsById.values) {
        _requireRollbackSuccess(
          await collectionsService.restoreForImport(original),
          'restore collection ${original.id}',
        );
      }
      for (final id in createdCollectionIds.reversed) {
        _requireRollbackSuccess(
          await collectionsService.deleteForImport(id),
          'delete collection $id',
        );
      }
    }

    for (final original in originalBookmarksById.values) {
      _requireRollbackSuccess(
        await _repository.update(
          original.id,
          BookmarkInput(
            title: original.title,
            url: original.url,
            description: original.description,
            tags: original.tags,
            imageUrls: original.imageUrls,
            videoUrl: original.videoUrl,
          ),
        ),
        'restore bookmark ${original.id}',
      );
    }
    for (final id in createdBookmarkIds.reversed) {
      _requireRollbackSuccess(
        await _repository.delete(id),
        'delete bookmark $id',
      );
    }
  }

  void _requireRollbackSuccess<T>(Result<T> result, String operation) {
    if (result case Err(:final failure)) {
      throw StateError('Could not $operation: ${failure.message}');
    }
  }
}
