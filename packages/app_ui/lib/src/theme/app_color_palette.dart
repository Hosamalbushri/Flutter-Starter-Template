import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Application-level brand colors used to build a complete Material scheme.
///
/// Standard UI roles still come from [ColorScheme]. This small input model is
/// intentionally limited to brand identity, so applications can rebrand the
/// shared design system without defining a parallel set of component colors.
@immutable
class AppColorPalette {
  const AppColorPalette({
    required this.primary,
    this.secondary,
    this.tertiary,
  });

  /// A calm blue preset suitable for general-purpose applications.
  static const blue = AppColorPalette(
    primary: Color(0xFF1769AA),
    secondary: Color(0xFF50606E),
    tertiary: Color(0xFF6750A4),
  );

  /// An optional warm accent preset. Red is not required by the system.
  static const red = AppColorPalette(
    primary: Color(0xFFB4232C),
    secondary: Color(0xFF72575A),
    tertiary: Color(0xFF7A526A),
  );

  final Color primary;
  final Color? secondary;
  final Color? tertiary;

  /// Converts this brand input into FlexColorScheme's light seed model.
  FlexSchemeColor get lightColors => FlexSchemeColor.from(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    brightness: Brightness.light,
  );

  /// Converts this brand input into FlexColorScheme's dark seed model.
  FlexSchemeColor get darkColors => FlexSchemeColor.from(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
    brightness: Brightness.dark,
  );
}
