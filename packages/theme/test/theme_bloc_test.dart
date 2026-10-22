import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_utils/test_utils.dart';
import 'package:theme/theme.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late MockAnalyticsService mockAnalytics;
  late ThemeBloc bloc;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockAnalytics = MockAnalyticsService();
    stubAnalyticsService(mockAnalytics);
    registerFallbackValue('');
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    bloc = ThemeBloc(mockPrefs, mockAnalytics);
  });

  tearDown(() {
    bloc.close();
  });

  group('ThemeBloc', () {
    test('initial state has default scheme and system mode when no prefs', () {
      expect(bloc.state.mode, ThemeMode.system);
      expect(bloc.state.scheme, ThemeState.defaultScheme);
      expect(bloc.state.fontFamily, 'system');
      expect(bloc.state.textScale, AppTextScale.system);
    });

    test('reads initial state from SharedPreferences', () {
      when(() => mockPrefs.getString('app.theme_mode')).thenReturn('dark');
      when(() => mockPrefs.getString('app.theme_scheme')).thenReturn('indigo');
      when(() => mockPrefs.getString('app.font_family')).thenReturn('cairo');
      when(() => mockPrefs.getString('app.text_scale')).thenReturn('large');

      final c = ThemeBloc(mockPrefs, mockAnalytics);
      expect(c.state.mode, ThemeMode.dark);
      expect(c.state.scheme, FlexScheme.indigo);
      expect(c.state.fontFamily, 'Cairo');
      expect(c.state.textScale, AppTextScale.large);
      c.close();
    });

    group('setMode', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits new mode and persists to prefs',
        build: () => bloc,
        act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.dark)),
        expect: () => [
          predicate<ThemeState>(
            (s) =>
                s.mode == ThemeMode.dark &&
                s.scheme == ThemeState.defaultScheme,
          ),
        ],
        verify: (_) {
          verify(() => mockPrefs.setString('app.theme_mode', 'dark')).called(1);
          verifyNever(
            () => mockPrefs.setString('app.theme_scheme', any()),
          );
          verify(
            () => mockAnalytics.logEvent(
              'theme_mode_changed',
              parameters: any(named: 'parameters'),
            ),
          ).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'does nothing when mode is unchanged',
        build: () => bloc,
        act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.system)),
        expect: () => <ThemeState>[],
      );
    });

    group('setScheme', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits new scheme and persists to prefs',
        build: () => bloc,
        act: (bloc) => bloc.add(const ThemeSchemeChanged(FlexScheme.mango)),
        expect: () => [
          predicate<ThemeState>(
            (s) => s.mode == ThemeMode.system && s.scheme == FlexScheme.mango,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockPrefs.setString('app.theme_mode', any()));
          verify(
            () => mockPrefs.setString('app.theme_scheme', 'mango'),
          ).called(1);
          verify(
            () => mockAnalytics.logEvent(
              'theme_scheme_changed',
              parameters: any(named: 'parameters'),
            ),
          ).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'does nothing when scheme is unchanged',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const ThemeSchemeChanged(ThemeState.defaultScheme)),
        expect: () => <ThemeState>[],
      );
    });

    group('setLocale', () {
      blocTest<ThemeBloc, ThemeState>(
        'emits new locale and persists languageCode to prefs',
        build: () => bloc,
        act: (bloc) => bloc.add(const ThemeLocaleChanged(Locale('ar'))),
        expect: () => [
          predicate<ThemeState>(
            (s) => s.locale == const Locale('ar'),
          ),
        ],
        verify: (_) {
          verify(() => mockPrefs.setString('app.locale', 'ar')).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'clears locale when null is passed',
        build: () {
          when(() => mockPrefs.getString('app.locale')).thenReturn('ar');
          return ThemeBloc(mockPrefs, mockAnalytics);
        },
        act: (bloc) => bloc.add(const ThemeLocaleChanged(null)),
        expect: () => [
          predicate<ThemeState>((s) => s.locale == null),
        ],
        verify: (_) {
          verify(() => mockPrefs.setString('app.locale', '')).called(1);
        },
      );
    });

    group('system settings', () {
      blocTest<ThemeBloc, ThemeState>(
        'persists the selected font family',
        build: () => bloc,
        act: (bloc) => bloc.add(
          const ThemeFontFamilyChanged('Noto Kufi Arabic'),
        ),
        expect: () => [
          predicate<ThemeState>(
            (state) => state.fontFamily == 'Noto Kufi Arabic',
          ),
        ],
        verify: (_) {
          verify(
            () => mockPrefs.setString('app.font_family', 'Noto Kufi Arabic'),
          ).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'persists the selected text scale',
        build: () => bloc,
        act: (bloc) =>
            bloc.add(const ThemeTextScaleChanged(AppTextScale.large)),
        expect: () => [
          predicate<ThemeState>(
            (state) => state.textScale == AppTextScale.large,
          ),
        ],
        verify: (_) {
          verify(
            () => mockPrefs.setString('app.text_scale', 'large'),
          ).called(1);
        },
      );

      blocTest<ThemeBloc, ThemeState>(
        'reset restores all system defaults',
        build: () {
          when(() => mockPrefs.getString('app.theme_mode')).thenReturn('dark');
          when(
            () => mockPrefs.getString('app.theme_scheme'),
          ).thenReturn('mango');
          when(() => mockPrefs.getString('app.locale')).thenReturn('ar');
          when(
            () => mockPrefs.getString('app.font_family'),
          ).thenReturn('cairo');
          when(() => mockPrefs.getString('app.text_scale')).thenReturn('large');
          return ThemeBloc(mockPrefs, mockAnalytics);
        },
        act: (bloc) => bloc.add(const ThemeSettingsReset()),
        expect: () => [
          predicate<ThemeState>(
            (state) =>
                state.mode == ThemeMode.system &&
                state.scheme == ThemeState.defaultScheme &&
                state.locale == null &&
                state.fontFamily == 'system' &&
                state.textScale == AppTextScale.system,
          ),
        ],
        verify: (_) {
          verify(() => mockPrefs.setString('app.locale', '')).called(1);
          verify(
            () => mockPrefs.setString('app.font_family', 'system'),
          ).called(1);
          verify(
            () => mockPrefs.setString('app.text_scale', 'system'),
          ).called(1);
        },
      );
    });
  });
}
