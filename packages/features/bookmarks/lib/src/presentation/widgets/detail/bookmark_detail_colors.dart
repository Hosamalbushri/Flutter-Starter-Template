import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// Semantic color tokens tailored for the bookmark detail view.
abstract final class BookmarkDetailColors {
  static Color background(BuildContext context) =>
      context.isDark ? context.colorScheme.surface : const Color(0xFFF7F9FB);
  static Color surface(BuildContext context) => context.isDark
      ? context.colorScheme.surfaceContainerLow
      : const Color(0xFFFFFFFF);
  static Color surfaceLow(BuildContext context) => context.isDark
      ? context.colorScheme.surfaceContainerHigh
      : const Color(0xFFF2F4F6);
  static Color surfaceHigh(BuildContext context) => context.isDark
      ? context.colorScheme.outlineVariant
      : const Color(0xFFE0E3E5);
  static Color primary(BuildContext context) => context.colorScheme.primary;
  static Color secondary(BuildContext context) =>
      context.colorScheme.onSurfaceVariant;
  static Color text(BuildContext context) => context.colorScheme.onSurface;
  static Color mutedText(BuildContext context) =>
      context.colorScheme.onSurfaceVariant;
}

