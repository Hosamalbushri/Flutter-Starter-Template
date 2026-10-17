import 'package:flutter/material.dart';

/// Semantic typography authority for shared UI.
///
/// English can use the configured open-licensed brand font, while Arabic is
/// explicitly routed through Arabic-capable platform fallbacks instead of
/// being forced through an English-first face.
abstract final class AppTypography {
  /// Common Arabic-capable platform fonts, followed by the system fallback.
  /// No font files are bundled; availability is resolved by the host OS.
  static const fontFamilyFallback = <String>[
    'Noto Sans Arabic',
    'Noto Naskh Arabic',
    'Arial',
  ];

  /// Applies predictable weights and line heights to Material's type scale.
  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displayLarge: _style(
      base.displayLarge,
      weight: FontWeight.w700,
      height: 1.12,
    ),
    displayMedium: _style(
      base.displayMedium,
      weight: FontWeight.w700,
      height: 1.15,
    ),
    displaySmall: _style(
      base.displaySmall,
      weight: FontWeight.w700,
      height: 1.18,
    ),
    headlineLarge: _style(
      base.headlineLarge,
      weight: FontWeight.w700,
      height: 1.2,
    ),
    headlineMedium: _style(
      base.headlineMedium,
      weight: FontWeight.w700,
      height: 1.22,
    ),
    headlineSmall: _style(
      base.headlineSmall,
      weight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: _style(base.titleLarge, weight: FontWeight.w700, height: 1.3),
    titleMedium: _style(
      base.titleMedium,
      weight: FontWeight.w600,
      height: 1.35,
    ),
    titleSmall: _style(base.titleSmall, weight: FontWeight.w600, height: 1.35),
    bodyLarge: _style(base.bodyLarge, height: 1.5),
    bodyMedium: _style(base.bodyMedium, height: 1.5),
    bodySmall: _style(base.bodySmall, height: 1.45),
    labelLarge: _style(base.labelLarge, weight: FontWeight.w700, height: 1.3),
    labelMedium: _style(base.labelMedium, weight: FontWeight.w600, height: 1.3),
    labelSmall: _style(base.labelSmall, weight: FontWeight.w600, height: 1.3),
  );

  static TextStyle? pageTitle(TextTheme theme) => theme.headlineSmall;
  static TextStyle? sectionTitle(TextTheme theme) => theme.titleLarge;
  static TextStyle? cardTitle(TextTheme theme) => theme.titleMedium;
  static TextStyle? body(TextTheme theme) => theme.bodyLarge;
  static TextStyle? secondaryBody(TextTheme theme) => theme.bodyMedium;
  static TextStyle? label(TextTheme theme) => theme.labelMedium;
  static TextStyle? caption(TextTheme theme) => theme.bodySmall;
  static TextStyle? button(TextTheme theme) => theme.labelLarge;
  static TextStyle? navigationLabel(TextTheme theme) => theme.labelMedium;

  /// Numeric style with equal-width digits for stable counters and metrics.
  static TextStyle? numeric(TextTheme theme) => theme.titleMedium?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle? _style(
    TextStyle? source, {
    FontWeight? weight,
    required double height,
  }) => source?.copyWith(
    fontWeight: weight,
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    fontFamilyFallback: fontFamilyFallback,
  );
}
