import 'dart:convert';
import 'dart:io';

import 'lib/src/fingerprint_store.dart';
import 'lib/src/setup_planner.dart';

void printUsage() {
  stdout.writeln('''
Usage: dart tool/setup_planner.dart [options]

Modes:
  --plan         Analyze workspace and output plan as JSON (for setup.sh / CI).
  --commit       Update stored fingerprint cache after successful execution.
  --verify       Verify that all cached fingerprints and generated files are intact.
  --dry-run      Inspect what would run without executing or modifying cache.
  --full         Force full setup (invalidates all cached states in the plan).
  --fast         Fast check mode.

Options:
  -h, --help     Show this help message.
''');
}

void main(List<String> args) {
  var mode = 'plan';
  var forceFull = false;
  var fastMode = false;

  for (final arg in args) {
    switch (arg) {
      case '--plan':
        mode = 'plan';
      case '--commit':
        mode = 'commit';
      case '--verify':
        mode = 'verify';
      case '--dry-run':
        mode = 'dry-run';
      case '--full':
        forceFull = true;
      case '--fast':
        fastMode = true;
      case '-h':
      case '--help':
        printUsage();
        exit(0);
      default:
        stderr.writeln('Unknown argument: $arg');
        printUsage();
        exit(1);
    }
  }

  final repoRoot = Directory.current.path;
  final store = FingerprintStore(rootDir: repoRoot);
  final planner = SetupPlanner(
    rootDir: repoRoot,
    store: store,
    forceFull: forceFull,
    fastMode: fastMode,
  );

  final plan = planner.createPlan();

  if (mode == 'plan') {
    final output = <String, dynamic>{
      'is_up_to_date': plan.isCompletelyUpToDate,
      'pub_get_needed': plan.pubGetNeeded,
      'pub_get_reason': plan.pubGetReason,
      'l10n_needed': plan.l10nNeeded,
      'l10n_reason': plan.l10nReason,
      'packages_needing_codegen': plan.packagesNeedingCodegen,
      'package_codegen_reasons': plan.packageCodegenReasons,
      'drift_packages_needing_codegen': plan.driftPackagesNeedingCodegen,
      'drift_reasons': plan.driftReasons,
      'app_root_codegen_needed': plan.appRootCodegenNeeded,
      'app_root_codegen_reason': plan.appRootCodegenReason,
    };
    stdout.writeln(jsonEncode(output));
    exit(0);
  }

  if (mode == 'dry-run') {
    stdout.writeln('=== Setup Dry Run Plan ===');
    stdout.writeln(
      'Pub get needed: ${plan.pubGetNeeded} (${plan.pubGetReason})',
    );
    stdout.writeln(
      'Localization needed: ${plan.l10nNeeded} (${plan.l10nReason})',
    );
    stdout.writeln(
      'Packages needing codegen: ${plan.packagesNeedingCodegen.length}',
    );
    for (final pkg in plan.packagesNeedingCodegen) {
      stdout.writeln('  • $pkg: ${plan.packageCodegenReasons[pkg]}');
    }
    stdout.writeln(
      'Drift packages needing codegen: ${plan.driftPackagesNeedingCodegen.length}',
    );
    for (final pkg in plan.driftPackagesNeedingCodegen) {
      stdout.writeln('  • $pkg: ${plan.driftReasons[pkg]}');
    }
    stdout.writeln(
      'App root codegen needed: ${plan.appRootCodegenNeeded} (${plan.appRootCodegenReason})',
    );
    stdout.writeln(
      'Summary: ${plan.isCompletelyUpToDate ? "UP TO DATE (can skip all)" : "CHANGES DETECTED"}',
    );
    exit(0);
  }

  if (mode == 'verify') {
    stdout.writeln('▶ Verifying workspace setup state…');
    if (plan.isCompletelyUpToDate) {
      stdout.writeln(
        '✓ Workspace setup is completely verified and up to date.',
      );
      exit(0);
    } else {
      stderr.writeln(
        '✖ Workspace setup verification failed. Pending operations:',
      );
      if (plan.pubGetNeeded) {
        stderr.writeln('  • pub get: ${plan.pubGetReason}');
      }
      if (plan.l10nNeeded) {
        stderr.writeln('  • localization: ${plan.l10nReason}');
      }
      for (final pkg in plan.packagesNeedingCodegen) {
        stderr.writeln('  • $pkg: ${plan.packageCodegenReasons[pkg]}');
      }
      for (final pkg in plan.driftPackagesNeedingCodegen) {
        stderr.writeln('  • $pkg: ${plan.driftReasons[pkg]}');
      }
      if (plan.appRootCodegenNeeded) {
        stderr.writeln('  • app root: ${plan.appRootCodegenReason}');
      }
      exit(1);
    }
  }

  if (mode == 'commit') {
    final lock = store.acquireLock();
    try {
      // Read current manifest, update with latest computed hashes
      final manifest = store.loadManifest();
      manifest['environment_hash'] = plan.environmentHash;
      manifest['dependencies_hash'] = plan.pubGetHash;
      manifest['localization_hash'] = plan.l10nHash;
      manifest['app_root_codegen_hash'] = plan.appRootCodegenHash;

      final packages =
          (manifest['packages'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      for (final entry in plan.packageCodegenHashes.entries) {
        packages[entry.key] = {
          'hash': entry.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
      manifest['packages'] = packages;

      final driftPackages =
          (manifest['drift_packages'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      for (final entry in plan.driftHashes.entries) {
        driftPackages[entry.key] = {
          'hash': entry.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
      manifest['drift_packages'] = driftPackages;

      store.saveManifest(manifest);
      stdout.writeln('✓ Setup manifest committed.');
      exit(0);
    } finally {
      store.releaseLock(lock);
    }
  }
}
