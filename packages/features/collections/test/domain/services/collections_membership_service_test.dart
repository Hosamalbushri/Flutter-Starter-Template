import 'package:architecture/architecture.dart';
import 'package:feature_collections/src/domain/entities/collection.dart';
import 'package:feature_collections/src/domain/repositories/collections_repository.dart';
import 'package:feature_collections/src/domain/services/collections_membership_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements CollectionsRepository {
  _Repository(this.items);

  final Map<String, Collection> items;
  @override
  Future<Result<List<Collection>>> list() => listLocal();

  @override
  Future<Result<List<Collection>>> listLocal() async =>
      Ok(items.values.toList());

  @override
  Future<Result<Collection>> get(String id) async => Ok(items[id]!);

  @override
  Future<Result<Collection>> update(String id, CollectionInput input) async {
    final current = items[id]!;
    final updated = Collection(
      id: id,
      name: input.name,
      icon: input.icon,
      color: input.color,
      bookmarkIds: List.of(input.bookmarkIds),
      createdAt: current.createdAt,
      updatedAt: DateTime.utc(2026, 2),
    );
    items[id] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<Collection>> create(CollectionInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> delete(String id) {
    throw UnimplementedError();
  }
}

Collection _collection(String id, List<String> bookmarkIds) => Collection(
  id: id,
  name: id,
  icon: 'folder',
  color: 0,
  bookmarkIds: bookmarkIds,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  test(
    'removes a deleted bookmark from every collection and preserves peers',
    () async {
      final repository = _Repository({
        'c-1': _collection('c-1', ['target', 'keep-1']),
        'c-2': _collection('c-2', ['target']),
        'c-3': _collection('c-3', ['keep-2']),
      });
      final service = CollectionsMembershipService(repository);

      final result = await service.removeBookmarkEverywhere('target');

      expect(result, isA<Ok<void>>());
      expect(repository.items['c-1']!.bookmarkIds, ['keep-1']);
      expect(repository.items['c-2']!.bookmarkIds, isEmpty);
      expect(repository.items['c-3']!.bookmarkIds, ['keep-2']);
      expect(
        repository.items.values.expand((item) => item.bookmarkIds),
        isNot(contains('target')),
      );
    },
  );

  test(
    'repairs legacy dangling IDs without changing valid memberships',
    () async {
      final repository = _Repository({
        'legacy': _collection('legacy', ['valid-1', 'missing', 'valid-2']),
        'clean': _collection('clean', ['valid-2']),
      });
      final service = CollectionsMembershipService(repository);

      final result = await service.repairDanglingBookmarks({
        'valid-1',
        'valid-2',
      });

      expect(result, isA<Ok<void>>());
      expect(repository.items['legacy']!.bookmarkIds, ['valid-1', 'valid-2']);
      expect(repository.items['clean']!.bookmarkIds, ['valid-2']);
    },
  );
}
