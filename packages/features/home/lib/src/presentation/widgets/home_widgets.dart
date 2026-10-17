import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_contracts/shared_contracts.dart';
import 'package:shared_ui/shared_ui.dart';

import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
part 'home_welcome.dart';
part 'home_recent.dart';

/// Entry widget for the Home feature dashboard.
class HomeBody extends StatefulWidget {
  /// Creates the dashboard body used by the home screen.
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  static const double _contentMaxWidth = 720;
  static const double _bottomInset = 112;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _selectedFilterIdNotifier = ValueNotifier<String>(
    'all',
  );
  late final Listenable _filterListenable;

  @override
  void initState() {
    super.initState();
    _filterListenable = Listenable.merge([
      _searchController,
      _selectedFilterIdNotifier,
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _selectedFilterIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = SessionScope.maybeOf(context)?.currentUser?.username;
    final identityName = username == null || username.trim().isEmpty
        ? context.l10n.homeAppBarTitle
        : username.trim();
    final identityInitial = identityName.characters.first.toUpperCase();

    return AppScaffold(
      appBar: AppTopBar(
        title: context.l10n.loginHeadline,
        subtitle: identityName,
        variant: AppTopBarVariant.dashboard,
        profileAvatar: DecoratedBox(
          key: const ValueKey('home-dashboard-identity'),
          decoration: BoxDecoration(
            color: context.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Center(
            child: Text(
              identityInitial,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        searchAction: IconButton(
          key: const ValueKey('home-top-bar-search'),
          tooltip: context.l10n.homeSearchTitle,
          onPressed: _searchFocusNode.requestFocus,
          icon: const FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: AppIconSize.sm,
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('home-top-bar-notifications'),
            tooltip: context.l10n.notificationsAppBarTitle,
            onPressed: () => context.go('/notifications'),
            icon: const FaIcon(
              FontAwesomeIcons.bell,
              size: AppIconSize.sm,
            ),
          ),
          IconButton(
            key: const ValueKey('home-top-bar-refresh'),
            tooltip: context.l10n.commonRetry,
            onPressed: () => context.read<HomeBloc>().add(
              const HomeLoadRequested(),
            ),
            icon: const FaIcon(
              FontAwesomeIcons.rotateLeft,
              size: AppIconSize.sm,
            ),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      backgroundColor: context.colorScheme.surfaceContainerLow,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.isLoading && state.totalBookmarks == 0) {
            return const _HomeLoadingState();
          }
          if (state.failure != null && state.totalBookmarks == 0) {
            return AppErrorView(
              title: context.l10n.errorUnknown,
              message: context.l10n.homeLoadError,
              retryLabel: context.l10n.commonRetry,
              onRetry: () =>
                  context.read<HomeBloc>().add(const HomeLoadRequested()),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  _bottomInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // _QuickActions and _WeeklyDigestPanel are outside all
                        // listeners — their entrance animations are never
                        // re-triggered by search/filter input.
                        ListenableBuilder(
                          listenable: _searchController,
                          builder: (context, _) => _SearchSection(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (_) {},
                          ).animateFadeIn(delay: 100.ms),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _QuickActions(
                          onAdd: () => context.push<void>('/bookmarks/new'),
                          onLibrary: () => context.push<void>('/bookmarks'),
                          onTags: () => context.push<void>('/bookmarks'),
                        ).animateSlideUp(delay: 160.ms),
                        const SizedBox(height: AppSpacing.md),
                        ListenableBuilder(
                          listenable: _filterListenable,
                          builder: (context, _) {
                            final filters = _filters(context);
                            final filteredItems = _filterItems(
                              state.recentItems,
                              filters,
                            );
                            final hasActiveFilters =
                                _searchController.text.trim().isNotEmpty ||
                                _selectedFilterIdNotifier.value != 'all';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _FilterChips(
                                  filters: filters,
                                  selectedId: _selectedFilterIdNotifier.value,
                                  onSelected: (filter) =>
                                      _selectedFilterIdNotifier.value =
                                          filter.id,
                                ).animateFadeIn(delay: 220.ms),
                                const SizedBox(height: AppSpacing.xl),
                                _SuggestedBookmarksSection(
                                  items: filteredItems,
                                ).animateFadeIn(delay: 320.ms),
                                const SizedBox(height: AppSpacing.xl),
                                _FeaturedCollectionsSection(
                                  collections: state.collections,
                                ).animateFadeIn(delay: 380.ms),
                                const SizedBox(height: AppSpacing.xl),
                                _RecentBookmarksSection(
                                  recentItems: filteredItems,
                                  isEmpty: state.totalBookmarks == 0,
                                  hasMatches:
                                      !hasActiveFilters ||
                                      filteredItems.isNotEmpty,
                                  animationDelay: 440.ms,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _WeeklyDigestPanel(
                          recentCount: state.recentBookmarks,
                          onPressed: () => context.push<void>('/bookmarks'),
                        ).animateSlideUp(delay: 520.ms),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<BookmarkSummary> _filterItems(
    List<BookmarkSummary> items,
    List<_HomeFilter> filters,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final selectedFilter = filters.firstWhere(
      (filter) => filter.id == _selectedFilterIdNotifier.value,
      orElse: () => filters.first,
    );

    return items.where((bookmark) {
      final searchable = [
        bookmark.title,
        bookmark.url,
        bookmark.description,
        ...bookmark.tags,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesFilter =
          selectedFilter.id == 'all' ||
          selectedFilter.keywords.any(searchable.contains);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<_HomeFilter> _filters(BuildContext context) => [
    _HomeFilter(
      id: 'all',
      label: context.l10n.homeFilterAll,
      keywords: const [],
    ),
    _HomeFilter(
      id: 'design',
      label: context.l10n.homeFilterDesign,
      keywords: const ['design', 'ui', 'ux', 'figma'],
    ),
    _HomeFilter(
      id: 'articles',
      label: context.l10n.homeFilterArticles,
      keywords: const ['article', 'blog', 'medium', 'read'],
    ),
    _HomeFilter(
      id: 'inspiration',
      label: context.l10n.homeFilterInspiration,
      keywords: const ['inspiration', 'idea', 'creative', 'gallery'],
    ),
    _HomeFilter(
      id: 'tools',
      label: context.l10n.homeFilterTools,
      keywords: const ['tool', 'app', 'extension', 'package'],
    ),
  ];
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.commonLoading,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSkeleton.line(width: 180, height: 28),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton.line(width: 280),
                  SizedBox(height: AppSpacing.lg),
                  AppSkeleton(height: 64),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: AppSkeleton(height: 80)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: AppSkeleton(height: 80)),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: AppSkeleton(height: 80)),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl),
                  AppSkeleton(height: 180),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFilter {
  const _HomeFilter({
    required this.id,
    required this.label,
    required this.keywords,
  });

  final String id;
  final String label;
  final List<String> keywords;
}
