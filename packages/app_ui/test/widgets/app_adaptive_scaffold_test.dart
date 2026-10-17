import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  const destinations = [
    AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
    AppDestination(icon: FontAwesomeIcons.magnifyingGlass, label: 'Search'),
    AppDestination(icon: FontAwesomeIcons.circle, label: 'Settings'),
  ];

  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    ValueChanged<int>? onDestinationSelected,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppAdaptiveScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: onDestinationSelected ?? (_) {},
          body: const Center(child: Text('body')),
        ),
      ),
    );
  }

  group('AppAdaptiveScaffold', () {
    for (final testCase in <(double, bool, bool)>[
      (599, false, false),
      (600, true, false),
      (839, true, false),
      (840, true, true),
    ]) {
      testWidgets(
        'width ${testCase.$1.toInt()} selects the documented navigation mode',
        (tester) async {
          await pumpAt(tester, testCase.$1);

          expect(
            find.byType(NavigationRail),
            testCase.$2 ? findsOneWidget : findsNothing,
          );
          if (testCase.$2) {
            final rail = tester.widget<NavigationRail>(
              find.byType(NavigationRail),
            );
            expect(rail.extended, testCase.$3);
          }
        },
      );
    }

    testWidgets('compact width uses a floating bottom bar, not a rail', (
      tester,
    ) async {
      int? selected;
      await pumpAt(tester, 500, onDestinationSelected: (i) => selected = i);

      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).extendBody, isTrue);
      // The reference treatment keeps short labels visible under each icon.
      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('Home'), findsOneWidget);

      // Tapping another destination reports its index.
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.circle.codePoint,
        ),
      );
      expect(selected, 2);
    });

    testWidgets('compact bottom navigation works without a center action', (
      tester,
    ) async {
      await pumpAt(tester, 390);

      expect(find.byTooltip('Home'), findsOneWidget);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FaIcon &&
              widget.icon?.codePoint == FontAwesomeIcons.plus.codePoint,
        ),
        findsNothing,
      );
    });

    testWidgets('raised center action is independent from destinations', (
      tester,
    ) async {
      var centerPressed = false;
      int? selected;
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (index) => selected = index,
            centerAction: AppCenterAction(
              icon: FontAwesomeIcons.plus,
              label: 'Add item',
              onPressed: () => centerPressed = true,
            ),
            body: const Text('body'),
          ),
        ),
      );

      final center = find.byKey(
        const ValueKey('bottomNavigationCenterAction'),
      );
      expect(center, findsOneWidget);
      expect(tester.getSize(center), const Size.square(56));

      final decoration = tester.widget<DecoratedBox>(center).decoration;
      expect(
        (decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(AppRadius.lg),
      );

      final firstDestination = tester.getRect(
        find.byKey(const ValueKey('bottomNavigationDestination-0')),
      );
      expect(tester.getRect(center).top, lessThan(firstDestination.top));

      await tester.tap(center);
      expect(centerPressed, isTrue);
      expect(selected, isNull);
    });

    testWidgets('selected destination has the compact highlighted treatment', (
      tester,
    ) async {
      await pumpAt(tester, 390);

      final selectedSurface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('bottomNavigationDestinationSurface-0')),
      );
      final unselectedSurface = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('bottomNavigationDestinationSurface-1')),
      );
      final selectedDecoration = selectedSurface.decoration! as BoxDecoration;
      final unselectedDecoration =
          unselectedSurface.decoration! as BoxDecoration;

      expect(selectedDecoration.color, isNot(Colors.transparent));
      expect(unselectedDecoration.color, Colors.transparent);
    });

    testWidgets('backdrop blur is opt-in', (tester) async {
      await pumpAt(tester, 390);
      expect(find.byType(BackdropFilter), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: AppAdaptiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            enableBackdropBlur: true,
            body: const Text('body'),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('keyboard does not move or hide compact navigation', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Widget appWithKeyboard({required bool visible}) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(bottom: visible ? 0 : 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
            viewInsets: EdgeInsets.only(bottom: visible ? 300 : 0),
          ),
          child: child!,
        ),
        home: AppAdaptiveScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: const TextField(autofocus: true),
        ),
      );

      await tester.pumpWidget(appWithKeyboard(visible: false));
      final destination = find.byKey(
        const ValueKey('bottomNavigationDestination-0'),
      );
      final closedKeyboardRect = tester.getRect(destination);

      await tester.pumpWidget(appWithKeyboard(visible: true));
      await tester.pump();

      expect(destination, findsOneWidget);
      expect(tester.getRect(destination), closedKeyboardRect);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard can explicitly hide compact navigation', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
            child: child!,
          ),
          home: AppAdaptiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            hideBottomNavigationOnKeyboard: true,
            body: const TextField(autofocus: true),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('Home'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('medium width uses a collapsed NavigationRail', (tester) async {
      await pumpAt(tester, 700);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('expanded width uses an extended NavigationRail', (
      tester,
    ) async {
      await pumpAt(tester, 1000);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    Widget buildTestApp({
      required Widget child,
      Brightness brightness = Brightness.light,
      MediaQueryData? mediaQuery,
    }) {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF095D9E),
        brightness: brightness,
      );
      final theme = ThemeData(
        colorScheme: colorScheme,
        extensions: [SemanticColors.from(colorScheme)],
      );
      Widget app = MaterialApp(
        theme: theme,
        home: child,
      );
      if (mediaQuery != null) {
        app = MediaQuery(data: mediaQuery, child: app);
      }
      return app;
    }

    testWidgets(
      'renders correctly in light and dark mode with design tokens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            buildTestApp(
              brightness: brightness,
              child: AppAdaptiveScaffold(
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                body: const Text('content'),
              ),
            ),
          );

          expect(find.text('Home'), findsOneWidget);
          expect(find.byType(Scaffold), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'enableBackdropBlur clips filter with ClipRect when true and omits when false',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          buildTestApp(
            child: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              enableBackdropBlur: false,
              body: const Text('content'),
            ),
          ),
        );
        expect(find.byType(BackdropFilter), findsNothing);

        await tester.pumpWidget(
          buildTestApp(
            child: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              enableBackdropBlur: true,
              body: const Text('content'),
            ),
          ),
        );
        final filterFinder = find.byType(BackdropFilter);
        expect(filterFinder, findsOneWidget);
        expect(
          find.ancestor(of: filterFinder, matching: find.byType(ClipRect)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'center action has no unintended separate background rectangle',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          buildTestApp(
            child: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () {},
              ),
              body: const Text('content'),
            ),
          ),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.extendBody, isTrue);

        final centerFinder = find.byKey(
          const ValueKey('bottomNavigationCenterAction'),
        );
        expect(centerFinder, findsOneWidget);
        final centerRect = tester.getRect(centerFinder);
        final destinationRect = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-0')),
        );
        expect(centerRect.top, lessThan(destinationRect.top));
      },
    );

    testWidgets(
      'last scrollable item can be scrolled into view and tapped',
      (tester) async {
        tester.view.physicalSize = const Size(390, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var item24Tapped = false;

        await tester.pumpWidget(
          buildTestApp(
            child: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () {},
              ),
              body: Builder(
                builder: (context) {
                  final bottomInset = AppAdaptiveScaffold.bottomBarInsetOf(
                    context,
                  );
                  return ListView.builder(
                    itemCount: 25,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    itemBuilder: (context, index) {
                      return ListTile(
                        key: ValueKey('item-$index'),
                        title: Text('Item $index'),
                        onTap: () {
                          if (index == 24) item24Tapped = true;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('item-24')),
          500,
        );
        await tester.pumpAndSettle();

        final item24Finder = find.byKey(const ValueKey('item-24'));
        expect(item24Finder, findsOneWidget);

        final itemRect = tester.getRect(item24Finder);
        final centerActionRect = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationCenterAction')),
        );

        // The item is scrolled above the center action and bottom bar
        expect(itemRect.bottom, lessThanOrEqualTo(centerActionRect.top + 1));

        // Tapping the item fires its callback without being blocked by the bottom bar
        await tester.tap(item24Finder);
        await tester.pumpAndSettle();
        expect(item24Tapped, isTrue);
      },
    );

    testWidgets(
      'no RenderFlex overflow at 360px width with 4 and 5 destinations',
      (tester) async {
        const fiveDestinations = [
          AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
          AppDestination(
            icon: FontAwesomeIcons.magnifyingGlass,
            label: 'Search',
          ),
          AppDestination(icon: FontAwesomeIcons.bookmark, label: 'Saved'),
          AppDestination(icon: FontAwesomeIcons.bell, label: 'Alerts'),
          AppDestination(icon: FontAwesomeIcons.user, label: 'Profile'),
        ];

        for (final textScale in [1.0, 1.5, 2.0]) {
          for (final dests in [destinations, fiveDestinations]) {
            tester.view.physicalSize = const Size(360, 640);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF095D9E),
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child!,
                ),
                home: AppAdaptiveScaffold(
                  destinations: dests,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: const Center(child: Text('Content')),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'navigation selection and center action callbacks fire correctly',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var selectedIndex = 0;
        var centerActionFired = false;

        await tester.pumpWidget(
          buildTestApp(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => selectedIndex = index),
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () => centerActionFired = true,
                  ),
                  body: Text('Page $selectedIndex'),
                );
              },
            ),
          ),
        );

        // Tap destination 1
        await tester.tap(
          find.byKey(const ValueKey('bottomNavigationDestination-1')),
        );
        await tester.pumpAndSettle();
        expect(selectedIndex, 1);
        expect(find.text('Page 1'), findsOneWidget);

        // Tap destination 2
        await tester.tap(
          find.byKey(const ValueKey('bottomNavigationDestination-2')),
        );
        await tester.pumpAndSettle();
        expect(selectedIndex, 2);
        expect(find.text('Page 2'), findsOneWidget);

        // Tap center action: should fire onPressed without changing selected index
        await tester.tap(
          find.byKey(const ValueKey('bottomNavigationCenterAction')),
        );
        await tester.pumpAndSettle();
        expect(centerActionFired, isTrue);
        expect(selectedIndex, 2);
      },
    );

    testWidgets(
      'preserves SafeArea behavior when bottom system padding is present',
      (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 34),
                viewPadding: const EdgeInsets.only(bottom: 34),
              ),
              child: child!,
            ),
            home: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () {},
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );

        final destRect = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-0')),
        );
        // Items must sit safely above the 34px system area
        expect(destRect.bottom, lessThanOrEqualTo(800 - 34));

        final centerRect = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationCenterAction')),
        );
        expect(centerRect.bottom, lessThanOrEqualTo(800 - 34));

        // The bottom bar background extends down to 800 (the bottom of the screen)
        final inset = AppAdaptiveScaffold.bottomBarInsetOf(
          tester.element(find.byType(SizedBox).first),
        );
        expect(inset, greaterThan(34));
      },
    );

    group('Phase 02 Hardening — Responsive, RTL, Accessibility & Distribution', () {
      final allDestinations = [
        const AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
        const AppDestination(
          icon: FontAwesomeIcons.magnifyingGlass,
          label: 'Search',
        ),
        const AppDestination(icon: FontAwesomeIcons.bookmark, label: 'Saved'),
        const AppDestination(
          icon: FontAwesomeIcons.bell,
          label: 'Alerts',
          hasBadge: true,
          badgeCount: 5,
        ),
        const AppDestination(icon: FontAwesomeIcons.user, label: 'Profile'),
      ];

      testWidgets(
        'matrix test: widths (320, 360, 390, 600), RTL/LTR, counts (2,3,4,5), center +/- , textScales',
        (tester) async {
          for (final width in [320.0, 360.0, 390.0, 600.0]) {
            for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
              for (final count in [2, 3, 4, 5]) {
                for (final hasCenter in [true, false]) {
                  for (final scale in [1.0, 1.5, 2.0]) {
                    tester.view.physicalSize = Size(width, 700);
                    tester.view.devicePixelRatio = 1.0;
                    addTearDown(tester.view.reset);

                    final currentDests = allDestinations.sublist(0, count);
                    await tester.pumpWidget(
                      MaterialApp(
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                          ),
                          child: Directionality(
                            textDirection: dir,
                            child: child!,
                          ),
                        ),
                        home: AppAdaptiveScaffold(
                          destinations: currentDests,
                          selectedIndex: 0,
                          onDestinationSelected: (_) {},
                          centerAction: hasCenter
                              ? AppCenterAction(
                                  icon: FontAwesomeIcons.plus,
                                  label: 'Add',
                                  onPressed: () {},
                                )
                              : null,
                          body: const SizedBox.expand(),
                        ),
                      ),
                    );
                    await tester.pump();
                    expect(tester.takeException(), isNull);

                    if (width < AppBreakpoints.medium) {
                      if (hasCenter) {
                        final centerActionFinder = find.byKey(
                          const ValueKey('bottomNavigationCenterAction'),
                        );
                        expect(centerActionFinder, findsOneWidget);
                        final centerRect = tester.getRect(centerActionFinder);
                        expect(
                          (centerRect.center.dx - (width / 2)).abs(),
                          lessThanOrEqualTo(1.0),
                        );

                        for (var i = 0; i < count; i++) {
                          final destRect = tester.getRect(
                            find.byKey(
                              ValueKey('bottomNavigationDestination-$i'),
                            ),
                          );
                          final overlapsHorizontally =
                              destRect.left < centerRect.right - 2 &&
                              destRect.right > centerRect.left + 2;
                          expect(
                            overlapsHorizontally,
                            isFalse,
                            reason:
                                'Destination $i overlaps with center action at width $width, count $count, dir $dir',
                          );
                        }
                      }
                    } else {
                      expect(find.byType(NavigationRail), findsOneWidget);
                    }
                  }
                }
              }
            }
          }
        },
      );

      testWidgets('RTL vs LTR logical direction and selection', (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final testDests = allDestinations.sublist(0, 4);

        // LTR: index 0 is left, index 1 is next, index 2 is next, index 3 is right
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => Directionality(
              textDirection: TextDirection.ltr,
              child: child!,
            ),
            home: AppAdaptiveScaffold(
              destinations: testDests,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () {},
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );
        final ltrRect0 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-0')),
        );
        final ltrRect1 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-1')),
        );
        final ltrRect2 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-2')),
        );
        final ltrRect3 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-3')),
        );
        expect(ltrRect0.left, lessThan(ltrRect1.left));
        expect(ltrRect1.left, lessThan(ltrRect2.left));
        expect(ltrRect2.left, lessThan(ltrRect3.left));

        // RTL: index 0 is right, index 1 is next to the left, etc.
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
            home: AppAdaptiveScaffold(
              destinations: testDests,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () {},
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );
        final rtlRect0 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-0')),
        );
        final rtlRect1 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-1')),
        );
        final rtlRect2 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-2')),
        );
        final rtlRect3 = tester.getRect(
          find.byKey(const ValueKey('bottomNavigationDestination-3')),
        );
        expect(rtlRect0.right, greaterThan(rtlRect1.right));
        expect(rtlRect1.right, greaterThan(rtlRect2.right));
        expect(rtlRect2.right, greaterThan(rtlRect3.right));
      });

      testWidgets(
        'accessibility semantics: clear label, badge count, selected state, no duplicates',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final handle = tester.ensureSemantics();
          try {
            final testDests = [
              const AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
              const AppDestination(
                icon: FontAwesomeIcons.bell,
                label: 'Alerts',
                hasBadge: true,
                badgeCount: 5,
              ),
            ];

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: testDests,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    label: 'Create new',
                    onPressed: () {},
                  ),
                  body: const SizedBox.expand(),
                ),
              ),
            );

            // Destination 0: selected, button, label 'Home'
            expect(
              tester.getSemantics(
                find.byKey(
                  const ValueKey('bottomNavigationDestinationSemantics-0'),
                ),
              ),
              matchesSemantics(
                label: 'Home',
                isButton: true,
                isSelected: true,
                hasSelectedState: true,
              ),
            );

            // Destination 1: unselected, button, label includes badge count 'Alerts, 5'
            expect(
              tester.getSemantics(
                find.byKey(
                  const ValueKey('bottomNavigationDestinationSemantics-1'),
                ),
              ),
              matchesSemantics(
                label: 'Alerts, 5',
                isButton: true,
                isSelected: false,
                hasSelectedState: true,
              ),
            );

            // Center action semantics
            expect(
              tester.getSemantics(
                find.byKey(
                  const ValueKey('bottomNavigationCenterActionSemantics'),
                ),
              ),
              matchesSemantics(
                label: 'Create new',
                isButton: true,
              ),
            );
          } finally {
            handle.dispose();
          }
        },
      );

      testWidgets(
        'no double bottom padding when AppScaffold is hosted in AppAdaptiveScaffold',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(bottom: 34),
                  viewPadding: const EdgeInsets.only(bottom: 34),
                ),
                child: child!,
              ),
              home: AppAdaptiveScaffold(
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                body: const AppScaffold(
                  safeArea: true,
                  body: SizedBox(
                    key: ValueKey('innerBody'),
                    child: Text('Inner Content'),
                  ),
                ),
              ),
            ),
          );

          // Find the SafeArea inside AppScaffold that wraps content
          final innerSafeArea = tester.widget<SafeArea>(
            find.descendant(
              of: find.byType(AppScaffold),
              matching: find.byType(SafeArea),
            ),
          );
          // It must NOT apply bottom safe area because the outer AppAdaptiveScaffold provides the bottom chrome
          expect(innerSafeArea.bottom, isFalse);
        },
      );
    });

    group(
      'AppAdaptiveScaffold Phase 03 — Runtime Performance, Scroll Behavior & Layout Certification',
      () {
        testWidgets(
          'performance: zero rebuilds of AppAdaptiveScaffold during scrolling',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            var scaffoldBuildCount = 0;

            await tester.pumpWidget(
              MaterialApp(
                home: Builder(
                  builder: (context) {
                    scaffoldBuildCount++;
                    return AppAdaptiveScaffold(
                      destinations: destinations,
                      selectedIndex: 0,
                      onDestinationSelected: (_) {},
                      centerAction: AppCenterAction(
                        icon: FontAwesomeIcons.plus,
                        onPressed: () {},
                      ),
                      body: Builder(
                        builder: (context) {
                          final inset = AppAdaptiveScaffold.bottomBarInsetOf(
                            context,
                          );
                          return ListView.builder(
                            key: const ValueKey('scrollList'),
                            itemCount: 100,
                            padding: EdgeInsets.only(bottom: inset),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                height: 60,
                                child: Text('Item $index'),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            );

            await tester.pumpAndSettle();
            final initialScaffoldBuilds = scaffoldBuildCount;

            await tester.drag(
              find.byKey(const ValueKey('scrollList')),
              const Offset(0, -300),
            );
            await tester.pump();

            await tester.drag(
              find.byKey(const ValueKey('scrollList')),
              const Offset(0, -300),
            );
            await tester.pump();

            expect(scaffoldBuildCount, equals(initialScaffoldBuilds));
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          'scroll behavior: ListView can scroll to last item and tap it without occlusion',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            var lastItemTapped = false;

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: Builder(
                    builder: (context) {
                      final bottomInset = AppAdaptiveScaffold.bottomBarInsetOf(
                        context,
                      );
                      return ListView.builder(
                        itemCount: 40,
                        padding: EdgeInsets.only(bottom: bottomInset),
                        itemBuilder: (context, index) {
                          return ListTile(
                            key: ValueKey('list-item-$index'),
                            title: Text('List Item $index'),
                            onTap: () {
                              if (index == 39) lastItemTapped = true;
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('list-item-39')),
              500,
            );
            await tester.pumpAndSettle();

            final lastItemFinder = find.byKey(const ValueKey('list-item-39'));
            expect(lastItemFinder, findsOneWidget);

            final itemRect = tester.getRect(lastItemFinder);
            final centerActionRect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
            );

            expect(
              itemRect.bottom,
              lessThanOrEqualTo(centerActionRect.top + 1),
            );

            await tester.tap(lastItemFinder);
            await tester.pumpAndSettle();
            expect(lastItemTapped, isTrue);
          },
        );

        testWidgets(
          'scroll behavior: CustomScrollView with Slivers clears bottom bar and last item is tappable',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            var lastSliverTapped = false;

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: Builder(
                    builder: (context) {
                      final bottomInset = AppAdaptiveScaffold.bottomBarInsetOf(
                        context,
                      );
                      return CustomScrollView(
                        slivers: [
                          const SliverAppBar(
                            title: Text('Sliver Title'),
                            floating: true,
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ListTile(
                                key: ValueKey('sliver-item-$index'),
                                title: Text('Sliver Item $index'),
                                onTap: () {
                                  if (index == 29) lastSliverTapped = true;
                                },
                              ),
                              childCount: 30,
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.only(bottom: bottomInset),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('sliver-item-29')),
              500,
            );
            await tester.pumpAndSettle();

            final lastSliverFinder = find.byKey(
              const ValueKey('sliver-item-29'),
            );
            expect(lastSliverFinder, findsOneWidget);

            final itemRect = tester.getRect(lastSliverFinder);
            final centerRect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
            );
            expect(itemRect.bottom, lessThanOrEqualTo(centerRect.top + 1));

            await tester.tap(lastSliverFinder);
            await tester.pumpAndSettle();
            expect(lastSliverTapped, isTrue);
          },
        );

        testWidgets(
          'scroll behavior: SingleChildScrollView clears bottom bar and bottom-most button is tappable',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            var buttonTapped = false;

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: Builder(
                    builder: (context) {
                      final bottomInset = AppAdaptiveScaffold.bottomBarInsetOf(
                        context,
                      );
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < 20; i++)
                              Container(
                                height: 60,
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.blue.withValues(alpha: 0.1),
                                child: Center(child: Text('Card $i')),
                              ),
                            ElevatedButton(
                              key: const ValueKey('bottomSubmitButton'),
                              onPressed: () => buttonTapped = true,
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('bottomSubmitButton')),
              500,
            );
            await tester.pumpAndSettle();

            final buttonFinder = find.byKey(
              const ValueKey('bottomSubmitButton'),
            );
            expect(buttonFinder, findsOneWidget);

            final buttonRect = tester.getRect(buttonFinder);
            final centerRect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
            );
            expect(buttonRect.bottom, lessThanOrEqualTo(centerRect.top + 1));

            await tester.tap(buttonFinder);
            await tester.pumpAndSettle();
            expect(buttonTapped, isTrue);
          },
        );

        testWidgets(
          'scroll stability: bottom bar and center action remain perfectly rigid and fixed during scrolling',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: ListView.builder(
                    key: const ValueKey('fixedCheckList'),
                    itemCount: 60,
                    itemBuilder: (context, index) => SizedBox(
                      height: 50,
                      child: Text('Item $index'),
                    ),
                  ),
                ),
              ),
            );

            final centerActionFinder = find.byKey(
              const ValueKey('bottomNavigationCenterAction'),
            );
            final destination0Finder = find.byKey(
              const ValueKey('bottomNavigationDestination-0'),
            );

            final initialCenterRect = tester.getRect(centerActionFinder);
            final initialDest0Rect = tester.getRect(destination0Finder);

            for (final dy in [-150.0, -300.0, -450.0, 200.0]) {
              await tester.drag(
                find.byKey(const ValueKey('fixedCheckList')),
                Offset(0, dy),
              );
              await tester.pump();

              expect(
                tester.getRect(centerActionFinder),
                equals(initialCenterRect),
                reason: 'Center action moved during scrolling!',
              );
              expect(
                tester.getRect(destination0Finder),
                equals(initialDest0Rect),
                reason: 'Destination 0 moved during scrolling!',
              );
            }
          },
        );

        testWidgets(
          'keyboard behavior: hideBottomNavigationOnKeyboard true zeroes insets; false preserves bar geometry',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            Widget appWithConfig({
              required bool hideOnKeyboard,
              required bool keyboardOpen,
            }) {
              return MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: const EdgeInsets.only(bottom: 34),
                    viewPadding: const EdgeInsets.only(bottom: 34),
                    viewInsets: EdgeInsets.only(bottom: keyboardOpen ? 320 : 0),
                  ),
                  child: child!,
                ),
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  hideBottomNavigationOnKeyboard: hideOnKeyboard,
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: Builder(
                    builder: (context) {
                      final inset = AppAdaptiveScaffold.bottomBarInsetOf(
                        context,
                      );
                      return Center(child: Text('Inset: ${inset.toInt()}'));
                    },
                  ),
                ),
              );
            }

            // Case 1: hideBottomNavigationOnKeyboard = true
            await tester.pumpWidget(
              appWithConfig(hideOnKeyboard: true, keyboardOpen: false),
            );
            expect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
              findsOneWidget,
            );
            expect(
              find.text('Inset: 120'),
              findsOneWidget,
            ); // 64 bar + 22 lift + 34 padding

            await tester.pumpWidget(
              appWithConfig(hideOnKeyboard: true, keyboardOpen: true),
            );
            await tester.pump();
            expect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
              findsNothing,
            );
            expect(find.text('Inset: 0'), findsOneWidget);

            // Case 2: hideBottomNavigationOnKeyboard = false (default)
            await tester.pumpWidget(
              appWithConfig(hideOnKeyboard: false, keyboardOpen: false),
            );
            expect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
              findsOneWidget,
            );
            final normalRect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
            );

            await tester.pumpWidget(
              appWithConfig(hideOnKeyboard: false, keyboardOpen: true),
            );
            await tester.pump();
            expect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
              findsOneWidget,
            );
            expect(
              tester.getRect(
                find.byKey(const ValueKey('bottomNavigationCenterAction')),
              ),
              equals(normalRect),
            );
          },
        );

        testWidgets(
          'keyboard behavior: TextField retains focus and accepts input across keyboard transitions',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            final focusNode = FocusNode();
            final controller = TextEditingController();
            addTearDown(() {
              focusNode.dispose();
              controller.dispose();
            });

            Widget buildKeyboardTestApp({required double keyboardInset}) {
              return MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: EdgeInsets.only(bottom: keyboardInset),
                  ),
                  child: child!,
                ),
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  body: AppScaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        key: const ValueKey('inputField'),
                        focusNode: focusNode,
                        controller: controller,
                      ),
                    ),
                  ),
                ),
              );
            }

            await tester.pumpWidget(buildKeyboardTestApp(keyboardInset: 0));
            await tester.tap(find.byKey(const ValueKey('inputField')));
            await tester.pump();

            expect(focusNode.hasFocus, isTrue);

            await tester.pumpWidget(buildKeyboardTestApp(keyboardInset: 300));
            await tester.pump();

            expect(focusNode.hasFocus, isTrue);

            await tester.enterText(
              find.byKey(const ValueKey('inputField')),
              'Tested Text',
            );
            await tester.pump();
            expect(controller.text, equals('Tested Text'));

            await tester.pumpWidget(buildKeyboardTestApp(keyboardInset: 0));
            await tester.pump();

            expect(focusNode.hasFocus, isTrue);
            expect(controller.text, equals('Tested Text'));
          },
        );

        testWidgets(
          'RTL stability: RTL scrolling maintains centered center action and correct destination ordering',
          (tester) async {
            const width = 390.0;
            tester.view.physicalSize = const Size(width, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            int? selected;

            await tester.pumpWidget(
              MaterialApp(
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: AppAdaptiveScaffold(
                    destinations: const [
                      AppDestination(
                        icon: FontAwesomeIcons.house,
                        label: 'الرئيسية',
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.magnifyingGlass,
                        label: 'البحث',
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.bell,
                        label: 'الإشعارات',
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.user,
                        label: 'الحساب',
                      ),
                    ],
                    selectedIndex: 0,
                    onDestinationSelected: (i) => selected = i,
                    centerAction: AppCenterAction(
                      icon: FontAwesomeIcons.plus,
                      label: 'إضافة',
                      onPressed: () {},
                    ),
                    body: ListView.builder(
                      key: const ValueKey('rtlList'),
                      itemCount: 50,
                      itemBuilder: (context, i) =>
                          SizedBox(height: 50, child: Text('عنصر $i')),
                    ),
                  ),
                ),
              ),
            );

            final centerAction = find.byKey(
              const ValueKey('bottomNavigationCenterAction'),
            );
            final centerRect = tester.getRect(centerAction);
            expect(
              (centerRect.left + centerRect.right) / 2,
              closeTo(width / 2, 1.0),
            );

            final dest0Rect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationDestination-0')),
            );
            final dest3Rect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationDestination-3')),
            );
            expect(dest0Rect.left, greaterThan(dest3Rect.left));

            await tester.drag(
              find.byKey(const ValueKey('rtlList')),
              const Offset(0, -300),
            );
            await tester.pump();

            final centerRectAfter = tester.getRect(centerAction);
            expect(
              (centerRectAfter.left + centerRectAfter.right) / 2,
              closeTo(width / 2, 1.0),
            );
            expect(centerRectAfter, equals(centerRect));

            await tester.tap(
              find.byKey(const ValueKey('bottomNavigationDestination-3')),
            );
            expect(selected, 3);
          },
        );

        testWidgets(
          'text scale 2.0x: scrolling to last item clears scaled bottom bar without overflow at 320px',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            var lastTapped = false;

            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: child!,
                ),
                home: AppAdaptiveScaffold(
                  destinations: const [
                    AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
                    AppDestination(
                      icon: FontAwesomeIcons.magnifyingGlass,
                      label: 'Search',
                    ),
                    AppDestination(
                      icon: FontAwesomeIcons.bookmark,
                      label: 'Saved',
                    ),
                    AppDestination(icon: FontAwesomeIcons.user, label: 'User'),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: Builder(
                    builder: (context) {
                      final inset = AppAdaptiveScaffold.bottomBarInsetOf(
                        context,
                      );
                      return ListView.builder(
                        itemCount: 25,
                        padding: EdgeInsets.only(bottom: inset),
                        itemBuilder: (context, i) => ListTile(
                          key: ValueKey('scale2-item-$i'),
                          title: Text('Scale 2x Item $i'),
                          onTap: () {
                            if (i == 24) lastTapped = true;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            );

            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('scale2-item-24')),
              500,
            );
            await tester.pumpAndSettle();

            final lastItemFinder = find.byKey(const ValueKey('scale2-item-24'));
            expect(lastItemFinder, findsOneWidget);

            final itemRect = tester.getRect(lastItemFinder);
            final centerRect = tester.getRect(
              find.byKey(const ValueKey('bottomNavigationCenterAction')),
            );

            expect(itemRect.bottom, lessThanOrEqualTo(centerRect.top + 1));

            await tester.tap(lastItemFinder);
            await tester.pumpAndSettle();
            expect(lastTapped, isTrue);
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          'background certification: scrolling content flows behind translucent bar and center lift without white rectangle artifacts',
          (tester) async {
            tester.view.physicalSize = const Size(390, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              MaterialApp(
                home: AppAdaptiveScaffold(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  enableBackdropBlur: true,
                  centerAction: AppCenterAction(
                    icon: FontAwesomeIcons.plus,
                    onPressed: () {},
                  ),
                  body: ListView.builder(
                    key: const ValueKey('flowList'),
                    itemCount: 30,
                    itemBuilder: (context, i) => Container(
                      height: 80,
                      color: i.isEven ? Colors.deepPurple : Colors.amber,
                      child: Center(
                        child: Text(
                          'Colorful Content $i',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
            expect(scaffold.extendBody, isTrue);

            final centerAction = find.byKey(
              const ValueKey('bottomNavigationCenterAction'),
            );
            expect(centerAction, findsOneWidget);

            await tester.drag(
              find.byKey(const ValueKey('flowList')),
              const Offset(0, -250),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
          },
        );
      },
    );

    group('AppAdaptiveScaffold Phase 04 — Visual Design & Motion Refinement', () {
      testWidgets('light and dark mode theme token and contrast integration', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final isDark in [false, true]) {
          tester.platformDispatcher.platformBrightnessTestValue = isDark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          final colorScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF095D9E),
            brightness: isDark ? Brightness.dark : Brightness.light,
          );
          final theme = ThemeData(
            colorScheme: colorScheme,
            extensions: [SemanticColors.from(colorScheme)],
          );
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(isDark),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: theme,
              darkTheme: theme,
              home: AppAdaptiveScaffold(
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                centerAction: AppCenterAction(
                  icon: FontAwesomeIcons.plus,
                  onPressed: () {},
                ),
                body: const SizedBox(),
              ),
            ),
          );

          // Verify active destination pill color and styling
          final surfaceContainer = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('bottomNavigationDestinationSurface-0')),
          );
          final decoration = surfaceContainer.decoration as BoxDecoration?;
          expect(decoration, isNotNull);
          expect(decoration!.color, isNotNull);
          expect(
            decoration.borderRadius,
            BorderRadius.circular(AppRadius.lg),
          );

          // Verify center action button background and colors
          final centerMaterial = tester.widget<Material>(
            find.descendant(
              of: find.byKey(const ValueKey('bottomNavigationCenterAction')),
              matching: find.byType(Material),
            ),
          );
          expect(centerMaterial.color, colorScheme.primary);
          expect(
            centerMaterial.borderRadius,
            BorderRadius.circular(AppRadius.lg),
          );
        }
      });

      testWidgets('scale effect when pressing center action button', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var pressedCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: AppAdaptiveScaffold(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              centerAction: AppCenterAction(
                icon: FontAwesomeIcons.plus,
                onPressed: () => pressedCount++,
              ),
              body: const SizedBox(),
            ),
          ),
        );

        final actionFinder = find.byKey(
          const ValueKey('bottomNavigationCenterAction'),
        );
        expect(actionFinder, findsOneWidget);

        // Initial scale is 1.0
        final initialScale = tester.widget<AnimatedScale>(
          find.descendant(
            of: actionFinder,
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(initialScale.scale, 1.0);

        // Press down
        final gesture = await tester.startGesture(
          tester.getCenter(actionFinder),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        final pressedScale = tester.widget<AnimatedScale>(
          find.descendant(
            of: actionFinder,
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(pressedScale.scale, 0.93);

        // Release
        await gesture.up();
        await tester.pumpAndSettle();

        final releasedScale = tester.widget<AnimatedScale>(
          find.descendant(
            of: actionFinder,
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(releasedScale.scale, 1.0);
        expect(pressedCount, 1);
      });

      testWidgets('badge display does not overlap label or cause overflow', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final destinationsWithBadge = [
          const AppDestination(
            icon: FontAwesomeIcons.house,
            label: 'Home',
            badgeCount: 5,
          ),
          const AppDestination(
            icon: FontAwesomeIcons.magnifyingGlass,
            label: 'Search',
          ),
          const AppDestination(
            icon: FontAwesomeIcons.circle,
            label: 'Settings',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: AppAdaptiveScaffold(
              destinations: destinationsWithBadge,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              body: const SizedBox(),
            ),
          ),
        );

        final badgeFinder = find.descendant(
          of: find.byKey(const ValueKey('bottomNavigationDestination-0')),
          matching: find.byType(Badge),
        );
        expect(badgeFinder, findsOneWidget);

        final badgeLabelFinder = find.descendant(
          of: badgeFinder,
          matching: find.text('5'),
        );
        expect(badgeLabelFinder, findsOneWidget);

        final labelFinder = find.text('Home');
        final badgeRect = tester.getRect(badgeLabelFinder);
        final labelRect = tester.getRect(labelFinder);

        // Badge must be positioned above the text label without overlap
        expect(badgeRect.bottom, lessThan(labelRect.top));
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'motion respects MediaQuery disableAnimations (reduced motion)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: AppAdaptiveScaffold(
                destinations: destinations,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                centerAction: AppCenterAction(
                  icon: FontAwesomeIcons.plus,
                  onPressed: () {},
                ),
                body: const SizedBox(),
              ),
            ),
          );

          final actionFinder = find.byKey(
            const ValueKey('bottomNavigationCenterAction'),
          );
          final animatedScale = tester.widget<AnimatedScale>(
            find.descendant(
              of: actionFinder,
              matching: find.byType(AnimatedScale),
            ),
          );
          expect(animatedScale.duration, Duration.zero);

          final destinationContainer = tester.widget<AnimatedContainer>(
            find.byKey(const ValueKey('bottomNavigationDestinationSurface-0')),
          );
          expect(destinationContainer.duration, Duration.zero);
        },
      );

      testWidgets(
        'visual transition between destinations updates active state cleanly',
        (tester) async {
          tester.view.physicalSize = const Size(390, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          var selectedIndex = 0;
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return MaterialApp(
                  home: AppAdaptiveScaffold(
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (idx) {
                      setState(() => selectedIndex = idx);
                    },
                    body: const SizedBox(),
                  ),
                );
              },
            ),
          );

          // Initially index 0 selected
          var dest0TextStyle = tester
              .widget<AnimatedDefaultTextStyle>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('bottomNavigationDestinationSurface-0'),
                  ),
                  matching: find.byType(AnimatedDefaultTextStyle),
                ),
              )
              .style;
          expect(dest0TextStyle.fontWeight, FontWeight.w700);

          var dest1TextStyle = tester
              .widget<AnimatedDefaultTextStyle>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('bottomNavigationDestinationSurface-1'),
                  ),
                  matching: find.byType(AnimatedDefaultTextStyle),
                ),
              )
              .style;
          expect(dest1TextStyle.fontWeight, FontWeight.w500);

          // Tap on index 1
          await tester.tap(
            find.byKey(const ValueKey('bottomNavigationDestination-1')),
          );
          await tester.pumpAndSettle();

          expect(selectedIndex, 1);
          dest0TextStyle = tester
              .widget<AnimatedDefaultTextStyle>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('bottomNavigationDestinationSurface-0'),
                  ),
                  matching: find.byType(AnimatedDefaultTextStyle),
                ),
              )
              .style;
          expect(dest0TextStyle.fontWeight, FontWeight.w500);

          dest1TextStyle = tester
              .widget<AnimatedDefaultTextStyle>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('bottomNavigationDestinationSurface-1'),
                  ),
                  matching: find.byType(AnimatedDefaultTextStyle),
                ),
              )
              .style;
          expect(dest1TextStyle.fontWeight, FontWeight.w700);
        },
      );

      testWidgets(
        'visual layout stability across widths and destination counts (2, 3, 4, 5)',
        (tester) async {
          const testCounts = [2, 3, 4, 5];
          const testWidths = [320.0, 360.0, 390.0, 599.0];

          for (final count in testCounts) {
            final countDestinations = List.generate(
              count,
              (i) => AppDestination(
                icon: destinations[i % destinations.length].icon,
                label: 'Tab $i',
              ),
            );

            for (final width in testWidths) {
              tester.view.physicalSize = Size(width, 800);
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                MaterialApp(
                  home: AppAdaptiveScaffold(
                    destinations: countDestinations,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    centerAction: AppCenterAction(
                      icon: FontAwesomeIcons.plus,
                      onPressed: () {},
                    ),
                    body: const SizedBox(),
                  ),
                ),
              );

              expect(tester.takeException(), isNull);
              for (var i = 0; i < count; i++) {
                expect(
                  find.byKey(ValueKey('bottomNavigationDestination-$i')),
                  findsOneWidget,
                );
              }
              expect(
                find.byKey(const ValueKey('bottomNavigationCenterAction')),
                findsOneWidget,
              );
            }
          }
        },
      );
    });
  });
}
