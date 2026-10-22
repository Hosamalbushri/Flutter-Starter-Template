// Architecture guardrail: enforces lockfile reproducibility and guarantees
// that dependencies cannot mutate silently during CI or local builds.
//
// Rules enforced:
// 1. Root `pubspec.lock` must exist and must be tracked in version control (never ignored).
// 2. Published CLI `pubspec.lock` must exist when the submodule is present.
// 3. Every workspace package in root `pubspec.yaml` must exist and configure `resolution: workspace`.
// 4. Root `pubspec.lock` must pin hosted packages with sha256 integrity hashes.
// 5. `.github/workflows/ci.yml` must use `--enforce-lockfile` on dependency resolution steps
//    so CI never mutates lockfiles or hides dependency updates silently.
//
// Pure file-scan, runs in normal `fvm flutter test` / CI flow.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live workspace lockfile reproducibility', () {
    test('root pubspec.lock exists and is not ignored by git', () {
      final lockfile = File('pubspec.lock');
      expect(
        lockfile.existsSync(),
        isTrue,
        reason: 'Root pubspec.lock must be present for reproducible builds.',
      );

      final gitignore = File('.gitignore');
      if (gitignore.existsSync()) {
        final lines = gitignore.readAsLinesSync();
        final ignoresLockfile = lines.any((line) {
          final trimmed = line.trim();
          return trimmed == 'pubspec.lock' || trimmed == '/pubspec.lock';
        });
        expect(
          ignoresLockfile,
          isFalse,
          reason: 'pubspec.lock must NOT be ignored in .gitignore.',
        );
      }

      // Verify directly with the Git engine
      final gitResult = Process.runSync('git', [
        'check-ignore',
        'pubspec.lock',
      ]);
      expect(
        gitResult.exitCode,
        isNot(equals(0)),
        reason: 'git check-ignore reports pubspec.lock is ignored!',
      );
    });

    test('published/cli pubspec.lock exists when submodule is present', () {
      final cliDir = Directory('published/cli');
      if (!cliDir.existsSync()) return;

      final cliLockfile = File('published/cli/pubspec.lock');
      expect(
        cliLockfile.existsSync(),
        isTrue,
        reason:
            'published/cli/pubspec.lock must be committed to ensure CLI reproducibility.',
      );
    });

    test(
      'all workspace packages have valid pubspec with resolution: workspace',
      () {
        final pubspec = File('pubspec.yaml');
        if (!pubspec.existsSync()) return;

        final violations = validateWorkspacePackagesResolution(
          pubspecLines: pubspec.readAsLinesSync(),
          rootDir: Directory.current.path,
        );

        expect(
          violations,
          isEmpty,
          reason:
              'Workspace packages resolution violations:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );

    test('pubspec.lock pins hosted packages with sha256 integrity hashes', () {
      final lockfile = File('pubspec.lock');
      if (!lockfile.existsSync()) return;

      final violations = validateLockfileIntegrity(lockfile.readAsLinesSync());
      expect(
        violations,
        isEmpty,
        reason:
            'Lockfile integrity violations:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    });

    test('ci.yml enforces lockfile during dependency resolution steps', () {
      final ciFile = File('.github/workflows/ci.yml');
      if (!ciFile.existsSync()) return;

      final violations = validateCiEnforcesLockfile(ciFile.readAsLinesSync());
      expect(
        violations,
        isEmpty,
        reason:
            'CI workflow steps resolving dependencies without --enforce-lockfile:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    });
  });

  group('Lockfile validation regression tests (mutations)', () {
    test('passes on valid workspace packages configuration', () {
      const pubspec = '''
workspace:
  - packages/app_ui
  - packages/architecture
''';
      final violations = validateWorkspacePackagesResolution(
        pubspecLines: pubspec.split('\n'),
        rootDir: Directory.current.path,
      );
      expect(violations, isEmpty);
    });

    test(
      'detects workspace package missing pubspec or resolution: workspace',
      () {
        final violations = validateWorkspacePackagePubspecContent(
          path: 'packages/dummy_pkg',
          pubspecContent: 'name: dummy_pkg\nversion: 1.0.0\n',
        );
        expect(violations, isNotEmpty);
        expect(violations.first, contains('missing "resolution: workspace"'));
      },
    );

    test('detects hosted package in lockfile missing sha256 hash', () {
      const lockLines = [
        'packages:',
        '  bad_pkg:',
        '    source: hosted',
        '    version: "1.0.0"',
        '  good_pkg:',
        '    source: hosted',
        '    description:',
        '      sha256: "abc123"',
      ];
      final violations = validateLockfileIntegrity(lockLines);
      expect(violations, isNotEmpty);
      expect(violations.first, contains('bad_pkg'));
    });

    test('rejects CI dependency step that omits --enforce-lockfile', () {
      const ciLines = [
        '      - name: Install dependencies',
        '        run: flutter pub get',
      ];
      final violations = validateCiEnforcesLockfile(ciLines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains('missing --enforce-lockfile flag'),
      );
    });

    test(
      'allows scaffolded project smoke-tests to run plain pub get in temp directories',
      () {
        const ciLines = [
          '      - name: Run pub in freshly scaffolded project',
          '        working-directory: /tmp/test-project',
          '        run: flutter pub get',
        ];
        final violations = validateCiEnforcesLockfile(ciLines);
        expect(violations, isEmpty);
      },
    );

    test('detects path dependency pointing to non-existent directory', () {
      const lockLines = [
        'packages:',
        '  bogus_local:',
        '    source: path',
        '    version: "1.0.0"',
        '    description:',
        '      path: "non/existent/bogus/path"',
        '      relative: true',
      ];
      final violations = validateLockfileIntegrity(lockLines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains('points to non-existent path'),
      );
    });
  });
}

List<String> validateWorkspacePackagesResolution({
  required List<String> pubspecLines,
  required String rootDir,
}) {
  final violations = <String>[];
  var inWorkspace = false;
  final workspacePackagePaths = <String>[];

  for (final line in pubspecLines) {
    final trimmed = line.trim();
    if (trimmed == 'workspace:') {
      inWorkspace = true;
      continue;
    }
    if (inWorkspace &&
        line.isNotEmpty &&
        !line.startsWith(' ') &&
        !line.startsWith('\t')) {
      inWorkspace = false;
    }
    if (inWorkspace && trimmed.startsWith('-')) {
      final pkgPath = trimmed.substring(1).trim();
      if (pkgPath.isNotEmpty && !pkgPath.startsWith('#')) {
        workspacePackagePaths.add(pkgPath);
      }
    }
  }

  for (final relPath in workspacePackagePaths) {
    final pkgPubspec = File('$rootDir/$relPath/pubspec.yaml');
    if (!pkgPubspec.existsSync()) {
      violations.add(
        'Workspace package at "$relPath" is missing pubspec.yaml',
      );
      continue;
    }

    final content = pkgPubspec.readAsStringSync();
    violations.addAll(
      validateWorkspacePackagePubspecContent(
        path: relPath,
        pubspecContent: content,
      ),
    );
  }

  return violations;
}

List<String> validateWorkspacePackagePubspecContent({
  required String path,
  required String pubspecContent,
}) {
  final violations = <String>[];
  final hasResolutionWorkspace = RegExp(
    r'^\s*resolution:\s*workspace\s*$',
    multiLine: true,
  ).hasMatch(pubspecContent);

  if (!hasResolutionWorkspace) {
    violations.add(
      'Workspace package at "$path" is missing "resolution: workspace" in its pubspec.yaml',
    );
  }

  return violations;
}

List<String> validateLockfileIntegrity(List<String> lines) {
  final violations = <String>[];
  var currentPkg = '';
  var currentSource = '';
  var hasSha256 = false;

  void checkCurrent() {
    if (currentPkg.isNotEmpty && currentSource == 'hosted' && !hasSha256) {
      violations.add(
        'Hosted package "$currentPkg" in pubspec.lock has no sha256 checksum',
      );
    }
  }

  for (final line in lines) {
    final pkgMatch = RegExp('^  ([a-zA-Z0-9_]+):').firstMatch(line);
    if (pkgMatch != null) {
      checkCurrent();
      currentPkg = pkgMatch.group(1)!;
      currentSource = '';
      hasSha256 = false;
      continue;
    }

    final sourceMatch = RegExp(
      r'^\s*source:\s*([a-zA-Z0-9_]+)',
    ).firstMatch(line);
    if (sourceMatch != null) {
      currentSource = sourceMatch.group(1)!;
      continue;
    }

    if (line.contains('sha256:')) {
      hasSha256 = true;
    }

    final pathMatch = RegExp(r'^\s*path:\s*"([^"]+)"').firstMatch(line);
    if (pathMatch != null && currentSource == 'path') {
      final depPath = pathMatch.group(1)!;
      if (!Directory(depPath).existsSync() && !File(depPath).existsSync()) {
        violations.add(
          'Path dependency "$currentPkg" points to non-existent path: "$depPath"',
        );
      }
    }
  }
  checkCurrent();

  return violations;
}

List<String> validateCiEnforcesLockfile(List<String> lines) {
  final violations = <String>[];
  final pubGetRegex = RegExp(
    r'^\s*(?:run:\s*)?(?:fvm\s+)?(?:flutter|dart)\s+pub\s+get\b',
  );
  var currentStepName = '';
  var currentWorkingDir = '';

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.startsWith('- name:')) {
      currentStepName = trimmed;
      currentWorkingDir = '';
    }
    if (trimmed.startsWith('working-directory:')) {
      currentWorkingDir = trimmed;
    }

    if (pubGetRegex.hasMatch(trimmed)) {
      // Allow temp / newly scaffolded external smoke projects to run plain pub get
      final isTempOrScaffold =
          currentWorkingDir.contains('/tmp') ||
          currentWorkingDir.contains('runner.temp') ||
          currentStepName.toLowerCase().contains('scaffold');

      if (!isTempOrScaffold && !trimmed.contains('--enforce-lockfile')) {
        violations.add(
          'Line ${i + 1}: "$trimmed" is missing --enforce-lockfile flag in $currentStepName',
        );
      }
    }
  }

  return violations;
}
