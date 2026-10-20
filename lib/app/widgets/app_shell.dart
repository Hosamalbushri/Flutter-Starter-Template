import 'package:app_ui/app_ui.dart';
// fst:feature:bookmarks:start
import 'package:feature_bookmarks/feature_bookmarks.dart';
// fst:feature:bookmarks:end
// fst:feature:bookmarks:start
// fst:feature:collections:start
import 'package:feature_collections/feature_collections.dart';
// fst:feature:collections:end
// fst:feature:bookmarks:end
// fst:feature:notifications:start
import 'package:feature_notifications/feature_notifications.dart';
// fst:feature:notifications:end
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// fst:feature:notifications:start
import 'package:flutter_bloc/flutter_bloc.dart';
// fst:feature:notifications:end
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

// fst:feature:notifications:start
import '../di/injection.dart';

/// Index of the notifications destination in the [AppShell] destinations list.
///
/// Named so that reordering the list produces a compile-visible update point
/// rather than a silent behavioural break.
const int _kNotificationsTabIndex = 2;
// fst:feature:notifications:end

/// Hosts the persistent adaptive navigation around the authenticated branches.
///
/// Renders an [AppAdaptiveScaffold] whose body is the [navigationShell] (the
/// indexed stack of branch navigators), so each destination keeps its own
/// navigation stack.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.exitApplication,
  });

  final StatefulNavigationShell navigationShell;
  final Future<void> Function()? exitApplication;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _exitDialogVisible = false;

  // fst:feature:notifications:start
  @override
  void initState() {
    super.initState();
    // Fetch notifications on app start so the badge can be shown immediately
    // if there are unread notifications.
    getIt<NotificationsBloc>().add(const NotificationsLoadRequested());
  }
  // fst:feature:notifications:end

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // fst:feature:notifications:start
    final hasUnreadNotifications = context.select<NotificationsBloc, bool>(
      (bloc) => bloc.state.unreadCount > 0,
    );
    // fst:feature:notifications:end

    final destinations = [
      AppDestination(
        icon: FontAwesomeIcons.house,
        selectedIcon: FontAwesomeIcons.house,
        label: l10n.navHome,
      ),
      // fst:feature:bookmarks:start
      AppDestination(
        icon: FontAwesomeIcons.bookmark,
        selectedIcon: FontAwesomeIcons.solidBookmark,
        label: l10n.navBookmarks,
      ),
      // fst:feature:bookmarks:end
      // fst:feature:notifications:start
      AppDestination(
        icon: FontAwesomeIcons.bell,
        selectedIcon: FontAwesomeIcons.solidBell,
        label: l10n.navNotifications,
        hasBadge: hasUnreadNotifications,
      ),
      // fst:feature:notifications:end
      AppDestination(
        icon: FontAwesomeIcons.user,
        selectedIcon: FontAwesomeIcons.solidUser,
        label: l10n.navProfile,
      ),
    ];

    final routerCanPop = GoRouter.of(context).canPop();
    return PopScope<Object?>(
      canPop: routerCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBack();
      },
      child: AppAdaptiveScaffold(
        destinations: destinations,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // fst:feature:notifications:start
          if (index == _kNotificationsTabIndex) {
            // Refresh when tapping the tab to ensure it's up to date.
            getIt<NotificationsBloc>().add(const NotificationsLoadRequested());
          }
          // fst:feature:notifications:end
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        // fst:feature:bookmarks:start
        centerAction: AppCenterAction(
          icon: FontAwesomeIcons.plus,
          label: l10n.bookmarksAddTooltip,
          tooltip: l10n.bookmarksAddTooltip,
          onPressed: () => context.push(BookmarksRoutes.create),
          menuLabel: l10n.quickActionsTitle,
          quickActions: [
            AppQuickAction(
              icon: FontAwesomeIcons.link,
              label: l10n.homeQuickAdd,
              onPressed: () => context.push(BookmarksRoutes.create),
            ),
            AppQuickAction(
              icon: FontAwesomeIcons.layerGroup,
              label: l10n.homeCreateCollection,
              onPressed: () => context.push(CollectionsRoutes.create),
            ),
            AppQuickAction(
              icon: FontAwesomeIcons.bookmark,
              label: l10n.homeQuickLibrary,
              onPressed: () => widget.navigationShell.goBranch(1),
            ),
          ],
        ),
        // fst:feature:bookmarks:end
        body: widget.navigationShell,
      ),
    );
  }

  Future<void> _handleRootBack() async {
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }
    if (_exitDialogVisible || !mounted) return;
    _exitDialogVisible = true;
    final l10n = context.l10n;
    final shouldExit = await AppConfirmDialog.show(
      context,
      title: l10n.exitAppTitle,
      message: l10n.exitAppMessage,
      confirmLabel: l10n.exitAppConfirm,
      cancelLabel: l10n.commonCancel,
    );
    _exitDialogVisible = false;
    if (!mounted || !shouldExit) return;
    await (widget.exitApplication ?? SystemNavigator.pop)();
  }
}
