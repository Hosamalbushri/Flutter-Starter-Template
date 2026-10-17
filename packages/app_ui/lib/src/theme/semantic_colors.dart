import 'package:flutter/material.dart';

/// Theme roles that Material's [ColorScheme] does not expose directly.
///
/// Brand, surface, outline, and error colors remain owned by [ColorScheme].
/// This extension supplies status colors and shared aliases needed by custom
/// components, and animates with the rest of the theme.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    this.surfaceElevated = const Color(0xFFFFFFFF),
    this.mutedForeground = const Color(0xFF59636E),
    this.divider = const Color(0xFFDDE2E7),
    this.disabled = const Color(0xFFE2E5E9),
    this.onDisabled = const Color(0xFF73777F),
    this.focus = const Color(0xFF1769AA),
    this.navigationSelected = const Color(0xFF1769AA),
    this.navigationUnselected = const Color(0xFF59636E),
    this.scrim = const Color(0x66000000),
    this.skeletonBase = const Color(0xFFE3E8ED),
    this.skeletonHighlight = const Color(0xFFF7F9FA),
  });

  /// Derives component aliases from the active Material color scheme.
  factory SemanticColors.from(ColorScheme scheme) {
    final defaults = scheme.brightness == Brightness.dark ? dark : light;
    return defaults.copyWith(
      surfaceElevated: scheme.surfaceContainerHigh,
      mutedForeground: scheme.onSurfaceVariant,
      divider: scheme.outlineVariant,
      disabled: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.12),
        scheme.surface,
      ),
      onDisabled: scheme.onSurface.withValues(alpha: 0.38),
      focus: scheme.primary,
      navigationSelected: scheme.primary,
      navigationUnselected: scheme.onSurfaceVariant,
      scrim: scheme.scrim.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.6 : 0.4,
      ),
      skeletonBase: scheme.surfaceContainerHighest,
      skeletonHighlight: Color.alphaBlend(
        scheme.onSurface.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        scheme.surfaceContainerHighest,
      ),
    );
  }

  /// Backward-compatible light defaults for manually assembled themes.
  static const light = SemanticColors(
    success: Color(0xFF176B35),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF825000),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF00658F),
    onInfo: Color(0xFFFFFFFF),
  );

  /// Backward-compatible dark defaults for manually assembled themes.
  static const dark = SemanticColors(
    success: Color(0xFF75DC91),
    onSuccess: Color(0xFF003919),
    warning: Color(0xFFFFB95C),
    onWarning: Color(0xFF462A00),
    info: Color(0xFF63C7F5),
    onInfo: Color(0xFF003548),
    surfaceElevated: Color(0xFF24272B),
    mutedForeground: Color(0xFFBAC2CA),
    divider: Color(0xFF3E454C),
    disabled: Color(0xFF303438),
    onDisabled: Color(0xFF8D949B),
    focus: Color(0xFF8BC8FF),
    navigationSelected: Color(0xFF8BC8FF),
    navigationUnselected: Color(0xFFBAC2CA),
    scrim: Color(0x99000000),
    skeletonBase: Color(0xFF2B3035),
    skeletonHighlight: Color(0xFF42484E),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color surfaceElevated;
  final Color mutedForeground;
  final Color divider;
  final Color disabled;
  final Color onDisabled;
  final Color focus;
  final Color navigationSelected;
  final Color navigationUnselected;
  final Color scrim;
  final Color skeletonBase;
  final Color skeletonHighlight;

  @override
  SemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? surfaceElevated,
    Color? mutedForeground,
    Color? divider,
    Color? disabled,
    Color? onDisabled,
    Color? focus,
    Color? navigationSelected,
    Color? navigationUnselected,
    Color? scrim,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) => SemanticColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    divider: divider ?? this.divider,
    disabled: disabled ?? this.disabled,
    onDisabled: onDisabled ?? this.onDisabled,
    focus: focus ?? this.focus,
    navigationSelected: navigationSelected ?? this.navigationSelected,
    navigationUnselected: navigationUnselected ?? this.navigationUnselected,
    scrim: scrim ?? this.scrim,
    skeletonBase: skeletonBase ?? this.skeletonBase,
    skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
  );

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return SemanticColors(
      success: blend(success, other.success),
      onSuccess: blend(onSuccess, other.onSuccess),
      warning: blend(warning, other.warning),
      onWarning: blend(onWarning, other.onWarning),
      info: blend(info, other.info),
      onInfo: blend(onInfo, other.onInfo),
      surfaceElevated: blend(surfaceElevated, other.surfaceElevated),
      mutedForeground: blend(mutedForeground, other.mutedForeground),
      divider: blend(divider, other.divider),
      disabled: blend(disabled, other.disabled),
      onDisabled: blend(onDisabled, other.onDisabled),
      focus: blend(focus, other.focus),
      navigationSelected: blend(navigationSelected, other.navigationSelected),
      navigationUnselected: blend(
        navigationUnselected,
        other.navigationUnselected,
      ),
      scrim: blend(scrim, other.scrim),
      skeletonBase: blend(skeletonBase, other.skeletonBase),
      skeletonHighlight: blend(skeletonHighlight, other.skeletonHighlight),
    );
  }
}
