import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_contracts/shared_contracts.dart';

import '../entities/collection.dart';
import '../repositories/collections_repository.dart';
import 'collections_import_definition.dart';

/// Importer delegate that converts validated [DocumentRow]s into Collections and
/// commits them via [CollectionsRepository], preserving sync and domain rules.
@lazySingleton
class CollectionsImportDelegate implements DocumentImportDelegate {
  CollectionsImportDelegate(this._repository, this._bookmarkSummaries);

  final CollectionsRepository _repository;
  final BookmarkSummariesReader _bookmarkSummaries;

  @override
  String get datasetId => 'collections';

  @override
  String get datasetLabel => 'Collections';

  @override
  ImportDefinition get importDefinition => createCollectionsImportDefinition();

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
        'Could not read existing collections: ${failure.message}',
        rolledBack: false,
        cause: failure,
      ),
    };

    final existingByName = <String, Collection>{
      for (final c in existingList) c.name.trim().toLowerCase(): c,
    };
    final existingById = <String, Collection>{
      for (final c in existingList) c.id: c,
    };

    final bookmarkResult = await _bookmarkSummaries();
    final validBookmarkIds = switch (bookmarkResult) {
      Ok(value: final bookmarks) => bookmarks.map((item) => item.id).toSet(),
      Err(:final failure) => throw DocumentPersistenceFailure(
        'Could not validate collection bookmark references: ${failure.message}',
        rolledBack: false,
        cause: failure,
      ),
    };

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final skippedIds = <String>[];
    final errors = <String>[];
    final warnings = <String>[];
    final originalsById = <String, Collection>{};

    var duplicateCount = 0;
    var importedCount = 0;
    var failedCount = 0;
    final batchRepository = _repository is CollectionsImportBatchRepository
        ? _repository as CollectionsImportBatchRepository
        : null;
    var batchSuccessful = false;
    batchRepository?.beginImportBatch();

    try {
      for (var i = 0; i < validRows.length; i++) {
        cancellationToken?.throwIfCancelled();
        final row = validRows[i];

        final rawName = _extractString(row, 'name');
        final name = rawName.trim();
        if (name.isEmpty) {
          failedCount++;
          errors.add('Row ${i + 1}: Name cannot be empty.');
          continue;
        }

        final icon = _extractIcon(row);
        final color = _extractColor(row);
        final bookmarkIds = _extractBookmarkIds(row);
        final unknownBookmarkIds = bookmarkIds
            .where((id) => !validBookmarkIds.contains(id))
            .toList(growable: false);
        if (unknownBookmarkIds.isNotEmpty) {
          failedCount++;
          errors.add(
            'Row ${i + 1} ("$name") references unknown bookmark ids: '
            '${unknownBookmarkIds.join(', ')}.',
          );
          continue;
        }

        final normalizedName = name.toLowerCase();
        final match = existingByName[normalizedName];

        if (match != null) {
          duplicateCount++;
          switch (duplicatePolicy) {
            case DuplicatePolicy.skip:
              skippedIds.add(match.id);

            case DuplicatePolicy.update:
              originalsById.putIfAbsent(match.id, () => match);
              final mergedBookmarkIds = <String>{
                ...match.bookmarkIds,
                ...bookmarkIds,
              }.toList();

              final updateResult = await _repository.update(
                match.id,
                CollectionInput(
                  name: match.name,
                  icon: icon.isNotEmpty ? icon : match.icon,
                  color: color != 0 ? color : match.color,
                  bookmarkIds: mergedBookmarkIds,
                ),
              );

              switch (updateResult) {
                case Ok(value: final updated):
                  updatedIds.add(updated.id);
                  importedCount++;
                  existingByName[normalizedName] = updated;
                  existingById[updated.id] = updated;
                case Err(:final failure):
                  throw DocumentPersistenceFailure(
                    'Could not update collection on row ${i + 1}: '
                    '${failure.message}',
                    cause: failure,
                  );
              }

            case DuplicatePolicy.create:
              final createResult = await _repository.create(
                CollectionInput(
                  name: name,
                  icon: icon,
                  color: color,
                  bookmarkIds: bookmarkIds,
                ),
              );

              switch (createResult) {
                case Ok(value: final created):
                  createdIds.add(created.id);
                  importedCount++;
                  existingById[created.id] = created;
                case Err(:final failure):
                  throw DocumentPersistenceFailure(
                    'Could not create collection on row ${i + 1}: '
                    '${failure.message}',
                    cause: failure,
                  );
              }
          }
        } else {
          // Brand new collection
          final createResult = await _repository.create(
            CollectionInput(
              name: name,
              icon: icon,
              color: color,
              bookmarkIds: bookmarkIds,
            ),
          );

          switch (createResult) {
            case Ok(value: final created):
              createdIds.add(created.id);
              importedCount++;
              existingByName[normalizedName] = created;
              existingById[created.id] = created;
            case Err(:final failure):
              throw DocumentPersistenceFailure(
                'Could not create collection on row ${i + 1}: '
                '${failure.message}',
                cause: failure,
              );
          }
        }
      }
      cancellationToken?.throwIfCancelled();
      batchSuccessful = true;
    } on Object catch (error) {
      try {
        await _rollbackChanges(
          createdIds: createdIds,
          originalsById: originalsById,
        );
      } on Object catch (rollbackError) {
        throw DocumentPersistenceFailure(
          'Collections import failed and rollback was incomplete: '
          '$rollbackError',
          rolledBack: false,
          cause: error,
        );
      }
      rethrow;
    } finally {
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

  String _extractIcon(DocumentRow row) {
    final raw = _extractString(row, 'icon').trim();
    return raw.isNotEmpty ? raw : 'folder';
  }

  int _extractColor(DocumentRow row) {
    final val = row.getValue('color');
    if (val is IntDocumentValue) return val.value;
    final raw = _extractString(row, 'color').trim();
    if (raw.isEmpty) return 0xFF2196F3; // default blue

    if (raw.startsWith('#')) {
      final hex = raw.substring(1);
      final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (parsed != null) return parsed;
    }
    return int.tryParse(raw) ?? 0xFF2196F3;
  }

  List<String> _extractBookmarkIds(DocumentRow row) {
    final raw = _extractString(row, 'bookmarkIds').trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp('[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _rollbackChanges({
    required List<String> createdIds,
    required Map<String, Collection> originalsById,
  }) async {
    for (final id in createdIds.reversed) {
      _requireRollbackSuccess(
        await _repository.delete(id),
        'delete collection $id',
      );
    }
    for (final original in originalsById.values) {
      _requireRollbackSuccess(
        await _repository.update(
          original.id,
          CollectionInput(
            name: original.name,
            icon: original.icon,
            color: original.color,
            bookmarkIds: original.bookmarkIds,
          ),
        ),
        'restore collection ${original.id}',
      );
    }
  }

  void _requireRollbackSuccess<T>(Result<T> result, String operation) {
    if (result case Err(:final failure)) {
      throw StateError('Could not $operation: ${failure.message}');
    }
  }
}
