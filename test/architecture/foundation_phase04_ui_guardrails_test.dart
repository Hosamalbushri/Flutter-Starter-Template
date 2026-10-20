import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature presentation code does not define raw color constants', () {
    final roots = [
      Directory(
        'packages/features/bookmarks/lib/src/presentation/widgets/detail',
      ),
      Directory('packages/features/document_center/lib/src/presentation'),
    ];
    final violations = <String>[];
    for (final root in roots) {
      for (final file
          in root
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        if (source.contains('Color(0x') ||
            RegExp(r'\bColors\.').hasMatch(source)) {
          violations.add(file.path);
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Feature UI must consume ColorScheme/SemanticColors tokens.',
    );
  });

  test('Document Center has no directly embedded Text literals', () {
    final root = Directory(
      'packages/features/document_center/lib/src/presentation',
    );
    final literal = RegExp(r'''Text\(\s*(?:const\s+)?['\"]''');
    final violations = <String>[];
    for (final file
        in root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      if (literal.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty);
  });

  test('bookmark detail does not reintroduce feature-owned color tokens', () {
    expect(
      File(
        'packages/features/bookmarks/lib/src/presentation/widgets/detail/'
        'bookmark_detail_colors.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('Android predictive back callback is explicitly enabled', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:enableOnBackInvokedCallback="true"'),
    );
  });
}
