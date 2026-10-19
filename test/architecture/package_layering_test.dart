// Architecture guardrail: enforces package categories, permitted dependency
// directions, layer ranks, and DAG (cycle-free) structure across all workspace
// packages under `packages/` and `published/rev_sync`.
//
// Preserve all `// fst:` sentinel comments so `fst create`, `fst add-feature`,
// and `fst remove-feature` continue to rewrite this file deterministically.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Explicit architectural categories for every package in the repository.
enum PackageCategory {
  /// 1. Root application shell (`lib/`): composes features, DI, routing, theme,
  ///    and localization. No workspace package may depend on the shell.
  applicationShell,

  /// 2. Feature packages (`packages/features/*`): vertical feature slices.
  feature,

  /// 3. Shared domain contracts (`architecture`, `shared_contracts`): pure
  ///    domain primitives and narrow cross-feature read/state interfaces.
  sharedDomainContracts,

  /// 4. UI and design-system packages (`app_ui`, `localization`, `theme`,
  ///    `shared_ui`): design tokens, reusable widgets, localization, and
  ///    cross-feature presentation scopes.
  uiDesignSystem,

  /// 5. Infrastructure and service packages (`analytics`, `config`, `database`,
  ///    `database_drift`, `network`, `rev_sync`, `storage`).
  infrastructureService,

  /// 6. Platform integration packages (`app_platform`,
  ///    `sync_connectivity_plus`).
  platformIntegration,

  /// 7. Development and testing utilities (`test_utils`): shared fakes,
  ///    fixtures, and test helpers. Never allowed in runtime `dependencies:`.
  devTestUtilities,
}

/// Permitted runtime dependency directions between package categories.
const Map<PackageCategory, Set<PackageCategory>> _allowedCategoryDependencies =
    {
      PackageCategory.applicationShell: {
        PackageCategory.feature,
        PackageCategory.sharedDomainContracts,
        PackageCategory.uiDesignSystem,
        PackageCategory.infrastructureService,
        PackageCategory.platformIntegration,
      },
      PackageCategory.feature: {
        PackageCategory.feature, // subject to layer rank + capability allowlist
        PackageCategory.sharedDomainContracts,
        PackageCategory.uiDesignSystem,
        PackageCategory.infrastructureService,
        PackageCategory.platformIntegration,
      },
      PackageCategory.sharedDomainContracts: {
        PackageCategory.sharedDomainContracts,
      },
      PackageCategory.uiDesignSystem: {
        PackageCategory.uiDesignSystem,
        PackageCategory.sharedDomainContracts,
        PackageCategory.infrastructureService,
      },
      PackageCategory.infrastructureService: {
        PackageCategory.infrastructureService,
        PackageCategory.sharedDomainContracts,
      },
      PackageCategory.platformIntegration: {
        PackageCategory.platformIntegration,
        PackageCategory.infrastructureService,
        PackageCategory.sharedDomainContracts,
      },
      PackageCategory.devTestUtilities: {
        PackageCategory.sharedDomainContracts,
        PackageCategory.uiDesignSystem,
        PackageCategory.infrastructureService,
        PackageCategory.platformIntegration,
      },
    };

/// Explicit category assignment for non-feature workspace packages.
/// Any package named `feature_<name>` is automatically classified as
/// [PackageCategory.feature].
const Map<String, PackageCategory> _nonFeatureCategories = {
  'architecture': PackageCategory.sharedDomainContracts,
  'shared_contracts': PackageCategory.sharedDomainContracts,
  'app_ui': PackageCategory.uiDesignSystem,
  'localization': PackageCategory.uiDesignSystem,
  'theme': PackageCategory.uiDesignSystem,
  'shared_ui': PackageCategory.uiDesignSystem,
  'analytics': PackageCategory.infrastructureService,
  'config': PackageCategory.infrastructureService,
  'database': PackageCategory.infrastructureService,
  'database_drift': PackageCategory.infrastructureService,
  'network': PackageCategory.infrastructureService,
  'rev_sync': PackageCategory.infrastructureService,
  'storage': PackageCategory.infrastructureService,
  'app_platform': PackageCategory.platformIntegration,
  'sync_connectivity_plus': PackageCategory.platformIntegration,
  'test_utils': PackageCategory.devTestUtilities,
  'document_engine': PackageCategory.infrastructureService,
  // fst:package-categories — `fst create-package` inserts categories above
};

/// Layer rank per workspace package. A package may depend only on packages
/// with a strictly smaller rank.
const _layers = <String, int>{
  // 0 — pure-Dart foundation; depends on nothing in the workspace.
  'architecture': 0,
  'rev_sync': 0, // offline-first sync engine; pure Dart, no workspace deps
  // 1 — primitives: no workspace deps, or only on architecture / rev_sync.
  'config': 1, // firebase_remote_config wrapper
  'storage': 1, // shared_preferences / secure storage
  'analytics': 1, // -> architecture
  'app_ui': 1, // design tokens; no workspace package deps
  'localization': 1, // gen-l10n AppLocalizations; no workspace package deps
  'shared_contracts': 1, // cross-feature domain contracts -> architecture
  'database': 1, // centralized persistence -> rev_sync
  // fst:db:drift:start
  'database_drift':
      1, // Drift pkg (template state only; CLI renames to database)
  // fst:db:drift:end
  // fst:backend:start
  'sync_connectivity_plus': 1, // connectivity_plus adapter -> rev_sync
  // fst:backend:end
  // 2 — composed infra built on the primitives.
  'shared_ui': 2, // cross-feature presentation contracts -> shared_contracts
  // fst:network:start
  'network': 2, // -> config
  // fst:network:end
  'app_platform': 2, // -> analytics, architecture
  'theme': 2, // -> analytics, architecture
  // 3 — shared test harness, sits on top of what it provides fakes for.
  'test_utils': 3, // -> analytics, app_platform, storage
  // 4 — base feature packages: the top runtime layer (only the app composes
  //     them), each depending on no sibling feature.
  // fst:auth:start
  'feature_auth': 4,
  // fst:auth:end
  // fst:feature:collections:start
  'feature_collections': 4,
  // fst:feature:collections:end
  'feature_home': 4,
  // fst:feature:notifications:start
  'feature_notifications': 4,
  // fst:feature:notifications:end
  'feature_splash': 4,
  // 5 — feature packages that surface a single sibling's capability; each
  //     depends on exactly one lower feature (the capability provider). The
  //     allowed edges are documented in feature_boundaries_test.
  // fst:feature:bookmarks:start
  'feature_bookmarks': 5, // -> feature_collections
  // fst:feature:bookmarks:end
  'feature_profile': 5, // -> feature_auth
  'document_engine': 1,
  // fst:package-layers — `fst create-package` inserts package layers above
  'feature_document_center': 4,
  // fst:feature-layers — `fst add-feature` inserts generated features above
};

PackageCategory? categoryForPackage(String name, {String? rootPackageName}) {
  if (rootPackageName != null && name == rootPackageName) {
    return PackageCategory.applicationShell;
  }
  if (name.startsWith('feature_')) {
    return PackageCategory.feature;
  }
  return _nonFeatureCategories[name];
}

void main() {
  final packagesDir = Directory('packages');

  test('packages/ exists (run from the package root)', () {
    expect(
      packagesDir.existsSync(),
      isTrue,
      reason:
          'Expected to find packages/ relative to the current directory. '
          'Run this test from the repository root.',
    );
  });

  final rootPubspecLines = File('pubspec.yaml').readAsLinesSync();
  final rootPackageName = _packageName(rootPubspecLines) ?? 'app';
  final packages = _discoverPackages(packagesDir);

  test('every workspace package has a layer and category assigned', () {
    final unranked =
        packages.keys.where((name) => !_layers.containsKey(name)).toList()
          ..sort();
    expect(
      unranked,
      isEmpty,
      reason:
          'These workspace packages have no entry in _layers. Assign each '
          'a layer rank so its dependency direction is enforced:\n\n'
          '${unranked.map((p) => '  $p').join('\n')}',
    );

    final uncategorized =
        packages.keys
            .where(
              (name) =>
                  categoryForPackage(name, rootPackageName: rootPackageName) ==
                  null,
            )
            .toList()
          ..sort();
    expect(
      uncategorized,
      isEmpty,
      reason:
          'These workspace packages have no PackageCategory assigned:\n\n'
          '${uncategorized.map((p) => '  $p').join('\n')}',
    );
  });

  test(
    'packages only depend on strictly lower layers and permitted categories',
    () {
      final dependencyGraph = <String, Set<String>>{
        for (final entry in packages.entries)
          entry.key: _runtimeDependencies(entry.value),
      };
      final violations = validateLayeringAndCategories(
        dependencyGraph: dependencyGraph,
        layers: _layers,
        rootPackageName: rootPackageName,
      );

      expect(
        violations,
        isEmpty,
        reason:
            'These runtime dependencies violate package layering or category '
            'contracts:\n\n${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test(
    'root application shell only depends on permitted runtime categories',
    () {
      final rootDeps = _runtimeDependencies(rootPubspecLines);
      final violations = <String>[];
      for (final dep in rootDeps) {
        if (!packages.containsKey(dep)) continue;
        final depCategory = categoryForPackage(
          dep,
          rootPackageName: rootPackageName,
        );
        if (depCategory == null) continue;
        final allowed =
            _allowedCategoryDependencies[PackageCategory.applicationShell]!;
        if (!allowed.contains(depCategory)) {
          violations.add(
            '$rootPackageName (${PackageCategory.applicationShell.name}) -> '
            '$dep (${depCategory.name}) [forbidden category]',
          );
        }
      }
      expect(violations, isEmpty);
    },
  );

  test('workspace package graph is a DAG with no circular dependencies', () {
    final dependencyGraph = <String, Set<String>>{
      for (final entry in packages.entries)
        entry.key: _runtimeDependencies(entry.value),
      rootPackageName: _runtimeDependencies(rootPubspecLines),
    };
    final cycles = detectDependencyCycles(dependencyGraph);
    expect(
      cycles,
      isEmpty,
      reason:
          'Circular package dependencies detected:\n\n'
          '${cycles.map((c) => '  $c').join('\n')}',
    );
  });

  group('layering & category enforcement regression tests', () {
    test('accepts valid downward dependencies across permitted categories', () {
      final violations = validateLayeringAndCategories(
        dependencyGraph: {
          'architecture': const {},
          'shared_contracts': const {'architecture'},
          'app_ui': const {},
          'localization': const {},
          'analytics': const {'architecture'},
          'theme': const {'analytics', 'architecture'},
          'feature_home': const {'app_ui', 'localization', 'shared_contracts'},
        },
        layers: _layers,
        rootPackageName: 'my_app',
      );
      expect(violations, isEmpty);
    });

    test(
      'rejects upward, same-layer, devTestUtilities, shell, and forbidden category dependencies',
      () {
        final violations = validateLayeringAndCategories(
          dependencyGraph: {
            'architecture': const {
              'app_ui',
            }, // upward + forbidden category (sharedDomainContracts -> uiDesignSystem)
            'config': const {'storage'}, // same-layer (1 -> 1)
            'network': const {
              'app_ui',
            }, // forbidden category (infrastructureService -> uiDesignSystem)
            'feature_home': const {
              'test_utils',
              'my_app',
            }, // devTestUtilities + applicationShell in runtime deps
          },
          layers: _layers,
          rootPackageName: 'my_app',
        );
        expect(
          violations,
          containsAll([
            contains('architecture (layer 0) -> app_ui (layer 1)  [upward]'),
            contains(
              'architecture (sharedDomainContracts) -> app_ui (uiDesignSystem)  [forbidden-category]',
            ),
            contains('config (layer 1) -> storage (layer 1)  [same-layer]'),
            contains(
              'network (infrastructureService) -> app_ui (uiDesignSystem)  [forbidden-category]',
            ),
            contains(
              'feature_home (feature) -> test_utils (devTestUtilities)  [forbidden-category]',
            ),
            contains('feature_home -> my_app  [depends-on-application-shell]'),
          ]),
        );
      },
    );

    test('detects 2-node and 3-node circular package references', () {
      final cycles = detectDependencyCycles({
        'pkg_a': const {'pkg_b'},
        'pkg_b': const {'pkg_c'},
        'pkg_c': const {'pkg_a'},
      });
      expect(cycles, isNotEmpty);
      expect(cycles.first, contains('pkg_a -> pkg_b -> pkg_c -> pkg_a'));
    });
  });
}

List<String> validateLayeringAndCategories({
  required Map<String, Set<String>> dependencyGraph,
  required Map<String, int> layers,
  required String rootPackageName,
}) {
  final workspaceNames = dependencyGraph.keys.toSet();
  final violations = <String>[];

  dependencyGraph.forEach((name, deps) {
    final fromRank = layers[name];
    final fromCategory = categoryForPackage(
      name,
      rootPackageName: rootPackageName,
    );

    for (final dep in deps) {
      if (dep == rootPackageName) {
        violations.add('$name -> $dep  [depends-on-application-shell]');
        continue;
      }
      if (!workspaceNames.contains(dep) &&
          !_nonFeatureCategories.containsKey(dep)) {
        continue;
      }
      final toRank = layers[dep];
      if (fromRank != null && toRank != null && toRank >= fromRank) {
        final kind = toRank == fromRank ? 'same-layer' : 'upward';
        violations.add(
          '$name (layer $fromRank) -> $dep (layer $toRank)  [$kind]',
        );
      }

      final toCategory = categoryForPackage(
        dep,
        rootPackageName: rootPackageName,
      );
      if (fromCategory != null && toCategory != null) {
        final allowed = _allowedCategoryDependencies[fromCategory] ?? const {};
        if (!allowed.contains(toCategory)) {
          violations.add(
            '$name (${fromCategory.name}) -> $dep (${toCategory.name})  [forbidden-category]',
          );
        }
      }
    }
  });

  return violations;
}

List<String> detectDependencyCycles(Map<String, Set<String>> dependencyGraph) {
  final cycles = <String>[];
  final visited = <String>{};
  final activeStack = <String>[];
  final activeSet = <String>{};

  void dfs(String node) {
    visited.add(node);
    activeStack.add(node);
    activeSet.add(node);

    final deps = dependencyGraph[node] ?? const <String>{};
    for (final dep in deps) {
      if (!dependencyGraph.containsKey(dep)) continue;
      if (activeSet.contains(dep)) {
        final cycleStart = activeStack.indexOf(dep);
        final cyclePath = [
          ...activeStack.sublist(cycleStart),
          dep,
        ].join(' -> ');
        cycles.add(cyclePath);
      } else if (!visited.contains(dep)) {
        dfs(dep);
      }
    }

    activeStack.removeLast();
    activeSet.remove(node);
  }

  for (final node in dependencyGraph.keys) {
    if (!visited.contains(node)) {
      dfs(node);
    }
  }
  return cycles;
}

/// Maps each workspace package name to the lines of its `pubspec.yaml`.
Map<String, List<String>> _discoverPackages(Directory packagesDir) {
  final result = <String, List<String>>{};

  void add(Directory dir) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) return;
    final lines = pubspec.readAsLinesSync();
    final name = _packageName(lines);
    if (name != null) result[name] = lines;
  }

  for (final entity in packagesDir.listSync()) {
    if (entity is! Directory) continue;
    if (File('${entity.path}/pubspec.yaml').existsSync()) {
      add(entity);
    } else {
      entity.listSync().whereType<Directory>().forEach(add);
    }
  }
  final revSyncDir = Directory('published/rev_sync');
  if (revSyncDir.existsSync()) {
    add(revSyncDir);
  }
  return result;
}

String? _packageName(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

Set<String> _runtimeDependencies(List<String> lines) {
  final deps = <String>{};
  final entry = RegExp('^  ([a-zA-Z0-9_]+):');
  var inDependencies = false;

  for (final line in lines) {
    if (line.trimRight() == 'dependencies:') {
      inDependencies = true;
      continue;
    }
    if (inDependencies && line.isNotEmpty && !line.startsWith(' ')) {
      inDependencies = false;
    }
    if (!inDependencies) continue;

    final match = entry.firstMatch(line);
    if (match != null) deps.add(match.group(1)!);
  }
  return deps;
}
