import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Localization accessor for a [BuildContext].
extension BuildContextLocalization on BuildContext {
  /// The generated [AppLocalizations] for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Deterministic locale resolution callback for [WidgetsApp] / `MaterialApp`.
///
/// Matches the first preferred locale whose language code is supported, and
/// falls back deterministically to English (`Locale('en')`) when none match.
Locale resolveSupportedLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  if (preferredLocales != null) {
    for (final preferred in preferredLocales) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == preferred.languageCode) {
          return supported;
        }
      }
    }
  }
  return supportedLocales.firstWhere(
    (l) => l.languageCode == 'en',
    orElse: () => const Locale('en'),
  );
}
