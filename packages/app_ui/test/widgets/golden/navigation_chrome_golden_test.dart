@Tags(['golden'])
library;

import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _destinations = [
  AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
  AppDestination(icon: FontAwesomeIcons.magnifyingGlass, label: 'Search'),
  AppDestination(icon: FontAwesomeIcons.bookmark, label: 'Saved'),
  AppDestination(icon: FontAwesomeIcons.user, label: 'Profile'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final bytes = await _loadGoldenFontBytes();
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

  testWidgets('dark Arabic top bar', (tester) async {
    await _pumpTopBar(
      tester,
      brightness: Brightness.dark,
      direction: TextDirection.rtl,
      title: 'الإشعارات',
    );
    await _expectGolden(tester, 'app_top_bar_dark_ar');
  });

  testWidgets('light English top bar', (tester) async {
    await _pumpTopBar(
      tester,
      brightness: Brightness.light,
      direction: TextDirection.ltr,
      title: 'Notifications',
    );
    await _expectGolden(tester, 'app_top_bar_light_en');
  });

  testWidgets('compact Arabic dashboard top bar', (tester) async {
    await _pump(
      tester,
      brightness: Brightness.light,
      direction: TextDirection.rtl,
      size: const Size(390, 120),
      child: const Scaffold(
        appBar: AppTopBar(
          title: 'مرحبًا بك',
          subtitle: 'حسام حازم',
          variant: AppTopBarVariant.dashboard,
          profileAvatar: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFF1769AA),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Center(
              child: Text(
                'ح',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          searchAction: IconButton(
            tooltip: 'بحث',
            onPressed: _noop,
            icon: FaIcon(FontAwesomeIcons.magnifyingGlass),
          ),
          actions: [
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: _noop,
              icon: FaIcon(FontAwesomeIcons.bell),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _noop,
              icon: FaIcon(FontAwesomeIcons.rotateLeft),
            ),
          ],
        ),
        body: SizedBox.expand(),
      ),
    );
    await _expectGolden(tester, 'app_top_bar_dashboard_ar');
  });

  testWidgets('dark bottom navigation', (tester) async {
    await _pumpBottomBar(tester, brightness: Brightness.dark);
    await _expectGolden(tester, 'app_bottom_navigation_dark');
  });

  testWidgets('light bottom navigation', (tester) async {
    await _pumpBottomBar(tester, brightness: Brightness.light);
    await _expectGolden(tester, 'app_bottom_navigation_light');
  });

  testWidgets('center action variant', (tester) async {
    await _pumpBottomBar(
      tester,
      brightness: Brightness.light,
      centerAction: const AppCenterAction(
        icon: FontAwesomeIcons.plus,
        label: 'Create',
        onPressed: _noop,
      ),
    );
    await _expectGolden(tester, 'app_bottom_navigation_center_action');
  });

  testWidgets('no center action variant', (tester) async {
    await _pumpBottomBar(tester, brightness: Brightness.light);
    await _expectGolden(tester, 'app_bottom_navigation_no_center_action');
  });
}

Future<void> _pumpTopBar(
  WidgetTester tester, {
  required Brightness brightness,
  required TextDirection direction,
  required String title,
}) async {
  await _pump(
    tester,
    brightness: brightness,
    direction: direction,
    size: const Size(390, 112),
    child: Scaffold(
      appBar: AppTopBar(
        title: title,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _noop,
          icon: FaIcon(
            direction == TextDirection.rtl
                ? FontAwesomeIcons.chevronRight
                : FontAwesomeIcons.chevronLeft,
          ),
        ),
        notificationCount: 3,
        notificationTooltip: 'Notifications',
        onNotificationTap: _noop,
        onSearchTap: _noop,
      ),
      body: const SizedBox.expand(),
    ),
  );
}

Future<void> _pumpBottomBar(
  WidgetTester tester, {
  required Brightness brightness,
  AppCenterAction? centerAction,
}) async {
  await _pump(
    tester,
    brightness: brightness,
    direction: TextDirection.ltr,
    size: const Size(390, 180),
    child: AppAdaptiveScaffold(
      destinations: _destinations,
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      centerAction: centerAction,
      body: const ColoredBox(color: Colors.transparent),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  required TextDirection direction,
  required Size size,
  required Widget child,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _goldenTheme(brightness),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: Directionality(
          textDirection: direction,
          child: appChild!,
        ),
      ),
      home: RepaintBoundary(
        key: const ValueKey('golden'),
        child: child,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _expectGolden(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Future<Uint8List> _loadGoldenFontBytes() async {
  const candidates = [
    'test/widgets/golden/fonts/DejaVuSans.ttf',
    'packages/app_ui/test/widgets/golden/fonts/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsBytes();
    }
  }
  throw StateError('Could not find DejaVuSans.ttf in candidates: $candidates');
}

Future<void> _loadBundledFont(String family, String asset) async {
  final data = await rootBundle.load(asset);
  await (FontLoader(family)..addFont(Future.value(data))).load();
}

void _noop() {}

ThemeData _goldenTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF095D9E),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'GoldenText',
    colorScheme: colorScheme,
    extensions: [SemanticColors.from(colorScheme)],
  );
}
