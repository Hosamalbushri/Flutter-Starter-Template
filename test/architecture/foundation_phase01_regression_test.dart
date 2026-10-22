// Architecture guardrail: prevents regressions for Phase 01 Foundation items:
// 1. Android Release signing security (no debug keystore fallback in production).
// 2. Document engine offline asset integrity and font licensing.
// 3. Submodule registration and workspace checkout integrity.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 01: Android Release Security', () {
    late final String buildGradleContent;

    setUpAll(() {
      final file = File('android/app/build.gradle.kts');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'android/app/build.gradle.kts must exist',
      );
      buildGradleContent = file.readAsStringSync();
    });

    test('release build never falls back to debug signing config', () {
      expect(
        buildGradleContent,
        isNot(contains('signingConfigs.getByName("debug")')),
        reason:
            'Release builds must never silently fall back to debug signing keys',
      );
    });

    test('production release fails fast if key.properties is absent', () {
      expect(
        buildGradleContent,
        contains('requestedProdRelease'),
        reason: 'Must detect tasks targeting ProdRelease',
      );
      expect(
        buildGradleContent,
        contains('throw GradleException('),
        reason: 'Must fail the build if production keystore is missing',
      );
    });

    test(
      'release signing config is only instantiated when keystore exists',
      () {
        expect(
          buildGradleContent,
          contains('if (keystorePropertiesFile.exists())'),
        );
        expect(
          buildGradleContent,
          contains('signingConfig = signingConfigs.getByName("release")'),
        );
      },
    );
  });

  group('Phase 01: Document Engine Asset & License Integrity', () {
    test('DejaVu license file is present with Bitstream Vera terms', () {
      if (!Directory('packages/document_engine').existsSync()) return;
      final licenseFile = File(
        'packages/document_engine/LICENSES/DejaVu-Fonts.txt',
      );
      expect(
        licenseFile.existsSync(),
        isTrue,
        reason: 'Bundled DejaVu font license file must be preserved in-tree',
      );

      final content = licenseFile.readAsStringSync();
      expect(content, contains('DejaVu Fonts'));
      expect(content, contains('Bitstream Vera'));
      expect(content, contains('Permission is hereby granted, free of charge'));
    });

    test('bundled DejaVu sans font definitions are valid base64 payloads', () {
      if (!Directory('packages/document_engine').existsSync()) return;
      final sourceFile = File(
        'packages/document_engine/lib/src/pdf/bundled_dejavu_sans.dart',
      );
      expect(
        sourceFile.existsSync(),
        isTrue,
        reason: 'bundled_dejavu_sans.dart must exist in-tree',
      );

      final source = sourceFile.readAsStringSync();
      expect(source, contains('const bundledDejaVuSansRegularBase64 ='));
      expect(source, contains('const bundledDejaVuSansBoldBase64 ='));

      const startMarker = "const bundledDejaVuSansRegularBase64 = '''";
      final startIndex = source.indexOf(startMarker);
      expect(
        startIndex,
        isNonNegative,
        reason: 'Regular font base64 payload marker must exist',
      );

      final contentStart = startIndex + startMarker.length;
      final endIndex = source.indexOf("''';", contentStart);
      expect(endIndex, greaterThan(contentStart));

      final rawPayload = source.substring(contentStart, endIndex);
      final cleanBase64 = rawPayload.replaceAll(RegExp(r'\s'), '');
      expect(
        cleanBase64.length,
        greaterThan(100000),
        reason: 'Font data must contain valid font bytes',
      );

      // Verify it decodes to true TTF header bytes (0x00, 0x01, 0x00, 0x00 or 'OTTO')
      final decoded = base64Decode(cleanBase64.substring(0, 100));
      expect(decoded.length, greaterThan(10));
      final isTtfOrOpenType =
          (decoded[0] == 0x00 &&
              decoded[1] == 0x01 &&
              decoded[2] == 0x00 &&
              decoded[3] == 0x00) ||
          (decoded[0] == 0x4F &&
              decoded[1] == 0x54 &&
              decoded[2] == 0x54 &&
              decoded[3] == 0x4F);
      expect(
        isTtfOrOpenType,
        isTrue,
        reason: 'Payload must begin with TrueType or OpenType magic bytes',
      );
    });

    test(
      'all document_engine source files are present without broken relative imports',
      () {
        final libDir = Directory('packages/document_engine/lib');
        if (!libDir.existsSync()) return;
        final files = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in files) {
          final lines = file.readAsLinesSync();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith("import '") ||
                trimmed.startsWith("part '")) {
              final uri = trimmed.split("'")[1];
              if (uri.startsWith('package:') || uri.startsWith('dart:')) {
                continue;
              }
              final resolvedFile = File('${file.parent.path}/$uri');
              expect(
                resolvedFile.existsSync(),
                isTrue,
                reason:
                    'Relative import "$uri" in ${file.path} must resolve on disk',
              );
            }
          }
        }
      },
    );
  });

  group('Phase 01: Submodule and Tree Registration Integrity', () {
    test('.gitmodules paths exist in workspace', () {
      final gitmodules = File('.gitmodules');
      // Generated projects deliberately start as clean repositories with
      // vendored source and no submodule metadata.
      if (!gitmodules.existsSync()) return;

      final lines = gitmodules.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('path = ')) {
          final submodulePath = trimmed.substring('path = '.length).trim();
          final dir = Directory(submodulePath);
          expect(
            dir.existsSync(),
            isTrue,
            reason:
                'Submodule path "$submodulePath" declared in .gitmodules must exist on disk',
          );
        }
      }
    });
  });
}
