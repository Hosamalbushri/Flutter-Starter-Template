import 'dart:convert';
import 'dart:io';

import 'sha256.dart';

/// Computes deterministic fingerprints and tracks cache state for workspace setup.
final class FingerprintStore {
  FingerprintStore({required this.rootDir});

  final String rootDir;

  String get cacheDir => '$rootDir/.dart_tool/fst_setup_cache';
  String get manifestPath => '$cacheDir/manifest.json';
  String get lockPath => '$cacheDir/setup.lock';

  /// Acquires an exclusive file lock to protect concurrent setup runs.
  RandomAccessFile? acquireLock({
    Duration timeout = const Duration(seconds: 30),
  }) {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final lockFile = File(lockPath);
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed <= timeout) {
      RandomAccessFile? raf;
      try {
        raf = lockFile.openSync(mode: FileMode.write);
        raf.lockSync(FileLock.exclusive);
        return raf;
      } on FileSystemException {
        try {
          raf?.closeSync();
        } on Object catch (_) {}
        sleep(const Duration(milliseconds: 100));
      }
    }
    return null;
  }

  void releaseLock(RandomAccessFile? raf) {
    if (raf == null) return;
    try {
      raf.unlockSync();
      raf.closeSync();
    } on Object catch (_) {}
  }

  /// Atomically writes manifest data by writing to a temporary file then renaming.
  void saveManifest(Map<String, dynamic> data) {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final tmpFile = File(
      '$manifestPath.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}',
    );
    tmpFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    tmpFile.renameSync(manifestPath);
  }

  Map<String, dynamic> loadManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Corrupt or invalid JSON; fallback to empty cache safely
    } on Object catch (_) {
      // Any I/O read failure falls back to empty cache
    }
    return <String, dynamic>{};
  }

  /// Hashes toolchain and generator environments.
  String hashEnvironment() {
    final buffer = StringBuffer();
    // Dart SDK version
    buffer.write('dart:${Platform.version}\n');

    // .fvmrc version
    final fvmrc = File('$rootDir/.fvmrc');
    if (fvmrc.existsSync()) {
      buffer.write('fvmrc:${fvmrc.readAsStringSync().trim()}\n');
    }

    // Generator versions in pubspec.lock
    final lockFile = File('$rootDir/pubspec.lock');
    if (lockFile.existsSync()) {
      final content = lockFile.readAsStringSync();
      const trackedGenerators = [
        'build_runner',
        'freezed',
        'injectable_generator',
        'drift_dev',
        'go_router_builder',
        'retrofit_generator',
        'json_serializable',
        'flutter_gen_runner',
      ];
      for (final gen in trackedGenerators) {
        final match = RegExp(
          '  $gen:\\s*\\n\\s*dependency:[^\\n]*\\n\\s*description:[^\\n]*\\n\\s*source:[^\\n]*\\n\\s*version:\\s*"([^"]+)"',
        ).firstMatch(content);
        if (match != null) {
          buffer.write('$gen:${match.group(1)}\n');
        }
      }
    }

    return Sha256.hashString(buffer.toString());
  }

  /// Computes a deterministic sha256 hash across multiple files.
  /// Paths are sorted and relative to `rootDir`.
  String hashFiles(List<String> filePaths) {
    final buffer = StringBuffer();
    final sorted = List<String>.from(filePaths)..sort();
    for (final path in sorted) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final rel = path.startsWith(rootDir)
          ? path
                .substring(rootDir.length)
                .replaceAll(r'\', '/')
                .replaceFirst(RegExp('^/'), '')
          : path;
      buffer.write('$rel:${Sha256.hashFileSync(file)}\n');
    }
    return Sha256.hashString(buffer.toString());
  }

  /// Hashes all relevant input files for code generation in a package directory.
  /// Excludes .dart_tool, build, and generated files (*.g.dart, *.freezed.dart, etc.).
  String hashPackageCodegenInputs(String packageDir) {
    final dir = Directory(packageDir);
    if (!dir.existsSync()) return '';

    final relevantFiles = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final p = entity.path.replaceAll(r'\', '/');
      if (p.contains('/.dart_tool/') || p.contains('/build/')) continue;

      final name = p.split('/').last;
      if (name.endsWith('.g.dart') ||
          name.endsWith('.freezed.dart') ||
          name.endsWith('.config.dart')) {
        continue;
      }

      // Track dart source, yaml configurations, arb files, json models, drift schemas
      if (name.endsWith('.dart') ||
          name.endsWith('.yaml') ||
          name.endsWith('.arb') ||
          name.endsWith('.json')) {
        relevantFiles.add(p);
      }
    }

    relevantFiles.sort();
    return hashFiles(relevantFiles);
  }

  /// Hashes dependency inputs (all pubspec.yaml across the workspace + root pubspec.lock).
  String hashDependencies() {
    final files = <String>[];
    final rootPubspec = '$rootDir/pubspec.yaml';
    final rootLock = '$rootDir/pubspec.lock';
    if (File(rootPubspec).existsSync()) files.add(rootPubspec);
    if (File(rootLock).existsSync()) files.add(rootLock);

    final packagesDir = Directory('$rootDir/packages');
    if (packagesDir.existsSync()) {
      for (final entity in packagesDir.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('pubspec.yaml')) {
          if (!entity.path.contains('/.dart_tool/')) {
            files.add(entity.path);
          }
        }
      }
    }
    return hashFiles(files);
  }

  /// Hashes localization inputs (`packages/localization/l10n.yaml` and `packages/localization/lib/l10n/*.arb`).
  String hashLocalizationInputs() {
    final files = <String>[];
    final l10nYaml = '$rootDir/packages/localization/l10n.yaml';
    if (File(l10nYaml).existsSync()) files.add(l10nYaml);

    final l10nDir = Directory('$rootDir/packages/localization/lib/l10n');
    if (l10nDir.existsSync()) {
      for (final entity in l10nDir.listSync(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.arb')) {
          files.add(entity.path);
        }
      }
    }
    return hashFiles(files);
  }
}
