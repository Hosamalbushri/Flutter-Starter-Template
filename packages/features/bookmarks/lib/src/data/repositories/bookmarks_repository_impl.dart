import 'package:architecture/architecture.dart';
import 'package:clock/clock.dart';
import 'package:database/database.dart';
import 'package:feature_collections/feature_collections.dart';
import 'package:injectable/injectable.dart';
import 'package:rev_sync/rev_sync.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../../domain/services/bookmarks_sync_controller.dart';
import '../local/bookmark_entity_mapper.dart';
import '../local/bookmarks_local_data_source.dart';

/// Offline-first: reads always serve from the local ObjectBox store, writes
/// commit locally first (and mark sync state), then kick a fire-and-forget
/// sync. The UI gets immediate confirmation regardless of network state.
@LazySingleton(as: BookmarksRepository)
class BookmarksRepositoryImpl
    implements BookmarksRepository, BookmarksImportBatchRepository {
  BookmarksRepositoryImpl(
    this._local,
    this._sync,
    this._uuid,
    this._atomic,
    this._collections,
  );

  final BookmarksLocalDataSource _local;
  final BookmarksSyncController _sync;
  final Uuid _uuid;
  final AtomicWriteCoordinator _atomic;
  final CollectionsMembershipService _collections;
  var _importBatchDepth = 0;
  var _importBatchDirty = false;

  @override
  Future<Result<List<Bookmark>>> list() async {
    final result = await listLocal();
    // Trigger a refresh in the background; reads return immediately.
    _requestSync();
    return result;
  }

  @override
  Future<Result<List<Bookmark>>> listLocal() async {
    return _atomic.run(() async {
      final rows = await _local.listVisible();
      final repair = await _collections.repairDanglingBookmarks(
        rows.map((row) => row.uuid).toSet(),
      );
      if (repair case Err(:final failure)) {
        return Err(failure);
      }
      return Ok(rows.map((e) => e.toDomain()).toList(growable: false));
    });
  }

  @override
  Future<Result<Bookmark>> get(String id) async {
    final row = await _local.getByUuid(id);
    if (row == null || row.syncState == SyncState.pendingDelete) {
      return const Err(NotFoundFailure('Bookmark not found.'));
    }
    return Ok(row.toDomain());
  }

  @override
  Future<Result<Bookmark>> create(BookmarkInput input) async {
    return _atomic.run(() async {
      final normalized = _normalize(input);
      final now = clock.now().toUtc();
      final entity = BookmarkEntity(
        uuid: _uuid.v4(),
        title: normalized.title,
        url: normalized.url,
        description: normalized.description,
        tags: List.of(normalized.tags),
        imageUrls: List.of(normalized.imageUrls),
        videoUrl: normalized.videoUrl,
        createdAt: now,
        updatedAt: now,
        syncStateCode: SyncState.pendingCreate.code,
      );
      await _local.putNew(entity);
      _requestSync();
      return Ok(entity.toDomain());
    });
  }

  @override
  Future<Result<Bookmark>> update(String id, BookmarkInput input) async {
    return _atomic.run(() async {
      final existing = await _local.getByUuid(id);
      if (existing == null || existing.syncState == SyncState.pendingDelete) {
        return const Err(NotFoundFailure('Bookmark not found.'));
      }
      final normalized = _normalize(input);
      existing.applyInput(normalized, now: clock.now().toUtc());
      if (existing.syncState != SyncState.pendingCreate) {
        existing.syncState = SyncState.pendingUpdate;
      }
      await _local.put(existing);
      _requestSync();
      return Ok(existing.toDomain());
    });
  }

  @override
  Future<Result<void>> delete(String id) async {
    return _atomic.run(() async {
      final existing = await _local.getByUuid(id);
      if (existing == null || existing.syncState == SyncState.pendingDelete) {
        return const Err(NotFoundFailure('Bookmark not found.'));
      }
      final cleanup = await _collections.removeBookmarkEverywhere(id);
      if (cleanup case Err(:final failure)) return Err(failure);
      if (existing.syncState == SyncState.pendingCreate) {
        await _local.hardDelete(existing);
        return const Ok(null);
      }
      existing.syncState = SyncState.pendingDelete;
      existing.updatedAt = clock.now().toUtc();
      await _local.put(existing);
      _requestSync();
      return const Ok(null);
    });
  }

  @override
  void beginImportBatch() {
    _importBatchDepth++;
  }

  @override
  void endImportBatch({required bool successful}) {
    if (_importBatchDepth == 0) {
      throw StateError('No bookmarks import batch is active.');
    }
    _importBatchDepth--;
    if (_importBatchDepth != 0) return;

    final shouldSync = successful && _importBatchDirty;
    _importBatchDirty = false;
    if (shouldSync) _sync.sync().fire();
  }

  void _requestSync() {
    if (_atomic.isActive) {
      _atomic.afterCommit(_requestSync);
      return;
    }
    if (_importBatchDepth > 0) {
      _importBatchDirty = true;
      return;
    }
    _sync.sync().fire();
  }

  /// Trim + dedupe tags so storage matches what the server would compute.
  BookmarkInput _normalize(BookmarkInput input) {
    final seen = <String>{};
    final tags = <String>[];
    for (final raw in input.tags) {
      final t = raw.trim();
      if (t.isEmpty || !seen.add(t)) continue;
      tags.add(t);
    }
    return BookmarkInput(
      title: input.title.trim(),
      url: input.url.trim(),
      description: input.description.trim(),
      tags: tags,
      imageUrls: List.of(input.imageUrls),
      videoUrl: input.videoUrl,
    );
  }
}
