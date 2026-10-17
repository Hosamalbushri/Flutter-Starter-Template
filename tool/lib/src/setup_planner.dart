import 'dart:io';

import 'fingerprint_store.dart';

final class SetupPlanner {
  SetupPlanner({
    required this.rootDir,
    required this.store,
    this.forceFull = false,
    this.fastMode = false,
  });

  final String rootDir;
  final FingerprintStore store;
  final bool forceFull;
  final bool fastMode;

  /// Inspects current state against stored manifest and returns plan.
  SetupPlan createPlan() {
    final manifest = forceFull ? <String, dynamic>{} : store.loadManifest();

    final currentEnvHash = store.hashEnvironment();
    final cachedEnvHash = manifest['environment_hash'] as String?;
    final envChanged = cachedEnvHash != null && cachedEnvHash != currentEnvHash;

    final pubGetNeeded = _checkPubGet(manifest, envChanged);
    final l10nNeeded = _checkLocalization(manifest, envChanged);
    final codegenPackages = _checkCodegenPackages(manifest, envChanged);
    final driftPackages = _checkDriftPackages(manifest, envChanged);
    final appRootCodegenNeeded = _checkAppRootCodegen(
      manifest,
      codegenPackages,
      envChanged,
    );

    return SetupPlan(
      environmentHash: currentEnvHash,
      pubGetNeeded: pubGetNeeded.needed,
      pubGetReason: pubGetNeeded.reason,
      pubGetHash: pubGetNeeded.newHash,
      l10nNeeded: l10nNeeded.needed,
      l10nReason: l10nNeeded.reason,
      l10nHash: l10nNeeded.newHash,
      packagesNeedingCodegen: codegenPackages.neededPackages,
      packageCodegenReasons: codegenPackages.reasons,
      packageCodegenHashes: codegenPackages.newHashes,
      appRootCodegenNeeded: appRootCodegenNeeded.needed,
      appRootCodegenReason: appRootCodegenNeeded.reason,
      appRootCodegenHash: appRootCodegenNeeded.newHash,
      driftPackagesNeedingCodegen: driftPackages.neededPackages,
      driftReasons: driftPackages.reasons,
      driftHashes: driftPackages.newHashes,
    );
  }

  _CheckResult _checkPubGet(Map<String, dynamic> manifest, bool envChanged) {
    final packageConfig = File('$rootDir/.dart_tool/package_config.json');
    if (!packageConfig.existsSync()) {
      return const _CheckResult(
        needed: true,
        reason: 'package_config.json is missing',
        newHash: '',
      );
    }

    final newHash = store.hashDependencies();
    final cachedHash = manifest['dependencies_hash'] as String?;

    if (cachedHash == null) {
      return _CheckResult(
        needed: true,
        reason: 'No previous dependency cache record found',
        newHash: newHash,
      );
    }
    if (envChanged) {
      return _CheckResult(
        needed: true,
        reason: 'SDK or generator environment version changed',
        newHash: newHash,
      );
    }
    if (cachedHash != newHash) {
      return _CheckResult(
        needed: true,
        reason: 'pubspec or pubspec.lock has changed',
        newHash: newHash,
      );
    }

    return _CheckResult(
      needed: false,
      reason: 'Dependencies are up to date',
      newHash: newHash,
    );
  }

  _CheckResult _checkLocalization(
    Map<String, dynamic> manifest,
    bool envChanged,
  ) {
    final genFiles = [
      '$rootDir/packages/localization/lib/l10n/app_localizations.dart',
      '$rootDir/packages/localization/lib/l10n/app_localizations_en.dart',
      '$rootDir/packages/localization/lib/l10n/app_localizations_ar.dart',
    ];
    for (final f in genFiles) {
      if (!File(f).existsSync()) {
        return _CheckResult(
          needed: true,
          reason: 'Generated localization file ${f.split('/').last} is missing',
          newHash: '',
        );
      }
    }

    final newHash = store.hashLocalizationInputs();
    final cachedHash = manifest['localization_hash'] as String?;

    if (cachedHash == null) {
      return _CheckResult(
        needed: true,
        reason: 'No previous localization cache record found',
        newHash: newHash,
      );
    }
    if (envChanged) {
      return _CheckResult(
        needed: true,
        reason: 'SDK version changed',
        newHash: newHash,
      );
    }
    if (cachedHash != newHash) {
      return _CheckResult(
        needed: true,
        reason: 'ARB files or l10n.yaml have changed',
        newHash: newHash,
      );
    }

    return _CheckResult(
      needed: false,
      reason: 'Localization outputs are up to date',
      newHash: newHash,
    );
  }

  _PackageCheckResult _checkCodegenPackages(
    Map<String, dynamic> manifest,
    bool envChanged,
  ) {
    final candidateDirs = <String>[];
    final packagesDir = Directory('$rootDir/packages');
    if (packagesDir.existsSync()) {
      for (final entity in packagesDir.listSync()) {
        if (entity is Directory) {
          final pubspec = File('${entity.path}/pubspec.yaml');
          if (pubspec.existsSync()) {
            candidateDirs.add(entity.path.replaceAll(r'\', '/'));
          }
        }
      }
    }
    final featuresDir = Directory('$rootDir/packages/features');
    if (featuresDir.existsSync()) {
      for (final entity in featuresDir.listSync()) {
        if (entity is Directory) {
          final pubspec = File('${entity.path}/pubspec.yaml');
          if (pubspec.existsSync()) {
            candidateDirs.add(entity.path.replaceAll(r'\', '/'));
          }
        }
      }
    }

    candidateDirs.sort();

    final needed = <String>[];
    final reasons = <String, String>{};
    final newHashes = <String, String>{};
    final cachedPackages =
        (manifest['packages'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    for (final dir in candidateDirs) {
      final name = dir
          .substring(rootDir.length)
          .replaceAll(r'\', '/')
          .replaceFirst(RegExp('^/'), '');
      if (name == 'packages/database' || name == 'packages/database_drift') {
        continue; // Handled separately
      }

      final pubspec = File('$dir/pubspec.yaml');
      if (!pubspec.existsSync()) continue;
      final pubspecContent = pubspec.readAsStringSync();
      if (!pubspecContent.contains('build_runner')) {
        continue;
      }

      final inputHash = store.hashPackageCodegenInputs(dir);
      newHashes[name] = inputHash;

      // Verify required outputs exist
      final missingOutput = _findMissingGeneratedOutput(dir);
      if (missingOutput != null) {
        needed.add(name);
        reasons[name] = 'Generated output $missingOutput is missing';
        continue;
      }

      if (envChanged) {
        needed.add(name);
        reasons[name] = 'Generator or SDK version changed';
        continue;
      }

      final pkgEntry = cachedPackages[name];
      final cachedHash = pkgEntry is String
          ? pkgEntry
          : (pkgEntry is Map ? pkgEntry['hash'] as String? : null);
      if (cachedHash == null) {
        needed.add(name);
        reasons[name] = 'No previous cache record found for package';
        continue;
      }

      if (cachedHash != inputHash) {
        needed.add(name);
        reasons[name] = 'Source or generator inputs have changed';
        continue;
      }
    }

    return _PackageCheckResult(needed, reasons, newHashes);
  }

  _PackageCheckResult _checkDriftPackages(
    Map<String, dynamic> manifest,
    bool envChanged,
  ) {
    final candidateDirs = [
      '$rootDir/packages/database',
      '$rootDir/packages/database_drift',
    ];

    final needed = <String>[];
    final reasons = <String, String>{};
    final newHashes = <String, String>{};
    final cachedPackages =
        (manifest['drift_packages'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    for (final dir in candidateDirs) {
      if (!File('$dir/lib/src/app_database.dart').existsSync()) continue;
      final name = dir
          .substring(rootDir.length)
          .replaceAll(r'\', '/')
          .replaceFirst(RegExp('^/'), '');

      final gFile = File('$dir/lib/src/app_database.g.dart');
      final inputHash = store.hashPackageCodegenInputs(dir);
      newHashes[name] = inputHash;

      if (!gFile.existsSync()) {
        needed.add(name);
        reasons[name] = 'app_database.g.dart is missing';
        continue;
      }

      if (envChanged) {
        needed.add(name);
        reasons[name] = 'Drift generator or SDK version changed';
        continue;
      }

      final pkgEntry = cachedPackages[name];
      final cachedHash = pkgEntry is Map ? pkgEntry['hash'] as String? : null;
      if (cachedHash == null) {
        needed.add(name);
        reasons[name] = 'No previous cache record found for database package';
        continue;
      }

      if (cachedHash != inputHash) {
        needed.add(name);
        reasons[name] = 'Database schema or source inputs have changed';
        continue;
      }
    }

    return _PackageCheckResult(needed, reasons, newHashes);
  }

  _CheckResult _checkAppRootCodegen(
    Map<String, dynamic> manifest,
    _PackageCheckResult packageResult,
    bool envChanged,
  ) {
    final rootOutputs = [
      '$rootDir/lib/app/di/injection.config.dart',
      '$rootDir/lib/app/router.g.dart',
    ];
    for (final out in rootOutputs) {
      if (!File(out).existsSync()) {
        return _CheckResult(
          needed: true,
          reason: 'App root output ${out.split('/').last} is missing',
          newHash: '',
        );
      }
    }

    // App root depends on its own inputs (lib/**, test/**, pubspec.yaml, build.yaml)
    final rootDirEntity = Directory('$rootDir/lib');
    final rootFiles = <String>[
      '$rootDir/pubspec.yaml',
      '$rootDir/build.yaml',
    ];
    if (rootDirEntity.existsSync()) {
      for (final entity in rootDirEntity.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (!entity.path.endsWith('.config.dart') &&
              !entity.path.endsWith('.g.dart')) {
            rootFiles.add(entity.path);
          }
        }
      }
    }
    final newHash = store.hashFiles(rootFiles);

    // If any package regenerated code, the app root DI graph or router might need recompilation
    if (packageResult.neededPackages.isNotEmpty) {
      return _CheckResult(
        needed: true,
        reason:
            'Workspace packages changed: ${packageResult.neededPackages.join(', ')}',
        newHash: newHash,
      );
    }

    if (envChanged) {
      return _CheckResult(
        needed: true,
        reason: 'App root generator or SDK version changed',
        newHash: newHash,
      );
    }

    final cachedHash = manifest['app_root_codegen_hash'] as String?;
    if (cachedHash == null) {
      return _CheckResult(
        needed: true,
        reason: 'No previous app root codegen cache record found',
        newHash: newHash,
      );
    }
    if (cachedHash != newHash) {
      return _CheckResult(
        needed: true,
        reason: 'App root source or configuration changed',
        newHash: newHash,
      );
    }

    return _CheckResult(
      needed: false,
      reason: 'App root codegen is up to date',
      newHash: newHash,
    );
  }

  String? _findMissingGeneratedOutput(String packageDir) {
    // If package has @InjectableInit.microPackage(), check for di.module.dart
    final diFile = File('$packageDir/lib/src/di.dart');
    if (diFile.existsSync() &&
        diFile.readAsStringSync().contains('@InjectableInit.microPackage')) {
      final moduleFile = File('$packageDir/lib/src/di.module.dart');
      if (!moduleFile.existsSync()) {
        return 'lib/src/di.module.dart';
      }
    }

    // Check for part 'foo.g.dart' or part 'foo.freezed.dart'
    final dir = Directory('$packageDir/lib');
    if (dir.existsSync()) {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          final partMatches = RegExp(
            r'''part\s+['"]([^'"]+\.(?:g|freezed)\.dart)['"]''',
          ).allMatches(content);
          for (final match in partMatches) {
            final partName = match.group(1)!;
            final parentDir = entity.parent.path;
            final partFile = File('$parentDir/$partName');
            if (!partFile.existsSync()) {
              return '$parentDir/$partName'.replaceFirst('$packageDir/', '');
            }
          }
        }
      }
    }
    return null;
  }
}

final class _CheckResult {
  const _CheckResult({
    required this.needed,
    required this.reason,
    required this.newHash,
  });
  final bool needed;
  final String reason;
  final String newHash;
}

final class _PackageCheckResult {
  const _PackageCheckResult(this.neededPackages, this.reasons, this.newHashes);
  final List<String> neededPackages;
  final Map<String, String> reasons;
  final Map<String, String> newHashes;
}

final class SetupPlan {
  const SetupPlan({
    required this.environmentHash,
    required this.pubGetNeeded,
    required this.pubGetReason,
    required this.pubGetHash,
    required this.l10nNeeded,
    required this.l10nReason,
    required this.l10nHash,
    required this.packagesNeedingCodegen,
    required this.packageCodegenReasons,
    required this.packageCodegenHashes,
    required this.appRootCodegenNeeded,
    required this.appRootCodegenReason,
    required this.appRootCodegenHash,
    required this.driftPackagesNeedingCodegen,
    required this.driftReasons,
    required this.driftHashes,
  });

  final String environmentHash;

  final bool pubGetNeeded;
  final String pubGetReason;
  final String pubGetHash;

  final bool l10nNeeded;
  final String l10nReason;
  final String l10nHash;

  final List<String> packagesNeedingCodegen;
  final Map<String, String> packageCodegenReasons;
  final Map<String, String> packageCodegenHashes;

  final bool appRootCodegenNeeded;
  final String appRootCodegenReason;
  final String appRootCodegenHash;

  final List<String> driftPackagesNeedingCodegen;
  final Map<String, String> driftReasons;
  final Map<String, String> driftHashes;

  bool get isCompletelyUpToDate =>
      !pubGetNeeded &&
      !l10nNeeded &&
      packagesNeedingCodegen.isEmpty &&
      driftPackagesNeedingCodegen.isEmpty &&
      !appRootCodegenNeeded;
}
