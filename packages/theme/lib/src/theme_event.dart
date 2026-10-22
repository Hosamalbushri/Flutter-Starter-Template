part of 'theme_bloc.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

final class ThemeModeChanged extends ThemeEvent {
  const ThemeModeChanged(this.mode);

  final ThemeMode mode;
}

final class ThemeSchemeChanged extends ThemeEvent {
  const ThemeSchemeChanged(this.scheme);

  final FlexScheme scheme;
}

final class ThemeLocaleChanged extends ThemeEvent {
  const ThemeLocaleChanged(this.locale);

  final Locale? locale;
}

final class ThemeFontFamilyChanged extends ThemeEvent {
  const ThemeFontFamilyChanged(this.fontFamily);

  final String fontFamily;
}

final class ThemeTextScaleChanged extends ThemeEvent {
  const ThemeTextScaleChanged(this.textScale);

  final AppTextScale textScale;
}

final class ThemeSettingsReset extends ThemeEvent {
  const ThemeSettingsReset();
}
