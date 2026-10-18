import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class FontCatalogPage {
  const FontCatalogPage({required this.items, required this.hasMore});

  final List<String> items;
  final bool hasMore;
}

typedef FontCatalogLoader =
    Future<FontCatalogPage> Function({
      required int offset,
      required int limit,
      required String query,
    });

Future<FontCatalogPage> loadGoogleFontsPage({
  required int offset,
  required int limit,
  required String query,
}) async {
  final normalizedQuery = query.trim().toLowerCase();
  final matches = GoogleFonts.asMap().keys.where(
    (family) =>
        normalizedQuery.isEmpty ||
        family.toLowerCase().contains(normalizedQuery),
  );
  final window = matches.skip(offset).take(limit + 1).toList(growable: false);
  return FontCatalogPage(
    items: window.take(limit).toList(growable: false),
    hasMore: window.length > limit,
  );
}

class FontCatalogState {
  const FontCatalogState({
    this.items = const [],
    this.query = '',
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<String> items;
  final String query;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  FontCatalogState copyWith({
    List<String>? items,
    String? query,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => FontCatalogState(
    items: items ?? this.items,
    query: query ?? this.query,
    isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : error ?? this.error,
  );
}

class FontCatalogCubit extends Cubit<FontCatalogState> {
  FontCatalogCubit(this._loadPage, {this.pageSize = 30})
    : assert(pageSize > 0, 'pageSize must be greater than zero'),
      super(const FontCatalogState());

  final FontCatalogLoader _loadPage;
  final int pageSize;
  int _requestGeneration = 0;

  Future<void> loadInitial() => _replace(query: state.query);

  Future<void> search(String query) {
    final normalized = query.trim();
    if (normalized == state.query && state.items.isNotEmpty) {
      return Future.value();
    }
    return _replace(query: normalized);
  }

  Future<void> retry() => _replace(query: state.query);

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) return;

    final generation = _requestGeneration;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await _loadPage(
        offset: state.items.length,
        limit: pageSize,
        query: state.query,
      );
      if (generation != _requestGeneration || isClosed) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          isLoadingMore: false,
          hasMore: page.hasMore,
          clearError: true,
        ),
      );
    } on Object catch (error) {
      if (generation != _requestGeneration || isClosed) return;
      emit(state.copyWith(isLoadingMore: false, error: error));
    }
  }

  Future<void> _replace({required String query}) async {
    final generation = ++_requestGeneration;
    emit(FontCatalogState(query: query, isInitialLoading: true));
    try {
      final page = await _loadPage(
        offset: 0,
        limit: pageSize,
        query: query,
      );
      if (generation != _requestGeneration || isClosed) return;
      emit(
        FontCatalogState(
          items: page.items,
          query: query,
          hasMore: page.hasMore,
        ),
      );
    } on Object catch (error) {
      if (generation != _requestGeneration || isClosed) return;
      emit(FontCatalogState(query: query, error: error, hasMore: false));
    }
  }
}
