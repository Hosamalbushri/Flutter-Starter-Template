import 'package:analytics/analytics.dart';
import 'package:architecture/architecture.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

part 'theme_event.dart';

const _kThemeModeKey = 'app.theme_mode';
const _kThemeSchemeKey = 'app.theme_scheme';
const _kLocaleKey = 'app.locale';
const _kFontFamilyKey = 'app.font_family';
const _kTextScaleKey = 'app.text_scale';

@lazySingleton
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(this._prefs, this._analytics) : super(_readInitial(_prefs)) {
    on<ThemeModeChanged>(_onModeChanged, transformer: sequential());
    on<ThemeSchemeChanged>(_onSchemeChanged, transformer: sequential());
    on<ThemeLocaleChanged>(_onLocaleChanged, transformer: sequential());
    on<ThemeFontFamilyChanged>(_onFontFamilyChanged, transformer: sequential());
    on<ThemeTextScaleChanged>(_onTextScaleChanged, transformer: sequential());
    on<ThemeSettingsReset>(_onSettingsReset, transformer: sequential());
  }

  final SharedPreferences _prefs;
  final AnalyticsService _analytics;

  static ThemeState _readInitial(SharedPreferences prefs) {
    final modeRaw = prefs.getString(_kThemeModeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == modeRaw,
      orElse: () => ThemeMode.system,
    );

    final schemeRaw = prefs.getString(_kThemeSchemeKey);
    final scheme = FlexScheme.values.firstWhere(
      (s) => s.name == schemeRaw,
      orElse: () => ThemeState.defaultScheme,
    );

    final localeRaw = prefs.getString(_kLocaleKey);
    final locale = (localeRaw != null && localeRaw.isNotEmpty)
        ? Locale(localeRaw)
        : null;

    final fontFamily = _migrateFontFamily(prefs.getString(_kFontFamilyKey));

    final scaleRaw = prefs.getString(_kTextScaleKey);
    final textScale = AppTextScale.values.firstWhere(
      (scale) => scale.name == scaleRaw,
      orElse: () => AppTextScale.system,
    );

    return ThemeState(
      mode: mode,
      scheme: scheme,
      locale: locale,
      fontFamily: fontFamily,
      textScale: textScale,
    );
  }

  static String _migrateFontFamily(String? stored) => switch (stored) {
    null || '' || 'system' => 'system',
    'inter' => 'Inter',
    'cairo' => 'Cairo',
    'notoKufiArabic' => 'Noto Kufi Arabic',
    _ => stored,
  };

  Future<void> _onModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.mode == state.mode) return;
    emit(state.copyWith(mode: event.mode));
    await _prefs.setString(_kThemeModeKey, event.mode.name);
    _analytics.trackThemeModeChanged(event.mode.name).fire();
  }

  Future<void> _onSchemeChanged(
    ThemeSchemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.scheme == state.scheme) return;
    emit(state.copyWith(scheme: event.scheme));
    await _prefs.setString(_kThemeSchemeKey, event.scheme.name);
    _analytics.trackThemeSchemeChanged(event.scheme.name).fire();
  }

  Future<void> _onLocaleChanged(
    ThemeLocaleChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.locale == state.locale) return;
    emit(
      state.copyWith(
        locale: event.locale,
        clearLocale: event.locale == null,
      ),
    );
    await _prefs.setString(_kLocaleKey, event.locale?.languageCode ?? '');
  }

  Future<void> _onFontFamilyChanged(
    ThemeFontFamilyChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.fontFamily == state.fontFamily) return;
    emit(state.copyWith(fontFamily: event.fontFamily));
    await _prefs.setString(_kFontFamilyKey, event.fontFamily);
  }

  Future<void> _onTextScaleChanged(
    ThemeTextScaleChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.textScale == state.textScale) return;
    emit(state.copyWith(textScale: event.textScale));
    await _prefs.setString(_kTextScaleKey, event.textScale.name);
  }

  Future<void> _onSettingsReset(
    ThemeSettingsReset event,
    Emitter<ThemeState> emit,
  ) async {
    const defaults = ThemeState(
      mode: ThemeMode.system,
      scheme: ThemeState.defaultScheme,
    );
    if (state.mode == defaults.mode &&
        state.scheme == defaults.scheme &&
        state.locale == defaults.locale &&
        state.fontFamily == defaults.fontFamily &&
        state.textScale == defaults.textScale) {
      return;
    }
    emit(defaults);
    await Future.wait([
      _prefs.setString(_kThemeModeKey, defaults.mode.name),
      _prefs.setString(_kThemeSchemeKey, defaults.scheme.name),
      _prefs.setString(_kLocaleKey, ''),
      _prefs.setString(_kFontFamilyKey, defaults.fontFamily),
      _prefs.setString(_kTextScaleKey, defaults.textScale.name),
    ]);
  }
}
