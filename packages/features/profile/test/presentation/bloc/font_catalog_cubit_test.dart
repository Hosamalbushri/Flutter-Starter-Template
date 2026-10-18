import 'package:feature_profile/src/presentation/bloc/font_catalog_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFontCatalogSource {
  _FakeFontCatalogSource(this.families);

  final List<String> families;
  final calls = <({int offset, int limit, String query})>[];

  Future<FontCatalogPage> loadPage({
    required int offset,
    required int limit,
    required String query,
  }) async {
    calls.add((offset: offset, limit: limit, query: query));
    final matches = families
        .where((font) => font.toLowerCase().contains(query.toLowerCase()))
        .toList(growable: false);
    final end = (offset + limit).clamp(0, matches.length);
    return FontCatalogPage(
      items: offset >= matches.length ? const [] : matches.sublist(offset, end),
      hasMore: end < matches.length,
    );
  }
}

void main() {
  test('loads only the first page initially', () async {
    final source = _FakeFontCatalogSource(
      List.generate(8, (index) => 'Font $index'),
    );
    final cubit = FontCatalogCubit(source.loadPage, pageSize: 3);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.items, ['Font 0', 'Font 1', 'Font 2']);
    expect(cubit.state.hasMore, isTrue);
    expect(source.calls, [(offset: 0, limit: 3, query: '')]);
  });

  test('appends the next page when requested', () async {
    final source = _FakeFontCatalogSource(
      List.generate(5, (index) => 'Font $index'),
    );
    final cubit = FontCatalogCubit(source.loadPage, pageSize: 3);
    addTearDown(cubit.close);
    await cubit.loadInitial();

    await cubit.loadMore();

    expect(cubit.state.items, [
      'Font 0',
      'Font 1',
      'Font 2',
      'Font 3',
      'Font 4',
    ]);
    expect(cubit.state.hasMore, isFalse);
    expect(source.calls.last, (offset: 3, limit: 3, query: ''));
  });

  test('search replaces items and starts from the first page', () async {
    final source = _FakeFontCatalogSource([
      'Cairo',
      'Inter',
      'Noto Kufi Arabic',
      'Noto Sans Arabic',
    ]);
    final cubit = FontCatalogCubit(source.loadPage, pageSize: 2);
    addTearDown(cubit.close);
    await cubit.loadInitial();

    await cubit.search('Noto');

    expect(cubit.state.items, ['Noto Kufi Arabic', 'Noto Sans Arabic']);
    expect(cubit.state.query, 'Noto');
    expect(source.calls.last, (offset: 0, limit: 2, query: 'Noto'));
  });

  test('does not request another page after reaching the end', () async {
    final source = _FakeFontCatalogSource(['Cairo']);
    final cubit = FontCatalogCubit(source.loadPage, pageSize: 3);
    addTearDown(cubit.close);
    await cubit.loadInitial();

    await cubit.loadMore();

    expect(source.calls, hasLength(1));
  });
}
