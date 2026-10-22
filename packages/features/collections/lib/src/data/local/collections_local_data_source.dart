import 'package:database/database.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:rev_sync/rev_sync.dart';

/// ObjectBox-backed CRUD + sync helpers. All operations are synchronous on
/// the ObjectBox side; wrapped in `Future` to keep the repository contract
/// async-friendly.
///
/// Identity at this layer is the string [CollectionEntity.uuid]. The integer
/// `id` is an internal ObjectBox PK that callers never see. Implements
/// [SyncLocalStore] so the generic sync engine can drive it.
abstract interface class CollectionsLocalDataSource
    implements SyncLocalStore<CollectionEntity> {
  /// All non-tombstoned collections, newest-first.
  Future<List<CollectionEntity>> listVisible();

  /// Includes tombstoned (pendingDelete) rows.
  Future<List<CollectionEntity>> listAll();

  /// Inserts a new row in [SyncState.pendingCreate].
  Future<CollectionEntity> putNew(CollectionEntity entity);
}

@LazySingleton(as: CollectionsLocalDataSource)
class ObjectBoxCollectionsDataSource implements CollectionsLocalDataSource {
  ObjectBoxCollectionsDataSource(Store store, this._atomic)
    : _box = store.box<CollectionEntity>();

  final Box<CollectionEntity> _box;
  final AtomicWriteCoordinator _atomic;
  final Map<String, CollectionEntity> _stagedPuts = {};
  final Set<String> _stagedDeletes = {};
  bool _cleanupRegistered = false;

  @override
  Future<List<CollectionEntity>> listVisible() async {
    final query = _box
        .query(
          CollectionEntity_.syncStateCode.notEquals(
            SyncState.pendingDelete.code,
          ),
        )
        .order(CollectionEntity_.createdAt, flags: Order.descending)
        .build();
    try {
      return _mergeStaged(query.find(), visibleOnly: true);
    } finally {
      query.close();
    }
  }

  @override
  Future<List<CollectionEntity>> listAll() async {
    final query = _box
        .query()
        .order(CollectionEntity_.createdAt, flags: Order.descending)
        .build();
    try {
      return _mergeStaged(query.find(), visibleOnly: false);
    } finally {
      query.close();
    }
  }

  @override
  Future<CollectionEntity?> getByUuid(String uuid) async {
    final query = _box.query(CollectionEntity_.uuid.equals(uuid)).build();
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
  Future<List<CollectionEntity>> listPending() async {
    // Only the active push-queue states — conflicted/failed rows await user
    // action and must not be re-pushed.
    final query = _box
        .query(
          CollectionEntity_.syncStateCode.oneOf([
            SyncState.pendingCreate.code,
            SyncState.pendingUpdate.code,
            SyncState.pendingDelete.code,
          ]),
        )
        .order(CollectionEntity_.updatedAt)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<CollectionEntity> putNew(CollectionEntity entity) async {
    if (!_atomic.isActive) {
      return _atomic.run(() => putNew(entity));
    }
    _stagePut(entity);
    return entity;
  }

  @override
  Future<void> put(CollectionEntity entity) async {
    if (!_atomic.isActive) {
      await _atomic.run(() => put(entity));
      return;
    }
    _stagePut(entity);
  }

  @override
  Future<void> hardDelete(CollectionEntity entity) async {
    if (!_atomic.isActive) {
      await _atomic.run(() => hardDelete(entity));
      return;
    }
    _prepareStaging();
    _stagedPuts.remove(entity.uuid);
    _stagedDeletes.add(entity.uuid);
    _atomic.stage(
      sync: () => _box.remove(entity.id),
      async: () async => _box.remove(entity.id),
    );
  }

  void _stagePut(CollectionEntity entity) {
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

  List<CollectionEntity> _mergeStaged(
    List<CollectionEntity> persisted, {
    required bool visibleOnly,
  }) {
    if (!_atomic.isActive) return persisted;
    final byUuid = <String, CollectionEntity>{
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
