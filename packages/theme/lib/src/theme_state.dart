import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({
    required this.mode,
    required this.scheme,
    this.locale,
  });

  final ThemeMode mode;
  final FlexScheme scheme;
  final Locale? locale;

  static const FlexScheme defaultScheme = FlexScheme.bahamaBlue;

  ThemeState copyWith({
    ThemeMode? mode,
    FlexScheme? scheme,
    Locale? locale,
    bool clearLocale = false,
  }) => ThemeState(
    mode: mode ?? this.mode,
    scheme: scheme ?? this.scheme,
    locale: clearLocale ? null : (locale ?? this.locale),
  );
}
