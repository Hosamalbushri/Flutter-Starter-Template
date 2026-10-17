// Architecture guardrail: enforces public API barrel contracts across all
// workspace packages under `packages/` and `published/rev_sync`.
//
// Rules enforced:
// 1. Every workspace package exposes a single public entry point at
//    `lib/<package_name>.dart`.
// 2. All other `.dart` source files inside a workspace package's `lib/`
//    directory must reside under `lib/src/` (or `lib/l10n/` for generated
//    localization classes in `package:localization`).
// 3. No barrel file may export internal DI anchors (`src/di.dart`) or internal
//    service-locator shims (`src/locator.dart`).
// 4. Feature package barrels (`feature_*`) may only export:
//    - `src/di.module.dart` (Injectable micro-package module)
//    - `src/presentation/**` (routes, screens, capability widgets/cubits/blocs)
//    - `src/domain/entities/**` (domain entities)
//    - `src/domain/services/**` (sync lifecycle controllers)
//    They must never leak `src/data/**`, `src/domain/repositories/**`, or
//    `src/domain/usecases/**`.
// 5. Infrastructure, platform, UI, and contract package barrels must not
//    re-export raw Firebase SDK packages (`package:firebase_*/`) or raw
//    storage plugin packages (`package:shared_preferences/`,
//    `package:flutter_secure_storage/`).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workspacePackages = _discoverWorkspacePackages();

  test(
    'every workspace package has a single public barrel lib/<package>.dart',
    () {
      final violations = <String>[];
      for (final pkg in workspacePackages) {
        violations.addAll(
          validatePackageLibStructure(
            packageName: pkg.name,
            packageDir: pkg.dirPath,
            libRelativeDartFiles: pkg.libRelativeDartFiles,
          ),
        );
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Every workspace package must expose only `lib/<package>.dart` at '
            'the top level of `lib/` and keep implementation files under '
            '`lib/src/`:\n\n${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test(
    'no workspace package barrel leaks internal or third-party implementation details',
    () {
      final violations = <String>[];
      for (final pkg in workspacePackages) {
        final barrelFile = File('${pkg.dirPath}/lib/${pkg.name}.dart');
        if (!barrelFile.existsSync()) continue;
        violations.addAll(
          validateBarrelExports(
            packageName: pkg.name,
            barrelPath: '${pkg.dirPath}/lib/${pkg.name}.dart',
            lines: barrelFile.readAsLinesSync(),
          ),
        );
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Public barrel files leaked internal implementation symbols or '
            'unwrapped third-party SDKs:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  group('public API contract regression tests', () {
    test('accepts compliant feature and infrastructure barrels', () {
      expect(
        validatePackageLibStructure(
          packageName: 'feature_bookmarks',
          packageDir: 'packages/features/bookmarks',
          libRelativeDartFiles: const [
            'feature_bookmarks.dart',
            'src/di.dart',
            'src/di.module.dart',
            'src/presentation/bookmarks_routes.dart',
          ],
        ),
        isEmpty,
      );
      expect(
        validateBarrelExports(
          packageName: 'feature_bookmarks',
          barrelPath: 'packages/features/bookmarks/lib/feature_bookmarks.dart',
          lines: const [
            'library;',
            "export 'src/di.module.dart' show FeatureBookmarksPackageModule;",
            "export 'src/domain/entities/bookmark.dart';",
            "export 'src/domain/services/bookmarks_sync_controller.dart';",
            "export 'src/presentation/bookmarks_routes.dart';",
          ],
        ),
        isEmpty,
      );
      expect(
        validateBarrelExports(
          packageName: 'network',
          barrelPath: 'packages/network/lib/network.dart',
          lines: const [
            "export 'package:dio/dio.dart';",
            "export 'package:retrofit/retrofit.dart';",
            "export 'src/dio_module.dart';",
          ],
        ),
        isEmpty,
      );
    });

    test(
      'rejects extra top-level files outside lib/src/ or missing barrel',
      () {
        final missingBarrel = validatePackageLibStructure(
          packageName: 'feature_orders',
          packageDir: 'packages/features/orders',
          libRelativeDartFiles: const ['src/di.dart'],
        );
        expect(missingBarrel, contains(contains('missing public barrel')));

        final extraTopLevel = validatePackageLibStructure(
          packageName: 'feature_orders',
          packageDir: 'packages/features/orders',
          libRelativeDartFiles: const [
            'feature_orders.dart',
            'orders_internal_helper.dart',
          ],
        );
        expect(
          extraTopLevel,
          contains(contains('non-barrel file outside lib/src/')),
        );
      },
    );

    test(
      'rejects barrel exports of di.dart, locator.dart, data/, repositories/, usecases/, and firebase_*',
      () {
        final featureLeaks = validateBarrelExports(
          packageName: 'feature_orders',
          barrelPath: 'packages/features/orders/lib/feature_orders.dart',
          lines: const [
            "export 'src/di.dart';",
            "export 'src/locator.dart';",
            "export 'src/data/repositories/orders_repository_impl.dart';",
            "export 'src/domain/repositories/orders_repository.dart';",
            "export 'src/domain/usecases/get_orders.dart';",
          ],
        );
        expect(
          featureLeaks,
          containsAll([
            contains('leaks internal DI anchor: src/di.dart'),
            contains('leaks internal service locator: src/locator.dart'),
            contains(
              'feature barrel leaks internal layer: src/data/repositories/orders_repository_impl.dart',
            ),
            contains(
              'feature barrel leaks internal layer: src/domain/repositories/orders_repository.dart',
            ),
            contains(
              'feature barrel leaks internal layer: src/domain/usecases/get_orders.dart',
            ),
          ]),
        );

        final infraLeaks = validateBarrelExports(
          packageName: 'network',
          barrelPath: 'packages/network/lib/network.dart',
          lines: const [
            "export 'package:firebase_performance/firebase_performance.dart';",
            "export 'package:firebase_crashlytics/firebase_crashlytics.dart';",
          ],
        );
        expect(
          infraLeaks,
          containsAll([
            contains('firebase_performance'),
            contains('firebase_crashlytics'),
          ]),
        );
      },
    );
  });
}

final class _WorkspacePackageInfo {
  const _WorkspacePackageInfo({
    required this.name,
    required this.dirPath,
    required this.libRelativeDartFiles,
  });

  final String name;
  final String dirPath;
  final List<String> libRelativeDartFiles;
}

final RegExp _exportDirective = RegExp(
  r'''^\s*export\s+['"]([^'"]+)['"]''',
);

const Set<String> _forbiddenWrappedSdkExports = {
  'package:firebase_analytics/',
  'package:firebase_crashlytics/',
  'package:firebase_performance/',
  'package:firebase_remote_config/',
};

List<String> validatePackageLibStructure({
  required String packageName,
  required String packageDir,
  required List<String> libRelativeDartFiles,
}) {
  final violations = <String>[];
  // `database_drift` is a template-only directory renamed to `database` by
  // `fst create --database drift`, so its public barrel is `database.dart`.
  final expectedBarrel = packageName == 'database_drift'
      ? 'database.dart'
      : '$packageName.dart';
  if (!libRelativeDartFiles.contains(expectedBarrel)) {
    violations.add(
      '$packageDir/lib is missing public barrel $expectedBarrel',
    );
  }
  for (final relPath in libRelativeDartFiles) {
    if (relPath == expectedBarrel) continue;
    if (relPath.startsWith('src/')) continue;
    if (packageName == 'localization' && relPath.startsWith('l10n/')) continue;
    // ObjectBox generates `objectbox.g.dart` directly under `lib/`.
    if (packageName == 'database' && relPath == 'objectbox.g.dart') continue;
    violations.add(
      '$packageDir/lib/$relPath ($packageName) is a non-barrel file outside lib/src/',
    );
  }
  return violations;
}

List<String> validateBarrelExports({
  required String packageName,
  required String barrelPath,
  required List<String> lines,
}) {
  final violations = <String>[];
  final isFeature = packageName.startsWith('feature_');

  for (var i = 0; i < lines.length; i++) {
    final match = _exportDirective.firstMatch(lines[i]);
    if (match == null) continue;
    final uri = match.group(1)!;

    if (uri == 'src/di.dart' || uri.endsWith('/src/di.dart')) {
      violations.add(
        '$barrelPath:${i + 1} ($packageName) leaks internal DI anchor: $uri',
      );
      continue;
    }
    if (uri == 'src/locator.dart' || uri.endsWith('/src/locator.dart')) {
      violations.add(
        '$barrelPath:${i + 1} ($packageName) leaks internal service locator: $uri',
      );
      continue;
    }
    if (_forbiddenWrappedSdkExports.any(uri.startsWith)) {
      violations.add(
        '$barrelPath:${i + 1} ($packageName) re-exports raw third-party SDK: $uri',
      );
      continue;
    }

    if (isFeature) {
      final allowedFeatureExport =
          uri == 'src/di.module.dart' ||
          uri.startsWith('src/presentation/') ||
          uri.startsWith('src/domain/entities/') ||
          uri.startsWith('src/domain/services/');
      if (!allowedFeatureExport) {
        violations.add(
          '$barrelPath:${i + 1} ($packageName) feature barrel leaks internal layer: $uri',
        );
      }
    }
  }
  return violations;
}

List<_WorkspacePackageInfo> _discoverWorkspacePackages() {
  final result = <_WorkspacePackageInfo>[];

  void addDir(Directory dir) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) return;
    final name = _packageName(pubspec.readAsLinesSync());
    if (name == null) return;
    final libDir = Directory('${dir.path}/lib');
    if (!libDir.existsSync()) return;
    final libPrefix = '${_posix(libDir.path)}/';
    final files =
        libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map((f) => _posix(f.path).substring(libPrefix.length))
            .toList()
          ..sort();
    result.add(
      _WorkspacePackageInfo(
        name: name,
        dirPath: _posix(dir.path),
        libRelativeDartFiles: files,
      ),
    );
  }

  final packagesDir = Directory('packages');
  if (packagesDir.existsSync()) {
    for (final entity in packagesDir.listSync().whereType<Directory>()) {
      if (File('${entity.path}/pubspec.yaml').existsSync()) {
        addDir(entity);
      } else {
        entity.listSync().whereType<Directory>().forEach(addDir);
      }
    }
  }
  final revSyncDir = Directory('published/rev_sync');
  if (revSyncDir.existsSync()) {
    addDir(revSyncDir);
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

String? _packageName(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

String _posix(String path) => path.replaceAll(r'\', '/');
