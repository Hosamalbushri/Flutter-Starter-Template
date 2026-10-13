import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_starter_template/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> sendPlatformRoute(WidgetTester tester, String location) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', <String, Object?>{
      'location': location,
      'state': null,
    }),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'warm platform links replace the location and preserve nested back behavior',
    (tester) async {
      final result = buildRouterWithDeepLink(
        null,
        featureRoutes: [
          GoRoute(
            path: '/warm',
            builder: (context, state) => const Material(
              child: Center(child: Text('warm root')),
            ),
            routes: [
              GoRoute(
                path: 'details',
                builder: (context, state) => const Material(
                  child: Center(child: Text('warm details')),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(result.router.dispose);
      result.deepLink.splashCompleted = true;
      result.router.go('/warm');

      await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));
      await tester.pumpAndSettle();
      expect(find.text('warm root'), findsOneWidget);

      await sendPlatformRoute(
        tester,
        'https://yourdomain.com/warm/details?source=android',
      );
      expect(find.text('warm details'), findsOneWidget);

      // Re-delivering the same intent must not add a duplicate page.
      await sendPlatformRoute(
        tester,
        'https://yourdomain.com/warm/details?source=android',
      );
      expect(find.text('warm details'), findsOneWidget);
      expect(result.router.canPop(), isTrue);

      result.router.pop();
      await tester.pumpAndSettle();
      expect(find.text('warm root'), findsOneWidget);
      expect(result.router.canPop(), isFalse);
    },
  );

  testWidgets('a warm unknown link uses the existing error page', (
    tester,
  ) async {
    final result = buildRouterWithDeepLink(
      null,
      featureRoutes: [
        GoRoute(
          path: '/warm',
          builder: (context, state) => const Material(child: Text('warm root')),
        ),
      ],
    );
    addTearDown(result.router.dispose);
    result.deepLink.splashCompleted = true;
    result.router.go('/warm');

    await tester.pumpWidget(MaterialApp.router(routerConfig: result.router));
    await tester.pumpAndSettle();
    await sendPlatformRoute(tester, 'https://yourdomain.com/not-a-route');

    expect(find.text('Page Not Found'), findsOneWidget);
  });
}
