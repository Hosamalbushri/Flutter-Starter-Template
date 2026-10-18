import 'package:feature_profile/src/presentation/screens/system_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:theme/theme.dart';

import '../../support.dart';

class MockThemeBloc extends Mock implements ThemeBloc {}

void main() {
  late MockThemeBloc themeBloc;

  setUpAll(() {
    registerFallbackValue(const ThemeSettingsReset());
  });

  setUp(() {
    themeBloc = MockThemeBloc();
    when(() => themeBloc.state).thenReturn(
      const ThemeState(
        mode: ThemeMode.system,
        scheme: ThemeState.defaultScheme,
      ),
    );
    when(() => themeBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<ThemeBloc>.value(
        value: themeBloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SystemSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the complete system settings groups', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Appearance and color'), findsOneWidget);
    expect(find.text('Type and reading'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.byKey(const ValueKey('openFontLibrary')), findsOneWidget);
    expect(find.byKey(const ValueKey('language-ar')), findsOneWidget);
  });

  testWidgets('dispatches font, language, and reset changes', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('openFontLibrary')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fontSearchField')),
      'Cairo',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fontResult-Cairo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-ar')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('resetSystemSettings')),
    );
    await tester.tap(find.byKey(const ValueKey('resetSystemSettings')));

    final events = verify(() => themeBloc.add(captureAny())).captured;
    expect(
      events.whereType<ThemeFontFamilyChanged>().single.fontFamily,
      'Cairo',
    );
    expect(
      events.whereType<ThemeLocaleChanged>().single.locale,
      const Locale('ar'),
    );
    expect(events.whereType<ThemeSettingsReset>(), hasLength(1));
  });

  testWidgets('font library searches and selects any available family', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('openFontLibrary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fontSearchField')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('fontSearchField')),
      'Roboto Slab',
    );
    await tester.pumpAndSettle();
    final result = find.byKey(const ValueKey('fontResult-Roboto Slab'));
    expect(result, findsOneWidget);
    await tester.tap(result);
    await tester.pumpAndSettle();

    final events = verify(() => themeBloc.add(captureAny())).captured;
    expect(
      events.whereType<ThemeFontFamilyChanged>().single.fontFamily,
      'Roboto Slab',
    );
  });
}
