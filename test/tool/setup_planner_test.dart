// Standalone test file for workspace setup tooling imports tool/lib directly
// and uses test package APIs.
// ignore_for_file: avoid_relative_lib_imports, depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/lib/src/fingerprint_store.dart';
import '../../tool/lib/src/setup_planner.dart';
import '../../tool/lib/src/sha256.dart';

void main() {
  group('Sha256 NIST & RFC 6234 Standards Compliance', () {
    test('Vector 1: Empty string', () {
      expect(
        Sha256.hashString(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('Vector 2: "abc"', () {
      expect(
        Sha256.hashString('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('Vector 3: Multi-block (56 bytes, boundary crossing)', () {
      const input = 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
      expect(
        Sha256.hashString(input),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('Vector 4: Streaming 1,000,000 repetitions of "a"', () {
      final sink = Sha256Sink();
      final chunk = utf8.encode('a' * 1000);
      for (var i = 0; i < 1000; i++) {
        sink.add(chunk);
      }
      expect(
        sink.close(),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
      );
    });

    test(
      'Streaming file hashing matches hashFileSync and hashString',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('sha256_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final testFile = File('${tempDir.path}/sample.txt');
        final content = 'The quick brown fox jumps over the lazy dog' * 500;
        testFile.writeAsStringSync(content);

        final syncHash = Sha256.hashFileSync(testFile);
        final asyncHash = await Sha256.hashFile(testFile);
        final memoryHash = Sha256.hashString(content);

        expect(syncHash, memoryHash);
        expect(asyncHash, memoryHash);
      },
    );
  });

  group('FingerprintStore Concurrency and Resilience', () {
    test(
      'acquireLock and releaseLock provide inter-process mutual exclusion',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('lock_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final store = FingerprintStore(rootDir: tempDir.path);

        // Create lock file directory and lock script
        final script = File('${tempDir.path}/lock_holder.dart');
        script.writeAsStringSync('''
import 'dart:io';
void main() {
  final file = File('${tempDir.path}/.dart_tool/fst_setup_cache/setup.lock');
  file.createSync(recursive: true);
  final raf = file.openSync(mode: FileMode.write);
  raf.lockSync(FileLock.exclusive);
  stdout.writeln('LOCKED');
  sleep(const Duration(milliseconds: 600));
  raf.unlockSync();
  raf.closeSync();
}
''');

        final proc = await Process.start(Platform.resolvedExecutable, [
          script.path,
        ]);
        // Wait until child script prints LOCKED
        await proc.stdout.transform(const SystemEncoding().decoder).first;

        // Attempting to lock while child holds it must timeout and return null
        final raf = store.acquireLock(
          timeout: const Duration(milliseconds: 100),
        );
        expect(raf, isNull);

        // Wait for child process to finish and release lock
        await proc.exitCode;

        // Now acquiring lock must succeed
        final acquiredRaf = store.acquireLock(
          timeout: const Duration(seconds: 2),
        );
        expect(acquiredRaf, isNotNull);
        store.releaseLock(acquiredRaf);
      },
    );

    test('atomic manifest write produces readable json', () {
      final tempDir = Directory.systemTemp.createTempSync('manifest_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final store = FingerprintStore(rootDir: tempDir.path);
      store.saveManifest({
        'version': 1,
        'environment_hash': 'test-env-hash',
        'packages': {'test_pkg': 'hash123'},
      });

      final loaded = store.loadManifest();
      expect(loaded['version'], 1);
      expect(loaded['environment_hash'], 'test-env-hash');
      expect((loaded['packages'] as Map)['test_pkg'], 'hash123');
    });

    test('corrupted manifest falls back to empty map gracefully', () {
      final tempDir = Directory.systemTemp.createTempSync('corrupt_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final cacheDir = Directory('${tempDir.path}/.dart_tool/fst_setup_cache');
      cacheDir.createSync(recursive: true);
      File(
        '${cacheDir.path}/manifest.json',
      ).writeAsStringSync('{ invalid json content ...');

      final store = FingerprintStore(rootDir: tempDir.path);
      final loaded = store.loadManifest();
      expect(loaded, isEmpty);
    });

    test('hashFiles is deterministic regardless of order', () {
      final store = FingerprintStore(rootDir: Directory.current.path);
      final files = ['pubspec.yaml', 'build.yaml'];
      final hash1 = store.hashFiles(files);
      final hash2 = store.hashFiles(files.reversed.toList());
      expect(hash1, hash2);
      expect(hash1, isNotEmpty);
    });
  });

  group('SetupPlanner Cache Invalidation & Planning', () {
    test('SetupPlanner detects up-to-date state correctly', () {
      final repoRoot = Directory.current.path;
      final store = FingerprintStore(rootDir: repoRoot);
      final planner = SetupPlanner(rootDir: repoRoot, store: store);

      final plan = planner.createPlan();
      expect(plan.pubGetNeeded, isFalse);
      expect(plan.l10nNeeded, isFalse);
      expect(plan.packagesNeedingCodegen, isEmpty);
      expect(plan.driftPackagesNeedingCodegen, isEmpty);
      expect(plan.appRootCodegenNeeded, isFalse);
      expect(plan.isCompletelyUpToDate, isTrue);
    });

    test('SetupPlanner invalidates when environment hash changes', () {
      final tempDir = Directory.systemTemp.createTempSync('env_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final store = FingerprintStore(rootDir: tempDir.path);
      // Simulate existing cache with outdated environment hash
      store.saveManifest({
        'version': 1,
        'environment_hash': 'outdated-sdk-hash',
        'dependencies_hash': store.hashDependencies(),
        'localization_hash': store.hashLocalizationInputs(),
      });

      // Create fake package_config.json so it doesn't fail on missing package_config
      final pkgConfig = File('${tempDir.path}/.dart_tool/package_config.json');
      pkgConfig.createSync(recursive: true);
      pkgConfig.writeAsStringSync('{}');

      final planner = SetupPlanner(rootDir: tempDir.path, store: store);
      final plan = planner.createPlan();

      expect(plan.pubGetNeeded, isTrue);
      expect(plan.pubGetReason, contains('environment version changed'));
    });

    test('SetupPlanner detects missing generated outputs', () {
      final tempDir = Directory.systemTemp.createTempSync('fst_setup_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final pkgDir = Directory('${tempDir.path}/packages/dummy');
      pkgDir.createSync(recursive: true);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync(
        'name: dummy\ndev_dependencies:\n  build_runner: ^2.4.0\n',
      );
      final libSrc = Directory('${pkgDir.path}/lib/src');
      libSrc.createSync(recursive: true);
      File(
        '${libSrc.path}/di.dart',
      ).writeAsStringSync('@InjectableInit.microPackage()\nvoid init() {}\n');

      final store = FingerprintStore(rootDir: tempDir.path);
      final planner = SetupPlanner(rootDir: tempDir.path, store: store);
      final plan = planner.createPlan();

      // di.module.dart is missing
      expect(plan.packagesNeedingCodegen.contains('packages/dummy'), isTrue);
      expect(
        plan.packageCodegenReasons['packages/dummy'],
        contains('di.module.dart is missing'),
      );
    });

    test('SetupPlanner invalidates package on build.yaml change', () {
      final tempDir = Directory.systemTemp.createTempSync('build_yaml_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final pkgDir = Directory('${tempDir.path}/packages/dummy');
      pkgDir.createSync(recursive: true);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync(
        'name: dummy\ndev_dependencies:\n  build_runner: ^2.4.0\n',
      );
      File('${pkgDir.path}/build.yaml').writeAsStringSync('targets: {}\n');

      final store = FingerprintStore(rootDir: tempDir.path);
      final initialHash = store.hashPackageCodegenInputs(pkgDir.path);

      // Save initial hash into manifest
      store.saveManifest({
        'version': 1,
        'environment_hash': store.hashEnvironment(),
        'packages': {'packages/dummy': initialHash},
      });

      // Modify build.yaml
      File(
        '${pkgDir.path}/build.yaml',
      ).writeAsStringSync('targets: {modified: true}\n');

      final planner = SetupPlanner(rootDir: tempDir.path, store: store);
      final plan = planner.createPlan();

      expect(plan.packagesNeedingCodegen.contains('packages/dummy'), isTrue);
      expect(
        plan.packageCodegenReasons['packages/dummy'],
        contains('Source or generator inputs have changed'),
      );
    });

    test('SetupPlanner forces full run when --full is specified', () {
      final repoRoot = Directory.current.path;
      final store = FingerprintStore(rootDir: repoRoot);
      final planner = SetupPlanner(
        rootDir: repoRoot,
        store: store,
        forceFull: true,
      );

      final plan = planner.createPlan();
      expect(plan.pubGetNeeded, isTrue);
      expect(plan.l10nNeeded, isTrue);
      expect(plan.packagesNeedingCodegen, isNotEmpty);
      expect(plan.appRootCodegenNeeded, isTrue);
      expect(plan.isCompletelyUpToDate, isFalse);
    });
  });
}
