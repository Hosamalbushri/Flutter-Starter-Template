import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../animation/app_durations.dart';
import '../layout/app_breakpoints.dart';
import '../theme/app_border_width.dart';
import '../theme/app_elevation.dart';
import '../theme/app_icon_size.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// A single destination in the [AppAdaptiveScaffold] navigation.
@immutable
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.label,
    FaIconData? selectedIcon,
    this.hasBadge = false,
    this.badgeCount,
  }) : selectedIcon = selectedIcon ?? icon;

  /// Icon shown when the destination is not selected.
  final FaIconData icon;

  /// Icon shown when the destination is selected.
  final FaIconData selectedIcon;

  /// Label shown beside or under the icon.
  final String label;

  /// Whether to show a badge on the icon.
  final bool hasBadge;

  /// Optional numeric count on the badge.
  final int? badgeCount;
}

/// Optional prominent central action on the bottom navigation bar.
@immutable
class AppCenterAction {
  const AppCenterAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.label,
  });

  final FaIconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final String? label;
}

/// Scaffolding that adapts its navigation affordance to the available width.
///
/// - Compact (`< [AppBreakpoints.medium]`): a floating rounded bottom bar.
/// - Medium (`< [AppBreakpoints.expanded]`): a collapsed [NavigationRail].
/// - Expanded: an extended [NavigationRail] with labels and optional drawer.
///
/// [body] is expected to be a branch's own `Scaffold` (with its app bar and
/// any floating action button); this widget supplies the navigation chrome around it.
class AppAdaptiveScaffold extends StatelessWidget {
  const AppAdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.centerAction,
    this.drawer,
    this.enableBackdropBlur = false,
    this.hideBottomNavigationOnKeyboard = false,
  }) : assert(
         destinations.length >= 2 && destinations.length <= 5,
         'Provide between two and five destinations. Three to five is '
         'recommended for production navigation.',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex must identify an available destination.',
       );

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final AppCenterAction? centerAction;
  final Widget? drawer;
  final bool enableBackdropBlur;
  final bool hideBottomNavigationOnKeyboard;

  /// Returns the total bottom clearance required to avoid occlusion by the
  /// compact navigation bar (including raised center action and bottom system padding).
  ///
  /// Returns 0.0 on larger screens where a [NavigationRail] is used or when
  /// the bottom bar is hidden.
  static double bottomBarInsetOf(BuildContext context) {
    return AppAdaptiveNavigationScope.bottomBarTotalExtentOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < AppBreakpoints.medium) {
          final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
          final isBarHidden = keyboardVisible && hideBottomNavigationOnKeyboard;
          final textScaler = MediaQuery.textScalerOf(context);
          final scaledTextHeight = textScaler.scale(12);
          final barHeight = (_bottomBarHeight + ((scaledTextHeight - 12) * 1.5))
              .clamp(64.0, 92.0);
          final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
          final paddingBottom = MediaQuery.paddingOf(context).bottom;
          final bottomPadding = viewPaddingBottom > 0
              ? viewPaddingBottom
              : paddingBottom;
          final hasCenter = centerAction != null;
          final totalExtent = isBarHidden
              ? 0.0
              : (barHeight +
                    (hasCenter ? _centerActionLift : 0.0) +
                    bottomPadding);

          return AppAdaptiveNavigationScope(
            bottomBarHeight: isBarHidden ? 0.0 : barHeight,
            bottomBarTotalExtent: totalExtent,
            child: Scaffold(
              drawer: drawer,
              // Let the page continue behind the raised center action so the
              // navigation slot does not paint an opaque rectangle around it.
              extendBody: true,
              // The nested branch scaffold remains responsible for keeping its
              // focused content visible. This outer navigation scaffold must
              // retain identical geometry while the keyboard animates.
              resizeToAvoidBottomInset: false,
              body: body,
              bottomNavigationBar: isBarHidden
                  ? null
                  : _FloatingBottomBar(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      centerAction: centerAction,
                      enableBackdropBlur: enableBackdropBlur,
                    ),
            ),
          );
        }

        final extended = width >= AppBreakpoints.expanded;
        final semantic = context.semanticColors;
        return AppAdaptiveNavigationScope(
          bottomBarHeight: 0,
          bottomBarTotalExtent: 0,
          child: Scaffold(
            drawer: drawer,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: context.colorScheme.surface,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  extended: extended,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: centerAction != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: FloatingActionButton(
                            elevation: AppElevation.sm,
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: context.colorScheme.onPrimary,
                            onPressed: centerAction!.onPressed,
                            tooltip: centerAction!.tooltip,
                            shape: const CircleBorder(),
                            child: FaIcon(
                              centerAction!.icon,
                              size: AppIconSize.md,
                            ),
                          ),
                        )
                      : null,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Badge(
                          isLabelVisible: d.hasBadge || (d.badgeCount ?? 0) > 0,
                          label: d.badgeCount != null
                              ? Text('${d.badgeCount}')
                              : null,
                          child: FaIcon(d.icon),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: d.hasBadge || (d.badgeCount ?? 0) > 0,
                          label: d.badgeCount != null
                              ? Text('${d.badgeCount}')
                              : null,
                          child: FaIcon(d.selectedIcon),
                        ),
                        label: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: extended ? 160 : 76,
                          ),
                          child: Text(
                            d.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: extended
                                ? TextAlign.start
                                : TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: AppBorderWidth.hairline,
                  thickness: AppBorderWidth.hairline,
                  color: semantic.divider.withValues(alpha: 0.5),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Inset and geometry information provided by [AppAdaptiveScaffold] to descendants.
class AppAdaptiveNavigationScope extends InheritedWidget {
  const AppAdaptiveNavigationScope({
    super.key,
    required this.bottomBarHeight,
    required this.bottomBarTotalExtent,
    required super.child,
  });

  /// Height of the compact bottom bar surface itself (excluding system bottom view padding).
  final double bottomBarHeight;

  /// Total bottom extent of the navigation chrome including the raised center action
  /// (if present) and system bottom view padding.
  ///
  /// Returns 0.0 when a [NavigationRail] is used (medium/expanded screens)
  /// or when the bottom bar is hidden.
  final double bottomBarTotalExtent;

  /// Obtains the nearest [AppAdaptiveNavigationScope] from the given [context], if any.
  static AppAdaptiveNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppAdaptiveNavigationScope>();
  }

  /// Obtains the total bottom extent of the adaptive navigation chrome, or 0.0.
  static double bottomBarTotalExtentOf(BuildContext context) {
    return maybeOf(context)?.bottomBarTotalExtent ?? 0.0;
  }

  /// Obtains the bottom bar height, or 0.0.
  static double bottomBarHeightOf(BuildContext context) {
    return maybeOf(context)?.bottomBarHeight ?? 0.0;
  }

  @override
  bool updateShouldNotify(AppAdaptiveNavigationScope oldWidget) =>
      bottomBarHeight != oldWidget.bottomBarHeight ||
      bottomBarTotalExtent != oldWidget.bottomBarTotalExtent;
}

/// Geometry of the compact navigation treatment.
const double _bottomBarHeight = 64;
const double _centerActionExtent = 56;
const double _centerActionLift = 22;
const double _centerActionSlotWidth = _centerActionExtent + 16;

/// A bottom navigation bar with labelled destinations and an optional raised
/// center action.
///
/// The action occupies its own visual slot instead of becoming a destination,
/// so selecting it never changes the active navigation branch.
class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.centerAction,
    required this.enableBackdropBlur,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppCenterAction? centerAction;
  final bool enableBackdropBlur;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = context.isDark;
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledTextHeight = textScaler.scale(12);
    final barHeight = (_bottomBarHeight + ((scaledTextHeight - 12) * 1.5))
        .clamp(64.0, 92.0);

    // Keep the system-navigation inset stable when viewInsets replaces the
    // ordinary bottom padding while the keyboard is visible.
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final padding = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = viewPadding > 0 ? viewPadding : padding;

    final hasCenter = centerAction != null;
    final totalHeight =
        barHeight + (hasCenter ? _centerActionLift : 0.0) + bottomPadding;
    final backgroundHeight = barHeight + bottomPadding;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: backgroundHeight,
                child: _OptionalBackdropBlur(
                  enabled: enableBackdropBlur,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? semantic.surfaceElevated
                                  : context.colorScheme.surface)
                              .withValues(
                                alpha: enableBackdropBlur ? 0.90 : 0.98,
                              ),
                      border: Border(
                        top: BorderSide(
                          color: semantic.divider.withValues(
                            alpha: isDark ? 0.35 : 0.60,
                          ),
                          width: AppBorderWidth.hairline,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.05,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: bottomPadding,
                height: barHeight,
                child: Material(
                  color: Colors.transparent,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final count = destinations.length;

                      if (!hasCenter) {
                        return Row(
                          children: [
                            for (var i = 0; i < count; i++)
                              Expanded(
                                child: _BottomBarItem(
                                  index: i,
                                  destination: destinations[i],
                                  selected: i == selectedIndex,
                                  onTap: () => onDestinationSelected(i),
                                ),
                              ),
                          ],
                        );
                      }

                      final slotWidth = availableWidth < 360
                          ? (_centerActionExtent + 8)
                          : _centerActionSlotWidth;
                      final halfWidth = (availableWidth - slotWidth) / 2;
                      final mid = count ~/ 2;
                      final startDestinations = destinations.sublist(0, mid);
                      final endDestinations = destinations.sublist(mid);
                      final maxPerSide = math.max(
                        startDestinations.length,
                        endDestinations.length,
                      );
                      final itemWidth = halfWidth / maxPerSide;

                      return Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (
                                  var i = 0;
                                  i < startDestinations.length;
                                  i++
                                )
                                  SizedBox(
                                    width: itemWidth,
                                    child: _BottomBarItem(
                                      index: i,
                                      destination: startDestinations[i],
                                      selected: i == selectedIndex,
                                      onTap: () => onDestinationSelected(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: slotWidth),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (var i = 0; i < endDestinations.length; i++)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _BottomBarItem(
                                      index: i + mid,
                                      destination: endDestinations[i],
                                      selected: (i + mid) == selectedIndex,
                                      onTap: () =>
                                          onDestinationSelected(i + mid),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (hasCenter)
                Positioned(
                  top: 0,
                  child: _CenterActionButton(action: centerAction!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalBackdropBlur extends StatelessWidget {
  const _OptionalBackdropBlur({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: child,
      ),
    );
  }
}

class _CenterActionButton extends StatefulWidget {
  const _CenterActionButton({required this.action});

  final AppCenterAction action;

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final action = widget.action;
    final semanticLabel = action.label ?? action.tooltip ?? '';

    return Semantics(
      key: const ValueKey('bottomNavigationCenterActionSemantics'),
      container: true,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: action.tooltip ?? action.label ?? '',
        child: DecoratedBox(
          key: const ValueKey('bottomNavigationCenterAction'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withValues(
                  alpha: context.isDark ? 0.45 : 0.28,
                ),
                blurRadius: _pressed ? 6 : 14,
                offset: Offset(0, _pressed ? 2 : 5),
              ),
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.30 : 0.07,
                ),
                blurRadius: _pressed ? 2 : 6,
                offset: Offset(0, _pressed ? 1 : 2),
              ),
            ],
          ),
          child: AnimatedScale(
            scale: _pressed ? 0.93 : 1,
            duration: reduceMotion ? Duration.zero : AppDurations.xfast,
            curve: Curves.easeOutCubic,
            child: Material(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              clipBehavior: Clip.antiAlias,
              color: context.colorScheme.primary,
              child: InkWell(
                onHighlightChanged: _setPressed,
                onTap: () {
                  HapticFeedback.lightImpact();
                  action.onPressed();
                },
                focusColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0.25,
                ),
                hoverColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0.15,
                ),
                splashColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0.20,
                ),
                highlightColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0.10,
                ),
                child: SizedBox.square(
                  dimension: _centerActionExtent,
                  child: Center(
                    child: FaIcon(
                      action.icon,
                      color: context.colorScheme.onPrimary,
                      size: AppIconSize.lg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tappable destination within the [_FloatingBottomBar].
class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.index,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final foreground = selected
        ? semantic.navigationSelected
        : semantic.navigationUnselected;

    final effectiveBadgeCount = destination.badgeCount;
    final semanticLabel =
        (effectiveBadgeCount != null && effectiveBadgeCount > 0)
        ? '${destination.label}, $effectiveBadgeCount'
        : destination.label;

    return Semantics(
      key: ValueKey('bottomNavigationDestinationSemantics-$index'),
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          key: ValueKey('bottomNavigationDestination-$index'),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          focusColor: semantic.navigationSelected.withValues(alpha: 0.15),
          hoverColor: semantic.navigationSelected.withValues(alpha: 0.08),
          splashColor: semantic.navigationSelected.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 4,
              ),
              child: AnimatedContainer(
                key: ValueKey('bottomNavigationDestinationSurface-$index'),
                duration: reduceMotion ? Duration.zero : AppDurations.fast,
                curve: _curve,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? foreground.withValues(
                          alpha: context.isDark ? 0.14 : 0.09,
                        )
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.06 : 1,
                      duration: reduceMotion
                          ? Duration.zero
                          : AppDurations.fast,
                      curve: _curve,
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : AppDurations.fast,
                        switchInCurve: _curve,
                        switchOutCurve: Curves.easeInCubic,
                        child: Badge(
                          isLabelVisible:
                              destination.hasBadge ||
                              (effectiveBadgeCount ?? 0) > 0,
                          label: effectiveBadgeCount != null
                              ? Text('$effectiveBadgeCount')
                              : null,
                          backgroundColor: context.colorScheme.error,
                          textColor: context.colorScheme.onError,
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          child: FaIcon(
                            selected
                                ? destination.selectedIcon
                                : destination.icon,
                            key: ValueKey<bool>(selected),
                            color: foreground,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: reduceMotion
                          ? Duration.zero
                          : AppDurations.fast,
                      curve: _curve,
                      style: context.textTheme.labelSmall!.copyWith(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: -0.1,
                        height: 1.15,
                      ),
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
