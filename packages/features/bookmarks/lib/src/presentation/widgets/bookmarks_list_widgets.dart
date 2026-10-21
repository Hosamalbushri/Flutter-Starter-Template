import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/services/bookmarks_sync_controller.dart';
import '../bloc/bookmarks_list/bookmarks_list_bloc.dart';
import '../bloc/bookmarks_list/bookmarks_list_state.dart';
import '../bookmarks_routes.dart';
// fst:document:engine:start
import 'bookmarks_import_sheet.dart';
// fst:document:engine:end
import 'bookmarks_list_master.dart';

class BookmarksListView extends StatefulWidget {
  const BookmarksListView({super.key});

  @override
  State<BookmarksListView> createState() => _BookmarksListViewState();
}

class _BookmarksListViewState extends State<BookmarksListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  BookmarkTab _activeTab = BookmarkTab.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      context.read<BookmarksListBloc>().add(BookmarksListQueryChanged(value));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<BookmarksListBloc>().add(const BookmarksListQueryChanged(''));
  }

  Future<void> _reload() {
    final bloc = context.read<BookmarksListBloc>();
    // orElse guards against the bloc closing mid-refresh (e.g. user navigates
    // away), which would otherwise throw a StateError inside RefreshIndicator.
    final completion = bloc.stream.firstWhere(
      (state) => !state.isLoading,
      orElse: () => bloc.state,
    );
    bloc.add(const BookmarksListLoadRequested());
    return completion.then((_) {});
  }

  Future<void> _openNew() async {
    final changed = await context.push<bool>(BookmarksRoutes.create);
    if (changed == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openDetail(Bookmark bookmark) async {
    final changed = await context.push<bool>(
      BookmarksRoutes.detail(bookmark.id),
    );
    if (changed == true && mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.bookmarksAppBarTitle,
      padding: EdgeInsets.zero,
      actions: [
        // fst:document:engine:start
        IconButton(
          icon: const Icon(Icons.file_upload_outlined),
          tooltip: context.l10n.bookmarksImportAction,
          onPressed: () => BookmarksImportSheet.show(
            context,
            onImportCompleted: _reload,
          ),
        ),
        // fst:document:engine:end
        BlocBuilder<BookmarksListBloc, BookmarksListState>(
          buildWhen: (a, b) => a.syncStatus != b.syncStatus,
          builder: (context, state) =>
              _SyncStatusIcon(status: state.syncStatus),
        ),
        BlocBuilder<BookmarksListBloc, BookmarksListState>(
          buildWhen: (a, b) => a.sort != b.sort,
          builder: (context, state) => _SortMenuButton(sort: state.sort),
        ),
      ],
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.sizeOf(context).width < AppBreakpoints.medium
              ? 32 + MediaQuery.paddingOf(context).bottom
              : 0,
        ),
        child: FloatingActionButton(
          // This action has no shared-element counterpart on the form route.
          // Keeping a fixed Hero tag makes retained shell subtrees collide
          // when more than one bookmarks branch is briefly mounted.
          heroTag: null,
          onPressed: _openNew,
          tooltip: context.l10n.bookmarksAddTooltip,
          child: const FaIcon(FontAwesomeIcons.plus),
        ).animateScale(delay: 300.ms),
      ),
      body: BookmarksListMaster(
        searchController: _searchController,
        activeTab: _activeTab,
        onSearchChanged: _onSearchChanged,
        onClearSearch: _clearSearch,
        onTabChanged: (tab) => setState(() => _activeTab = tab),
        onReload: _reload,
        onItemTap: _openDetail,
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({required this.sort});

  final BookmarkSort sort;

  String _labelFor(BuildContext context, BookmarkSort value) => switch (value) {
    BookmarkSort.newest => context.l10n.bookmarksSortNewest,
    BookmarkSort.oldest => context.l10n.bookmarksSortOldest,
    BookmarkSort.titleAz => context.l10n.bookmarksSortTitleAz,
  };

  FaIconData _iconFor(BookmarkSort value) => switch (value) {
    BookmarkSort.newest => FontAwesomeIcons.calendarDay,
    BookmarkSort.oldest => FontAwesomeIcons.calendar,
    BookmarkSort.titleAz => FontAwesomeIcons.arrowDownAZ,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return PopupMenuButton<BookmarkSort>(
      padding: EdgeInsets.zero,
      tooltip: context.l10n.bookmarksSortTooltip,
      initialValue: sort,
      color: colorScheme.surface,
      elevation: AppElevation.lg,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      offset: const Offset(0, AppSpacing.sm),
      position: PopupMenuPosition.under,
      onSelected: (value) => context.read<BookmarksListBloc>().add(
        BookmarksListSortChanged(value),
      ),
      child: Semantics(
        button: true,
        label: context.l10n.bookmarksSortTooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.filter,
              size: AppIconSize.sm,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
      itemBuilder: (context) => [
        for (final value in BookmarkSort.values)
          PopupMenuItem<BookmarkSort>(
            value: value,
            padding: EdgeInsets.zero,
            child: _SortMenuItem(
              icon: _iconFor(value),
              label: _labelFor(context, value),
              selected: value == sort,
            ),
          ),
      ],
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final FaIconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.38)
          : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: FaIcon(
              icon,
              size: AppIconSize.sm,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusIcon extends StatelessWidget {
  const _SyncStatusIcon({required this.status});

  static const double _slotSize = 18;
  static const double _spinnerSize = 16;

  final BookmarksSyncStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      BookmarksSyncStatus.syncing => const Padding(
        padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
        child: SizedBox(
          width: _slotSize,
          height: _slotSize,
          child: Center(
            child: SizedBox(
              width: _spinnerSize,
              height: _spinnerSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      BookmarksSyncStatus.error => IconButton(
        tooltip: context.l10n.bookmarksSyncFailedRetryTooltip,
        icon: const FaIcon(FontAwesomeIcons.cloudArrowUp),
        onPressed: () => context.read<BookmarksListBloc>().add(
          const BookmarksListSyncRetried(),
        ),
      ),
      BookmarksSyncStatus.idle => const SizedBox.shrink(),
    };
  }
}
