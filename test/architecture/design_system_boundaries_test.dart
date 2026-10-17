import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared design token authorities are defined only by app_ui', () {
    final violations = <String>[];
    final authority = Directory('packages/app_ui/lib/src').absolute.path;
    final declaration = RegExp(
      r'\bclass\s+(AppColorPalette|AppTheme|AppTypography|AppSpacing|AppRadius|AppElevation|AppIconSize|AppDurations|AppBreakpoints|AppBorderWidth|SemanticColors)\b',
    );

    for (final file in _workspaceLibFiles()) {
      for (final match in declaration.allMatches(file.readAsStringSync())) {
        if (!file.absolute.path.startsWith(authority)) {
          violations.add('${file.path} redefines ${match.group(1)}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('app_ui has no feature dependencies or imports', () {
    final violations = <String>[];
    final pubspec = File('packages/app_ui/pubspec.yaml').readAsLinesSync();
    for (var index = 0; index < pubspec.length; index++) {
      if (RegExp(r'^\s+feature_[a-z0-9_]+:').hasMatch(pubspec[index])) {
        violations.add(
          'packages/app_ui/pubspec.yaml:${index + 1} ${pubspec[index]}',
        );
      }
    }
    for (final file
        in Directory('packages/app_ui/lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (lines[index].contains('package:feature_')) {
          violations.add('${file.path}:${index + 1} ${lines[index]}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('production libraries do not import another package private src', () {
    final violations = <String>[];
    for (final package in _packageRoots()) {
      final packageName = _packageName(File('${package.path}/pubspec.yaml'));
      final lib = Directory('${package.path}/lib');
      if (!lib.existsSync()) continue;
      for (final file
          in lib
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final match = RegExp(
            r'''import\s+['"]package:([^/'"]+)/src/''',
          ).firstMatch(lines[index]);
          if (match != null && match.group(1) != packageName) {
            violations.add(
              '${file.path}:${index + 1} imports ${match.group(1)}/src',
            );
          }
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('shared components do not embed component colors', () {
    final violations = <String>[];
    final allowedMediaFiles = <String>{
      'app_photo_view.dart',
      'app_photo_view_fullscreen.dart',
      'app_ui_showcase.dart',
    };
    for (final file
        in Directory('packages/app_ui/lib/src/widgets')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => !allowedMediaFiles.contains(file.uri.pathSegments.last),
            )) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trimLeft();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (RegExp(r'\bColors\.|\bColor\(0x').hasMatch(line)) {
          violations.add('${file.path}:${index + 1} $line');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('shared components do not add hard-coded user-facing copy', () {
    final violations = <String>[];
    final userFacingLiteral = RegExp(
      r'''(?:Text\(\s*|(?:tooltip|label|hintText|errorText|semanticLabel|message)\s*:\s*)['"][A-Za-z]''',
    );
    for (final file
        in Directory('packages/app_ui/lib/src/widgets')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where(
              (file) => file.uri.pathSegments.last != 'app_ui_showcase.dart',
            )) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index].trimLeft();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (userFacingLiteral.hasMatch(line)) {
          violations.add('${file.path}:${index + 1} $line');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

Iterable<File> _workspaceLibFiles() sync* {
  for (final root in _packageRoots()) {
    final lib = Directory('${root.path}/lib');
    if (!lib.existsSync()) continue;
    yield* lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }
}

Iterable<Directory> _packageRoots() sync* {
  yield Directory('.');
  yield* Directory('packages').listSync().whereType<Directory>().where(
    (directory) => File('${directory.path}/pubspec.yaml').existsSync(),
  );
}

String _packageName(File pubspec) {
  final line = pubspec.readAsLinesSync().firstWhere(
    (line) => line.startsWith('name:'),
  );
  return line.substring('name:'.length).trim();
}
