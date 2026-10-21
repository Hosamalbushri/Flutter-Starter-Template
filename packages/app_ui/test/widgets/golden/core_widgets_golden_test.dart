@Tags(['golden'])
library;

import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Pumps [child] inside a deterministic MaterialApp (a plain
/// `ColorScheme.fromSeed` theme, independent of the app theme) and captures
/// a golden of the region keyed `golden`.
Future<void> _pumpGolden(
  WidgetTester tester,
  Widget child, {
  required Brightness brightness,
  Size size = const Size(360, 320),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'GoldenText',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF095D9E),
          brightness: brightness,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('golden'),
            child: SizedBox.fromSize(
              size: size,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
  // Step frame-by-frame instead of pumpAndSettle: some widgets contain an
  // indeterminate CircularProgressIndicator that never settles (so
  // pumpAndSettle would time out). `flutter_animate`'s auto-played entrance
  // animations (fade/slide/scale-ins) advance per frame, not in a single jumped
  // pump, so we step ~1.2s in 100ms frames — long enough for those to finish —
  // which also lands the spinner on a deterministic frame. A single large pump
  // would leave the entrance animations at their opacity-0 start and capture a
  // blank golden.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _expectGolden(WidgetTester tester, String name) {
  return expectLater(
    find.byKey(const ValueKey('golden')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

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

  group('AppButton', () {
    const buttons = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        AppButton(
          label: 'Primary',
          onPressed: _noop,
          icon: FontAwesomeIcons.check,
        ),
        AppButton(
          label: 'Tonal',
          onPressed: _noop,
          variant: AppButtonVariant.tonal,
        ),
        AppButton(
          label: 'Outlined',
          onPressed: _noop,
          variant: AppButtonVariant.outlined,
        ),
        AppButton(
          label: 'Text',
          onPressed: _noop,
          variant: AppButtonVariant.text,
        ),
        AppButton(label: 'Loading', onPressed: _noop, isLoading: true),
      ],
    );

    testWidgets('variants (light)', (tester) async {
      await _pumpGolden(tester, buttons, brightness: Brightness.light);
      await _expectGolden(tester, 'app_button_light');
    });

    testWidgets('variants (dark)', (tester) async {
      await _pumpGolden(tester, buttons, brightness: Brightness.dark);
      await _expectGolden(tester, 'app_button_dark');
    });
  });

  group('AppEmptyView', () {
    const empty = AppEmptyView(
      title: 'Nothing here',
      message: 'You have no saved bookmarks yet.',
    );

    testWidgets('light', (tester) async {
      await _pumpGolden(tester, empty, brightness: Brightness.light);
      await _expectGolden(tester, 'app_empty_view_light');
    });

    testWidgets('dark', (tester) async {
      await _pumpGolden(tester, empty, brightness: Brightness.dark);
      await _expectGolden(tester, 'app_empty_view_dark');
    });
  });

  group('AppErrorView', () {
    const error = AppErrorView(
      title: 'Something went wrong',
      message: 'We could not load your data. Please try again.',
      onRetry: _noop,
      retryLabel: 'Retry',
    );

    testWidgets('light', (tester) async {
      await _pumpGolden(tester, error, brightness: Brightness.light);
      await _expectGolden(tester, 'app_error_view_light');
    });

    testWidgets('dark', (tester) async {
      await _pumpGolden(tester, error, brightness: Brightness.dark);
      await _expectGolden(tester, 'app_error_view_dark');
    });
  });

  group('AppLoading', () {
    const loading = AppLoading(label: 'Loading…');

    testWidgets('light', (tester) async {
      await _pumpGolden(tester, loading, brightness: Brightness.light);
      await _expectGolden(tester, 'app_loading_light');
    });

    testWidgets('dark', (tester) async {
      await _pumpGolden(tester, loading, brightness: Brightness.dark);
      await _expectGolden(tester, 'app_loading_dark');
    });
  });
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
