import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_border_width.dart';
import '../theme/app_elevation.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Visual configurations supported by [AppTopBar].
enum AppTopBarVariant { minimal, details, search, transparent, dashboard }

/// A minimal application top bar whose title is centered on the whole width.
///
/// Leading and trailing content is placed in equally wide regions, so uneven
/// action counts cannot shift the title away from the screen's center.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.showBackButton = true,
    this.elevation = AppElevation.none,
    this.backgroundColor,
    this.profileAvatar,
    this.notificationCount,
    this.notificationTooltip,
    this.onNotificationTap,
    this.searchAction,
    this.onSearchTap,
    this.searchTooltip,
    this.onMenuTap,
    this.menuTooltip,
    this.titleMaxLines = 1,
    this.showDivider = true,
    this.variant = AppTopBarVariant.minimal,
  }) : assert(
         titleMaxLines == 1 || titleMaxLines == 2,
         'titleMaxLines must be one or two.',
       );

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool showBackButton;
  final double elevation;
  final Color? backgroundColor;
  final Widget? profileAvatar;
  final int? notificationCount;
  final String? notificationTooltip;
  final VoidCallback? onNotificationTap;
  final Widget? searchAction;
  final VoidCallback? onSearchTap;
  final String? searchTooltip;
  final VoidCallback? onMenuTap;
  final String? menuTooltip;
  final int titleMaxLines;
  final bool showDivider;
  final AppTopBarVariant variant;

  static const double _actionExtent = kMinInteractiveDimension;
  static const double _dashboardHeight = 66;

  @override
  Size get preferredSize {
    if (variant == AppTopBarVariant.dashboard) {
      return Size.fromHeight(
        _dashboardHeight + (bottom?.preferredSize.height ?? 0),
      );
    }
    final baseHeight = subtitle != null || titleMaxLines == 2 ? 64.0 : 60.0;
    return Size.fromHeight(baseHeight + (bottom?.preferredSize.height ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final transparent = variant == AppTopBarVariant.transparent;
    final canPop = Navigator.of(context).canPop();

    final effectiveLeading =
        leading ??
        (canPop && showBackButton
            ? IconButton(
                icon: FaIcon(
                  isRtl
                      ? FontAwesomeIcons.chevronRight
                      : FontAwesomeIcons.chevronLeft,
                  size: AppIconSize.sm,
                ),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : onMenuTap != null
            ? IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.bars,
                  size: AppIconSize.sm,
                ),
                tooltip:
                    menuTooltip ??
                    MaterialLocalizations.of(context).openAppDrawerTooltip,
                onPressed: onMenuTap,
              )
            : profileAvatar);

    final effectiveActions = <Widget>[
      if (searchAction != null)
        searchAction!
      else if (onSearchTap != null)
        IconButton(
          tooltip:
              searchTooltip ??
              MaterialLocalizations.of(context).searchFieldLabel,
          onPressed: onSearchTap,
          icon: const FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: AppIconSize.sm,
          ),
        ),
      if (onNotificationTap != null)
        IconButton(
          tooltip: notificationTooltip,
          onPressed: onNotificationTap,
          icon: Badge(
            isLabelVisible: (notificationCount ?? 0) > 0,
            label: notificationCount == null
                ? null
                : Text(notificationCount! > 99 ? '99+' : '$notificationCount'),
            backgroundColor: colorScheme.error,
            textColor: colorScheme.onError,
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
            child: const FaIcon(
              FontAwesomeIcons.bell,
              size: AppIconSize.sm,
            ),
          ),
        ),
      ...?actions,
    ];

    if (variant == AppTopBarVariant.dashboard) {
      final semantic = context.semanticColors;
      final dashboardStart =
          backgroundColor ??
          (context.isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface);
      final dashboardEnd =
          backgroundColor ??
          (context.isDark
              ? colorScheme.surface
              : colorScheme.surfaceContainerLow);

      return AppBar(
        key: key,
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0),
        scrolledUnderElevation: AppElevation.none,
        elevation: AppElevation.none,
        toolbarHeight:
            preferredSize.height - (bottom?.preferredSize.height ?? 0),
        titleSpacing: 12,
        flexibleSpace: ColoredBox(
          color: context.isDark
              ? colorScheme.surfaceContainerLowest
              : colorScheme.surfaceContainerLow.withValues(alpha: 0.55),
        ),
        title: Container(
          key: const ValueKey('dashboardTopBarBackground'),
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [dashboardStart, dashboardEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: semantic.divider.withValues(
                alpha: context.isDark ? 0.38 : 0.52,
              ),
              width: AppBorderWidth.hairline,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: context.isDark ? 0.20 : 0.07,
                ),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PositionedDirectional(
                start: -18,
                top: -30,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onSurface.withValues(alpha: 0.035),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 112,
                bottom: -42,
                child: Transform.rotate(
                  angle: -0.45,
                  child: Container(
                    width: 92,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      color: colorScheme.onSurface.withValues(alpha: 0.025),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: _DashboardTopBarContent(
                  title: title,
                  subtitle: subtitle,
                  avatar: profileAvatar,
                  actions: effectiveActions,
                ),
              ),
            ],
          ),
        ),
        bottom: bottom,
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colorScheme.surface.withValues(alpha: 0),
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0),
      scrolledUnderElevation: AppElevation.none,
      elevation: transparent ? AppElevation.none : elevation,
      flexibleSpace: transparent
          ? null
          : _TopBarBackground(
              backgroundColor: backgroundColor,
              showDivider: showDivider,
            ),
      toolbarHeight: preferredSize.height - (bottom?.preferredSize.height ?? 0),
      titleSpacing: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final leadingWidth = effectiveLeading == null ? 0.0 : _actionExtent;
          final actionsWidth = effectiveActions.length * _actionExtent;
          final requestedSideWidth = math.max(leadingWidth, actionsWidth);
          final sideWidth = math.min<double>(
            requestedSideWidth,
            math.max<double>(
              0,
              (constraints.maxWidth - _actionExtent) / 2,
            ),
          );

          return SizedBox(
            width: constraints.maxWidth,
            child: Row(
              children: [
                SizedBox(
                  key: const ValueKey('appTopBarLeadingRegion'),
                  width: sideWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: effectiveLeading == null
                        ? null
                        : _ActionSlot(child: effectiveLeading),
                  ),
                ),
                Expanded(
                  child: _TopBarTitle(
                    title: title,
                    subtitle: subtitle,
                    maxLines: titleMaxLines,
                    centered: centerTitle,
                  ),
                ),
                SizedBox(
                  key: const ValueKey('appTopBarTrailingRegion'),
                  width: sideWidth,
                  child: ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final action in effectiveActions)
                            _ActionSlot(child: action),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottom: bottom,
    );
  }
}

/// A quiet surface separates global navigation from the page without adding
/// decorative noise. The faint brand wash is only used by dashboards.
class _TopBarBackground extends StatelessWidget {
  const _TopBarBackground({
    required this.backgroundColor,
    required this.showDivider,
  });

  final Color? backgroundColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final semantic = context.semanticColors;
    final baseColor =
        backgroundColor ??
        (context.isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerLowest);

    return DecoratedBox(
      key: const ValueKey('dashboardTopBarBackground'),
      decoration: BoxDecoration(
        color: baseColor,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: semantic.divider.withValues(
                    alpha: context.isDark ? 0.32 : 0.22,
                  ),
                  width: AppBorderWidth.hairline,
                ),
              )
            : null,
      ),
    );
  }
}

/// Compact dashboard identity treatment: brand/avatar, two-line identity, and
/// a small group of real actions. It follows ambient directionality so the
/// identity remains at the leading edge in both Arabic and English.
class _DashboardTopBarContent extends StatelessWidget {
  const _DashboardTopBarContent({
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? avatar;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (avatar != null) ...[
          Container(
            key: const ValueKey('dashboardTopBarAvatarFrame'),
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.semanticColors.divider.withValues(alpha: 0.72),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: avatar,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            key: const ValueKey('dashboardTopBarIdentity'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.semanticColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, action) in actions.indexed) ...[
                if (index > 0) const SizedBox(width: 2),
                _DashboardActionSlot(child: action),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _DashboardActionSlot extends StatelessWidget {
  const _DashboardActionSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = colorScheme.onSurfaceVariant;

    return SizedBox.square(
      key: const ValueKey('dashboardTopBarAction'),
      dimension: 36,
      child: Material(
        color: colorScheme.onSurface.withValues(
          alpha: context.isDark ? 0.10 : 0.055,
        ),
        clipBehavior: Clip.antiAlias,
        shape: const CircleBorder(),
        child: IconTheme(
          data: IconThemeData(color: foreground, size: AppIconSize.sm),
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: foreground,
                iconSize: AppIconSize.sm,
                minimumSize: const Size.square(36),
                maximumSize: const Size.square(36),
                padding: EdgeInsets.zero,
                backgroundColor: colorScheme.surface.withValues(alpha: 0),
                overlayColor: colorScheme.onSurface.withValues(alpha: 0.10),
                shape: const CircleBorder(),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ActionSlot extends StatelessWidget {
  const _ActionSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return SizedBox.square(
      dimension: AppTopBar._actionExtent,
      child: IconTheme(
        data: IconThemeData(
          color: colorScheme.onSurface,
          size: AppIconSize.sm,
        ),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              iconSize: AppIconSize.sm,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _TopBarTitle extends StatelessWidget {
  const _TopBarTitle({
    required this.title,
    required this.subtitle,
    required this.maxLines,
    required this.centered,
  });

  final String title;
  final String? subtitle;
  final int maxLines;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final titleAlignment = centered ? TextAlign.center : TextAlign.start;
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        key: const ValueKey('appTopBarTitle'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.15,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: titleAlignment,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1.5),
            Text(
              subtitle!,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.semanticColors.mutedForeground,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: titleAlignment,
            ),
          ],
        ],
      ),
    );
  }
}
