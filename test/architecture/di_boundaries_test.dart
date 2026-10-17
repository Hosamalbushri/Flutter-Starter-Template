// Architecture guardrail: enforces Dependency Injection boundaries across the
// application shell, feature packages, and infrastructure/platform packages.
//
// Rules enforced:
// 1. Feature packages (`packages/features/*/lib/`) must not configure or
//    reference another feature's `Feature*PackageModule` or `init*Feature`.
// 2. Feature `domain/` and `data/` layers must use constructor injection via
//    `@injectable` / `@LazySingleton` and must never import `get_it` or
//    `locator.dart` directly (service locator access is restricted to
//    `presentation/` and application shell composition).
// 3. No workspace package under `packages/*/lib/` may call `getIt.register*`
//    manually outside generated `*.module.dart` files.
// 4. Root `lib/app/di/injection.dart` must register infrastructure, platform,
//    and shared-contract modules deterministically before feature modules in
//    `externalPackageModulesBefore`.
// 5. Optional feature reader fallbacks (`registerReaderFallbacks`) must safely
//    provide `NoOpBookmarkStatsReader` and `NoOpCollectionsReader` when those
//    features are disabled, without overriding existing bindings.

import 'dart:io';

import 'package:architecture/architecture.dart';
import 'package:flutter_starter_template/app/di/reader_fallbacks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_contracts/shared_contracts.dart';

void main() {
  test(
    'feature packages do not reference unrelated Feature*PackageModule or manual getIt registrations',
    () {
      final violations = <String>[];
      final featuresDir = Directory('packages/features');
      for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
        final pubspecFile = File('${featureDir.path}/pubspec.yaml');
        if (!pubspecFile.existsSync()) continue;
        final pkgName = _packageName(pubspecFile.readAsLinesSync());
        if (pkgName == null) continue;
        final libDir = Directory('${featureDir.path}/lib');
        if (!libDir.existsSync()) continue;

        for (final file
            in libDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final relPath = _posix(file.path);
          violations.addAll(
            validateFeatureDiFile(
              packageName: pkgName,
              filePath: relPath,
              lines: file.readAsLinesSync(),
            ),
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Feature packages violated DI boundaries:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test(
    'non-feature workspace packages do not call getIt.register* outside generated *.module.dart',
    () {
      final violations = <String>[];
      final packagesDir = Directory('packages');
      for (final entity in packagesDir.listSync().whereType<Directory>()) {
        if (_posix(entity.path).endsWith('/features')) continue;
        final libDir = Directory('${entity.path}/lib');
        if (!libDir.existsSync()) continue;
        for (final file
            in libDir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final relPath = _posix(file.path);
          if (relPath.endsWith('.module.dart')) continue;
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (RegExp(r'\bgetIt\s*\.\s*register').hasMatch(lines[i])) {
              violations.add(
                '$relPath:${i + 1} calls getIt.register* manually outside generated module',
              );
            }
          }
        }
      }
      expect(violations, isEmpty);
    },
  );

  test(
    'lib/app/di/injection.dart orders infrastructure modules deterministically before feature modules',
    () {
      final injectionSource = File(
        'lib/app/di/injection.dart',
      ).readAsStringSync();
      final violations = validateInjectionModuleOrdering(injectionSource);
      expect(
        violations,
        isEmpty,
        reason:
            'lib/app/di/injection.dart violated deterministic DI module ordering:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test(
    'registerReaderFallbacks safely provides fallbacks when optional features are absent and preserves real bindings',
    () async {
      final container = GetIt.asNewInstance();
      addTearDown(container.reset);

      registerReaderFallbacks(container);
      // Calling twice must be idempotent.
      registerReaderFallbacks(container);

      expect(container.isRegistered<BookmarkStatsReader>(), isTrue);
      expect(container.isRegistered<CollectionsReader>(), isTrue);

      final statsResult = await container<BookmarkStatsReader>()();
      expect(statsResult, isA<Ok<BookmarkStats>>());
      expect((statsResult as Ok<BookmarkStats>).value.total, 0);

      final collectionsResult = await container<CollectionsReader>()();
      expect(collectionsResult, isA<Ok<List<CollectionSummary>>>());
      expect((collectionsResult as Ok<List<CollectionSummary>>).value, isEmpty);

      // When a real feature implementation is already registered, fallback must
      // not overwrite it.
      final containerWithReal = GetIt.asNewInstance();
      addTearDown(containerWithReal.reset);
      const customReader = _CustomBookmarkStatsReader();
      containerWithReal.registerSingleton<BookmarkStatsReader>(customReader);

      registerReaderFallbacks(containerWithReal);
      expect(
        identical(containerWithReal<BookmarkStatsReader>(), customReader),
        isTrue,
      );
    },
  );

  group('DI boundary regression tests', () {
    test(
      'accepts compliant feature DI anchor, presentation locator, and constructor-injected data/domain',
      () {
        expect(
          validateFeatureDiFile(
            packageName: 'feature_orders',
            filePath: 'packages/features/orders/lib/src/di.dart',
            lines: const [
              '@InjectableInit.microPackage()',
              'void initOrdersFeature() {}',
            ],
          ),
          isEmpty,
        );
        expect(
          validateFeatureDiFile(
            packageName: 'feature_orders',
            filePath:
                'packages/features/orders/lib/src/presentation/screens/orders_screen.dart',
            lines: const [
              'final cubit = getIt<OrdersCubit>();',
            ],
          ),
          isEmpty,
        );
        expect(
          validateFeatureDiFile(
            packageName: 'feature_orders',
            filePath:
                'packages/features/orders/lib/src/data/repositories/orders_repository_impl.dart',
            lines: const [
              '@LazySingleton(as: OrdersRepository)',
              'class OrdersRepositoryImpl implements OrdersRepository {}',
            ],
          ),
          isEmpty,
        );
      },
    );

    test(
      'rejects service locator in domain/ or data/, foreign Feature*PackageModule, and manual getIt.register*',
      () {
        const getItImportLine =
            'import '
            "'package:get_it/get_it.dart';";
        const locatorImportLine =
            'import '
            "'../../locator.dart';";

        final domainViolations = validateFeatureDiFile(
          packageName: 'feature_orders',
          filePath:
              'packages/features/orders/lib/src/domain/usecases/get_orders.dart',
          lines: const [
            getItImportLine,
            'final repo = getIt<OrdersRepository>();',
          ],
        );
        expect(
          domainViolations,
          contains(
            contains('domain/ or data/ layer must not use service locator'),
          ),
        );

        final dataViolations = validateFeatureDiFile(
          packageName: 'feature_orders',
          filePath:
              'packages/features/orders/lib/src/data/repositories/orders_repository_impl.dart',
          lines: [
            locatorImportLine,
            'void bad() => getIt.registerSingleton<String>("leak");',
            'const other = FeatureBookmarksPackageModule;',
          ],
        );
        expect(
          dataViolations,
          containsAll([
            contains('domain/ or data/ layer must not use service locator'),
            contains('manual getIt.register* call outside generated module'),
            contains(
              'references foreign feature DI module FeatureBookmarksPackageModule',
            ),
          ]),
        );
      },
    );

    test(
      'rejects feature modules registered before infrastructure modules in injection.dart',
      () {
        const badInjection = '''
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(FeatureHomePackageModule),
    ExternalModule(StoragePackageModule),
  ],
)
Future<void> configureDependencies() async {}
''';
        final violations = validateInjectionModuleOrdering(badInjection);
        expect(
          violations,
          contains(
            contains(
              'Infrastructure module StoragePackageModule is registered after feature module FeatureHomePackageModule',
            ),
          ),
        );
      },
    );
  });
}

List<String> validateFeatureDiFile({
  required String packageName,
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  if (filePath.endsWith('.module.dart')) return violations;

  final featureSuffix = packageName.startsWith('feature_')
      ? packageName.substring('feature_'.length)
      : packageName;
  final ownPascal = featureSuffix
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
  final ownModuleName = 'Feature${ownPascal}PackageModule';

  final isDomainOrData =
      filePath.contains('/lib/src/domain/') ||
      filePath.contains('/lib/src/data/');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (isDomainOrData &&
        (line.contains('package:get_it/get_it.dart') ||
            line.contains('locator.dart') ||
            RegExp(r'\bgetIt\b').hasMatch(line))) {
      violations.add(
        '$filePath:${i + 1} ($packageName) domain/ or data/ layer must not use service locator',
      );
    }

    if (RegExp(r'\bgetIt\s*\.\s*register').hasMatch(line)) {
      violations.add(
        '$filePath:${i + 1} ($packageName) has manual getIt.register* call outside generated module',
      );
    }

    for (final match in RegExp(
      r'\b(Feature[A-Za-z0-9]+PackageModule)\b',
    ).allMatches(line)) {
      final referencedModule = match.group(1)!;
      if (referencedModule != ownModuleName) {
        violations.add(
          '$filePath:${i + 1} ($packageName) references foreign feature DI module $referencedModule',
        );
      }
    }
  }
  return violations;
}

List<String> validateInjectionModuleOrdering(String injectionSource) {
  final violations = <String>[];
  final modules = RegExp(
    r'ExternalModule\(\s*([A-Za-z0-9_]+)\s*\)',
  ).allMatches(injectionSource).map((m) => m.group(1)!).toList();

  if (modules.isEmpty) {
    violations.add('No ExternalModule registrations found in injection.dart');
    return violations;
  }

  String? firstFeatureModule;
  for (final module in modules) {
    final isFeatureModule = module.startsWith('Feature');
    if (isFeatureModule) {
      firstFeatureModule ??= module;
    } else if (firstFeatureModule != null) {
      violations.add(
        'Infrastructure module $module is registered after feature module $firstFeatureModule',
      );
    }
  }

  final storageIndex = modules.indexOf('StoragePackageModule');
  final networkIndex = modules.indexOf('NetworkPackageModule');
  if (storageIndex != -1 && networkIndex != -1 && storageIndex > networkIndex) {
    violations.add(
      'StoragePackageModule must precede NetworkPackageModule in externalPackageModulesBefore',
    );
  }
  return violations;
}

final class _CustomBookmarkStatsReader extends BookmarkStatsReader {
  const _CustomBookmarkStatsReader();

  @override
  Future<Result<BookmarkStats>> call([NoParams param = noParams]) async =>
      const Ok(BookmarkStats(total: 42));
}

String? _packageName(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

String _posix(String path) => path.replaceAll(r'\', '/');
