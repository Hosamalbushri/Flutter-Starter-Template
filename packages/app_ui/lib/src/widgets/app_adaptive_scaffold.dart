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
    this.menuLabel,
    this.quickActions = const [],
  });

  final FaIconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final String? label;
  final String? menuLabel;
  final List<AppQuickAction> quickActions;
}

/// A shortcut revealed by the compact navigation's central action.
@immutable
class AppQuickAction {
  const AppQuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
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
              .clamp(62.0, 92.0);
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
const double _bottomBarHeight = 62;
const double _centerActionExtent = 48;
const double _centerActionLift = 20;
const double _centerActionSlotWidth = _centerActionExtent + 28;
const double _floatingBarHorizontalInset = 12;
const double _floatingBarBottomInset = 8;

/// An icon-only bottom navigation bar with an optional raised center action.
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
        .clamp(62.0, 92.0);

    // Keep the system-navigation inset stable when viewInsets replaces the
    // ordinary bottom padding while the keyboard is visible.
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final padding = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = viewPadding > 0 ? viewPadding : padding;

    final hasCenter = centerAction != null;
    final totalHeight =
        barHeight + (hasCenter ? _centerActionLift : 0.0) + bottomPadding;
    final floatingSurfaceHeight = barHeight - _floatingBarBottomInset;

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
                start: _floatingBarHorizontalInset,
                end: _floatingBarHorizontalInset,
                bottom: bottomPadding + _floatingBarBottomInset,
                height: floatingSurfaceHeight,
                child: DecoratedBox(
                  key: const ValueKey('bottomNavigationFloatingSurface'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: context.colorScheme.shadow.withValues(
                          alpha: isDark ? 0.22 : 0.07,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: _OptionalBackdropBlur(
                      enabled: enableBackdropBlur,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? semantic.surfaceElevated
                                      : context.colorScheme.surface)
                                  .withValues(
                                    alpha: enableBackdropBlur ? 0.92 : 0.99,
                                  ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: semantic.divider.withValues(
                              alpha: isDark ? 0.38 : 0.55,
                            ),
                            width: AppBorderWidth.hairline,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: _floatingBarHorizontalInset,
                end: _floatingBarHorizontalInset,
                bottom: bottomPadding + _floatingBarBottomInset,
                height: floatingSurfaceHeight,
                child: Material(
                  color: context.colorScheme.surface.withValues(alpha: 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final count = destinations.length;
                      final slotWidth = hasCenter
                          ? (availableWidth < 360
                                ? (_centerActionExtent + 20)
                                : _centerActionSlotWidth)
                          : 0.0;
                      final mid = count ~/ 2;

                      Widget destinationSlot({
                        required int index,
                        required double width,
                      }) => AnimatedContainer(
                        key: ValueKey(
                          'bottomNavigationDestinationSlot-$count-$index',
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : AppDurations.fast,
                        curve: Curves.easeOutCubic,
                        width: width,
                        height: double.infinity,
                        child: _BottomBarItem(
                          index: index,
                          destination: destinations[index],
                          selected: index == selectedIndex,
                          onTap: () => onDestinationSelected(index),
                        ),
                      );

                      if (hasCenter) {
                        final halfWidth = (availableWidth - slotWidth) / 2;

                        List<Widget> sideSlots(int start, int end) {
                          final sideCount = end - start;
                          final itemWidth = halfWidth / sideCount;
                          return [
                            for (var i = start; i < end; i++)
                              destinationSlot(
                                index: i,
                                width: itemWidth,
                              ),
                          ];
                        }

                        return Row(
                          children: [
                            SizedBox(
                              width: halfWidth,
                              child: Row(children: sideSlots(0, mid)),
                            ),
                            SizedBox(width: slotWidth),
                            SizedBox(
                              width: halfWidth,
                              child: Row(children: sideSlots(mid, count)),
                            ),
                          ],
                        );
                      }

                      final itemWidth = availableWidth / count;

                      return Row(
                        children: [
                          for (var i = 0; i < count; i++)
                            destinationSlot(
                              index: i,
                              width: itemWidth,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (hasCenter)
                Positioned(
                  top: 10,
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

class _CenterActionButtonState extends State<_CenterActionButton>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _menuEntry;
  bool _pressed = false;
  late final AnimationController _menuController;

  bool get _menuOpen => _menuEntry != null;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
      reverseDuration: AppDurations.fast,
    );
  }

  @override
  void dispose() {
    _menuEntry?.remove();
    _menuController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _toggleMenu() {
    if (widget.action.quickActions.isEmpty) {
      widget.action.onPressed();
      return;
    }
    if (_menuOpen) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    _menuEntry = OverlayEntry(
      builder: (overlayContext) => _QuickActionsOverlay(
        link: _layerLink,
        animation: _menuController,
        action: widget.action,
        onDismiss: _hideMenu,
        onSelected: (quickAction) {
          _hideMenu(afterClosed: quickAction.onPressed);
        },
      ),
    );
    overlay.insert(_menuEntry!);
    setState(() {});
    _menuController.forward(from: 0);
  }

  Future<void> _hideMenu({VoidCallback? afterClosed}) async {
    if (!_menuOpen) return;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _menuController.reverse();
    } else {
      _menuController.value = 0;
    }
    _menuEntry?.remove();
    _menuEntry = null;
    if (mounted) setState(() {});
    afterClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final action = widget.action;
    final semanticLabel = action.label ?? action.tooltip ?? '';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        key: const ValueKey('bottomNavigationCenterActionSemantics'),
        container: true,
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Tooltip(
          message: action.tooltip ?? action.label ?? '',
          child: Transform.rotate(
            angle: math.pi / 4,
            child: DecoratedBox(
              key: const ValueKey('bottomNavigationCenterAction'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.primary,
                    Color.lerp(
                      context.colorScheme.primary,
                      context.colorScheme.tertiary,
                      0.45,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: context.colorScheme.surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.primary.withValues(
                      alpha: context.isDark ? 0.36 : 0.24,
                    ),
                    blurRadius: _pressed ? 6 : 14,
                    offset: Offset(2, _pressed ? 1 : 4),
                  ),
                ],
              ),
              child: AnimatedScale(
                scale: _pressed ? 0.91 : 1,
                duration: reduceMotion ? Duration.zero : AppDurations.xfast,
                curve: Curves.easeOutCubic,
                child: Material(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  clipBehavior: Clip.antiAlias,
                  color: context.colorScheme.surface.withValues(
                    alpha: 0,
                    red: 0,
                    green: 0,
                    blue: 0,
                  ),
                  child: InkWell(
                    onHighlightChanged: _setPressed,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _toggleMenu();
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
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: AnimatedRotation(
                            turns: _menuOpen ? 0.125 : 0,
                            duration: reduceMotion
                                ? Duration.zero
                                : AppDurations.fast,
                            curve: Curves.easeOutBack,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsOverlay extends StatelessWidget {
  const _QuickActionsOverlay({
    required this.link,
    required this.animation,
    required this.action,
    required this.onDismiss,
    required this.onSelected,
  });

  final LayerLink link;
  final Animation<double> animation;
  final AppCenterAction action;
  final VoidCallback onDismiss;
  final ValueChanged<AppQuickAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final width = math.min<double>(
      MediaQuery.sizeOf(context).width - 32,
      360,
    );
    final entrance = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: GestureDetector(
              key: const ValueKey('quickActionsDismissArea'),
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(
                color: semantic.scrim.withValues(
                  alpha: context.isDark ? 0.20 : 0.06,
                ),
              ),
            ),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -16),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, 0.72, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(entrance),
              alignment: Alignment.bottomCenter,
              child: Material(
                key: const ValueKey('quickActionsMenu'),
                color: context.colorScheme.surface,
                elevation: AppElevation.lg,
                shadowColor: context.colorScheme.shadow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: width,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: semantic.divider.withValues(alpha: 0.55),
                      width: AppBorderWidth.hairline,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.menuLabel ?? action.label ?? '',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: semantic.mutedForeground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final (index, quickAction)
                              in action.quickActions.indexed)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: index == 0 ? 0 : 4,
                                  end: index == action.quickActions.length - 1
                                      ? 0
                                      : 4,
                                ),
                                child: _QuickActionTile(
                                  index: index,
                                  count: action.quickActions.length,
                                  animation: animation,
                                  action: quickAction,
                                  onTap: () => onSelected(quickAction),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.index,
    required this.count,
    required this.animation,
    required this.action,
    required this.onTap,
  });

  final int index;
  final int count;
  final Animation<double> animation;
  final AppQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = 0.12 + (index * 0.08);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(start, math.min(start + 0.55, 1), curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: itemAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.24),
          end: Offset.zero,
        ).animate(itemAnimation),
        child: Semantics(
          button: true,
          label: action.label,
          excludeSemantics: true,
          child: Material(
            color: context.colorScheme.primaryContainer.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('quickAction-$index'),
              onTap: onTap,
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        action.icon,
                        size: AppIconSize.md,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
        ? context.colorScheme.onPrimary
        : semantic.navigationUnselected;

    final effectiveBadgeCount = destination.badgeCount;
    final semanticLabel =
        (effectiveBadgeCount != null && effectiveBadgeCount > 0)
        ? '${destination.label}, $effectiveBadgeCount'
        : destination.label;
    Widget destinationIcon({required bool selectedState}) => Badge(
      isLabelVisible: destination.hasBadge || (effectiveBadgeCount ?? 0) > 0,
      label: effectiveBadgeCount != null ? Text('$effectiveBadgeCount') : null,
      backgroundColor: context.colorScheme.error,
      textColor: context.colorScheme.onError,
      textStyle: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      child: FaIcon(
        selectedState ? destination.selectedIcon : destination.icon,
        key: ValueKey('bottomNavigationIcon-$index-$selectedState'),
        color: foreground,
        size: 20,
      ),
    );

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
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Center(
            child: AnimatedContainer(
              key: ValueKey('bottomNavigationDestinationSurface-$index'),
              duration: reduceMotion ? Duration.zero : AppDurations.fast,
              curve: _curve,
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          context.colorScheme.primary,
                          Color.lerp(
                            context.colorScheme.primary,
                            context.colorScheme.tertiary,
                            0.42,
                          )!,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: context.colorScheme.primary.withValues(
                            alpha: context.isDark ? 0.26 : 0.18,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppDurations.fast,
                switchInCurve: _curve,
                switchOutCurve: Curves.easeInCubic,
                child: Center(
                  key: ValueKey('iconOnlyDestination-$selected'),
                  child: destinationIcon(selectedState: selected),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
