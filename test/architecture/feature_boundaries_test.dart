// Architecture guardrail: enforces feature-to-feature boundaries, cross-package
// private `lib/src/` import restrictions, and relative-import containment.
//
// Preserve all `// fst:` sentinel comments so `fst create` strips optional
// capability exceptions cleanly.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Documented capability exceptions, keyed by the importing feature package.
const _allowedCrossFeatureImports = <String, Set<String>>{
  // fst:feature:bookmarks:start
  // bookmarks surfaces collections' "add to collection" sheet and embedded
  // collections list (single consumer). See the capability exception in
  // CLAUDE.md; promote to shared_ui if a second consumer appears.
  'feature_bookmarks': {'feature_collections'},
  // fst:feature:bookmarks:end
  // fst:auth:start
  // profile surfaces auth's account-deletion flow (DeleteAccountCubit, single
  // consumer). See the DeleteAccountCubit worked example in CLAUDE.md.
  'feature_profile': {'feature_auth'},
  // fst:auth:end
};

void main() {
  final featuresDir = Directory('packages/features');

  test('packages/features exists (run from the package root)', () {
    expect(
      featuresDir.existsSync(),
      isTrue,
      reason:
          'Expected to find packages/features relative to the current '
          'directory. Run this test from the package root.',
    );
  });

  final featurePackages = <String, String>{};
  for (final entity in featuresDir.listSync().whereType<Directory>()) {
    final pubspec = File('${entity.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final name = _packageName(pubspec.readAsLinesSync());
    if (name != null) featurePackages[_posix(entity.path)] = name;
  }
  final featurePackageNames = featurePackages.values.toSet();

  final crossFeatureImports = _collectCrossFeatureImports(
    featurePackages,
    featurePackageNames,
  );

  test(
    'no feature imports another feature outside the documented allowlist',
    () {
      final violations = findDisallowedCrossFeatureImports(
        crossFeatureImports,
        _allowedCrossFeatureImports,
      );

      expect(
        violations,
        isEmpty,
        reason:
            'Cross-feature imports break the feature boundary documented in '
            'CLAUDE.md. Read shared state through a shared_contracts contract, '
            'or — if this is a deliberate single-consumer capability — add it '
            'to _allowedCrossFeatureImports in this test.\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test(
    'no feature declares another feature in pubspec.yaml outside the allowlist',
    () {
      final violations = <String>[];
      featurePackages.forEach((dirPath, ownName) {
        final lines = File('$dirPath/pubspec.yaml').readAsLinesSync();
        for (final dep in _runtimeDependencies(lines)) {
          if (!featurePackageNames.contains(dep) || dep == ownName) continue;
          final allowed =
              _allowedCrossFeatureImports[ownName]?.contains(dep) ?? false;
          if (!allowed) {
            violations.add('$dirPath/pubspec.yaml declares $ownName -> $dep');
          }
        }
      });
      expect(
        violations,
        isEmpty,
        reason:
            'Feature pubspec.yaml runtime dependencies must match '
            '_allowedCrossFeatureImports:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  test('every allowlisted capability import still exists (no stale entries)', () {
    final actual = crossFeatureImports
        .map((i) => '${i.sourceFeature} -> ${i.targetFeature}')
        .toSet();

    final stale = <String>[];
    _allowedCrossFeatureImports.forEach((feature, targets) {
      for (final target in targets) {
        if (!actual.contains('$feature -> $target')) {
          stale.add('$feature -> $target');
        }
      }
    });

    expect(
      stale,
      isEmpty,
      reason:
          'These whitelisted capability imports no longer exist. Remove '
          'them from _allowedCrossFeatureImports — a stale allowlist hides '
          'real boundary violations:\n\n${stale.map((s) => '  $s').join('\n')}',
    );
  });

  test(
    'no package or test imports another package private lib/src/ implementation',
    () {
      final violations = _collectPrivateSrcAndRelativeEscapeViolations();
      expect(
        violations,
        isEmpty,
        reason:
            'Cross-package imports into `package:<other>/src/...` or relative '
            'imports escaping a package root bypass public API boundaries:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    },
  );

  group('boundary & private import regression tests', () {
    test('accepts same-package src/ imports and public barrel imports', () {
      final violations = scanDirectivesForBoundaryViolations(
        owningPackage: 'feature_bookmarks',
        filePath:
            'packages/features/bookmarks/lib/src/presentation/bookmarks_screen.dart',
        packageLibRoot: 'packages/features/bookmarks/lib',
        lines: const [
          "import 'package:app_ui/app_ui.dart';",
          "import 'package:feature_bookmarks/src/domain/entities/bookmark.dart';",
          "import 'package:feature_collections/feature_collections.dart';",
          "import '../widgets/bookmark_card.dart';",
        ],
      );
      expect(violations, isEmpty);
    });

    test('rejects cross-package private lib/src/ imports and exports', () {
      final violations = scanDirectivesForBoundaryViolations(
        owningPackage: 'feature_bookmarks',
        filePath:
            'packages/features/bookmarks/lib/src/presentation/bookmarks_screen.dart',
        packageLibRoot: 'packages/features/bookmarks/lib',
        lines: const [
          "import 'package:feature_collections/src/presentation/bloc/collections_list_bloc.dart';",
          "export 'package:network/src/dio_module.dart';",
        ],
      );
      expect(
        violations,
        containsAll([
          contains('package:feature_collections/src/'),
          contains('package:network/src/dio_module.dart'),
        ]),
      );
    });

    test('rejects relative imports that escape the package lib/ directory', () {
      final violations = scanDirectivesForBoundaryViolations(
        owningPackage: 'feature_bookmarks',
        filePath:
            'packages/features/bookmarks/lib/src/presentation/bookmarks_screen.dart',
        packageLibRoot: 'packages/features/bookmarks/lib',
        lines: const [
          "import '../../../../collections/lib/src/di.dart';",
        ],
      );
      expect(violations, contains(contains('relative directive escapes')));
    });

    test('rejects unapproved cross-feature imports', () {
      final imports = [
        CrossFeatureImport(
          file: 'packages/features/home/lib/src/home_screen.dart',
          line: 1,
          sourceFeature: 'feature_home',
          targetFeature: 'feature_bookmarks',
          uri: 'package:feature_bookmarks/feature_bookmarks.dart',
        ),
      ];
      final disallowed = findDisallowedCrossFeatureImports(
        imports,
        _allowedCrossFeatureImports,
      );
      expect(disallowed, hasLength(1));
      expect(
        disallowed.single.toString(),
        contains('feature_home -> feature_bookmarks'),
      );
    });
  });
}

/// A single import that crosses from one feature package into another.
class CrossFeatureImport {
  CrossFeatureImport({
    required this.file,
    required this.line,
    required this.sourceFeature,
    required this.targetFeature,
    required this.uri,
  });

  final String file;
  final int line;
  final String sourceFeature;
  final String targetFeature;
  final String uri;

  @override
  String toString() => '$file:$line imports $sourceFeature -> $targetFeature';
}

List<CrossFeatureImport> findDisallowedCrossFeatureImports(
  List<CrossFeatureImport> imports,
  Map<String, Set<String>> allowlist,
) => imports
    .where(
      (i) => !(allowlist[i.sourceFeature]?.contains(i.targetFeature) ?? false),
    )
    .toList();

final _importDirective = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

final _featurePackageUri = RegExp('^package:(feature_[a-z0-9_]+)/');

List<CrossFeatureImport> _collectCrossFeatureImports(
  Map<String, String> featurePackages,
  Set<String> featurePackageNames,
) {
  final results = <CrossFeatureImport>[];

  featurePackages.forEach((dirPath, ownName) {
    final libDir = Directory('$dirPath/lib');
    if (!libDir.existsSync()) return;

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final relPath = _posix(file.path);
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final match = _importDirective.firstMatch(lines[i]);
        if (match == null) continue;

        final uri = match.group(1)!;
        final pkgMatch = _featurePackageUri.firstMatch(uri);
        if (pkgMatch == null) continue;

        final targetFeature = pkgMatch.group(1)!;
        if (targetFeature == ownName) continue;
        if (!featurePackageNames.contains(targetFeature)) continue;

        results.add(
          CrossFeatureImport(
            file: relPath,
            line: i + 1,
            sourceFeature: ownName,
            targetFeature: targetFeature,
            uri: uri,
          ),
        );
      }
    }
  });

  return results;
}

List<String> _collectPrivateSrcAndRelativeEscapeViolations() {
  final violations = <String>[];
  final rootPubspecLines = File('pubspec.yaml').readAsLinesSync();
  final rootPkgName = _packageName(rootPubspecLines) ?? 'app';

  final packageRoots = <(String, String)>[('.', rootPkgName)];
  final packagesDir = Directory('packages');
  if (packagesDir.existsSync()) {
    for (final entity in packagesDir.listSync().whereType<Directory>()) {
      final pubspec = File('${entity.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        final name = _packageName(pubspec.readAsLinesSync());
        if (name != null) packageRoots.add((_posix(entity.path), name));
      } else {
        for (final child in entity.listSync().whereType<Directory>()) {
          final childPubspec = File('${child.path}/pubspec.yaml');
          if (!childPubspec.existsSync()) continue;
          final name = _packageName(childPubspec.readAsLinesSync());
          if (name != null) packageRoots.add((_posix(child.path), name));
        }
      }
    }
  }
  final revSyncPubspec = File('published/rev_sync/pubspec.yaml');
  if (revSyncPubspec.existsSync()) {
    final name = _packageName(revSyncPubspec.readAsLinesSync());
    if (name != null) packageRoots.add(('published/rev_sync', name));
  }

  for (final (pkgRoot, pkgName) in packageRoots) {
    final scanDirs = <String>[
      '$pkgRoot/lib',
      '$pkgRoot/test',
      if (pkgRoot == '.') '$pkgRoot/integration_test',
    ];
    for (final scanDir in scanDirs) {
      final dir = Directory(scanDir);
      if (!dir.existsSync()) continue;
      final isLibScan = scanDir.endsWith('/lib');
      for (final file
          in dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final relPath = _posix(file.path);
        violations.addAll(
          scanDirectivesForBoundaryViolations(
            owningPackage: pkgName,
            filePath: relPath,
            packageLibRoot: isLibScan ? _posix(dir.path) : null,
            lines: file.readAsLinesSync(),
          ),
        );
      }
    }
  }
  return violations;
}

List<String> scanDirectivesForBoundaryViolations({
  required String owningPackage,
  required String filePath,
  required String? packageLibRoot,
  required List<String> lines,
}) {
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final match = _importDirective.firstMatch(lines[i]);
    if (match == null) continue;
    final uri = match.group(1)!;
    if (uri.startsWith('package:')) {
      final slash = uri.indexOf('/');
      if (slash == -1) continue;
      final targetPkg = uri.substring('package:'.length, slash);
      final targetSubpath = uri.substring(slash + 1);
      if (targetPkg != owningPackage && targetSubpath.startsWith('src/')) {
        violations.add(
          '$filePath:${i + 1} ($owningPackage) has cross-package private import: $uri',
        );
      }
    } else if (!uri.startsWith('dart:') && packageLibRoot != null) {
      final normalizedLibRoot = _normalizePosix(packageLibRoot);
      final resolved = _normalizePosix('${_dirnamePosix(filePath)}/$uri');
      if (!resolved.startsWith('$normalizedLibRoot/') &&
          resolved != normalizedLibRoot) {
        violations.add(
          '$filePath:${i + 1} ($owningPackage) relative directive escapes $normalizedLibRoot: $uri',
        );
      }
    }
  }
  return violations;
}

String _dirnamePosix(String path) {
  final idx = path.lastIndexOf('/');
  return idx == -1 ? '.' : path.substring(0, idx);
}

String _normalizePosix(String path) {
  final parts = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (parts.isNotEmpty && parts.last != '..') {
        parts.removeLast();
      } else {
        parts.add('..');
      }
    } else {
      parts.add(segment);
    }
  }
  return parts.join('/');
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

String _posix(String path) => path.replaceAll(r'\', '/');
