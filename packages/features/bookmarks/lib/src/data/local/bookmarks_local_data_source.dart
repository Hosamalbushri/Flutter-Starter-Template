import 'package:architecture/architecture.dart';
import 'package:database/database.dart';
import 'package:feature_collections/feature_collections.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:rev_sync/rev_sync.dart';

/// ObjectBox-backed CRUD + sync helpers. All operations are synchronous on
/// the ObjectBox side; wrapped in `Future` to keep the repository contract
/// async-friendly.
///
/// Identity at this layer is the string [BookmarkEntity.uuid]. The integer
/// `id` is an internal ObjectBox PK that callers never see. Implements
/// [SyncLocalStore] so the generic sync engine can drive it.
abstract interface class BookmarksLocalDataSource
    implements SyncLocalStore<BookmarkEntity> {
  /// All non-tombstoned bookmarks, newest-first.
  Future<List<BookmarkEntity>> listVisible();

  /// Includes tombstoned (pendingDelete) rows.
  Future<List<BookmarkEntity>> listAll();

  /// Inserts a new row in [SyncState.pendingCreate].
  Future<BookmarkEntity> putNew(BookmarkEntity entity);
}

@LazySingleton(as: BookmarksLocalDataSource)
class ObjectBoxBookmarksDataSource implements BookmarksLocalDataSource {
  ObjectBoxBookmarksDataSource(Store store, this._atomic, this._collections)
    : _box = store.box<BookmarkEntity>();

  final Box<BookmarkEntity> _box;
  final AtomicWriteCoordinator _atomic;
  final CollectionsMembershipService _collections;
  final Map<String, BookmarkEntity> _stagedPuts = {};
  final Set<String> _stagedDeletes = {};
  bool _cleanupRegistered = false;

  @override
  Future<List<BookmarkEntity>> listVisible() async {
    final query = _box
        .query(
          BookmarkEntity_.syncStateCode.notEquals(SyncState.pendingDelete.code),
        )
        .order(BookmarkEntity_.createdAt, flags: Order.descending)
        .build();
    try {
      return _mergeStaged(query.find(), visibleOnly: true);
    } finally {
      query.close();
    }
  }

  @override
  Future<List<BookmarkEntity>> listAll() async {
    final query = _box
        .query()
        .order(BookmarkEntity_.createdAt, flags: Order.descending)
        .build();
    try {
      return _mergeStaged(query.find(), visibleOnly: false);
    } finally {
      query.close();
    }
  }

  @override
  Future<BookmarkEntity?> getByUuid(String uuid) async {
    final query = _box.query(BookmarkEntity_.uuid.equals(uuid)).build();
    try {
      if (_atomic.isActive) {
        if (_stagedDeletes.contains(uuid)) return null;
        final staged = _stagedPuts[uuid];
        if (staged != null) return staged;
      }
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<BookmarkEntity>> listPending() async {
    // Only the active push-queue states — conflicted/failed rows await user
    // action and must not be re-pushed.
    final query = _box
        .query(
          BookmarkEntity_.syncStateCode.oneOf([
            SyncState.pendingCreate.code,
            SyncState.pendingUpdate.code,
            SyncState.pendingDelete.code,
          ]),
        )
        .order(BookmarkEntity_.updatedAt)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<BookmarkEntity> putNew(BookmarkEntity entity) async {
    if (!_atomic.isActive) {
      return _atomic.run(() => putNew(entity));
    }
    _stagePut(entity);
    return entity;
  }

  @override
  Future<void> put(BookmarkEntity entity) async {
    if (!_atomic.isActive) {
      await _atomic.run(() => put(entity));
      return;
    }
    _stagePut(entity);
  }

  @override
  Future<void> hardDelete(BookmarkEntity entity) async {
    await _atomic.run(() async {
      final cleanup = await _collections.removeBookmarkEverywhere(entity.uuid);
      if (cleanup case Err(:final failure)) {
        throw StateError(
          'Could not remove bookmark collection references: ${failure.message}',
        );
      }
      _prepareStaging();
      _stagedPuts.remove(entity.uuid);
      _stagedDeletes.add(entity.uuid);
      _atomic.stage(
        sync: () => _box.remove(entity.id),
        async: () async => _box.remove(entity.id),
      );
    });
  }

  void _stagePut(BookmarkEntity entity) {
    _prepareStaging();
    _stagedDeletes.remove(entity.uuid);
    _stagedPuts[entity.uuid] = entity;
    _atomic.stage(
      sync: () => _box.put(entity),
      async: () async => _box.put(entity),
    );
  }

  void _prepareStaging() {
    if (_cleanupRegistered) return;
    _cleanupRegistered = true;
    _atomic.afterCompletion(() {
      _stagedPuts.clear();
      _stagedDeletes.clear();
      _cleanupRegistered = false;
    });
  }

  List<BookmarkEntity> _mergeStaged(
    List<BookmarkEntity> persisted, {
    required bool visibleOnly,
  }) {
    if (!_atomic.isActive) return persisted;
    final byUuid = <String, BookmarkEntity>{
      for (final entity in persisted) entity.uuid: entity,
      ..._stagedPuts,
    }..removeWhere((uuid, _) => _stagedDeletes.contains(uuid));
    final result = byUuid.values
        .where(
          (entity) =>
              !visibleOnly || entity.syncState != SyncState.pendingDelete,
        )
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
