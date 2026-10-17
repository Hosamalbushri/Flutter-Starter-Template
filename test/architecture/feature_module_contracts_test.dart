// Architecture guardrail: enforces the `FeatureModule` contract across the
// live `enabledFeatures` registry and tests `validateFeatureModules` against
// positive and negative module fixtures.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_starter_template/app/feature_module.dart';
import 'package:flutter_starter_template/app/features.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('live enabledFeatures contract verification', () {
    test('enabledFeatures passes validateFeatureModules', () {
      expect(() => validateFeatureModules(enabledFeatures), returnsNormally);
    });

    test(
      'every enabled FeatureModule maps to an existing feature package and DI module',
      () {
        final injectionSource = File(
          'lib/app/di/injection.dart',
        ).readAsStringSync();
        for (final module in enabledFeatures) {
          final featureDir = Directory('packages/features/${module.id}');
          expect(
            featureDir.existsSync(),
            isTrue,
            reason:
                'FeatureModule(id: "${module.id}") has no matching directory at '
                'packages/features/${module.id}',
          );

          final pascal = module.id
              .split('_')
              .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
              .join();
          final expectedDiModule =
              'ExternalModule(Feature${pascal}PackageModule)';
          expect(
            injectionSource,
            contains(expectedDiModule),
            reason:
                'FeatureModule(id: "${module.id}") is enabled in lib/app/features.dart '
                'but $expectedDiModule is not registered in lib/app/di/injection.dart',
          );

          final pubspec = File(
            '${featureDir.path}/pubspec.yaml',
          ).readAsStringSync();
          for (final reqId in module.requiredFeatures) {
            expect(
              pubspec,
              contains('feature_$reqId:'),
              reason:
                  'FeatureModule(id: "${module.id}") declares requiredFeatures: '
                  '{$reqId}, so packages/features/${module.id}/pubspec.yaml '
                  'must declare feature_$reqId in dependencies.',
            );
          }
        }
      },
    );

    test(
      'every enabled FeatureModule.initialize() completes deterministically',
      () async {
        for (final module in enabledFeatures) {
          await expectLater(module.initialize(), completes);
        }
      },
    );
  });

  group('validateFeatureModules positive & negative regression tests', () {
    test('initializeFeatureModules awaits modules in registry order', () async {
      final events = <String>[];
      final firstCompleter = Completer<void>();
      final modules = <FeatureModule>[
        _TestFeatureModule(
          id: 'first',
          onInitialize: () async {
            events.add('first:start');
            await firstCompleter.future;
            events.add('first:end');
          },
        ),
        _TestFeatureModule(
          id: 'second',
          onInitialize: () async => events.add('second'),
        ),
      ];

      final initialization = initializeFeatureModules(modules);
      await Future<void>.delayed(Duration.zero);
      expect(events, ['first:start']);

      firstCompleter.complete();
      await initialization;
      expect(events, ['first:start', 'first:end', 'second']);
    });

    test('initializeFeatureModules attributes and stops on failure', () async {
      var laterModuleRan = false;
      final failure = StateError('setup failed');
      final modules = <FeatureModule>[
        _TestFeatureModule(
          id: 'failing',
          onInitialize: () async => throw failure,
        ),
        _TestFeatureModule(
          id: 'later',
          onInitialize: () async => laterModuleRan = true,
        ),
      ];

      await expectLater(
        initializeFeatureModules(modules),
        throwsA(
          isA<FeatureInitializationException>()
              .having((e) => e.featureId, 'featureId', 'failing')
              .having((e) => e.cause, 'cause', same(failure)),
        ),
      );
      expect(laterModuleRan, isFalse);
    });

    test(
      'accepts valid modules with routes, nested routes, navigation, and requiredFeatures',
      () {
        final modules = <FeatureModule>[
          _TestFeatureModule(
            id: 'collections',
            navigation: const FeatureNavigationRegistration(
              routePath: '/collections',
              routeName: 'collections',
            ),
            routes: [
              GoRoute(
                path: '/collections',
                name: 'collections',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          _TestFeatureModule(
            id: 'bookmarks',
            requiredFeatures: const {'collections'},
            navigation: const FeatureNavigationRegistration(
              routePath: '/bookmarks',
              routeName: 'bookmarks',
            ),
            routes: [
              GoRoute(
                path: '/bookmarks',
                name: 'bookmarks',
                builder: (_, _) => const SizedBox.shrink(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'bookmark-detail',
                    builder: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ];

        expect(() => validateFeatureModules(modules), returnsNormally);
      },
    );

    test('rejects empty or non-snake_case feature id', () {
      for (final badId in ['', 'Bookmarks', 'my-feature', '123feature']) {
        expect(
          () => validateFeatureModules([_TestFeatureModule(id: badId)]),
          throwsA(isA<StateError>()),
          reason: 'Expected invalid id "$badId" to be rejected',
        );
      }
    });

    test('rejects duplicate FeatureModule ids', () {
      const modules = <FeatureModule>[
        _TestFeatureModule(id: 'orders'),
        _TestFeatureModule(id: 'orders'),
      ];
      expect(
        () => validateFeatureModules(modules),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Duplicate FeatureModule.id "orders"'),
          ),
        ),
      );
    });

    test('rejects self-dependency and missing requiredFeatures', () {
      expect(
        () => validateFeatureModules(const [
          _TestFeatureModule(id: 'orders', requiredFeatures: {'orders'}),
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('cannot require itself in requiredFeatures'),
          ),
        ),
      );

      expect(
        () => validateFeatureModules(const [
          _TestFeatureModule(
            id: 'orders',
            requiredFeatures: {'inventory'},
          ),
        ]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('requires feature "inventory", which is not enabled'),
          ),
        ),
      );
    });

    test('rejects circular requiredFeatures between modules', () {
      const modules = <FeatureModule>[
        _TestFeatureModule(id: 'alpha', requiredFeatures: {'beta'}),
        _TestFeatureModule(id: 'beta', requiredFeatures: {'alpha'}),
      ];
      expect(
        () => validateFeatureModules(modules),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Circular requiredFeatures dependency detected'),
          ),
        ),
      );
    });

    test('rejects invalid navigation.routePath', () {
      const modules = <FeatureModule>[
        _TestFeatureModule(
          id: 'orders',
          navigation: FeatureNavigationRegistration(routePath: 'orders'),
        ),
      ];
      expect(
        () => validateFeatureModules(modules),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('invalid navigation.routePath'),
          ),
        ),
      );
    });

    test('rejects relative top-level GoRoute path', () {
      final modules = <FeatureModule>[
        _TestFeatureModule(
          id: 'orders',
          routes: [
            GoRoute(
              path: 'orders',
              name: 'orders',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ];
      expect(
        () => validateFeatureModules(modules),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('top-level GoRoute with invalid path "orders"'),
          ),
        ),
      );
    });

    test(
      'rejects duplicate top-level GoRoute paths and duplicate GoRoute names',
      () {
        final duplicatePaths = <FeatureModule>[
          _TestFeatureModule(
            id: 'orders',
            routes: [
              GoRoute(
                path: '/shared',
                name: 'orders',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          _TestFeatureModule(
            id: 'invoices',
            routes: [
              GoRoute(
                path: '/shared',
                name: 'invoices',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ];
        expect(
          () => validateFeatureModules(duplicatePaths),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Duplicate GoRoute path "/shared"'),
            ),
          ),
        );

        final duplicateNames = <FeatureModule>[
          _TestFeatureModule(
            id: 'orders',
            routes: [
              GoRoute(
                path: '/orders',
                name: 'detail-route',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          _TestFeatureModule(
            id: 'invoices',
            routes: [
              GoRoute(
                path: '/invoices',
                name: 'invoices',
                builder: (_, _) => const SizedBox.shrink(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    name: 'detail-route',
                    builder: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ];
        expect(
          () => validateFeatureModules(duplicateNames),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Duplicate GoRoute name "detail-route"'),
            ),
          ),
        );
      },
    );
  });
}

final class _TestFeatureModule extends FeatureModule {
  const _TestFeatureModule({
    required this.id,
    this.routes = const [],
    this.requiredFeatures = const {},
    this.navigation,
    this.onInitialize,
  });

  @override
  final String id;

  @override
  final Iterable<RouteBase> routes;

  @override
  final Set<String> requiredFeatures;

  @override
  final FeatureNavigationRegistration? navigation;

  final Future<void> Function()? onInitialize;

  @override
  Future<void> initialize() async {
    await onInitialize?.call();
  }
}
