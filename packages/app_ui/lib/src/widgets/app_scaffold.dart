import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app_ui.dart';

/// Wraps [Scaffold] with consistent app-bar styling and an optional full-screen
/// loading overlay driven by [isLoading].
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.appBar,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.safeArea = true,
    this.isLoading = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.profileAvatar,
    this.notificationCount,
    this.notificationTooltip,
    this.onNotificationTap,
    this.searchAction,
  }) : assert(
         appBar == null || title == null,
         'Provide either `title` or a custom `appBar`, not both.',
       );

  final Widget body;
  final String? title;
  final String? subtitle;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final EdgeInsetsGeometry padding;
  final bool safeArea;
  final bool isLoading;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final Widget? profileAvatar;
  final int? notificationCount;
  final String? notificationTooltip;
  final VoidCallback? onNotificationTap;
  final Widget? searchAction;

  /// Returns the bottom navigation bar inset from an ancestor [AppAdaptiveScaffold], if any.
  static double bottomBarInsetOf(BuildContext context) {
    return AppAdaptiveScaffold.bottomBarInsetOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasAdaptiveBottomBar =
        AppAdaptiveNavigationScope.bottomBarHeightOf(context) > 0;
    Widget content = Padding(padding: padding, child: body);
    if (safeArea) {
      content = SafeArea(
        bottom: !hasAdaptiveBottomBar,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar:
          appBar ??
          (title != null
              ? AppTopBar(
                  title: title!,
                  subtitle: subtitle,
                  leading: leading,
                  actions: actions,
                  profileAvatar: profileAvatar,
                  notificationCount: notificationCount,
                  notificationTooltip: notificationTooltip,
                  onNotificationTap: onNotificationTap,
                  searchAction: searchAction,
                )
              : null),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          content,
          AnimatedSwitcher(
            duration: AppDurations.medium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isLoading
                ? Stack(
                    key: const ValueKey('AppScaffoldLoading'),
                    children: [
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: ColoredBox(
                            color: context.semanticColors.scrim,
                          ),
                        ),
                      ),
                      // Elevated glassmorphism loading card
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxxxl,
                            vertical: AppSpacing.xxxl,
                          ),
                          decoration: BoxDecoration(
                            color: context.semanticColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: AppElevation.cardShadow,
                          ),
                          child: const AppLoading(),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
