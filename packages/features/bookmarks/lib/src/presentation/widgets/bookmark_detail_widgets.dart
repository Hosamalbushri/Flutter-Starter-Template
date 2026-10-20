import 'package:app_ui/app_ui.dart';
// capability: collections widgets surfaced inside bookmarks (single consumer).
// If a second feature needs these, promote to shared_ui per CLAUDE.md.
import 'package:feature_collections/feature_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

import '../../domain/entities/bookmark.dart';
import '../../locator.dart';
import '../bloc/bookmark_detail/bookmark_detail_bloc.dart';
import '../bloc/bookmark_detail/bookmark_detail_state.dart';
import '../bookmarks_routes.dart';
import 'bookmark_failure_messages.dart';
import 'detail/bookmark_detail_sections.dart';

/// Provides a [BookmarkDetailBloc] for [id] and renders the detail embedded in
/// a side pane (no back button; delete/edit report back via callbacks instead
/// of popping a route).
class BookmarkDetailPane extends StatelessWidget {
  const BookmarkDetailPane({
    super.key,
    required this.id,
    this.onDeleted,
    this.onEdited,
  });

  final String id;

  /// Called after the bookmark is deleted, so the host can clear its selection.
  final VoidCallback? onDeleted;

  /// Called after an edit returns with changes, so the host can refresh.
  final VoidCallback? onEdited;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BookmarkDetailBloc>()..add(BookmarkDetailLoadRequested(id)),
      child: BookmarkDetailView(
        id: id,
        embedded: true,
        onDeleted: onDeleted,
        onEdited: onEdited,
      ),
    );
  }
}

class BookmarkDetailView extends StatelessWidget {
  const BookmarkDetailView({
    super.key,
    required this.id,
    this.embedded = false,
    this.onDeleted,
    this.onEdited,
  });

  final String id;

  /// Whether the view is rendered inside a side pane rather than a full screen.
  final bool embedded;

  /// In embedded mode, called after the bookmark is deleted.
  final VoidCallback? onDeleted;

  /// In embedded mode, called after an edit returns with changes.
  final VoidCallback? onEdited;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookmarkDetailBloc, BookmarkDetailState>(
      listenWhen: (_, state) => state is BookmarkDetailDeleted,
      listener: (context, state) {
        if (embedded) {
          onDeleted?.call();
        } else {
          context.pop(true);
        }
      },
      child: AppScaffold(
        title: context.l10n.bookmarkAppBarTitle,
        padding: EdgeInsets.zero,
        backgroundColor: context.colorScheme.surface,
        actions: [
          BlocBuilder<BookmarkDetailBloc, BookmarkDetailState>(
            builder: (context, state) {
              if (state is! BookmarkDetailReady) return const SizedBox.shrink();
              final l10n = context.l10n;
              return PopupMenuButton<_DetailAction>(
                icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
                onSelected: (action) {
                  switch (action) {
                    case _DetailAction.share:
                      context.read<BookmarkDetailBloc>().add(
                        BookmarkDetailShareRequested(state.bookmark),
                      );
                    case _DetailAction.addToCollection:
                      AddToCollectionSheet.show(
                        context,
                        bookmarkId: state.bookmark.id,
                      );
                    case _DetailAction.edit:
                      _openEditor(context);
                    case _DetailAction.delete:
                      _confirmAndDelete(context, state.bookmark);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _DetailAction.share,
                    child: _MenuItem(
                      icon: FontAwesomeIcons.shareNodes,
                      label: l10n.commonShare,
                    ),
                  ),
                  PopupMenuItem(
                    value: _DetailAction.addToCollection,
                    child: _MenuItem(
                      icon: FontAwesomeIcons.layerGroup,
                      label: l10n.addToCollectionTitle,
                    ),
                  ),
                  PopupMenuItem(
                    value: _DetailAction.edit,
                    child: _MenuItem(
                      icon: FontAwesomeIcons.pen,
                      label: l10n.commonEdit,
                    ),
                  ),
                  PopupMenuItem(
                    value: _DetailAction.delete,
                    child: _MenuItem(
                      icon: FontAwesomeIcons.trashCan,
                      label: l10n.commonDelete,
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        body: BlocBuilder<BookmarkDetailBloc, BookmarkDetailState>(
          builder: (context, state) {
            return switch (state) {
              BookmarkDetailLoading() => const AppLoading(),
              BookmarkDetailFailure(:final failure) => AppErrorView(
                message: bookmarkFailureMessage(context, failure),
                retryLabel: context.l10n.commonRetry,
                onRetry: () => context.read<BookmarkDetailBloc>().add(
                  BookmarkDetailLoadRequested(id),
                ),
              ),
              BookmarkDetailReady(:final bookmark) ||
              BookmarkDetailDeleting(:final bookmark) => _DetailBody(
                bookmark: bookmark,
              ),
              BookmarkDetailDeleted() => const AppLoading(),
            };
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final changed = await context.push<bool>(BookmarksRoutes.edit(id));
    if (changed == true && context.mounted) {
      context.read<BookmarkDetailBloc>().add(BookmarkDetailLoadRequested(id));
      onEdited?.call();
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, Bookmark b) async {
    final l10n = context.l10n;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.bookmarkDeleteDialogTitle,
      message: l10n.bookmarkDeleteDialogBody,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<BookmarkDetailBloc>().add(BookmarkDetailDeleteRequested(b.id));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.bookmark});

  final Bookmark bookmark;

  bool get _hasMedia => bookmark.imageUrls.isNotEmpty;
  bool get _hasVideo =>
      bookmark.videoUrl != null && bookmark.videoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            112,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLinkPreview(
                url: bookmark.url,
                maxWidth: double.infinity,
                enableAnimation: true,
              ).animateFadeIn(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                bookmark.title,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ).animateSlideDown(),
              if (bookmark.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  bookmark.description,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.semanticColors.mutedForeground,
                    letterSpacing: 0,
                  ),
                ).animateFadeIn(delay: 100.ms),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SourceSection(
                bookmark: bookmark,
              ).animateSlideLeft(delay: 150.ms),
              if (bookmark.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                TagsSection(
                  tags: bookmark.tags,
                ).animateSlideLeft(delay: 200.ms),
              ],
              const SizedBox(height: AppSpacing.xxl),
              DetailsSection(
                bookmark: bookmark,
              ).animateSlideLeft(delay: 250.ms),
              if (_hasMedia) ...[
                const SizedBox(height: AppSpacing.xxl),
                MediaSection(
                  bookmark: bookmark,
                ).animateSlideLeft(delay: 300.ms),
              ],
              if (_hasVideo) ...[
                const SizedBox(height: AppSpacing.xxl),
                VideoSection(
                  videoUrl: bookmark.videoUrl!,
                ).animateFadeIn(delay: 350.ms),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: OpenInBrowserBar(bookmark: bookmark),
        ),
      ],
    );
  }
}

/// Overflow-menu actions on the detail app bar.
enum _DetailAction { share, addToCollection, edit, delete }

/// A single row in the app-bar overflow menu: leading icon + label.
class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final FaIconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.onSurface;
    return Row(
      children: [
        FaIcon(icon, size: AppIconSize.sm, color: color),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
