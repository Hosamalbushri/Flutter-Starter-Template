import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_border_width.dart';
import 'app_color_palette.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'semantic_colors.dart';

const _componentThemes = FlexSubThemesData(
  cardRadius: AppRadius.lg,
  cardElevation: AppElevation.sm,
  inputDecoratorRadius: AppRadius.lg,
  inputDecoratorIsFilled: true,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorUnfocusedBorderIsColored: true,
  inputDecoratorFocusedBorderWidth: AppBorderWidth.focus,
  filledButtonRadius: AppRadius.button,
  elevatedButtonRadius: AppRadius.button,
  elevatedButtonElevation: AppElevation.sm,
  outlinedButtonRadius: AppRadius.button,
  textButtonRadius: AppRadius.button,
  fabRadius: AppRadius.lg,
  chipRadius: AppRadius.sm,
  dialogRadius: AppRadius.xl,
  bottomSheetRadius: AppRadius.xl,
  navigationBarIndicatorRadius: AppRadius.lg,
  snackBarRadius: AppRadius.sm,
  snackBarElevation: AppElevation.md,
  useM2StyleDividerInM3: false,
  appBarScrolledUnderElevation: AppElevation.none,
);

/// Central theme factory for built-in schemes and application brand palettes.
class AppTheme {
  const AppTheme._();

  /// Builds a light theme. Passing [palette] takes precedence over [scheme].
  static ThemeData light({
    FlexScheme scheme = FlexScheme.blue,
    AppColorPalette? palette,
    String fontFamily = 'system',
  }) {
    final textTheme = _fontTextTheme(fontFamily, ThemeData.light().textTheme);
    final base = FlexThemeData.light(
      scheme: scheme,
      colors: palette?.lightColors,
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurfaces,
      blendLevel: 1,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      subThemesData: _componentThemes,
      appBarElevation: AppElevation.none,
      appBarStyle: FlexAppBarStyle.surface,
    );
    return _finish(base);
  }

  /// Builds a near-black dark theme. [palette] remains optional so persisted
  /// [FlexScheme] preferences keep their existing behavior.
  static ThemeData dark({
    FlexScheme scheme = FlexScheme.blue,
    AppColorPalette? palette,
    String fontFamily = 'system',
  }) {
    final textTheme = _fontTextTheme(fontFamily, ThemeData.dark().textTheme);
    final base = FlexThemeData.dark(
      scheme: scheme,
      colors: palette?.darkColors,
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurfaces,
      blendLevel: 4,
      darkIsTrueBlack: true,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      subThemesData: _componentThemes,
      appBarElevation: AppElevation.none,
      appBarStyle: FlexAppBarStyle.surface,
    );
    return _finish(base);
  }

  static ThemeData _finish(ThemeData base) {
    final semantic = SemanticColors.from(base.colorScheme);
    final textTheme = AppTypography.textTheme(base.textTheme);
    final primaryTextTheme = AppTypography.textTheme(base.primaryTextTheme);
    final buttonTextStyle = WidgetStatePropertyAll(textTheme.labelLarge);
    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: buttonTextStyle,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: (base.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: (base.textButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: buttonTextStyle,
        ),
      ),
      dividerColor: semantic.divider,
      disabledColor: semantic.onDisabled,
      focusColor: semantic.focus.withValues(alpha: 0.18),
      hoverColor: base.colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: base.colorScheme.primary.withValues(alpha: 0.12),
      extensions: [semantic],
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static TextTheme _fontTextTheme(String fontFamily, TextTheme base) {
    if (fontFamily == 'system') return base;
    try {
      return GoogleFonts.getTextTheme(fontFamily, base);
    } on Exception {
      // A removed or corrupted persisted family must never prevent startup.
      return base;
    }
  }
}

extension BuildContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  SemanticColors get semanticColors =>
      theme.extension<SemanticColors>() ??
      SemanticColors.from(theme.colorScheme);
  Brightness get brightness => theme.brightness;
  bool get isDark => brightness == Brightness.dark;
  bool get isLight => brightness == Brightness.light;
}
