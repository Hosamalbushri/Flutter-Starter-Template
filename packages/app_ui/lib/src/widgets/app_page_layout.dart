import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';
import '../theme/app_border_width.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Standard page layouts conforming to the Phase 11 design foundation.
///
/// Provides consistent padding, responsive constraints, scroll behavior,
/// and responsive layout wrappers for Dashboard, Details, Forms, and Settings.
class AppPageLayout extends StatelessWidget {
  const AppPageLayout({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.maxWidth = AppBreakpoints.expanded,
    this.scrollable = true,
    this.physics,
    this.controller,
  });

  /// Factory constructor for dashboard screens with standard constraints and padding.
  const AppPageLayout.dashboard({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl + kMinInteractiveDimension,
    ),
    this.maxWidth = 1000,
    this.scrollable = true,
    this.physics,
    this.controller,
  });

  /// Factory constructor for settings & profile screens.
  const AppPageLayout.settings({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxxl + kMinInteractiveDimension,
    ),
    this.maxWidth = 720,
    this.scrollable = true,
    this.physics,
    this.controller,
  });

  /// Factory constructor for form/details screens.
  const AppPageLayout.form({
    super.key,
    required this.child,
    this.header,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.maxWidth = 640,
    this.scrollable = true,
    this.physics,
    this.controller,
  });

  final Widget child;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final bool scrollable;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: AppSpacing.lg),
              ],
              child,
            ],
          ),
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        controller: controller,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return content;
  }
}

/// A structured section header for dashboard or settings pages.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.sectionTitle(textTheme)?.copyWith(
                    color: context.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption(textTheme)?.copyWith(
                      color: semantic.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, kMinInteractiveDimension),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              child: Text(
                actionLabel!,
                style: AppTypography.caption(textTheme)?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard grouped container for settings items and dashboard tiles.
class AppGroupSection extends StatelessWidget {
  const AppGroupSection({
    super.key,
    required this.children,
    this.title,
    this.description,
  });

  final String? title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = context.textTheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              title!,
              style: AppTypography.sectionTitle(textTheme)?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark
                ? context.colorScheme.surfaceContainer
                : context.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: semantic.divider.withValues(alpha: isDark ? 0.3 : 0.6),
              width: AppBorderWidth.hairline,
            ),
            boxShadow: isDark ? null : AppElevation.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: AppBorderWidth.hairline,
                    thickness: AppBorderWidth.hairline,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: semantic.divider.withValues(alpha: 0.4),
                  ),
              ],
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              description!,
              style: AppTypography.caption(textTheme)?.copyWith(
                color: semantic.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
