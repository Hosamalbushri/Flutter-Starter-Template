@Tags(['golden'])
library;

import 'dart:io';

import 'package:app_ui/app_ui.dart';
// fst:auth:start
import 'package:feature_auth/feature_auth.dart';
// fst:auth:end
import 'package:feature_home/feature_home.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localization/localization.dart';
// fst:auth:start
import 'package:shared_ui/shared_ui.dart';
// fst:auth:end
import 'package:test_utils/test_utils.dart';
import 'package:theme/theme.dart';

class _MockHomeBloc extends Mock implements HomeBloc {}

class _MockThemeBloc extends Mock implements ThemeBloc {}

class _MockProfileBloc extends Mock implements ProfileBloc {}

// fst:auth:start
class _MockDeleteAccountCubit extends Mock implements DeleteAccountCubit {}
// fst:auth:end

const _destinations = [
  AppDestination(
    icon: FontAwesomeIcons.house,
    selectedIcon: FontAwesomeIcons.house,
    label: 'Home',
  ),
  // fst:feature:bookmarks:start
  AppDestination(icon: FontAwesomeIcons.bookmark, label: 'Bookmarks'),
  // fst:feature:bookmarks:end
  // fst:feature:notifications:start
  AppDestination(icon: FontAwesomeIcons.bell, label: 'Notifications'),
  // fst:feature:notifications:end
  AppDestination(
    icon: FontAwesomeIcons.user,
    selectedIcon: FontAwesomeIcons.solidUser,
    label: 'Profile',
  ),
];

final int _profileIndex = _destinations.length - 1;

const int _canonicalTemplateVariant =
    0
    // fst:auth:start
    +
    1
    // fst:auth:end
    // fst:feature:bookmarks:start
    +
    1
    // fst:feature:bookmarks:end
    // fst:feature:notifications:start
    +
    1
// fst:feature:notifications:end
;
const _skipVariantGoldens = _canonicalTemplateVariant != 3;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockHomeBloc homeBloc;
  late _MockThemeBloc themeBloc;
  late _MockProfileBloc profileBloc;
  // fst:auth:start
  late _MockDeleteAccountCubit deleteAccountCubit;
  late FakeSession session;
  // fst:auth:end

  setUpAll(() async {
    final bytes = await File(
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ).readAsBytes();
    await (FontLoader(
      'GoldenText',
    )..addFont(Future.value(bytes.buffer.asByteData()))).load();
    await _loadBundledFont(
      'packages/font_awesome_flutter/FontAwesomeSolid',
      'packages/font_awesome_flutter/lib/fonts/'
          'Font-Awesome-7-Free-Solid-900.otf',
    );
    await _loadBundledFont(
      'packages/font_awesome_flutter/FontAwesomeRegular',
      'packages/font_awesome_flutter/lib/fonts/'
          'Font-Awesome-7-Free-Regular-400.otf',
    );
  });

  setUp(() {
    homeBloc = _MockHomeBloc();
    themeBloc = _MockThemeBloc();
    profileBloc = _MockProfileBloc();
    // fst:auth:start
    deleteAccountCubit = _MockDeleteAccountCubit();
    session = FakeSession(currentUser: testUser);
    // fst:auth:end

    when(() => homeBloc.state).thenReturn(const HomeState());
    when(() => homeBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => themeBloc.state).thenReturn(
      const ThemeState(
        mode: ThemeMode.light,
        scheme: ThemeState.defaultScheme,
      ),
    );
    when(() => themeBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => profileBloc.state).thenReturn(const ProfileState());
    when(() => profileBloc.stream).thenAnswer((_) => const Stream.empty());
    // fst:auth:start
    when(
      () => deleteAccountCubit.state,
    ).thenReturn(const DeleteAccountState.initial());
    when(
      () => deleteAccountCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    // fst:auth:end
  });

  testWidgets('Home dark RTL', (tester) async {
    await _pumpHome(
      tester,
      homeBloc: homeBloc,
      brightness: Brightness.dark,
      locale: const Locale('ar'),
      size: const Size(390, 844),
    );
    await _expectGolden(tester, 'home_dark_rtl');
  }, skip: _skipVariantGoldens);

  testWidgets('Home light LTR', (tester) async {
    await _pumpHome(
      tester,
      homeBloc: homeBloc,
      brightness: Brightness.light,
      locale: const Locale('en'),
      size: const Size(390, 844),
    );
    await _expectGolden(tester, 'home_light_ltr');
  }, skip: _skipVariantGoldens);

  testWidgets('Profile dark RTL', (tester) async {
    await _pumpProfile(
      tester,
      themeBloc: themeBloc,
      profileBloc: profileBloc,
      // fst:auth:start
      deleteAccountCubit: deleteAccountCubit,
      session: session,
      // fst:auth:end
      brightness: Brightness.dark,
      locale: const Locale('ar'),
    );
    await _expectGolden(tester, 'profile_dark_rtl');
  }, skip: _skipVariantGoldens);

  testWidgets('Settings light LTR', (tester) async {
    await _pumpProfile(
      tester,
      themeBloc: themeBloc,
      profileBloc: profileBloc,
      // fst:auth:start
      deleteAccountCubit: deleteAccountCubit,
      session: session,
      // fst:auth:end
      brightness: Brightness.light,
      locale: const Locale('en'),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -620));
    await tester.pumpAndSettle();
    await _expectGolden(tester, 'settings_light_ltr');
  }, skip: _skipVariantGoldens);

  testWidgets(
    'responsive rail preserves the integrated Home screen',
    (
      tester,
    ) async {
      await _pumpHome(
        tester,
        homeBloc: homeBloc,
        brightness: Brightness.light,
        locale: const Locale('en'),
        size: const Size(840, 900),
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      await _expectGolden(tester, 'responsive_rail_light_ltr');
    },
    skip: _skipVariantGoldens,
  );

  testWidgets('Home loading and error states are deterministic', (
    tester,
  ) async {
    when(
      () => homeBloc.state,
    ).thenReturn(const HomeState(isLoading: true));
    await _pumpHome(
      tester,
      homeBloc: homeBloc,
      brightness: Brightness.light,
      locale: const Locale('en'),
      size: const Size(390, 844),
    );
    await _expectGolden(tester, 'home_loading_light_ltr');

    when(
      () => homeBloc.state,
    ).thenReturn(const HomeState(failure: testFailure));
    await _pumpHome(
      tester,
      homeBloc: homeBloc,
      brightness: Brightness.light,
      locale: const Locale('en'),
      size: const Size(390, 844),
    );
    await tester.pump(const Duration(seconds: 1));
    await _expectGolden(tester, 'home_error_light_ltr');
  }, skip: _skipVariantGoldens);
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required HomeBloc homeBloc,
  required Brightness brightness,
  required Locale locale,
  required Size size,
}) async {
  await _pumpShell(
    tester,
    size: size,
    brightness: brightness,
    locale: locale,
    selectedIndex: 0,
    body: BlocProvider<HomeBloc>.value(
      value: homeBloc,
      child: const HomeBody(),
    ),
  );
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required ThemeBloc themeBloc,
  required ProfileBloc profileBloc,
  // fst:auth:start
  required DeleteAccountCubit deleteAccountCubit,
  required FakeSession session,
  // fst:auth:end
  required Brightness brightness,
  required Locale locale,
}) async {
  Widget body = MultiBlocProvider(
    providers: [
      BlocProvider<ThemeBloc>.value(value: themeBloc),
      BlocProvider<ProfileBloc>.value(value: profileBloc),
      // fst:auth:start
      BlocProvider<DeleteAccountCubit>.value(value: deleteAccountCubit),
      // fst:auth:end
    ],
    child: const ProfileBody(),
  );
  // fst:auth:start
  body = SessionScope(session: session, child: body);
  // fst:auth:end
  await _pumpShell(
    tester,
    size: const Size(390, 844),
    brightness: brightness,
    locale: locale,
    selectedIndex: _profileIndex,
    body: body,
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required Brightness brightness,
  required Locale locale,
  required int selectedIndex,
  required Widget body,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'GoldenText',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF095D9E),
          brightness: brightness,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const ValueKey('golden'),
        child: AppAdaptiveScaffold(
          destinations: _destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: (_) {},
          body: body,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectGolden(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Future<void> _loadBundledFont(String family, String asset) async {
  final data = await rootBundle.load(asset);
  await (FontLoader(family)..addFont(Future.value(data))).load();
}
