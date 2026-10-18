import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  group('AppTopBar', () {
    testWidgets('dashboard variant renders polished chrome and actions work', (
      tester,
    ) async {
      var searchTaps = 0;
      var notificationTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Welcome back',
              subtitle: 'Alex Morgan',
              variant: AppTopBarVariant.dashboard,
              profileAvatar: const ColoredBox(color: Colors.blue),
              onSearchTap: () => searchTaps++,
              onNotificationTap: () => notificationTaps++,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('dashboardTopBarBackground')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboardTopBarAvatarFrame')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboardTopBarAction')),
        findsNWidgets(2),
      );
      expect(tester.getSize(find.byType(AppTopBar)).height, 66);

      await tester.tap(find.byType(IconButton).at(0));
      await tester.tap(find.byType(IconButton).at(1));
      expect(searchTaps, 1);
      expect(notificationTaps, 1);
    });

    testWidgets('dashboard variant stays compact at 320px in RTL at 2x', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 180)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                appBar: AppTopBar(
                  title: 'مرحبًا بك',
                  subtitle: 'حسام حازم علي',
                  variant: AppTopBarVariant.dashboard,
                  profileAvatar: const ColoredBox(color: Colors.blue),
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                body: const SizedBox(),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('dashboardTopBarIdentity')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps title geometrically centered with uneven actions', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Centered',
              leading: IconButton(
                key: const ValueKey('leading'),
                onPressed: () {},
                icon: const Icon(Icons.menu),
              ),
              actions: [
                IconButton(
                  key: const ValueKey('firstAction'),
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  key: const ValueKey('secondAction'),
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getCenter(find.text('Centered')).dx, closeTo(195, 0.01));
      for (final key in ['leading', 'firstAction', 'secondAction']) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
        expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      }
    });

    testWidgets('keeps title centered in RTL', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppTopBar(
                title: 'العنوان',
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.getCenter(find.text('العنوان')).dx, closeTo(195, 0.01));
    });

    testWidgets('long Arabic title at 2x does not overlap actions', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppTopBar(
                title: 'عنوان عربي طويل للغاية لاختبار عدم تداخل المحتوى',
                titleMaxLines: 2,
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final title = tester.getRect(
        find.byKey(const ValueKey('appTopBarTitle')),
      );
      final leading = tester.getRect(
        find.byKey(const ValueKey('appTopBarLeadingRegion')),
      );
      final trailing = tester.getRect(
        find.byKey(const ValueKey('appTopBarTrailingRegion')),
      );
      expect(title.overlaps(leading), isFalse);
      expect(title.overlaps(trailing), isFalse);
    });

    testWidgets('renders title and subtitle with correct styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            appBar: AppTopBar(
              title: 'Dashboard',
              subtitle: 'Welcome back',
            ),
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('renders notification badge with count', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Notifications',
              notificationCount: 5,
              onNotificationTap: () => tapped = true,
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      final badgeRect = tester.getRect(find.byType(Badge));
      final bellRect = tester.getRect(find.byType(FaIcon));
      expect(badgeRect.center.dx, closeTo(bellRect.center.dx, 12));
      expect(badgeRect.top, lessThanOrEqualTo(bellRect.top));
      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });

    testWidgets('notification action works without a numeric badge', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppTopBar(
              title: 'Inbox',
              onNotificationTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });

    testWidgets('mirrors back button icon in RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Scaffold(
                            appBar: AppTopBar(title: 'تفاصيل'),
                            body: SizedBox(),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل'), findsOneWidget);
      final faIcon = tester.widget<FaIcon>(find.byType(FaIcon));
      expect(faIcon.icon?.codePoint, FontAwesomeIcons.chevronRight.codePoint);
    });
  });

  group('AppAdaptiveScaffold Center Action', () {
    const destinations = [
      AppDestination(icon: FontAwesomeIcons.house, label: 'Home'),
      AppDestination(icon: FontAwesomeIcons.magnifyingGlass, label: 'Search'),
      AppDestination(icon: FontAwesomeIcons.circle, label: 'Settings'),
    ];

    testWidgets('renders center action button and fires callback', (
      tester,
    ) async {
      var centerPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: AppAdaptiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            centerAction: AppCenterAction(
              icon: FontAwesomeIcons.plus,
              tooltip: 'Add item',
              label: 'Add item',
              onPressed: () => centerPressed = true,
            ),
            body: const Text('body'),
          ),
        ),
      );

      final plusFinder = find.byWidgetPredicate(
        (w) =>
            w is FaIcon && w.icon?.codePoint == FontAwesomeIcons.plus.codePoint,
      );
      expect(plusFinder, findsOneWidget);
      await tester.tap(plusFinder);
      expect(centerPressed, isTrue);
    });
  });

  group('AppPageLayout', () {
    testWidgets(
      'dashboard layout renders header and children without overflow',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: AppPageLayout.dashboard(
                header: AppSectionHeader(
                  title: 'Overview',
                  subtitle: 'Daily stats',
                ),
                child: AppGroupSection(
                  title: 'Items',
                  children: [
                    ListTile(title: Text('First item')),
                    ListTile(title: Text('Second item')),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Daily stats'), findsOneWidget);
        expect(find.text('Items'), findsOneWidget);
        expect(find.text('First item'), findsOneWidget);
      },
    );
  });
}
