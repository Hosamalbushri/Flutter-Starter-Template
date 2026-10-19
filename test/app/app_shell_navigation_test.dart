// fst:feature:notifications:start
import 'package:feature_notifications/feature_notifications.dart';
// fst:feature:notifications:end
import 'package:flutter/material.dart';
// fst:feature:notifications:start
import 'package:flutter_bloc/flutter_bloc.dart';
// fst:feature:notifications:end
import 'package:flutter_starter_template/app/di/injection.dart';
import 'package:flutter_starter_template/app/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';

// fst:feature:notifications:start
import '../test_utils.dart';
// fst:feature:notifications:end

void main() {
  // fst:feature:notifications:start
  late MockNotificationsBloc notificationsBloc;
  // fst:feature:notifications:end

  setUp(() async {
    await getIt.reset();
    // fst:feature:notifications:start
    notificationsBloc = MockNotificationsBloc();
    when(
      () => notificationsBloc.state,
    ).thenReturn(const NotificationsState());
    when(
      () => notificationsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<NotificationsBloc>(notificationsBloc);
    // fst:feature:notifications:end
  });

  tearDown(() async => getIt.reset());

  testWidgets(
    'branch stacks survive switching and compact-to-rail resizing',
    (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => _screen(
                      'home-root',
                      action: () => context.push('/details'),
                    ),
                    routes: [
                      GoRoute(
                        path: 'details',
                        builder: (context, state) => _screen('home-details'),
                      ),
                    ],
                  ),
                ],
              ),
              // fst:feature:bookmarks:start
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/bookmarks',
                    builder: (context, state) => _screen('bookmarks-root'),
                  ),
                ],
              ),
              // fst:feature:bookmarks:end
              // fst:feature:notifications:start
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/notifications',
                    builder: (context, state) => _screen('notifications-root'),
                  ),
                ],
              ),
              // fst:feature:notifications:end
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) => _screen('profile-root'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      Widget app = MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
      // fst:feature:notifications:start
      app = BlocProvider<NotificationsBloc>.value(
        value: notificationsBloc,
        child: app,
      );
      // fst:feature:notifications:end
      await tester.pumpWidget(
        app,
      );
      await tester.pumpAndSettle();

      expect(find.text('home-root'), findsOneWidget);
      await tester.tap(find.text('open-details'));
      await tester.pumpAndSettle();
      expect(find.text('home-details'), findsOneWidget);

      // fst:feature:bookmarks:start
      await tester.tap(
        find.byKey(const ValueKey('bottomNavigationDestination-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('bookmarks-root'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('bottomNavigationDestination-0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('home-details'), findsOneWidget);
      // fst:feature:bookmarks:end

      tester.view.physicalSize = const Size(840, 900);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('home-details'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home-root'), findsOneWidget);
    },
  );
}

Widget _screen(String label, {VoidCallback? action}) {
  return Scaffold(
    body: Center(
      child: action == null
          ? Text(label)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                FilledButton(
                  onPressed: action,
                  child: const Text('open-details'),
                ),
              ],
            ),
    ),
  );
}
