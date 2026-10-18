import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

enum AppTextScale { system, compact, standard, large }

extension AppTextScaleValue on AppTextScale {
  double? get scale => switch (this) {
    AppTextScale.system => null,
    AppTextScale.compact => 0.9,
    AppTextScale.standard => 1,
    AppTextScale.large => 1.15,
  };
}

class ThemeState {
  const ThemeState({
    required this.mode,
    required this.scheme,
    this.locale,
    this.fontFamily = 'system',
    this.textScale = AppTextScale.system,
  });

  final ThemeMode mode;
  final FlexScheme scheme;
  final Locale? locale;

  /// Google Fonts family name, or `system` to follow the host platform.
  final String fontFamily;
  final AppTextScale textScale;

  static const FlexScheme defaultScheme = FlexScheme.bahamaBlue;

  ThemeState copyWith({
    ThemeMode? mode,
    FlexScheme? scheme,
    Locale? locale,
    bool clearLocale = false,
    String? fontFamily,
    AppTextScale? textScale,
  }) => ThemeState(
    mode: mode ?? this.mode,
    scheme: scheme ?? this.scheme,
    locale: clearLocale ? null : (locale ?? this.locale),
    fontFamily: fontFamily ?? this.fontFamily,
    textScale: textScale ?? this.textScale,
  );
}
