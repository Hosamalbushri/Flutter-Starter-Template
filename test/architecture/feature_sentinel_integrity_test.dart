// Architecture guardrail: enforces symmetrical balance, valid nesting, and
// stripping safety of `// fst:` sentinel markers across all wiring and template
// files processed by the CLI.
//
// Rules enforced:
// 1. Every `fst:<marker>:start` sentinel must have a matching `fst:<marker>:end`.
// 2. No orphan `:end` without preceding `:start`.
// 3. No unclosed sentinels at end-of-file.
// 4. Feature sentinels (`fst:feature:*`) must never be nested inside another
//    feature sentinel (preventing accidental stripping cascades like PROB-08).
// 5. Simulating feature exclusion must leave balanced brackets and must not
//    corrupt file syntax or strip non-optional structural anchors.
//
// Pure file-scan, no third-party dependency; runs in `fvm flutter test` / CI.

import 'dart:io';

// The analyzer package is resolved transitively via build_runner;
// used here solely for static AST parsing in architecture test fixtures.
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:flutter_test/flutter_test.dart';

/// The canonical wiring files processed by `fst create` and `fst add-feature`.
const kKnownSentinelWiringFiles = [
  'pubspec.yaml',
  'lib/app/di/injection.dart',
  'lib/app/features.dart',
  'lib/app/router.dart',
  'lib/app/widgets/app_shell.dart',
  'lib/app/app.dart',
  'ios/Runner/Info.plist',
  'android/app/src/main/AndroidManifest.xml',
  'test/app/app_shell_navigation_test.dart',
  'test/architecture/di_module_ordering_test.dart',
  'test/architecture/package_layering_test.dart',
  'test/architecture/feature_boundaries_test.dart',
  'test/architecture/ios_permission_strings_test.dart',
];

void main() {
  group('Live workspace sentinel marker integrity', () {
    test(
      'all fst sentinels in known wiring files are balanced and correctly nested',
      () {
        final violations = <String>[];

        for (final relPath in kKnownSentinelWiringFiles) {
          final file = File(relPath);
          if (!file.existsSync()) continue;

          violations.addAll(
            validateSentinels(
              filePath: relPath,
              lines: file.readAsLinesSync(),
            ),
          );
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Sentinel marker violations found in wiring files:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );

    test(
      'simulated feature stripping leaves balanced brackets in Dart wiring files',
      () {
        const dartWiringFiles = [
          'lib/app/di/injection.dart',
          'lib/app/features.dart',
          'lib/app/router.dart',
          'lib/app/widgets/app_shell.dart',
          'test/architecture/package_layering_test.dart',
        ];

        final featuresToTest = [
          'bookmarks',
          'collections',
          'notifications',
          'document_center',
        ];
        final violations = <String>[];

        for (final relPath in dartWiringFiles) {
          final file = File(relPath);
          if (!file.existsSync()) continue;
          final original = file.readAsStringSync();

          for (final feature in featuresToTest) {
            final stripped = stripFeatureSentinels(original, feature);

            // Verify bracket balance on stripped content
            final bracketErrors = checkBracketBalance(stripped);
            if (bracketErrors.isNotEmpty) {
              violations.add(
                '$relPath when stripping feature "$feature" produced unbalanced brackets: '
                '${bracketErrors.join(", ")}',
              );
            }

            // Verify Dart AST syntax validity on stripped content
            final syntaxErrors = validateDartSyntax(stripped);
            if (syntaxErrors.isNotEmpty) {
              violations.add(
                '$relPath when stripping feature "$feature" produced invalid Dart syntax:\n'
                '${syntaxErrors.map((e) => "  $e").join("\n")}',
              );
            }

            // Verify no lingering unclosed sentinel for that feature
            if (stripped.contains('fst:feature:$feature:')) {
              violations.add(
                '$relPath still contains fst:feature:$feature sentinel fragments after stripping',
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Feature stripping simulation produced corrupted syntax:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );
  });

  group('Sentinel validation regression tests (mutations)', () {
    test('passes on valid balanced sentinels', () {
      const lines = [
        '// fst:feature:bookmarks:start',
        'import "package:feature_bookmarks/feature_bookmarks.dart";',
        '// fst:feature:bookmarks:end',
        '// fst:feature:collections:start',
        'import "package:feature_collections/feature_collections.dart";',
        '// fst:feature:collections:end',
      ];
      final violations = validateSentinels(filePath: 'test.dart', lines: lines);
      expect(violations, isEmpty);
    });

    test('rejects unclosed start sentinel at EOF', () {
      const lines = [
        '// fst:feature:bookmarks:start',
        'import "package:feature_bookmarks/feature_bookmarks.dart";',
      ];
      final violations = validateSentinels(filePath: 'test.dart', lines: lines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Unclosed sentinel marker "feature:bookmarks" opened at line 1',
        ),
      );
    });

    test('rejects orphan end sentinel without start', () {
      const lines = [
        '// fst:feature:bookmarks:end',
      ];
      final violations = validateSentinels(filePath: 'test.dart', lines: lines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Found ":end" for "feature:bookmarks" at line 1 without matching ":start"',
        ),
      );
    });

    test('rejects mismatched nested end sentinel', () {
      const lines = [
        '// fst:feature:bookmarks:start',
        '// fst:feature:collections:end',
      ];
      final violations = validateSentinels(filePath: 'test.dart', lines: lines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains('Mismatched marker: expected end of "feature:bookmarks"'),
      );
    });

    test('rejects illegal nesting of one feature marker inside another', () {
      const lines = [
        '// fst:feature:notifications:start',
        '// fst:feature:document_center:start',
        'import "package:feature_document_center/feature_document_center.dart";',
        '// fst:feature:document_center:end',
        '// fst:feature:notifications:end',
      ];
      final violations = validateSentinels(filePath: 'test.dart', lines: lines);
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Illegal nesting: feature marker "feature:document_center" at line 2 sits inside "feature:notifications"',
        ),
      );
    });

    test(
      'positive test: valid stripped Dart parses cleanly without syntax errors',
      () {
        const validDart = '''
void configure() {
  final list = <String>[];
  list.add('item');
}
''';
        final syntaxErrors = validateDartSyntax(validDart);
        expect(syntaxErrors, isEmpty);
      },
    );

    test(
      'negative / mutation test: catches corrupted Dart syntax after bad stripping',
      () {
        // Simulate bad stripping that cut mid-expression leaving invalid Dart syntax
        const brokenDart = '''
void configure() {
  final list = <String>[; // Syntax error: missing expression before semicolon
}
''';
        final syntaxErrors = validateDartSyntax(brokenDart);
        expect(syntaxErrors, isNotEmpty);
        expect(syntaxErrors.first, contains('Expected to find'));
      },
    );

    test(
      'false negative test: catches balanced brackets that contain invalid Dart statements',
      () {
        // Brackets are balanced (2 opening, 2 closing), but Dart syntax is invalid!
        const balancedButInvalid = '''
class AppShell {
  void build() {
    int x = ; // Brackets balanced, but statement broken!
  }
}
''';
        // Bracket checker says OK:
        expect(checkBracketBalance(balancedButInvalid), isEmpty);
        // But Dart AST validator correctly catches the failure:
        final syntaxErrors = validateDartSyntax(balancedButInvalid);
        expect(syntaxErrors, isNotEmpty);
      },
    );
  });
}

List<String> validateDartSyntax(String source) {
  try {
    final parseResult = parseString(content: source, throwIfDiagnostics: false);
    return parseResult.errors
        .where((e) => e.severity.name == 'error')
        .map((e) => 'Offset ${e.offset}: ${e.message}')
        .toList();
  } on Exception catch (e) {
    return ['Syntax parsing exception: $e'];
  }
}

final RegExp _sentinelPattern = RegExp(
  r'(?://|<!--|#)\s*fst:([a-zA-Z0-9_:-]+):(start|end)',
);

/// Known allowed feature nesting exceptions where feature A depends on feature B.
const _allowedFeatureNesting = <String, Set<String>>{
  // In app_shell.dart, collections quick-action is only rendered within bookmarks quickActions.
  'feature:bookmarks': {'feature:collections'},
};

List<String> validateSentinels({
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  final stack = <({String marker, int line})>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = _sentinelPattern.firstMatch(line);
    if (match == null) continue;

    final marker = match.group(1)!;
    final action = match.group(2)!;

    if (action == 'start') {
      // Rule 4: Prevent illegal feature-in-feature nesting (e.g. PROB-08: doc center in notifications)
      if (stack.isNotEmpty) {
        final parent = stack.last.marker;
        if (parent.startsWith('feature:') && marker.startsWith('feature:')) {
          final isAllowed =
              _allowedFeatureNesting[parent]?.contains(marker) ?? false;
          if (!isAllowed) {
            violations.add(
              '$filePath:${i + 1} Illegal nesting: feature marker "$marker" at line ${i + 1} '
              'sits inside "$parent" (opened at line ${stack.last.line}). Each feature must have independent sentinels.',
            );
          }
        }
      }
      stack.add((marker: marker, line: i + 1));
    } else if (action == 'end') {
      if (stack.isEmpty) {
        violations.add(
          '$filePath:${i + 1} Found ":end" for "$marker" at line ${i + 1} without matching ":start".',
        );
      } else {
        final top = stack.removeLast();
        if (top.marker != marker) {
          violations.add(
            '$filePath:${i + 1} Mismatched marker: expected end of "${top.marker}" '
            '(opened at line ${top.line}), but found "$marker" at line ${i + 1}.',
          );
        }
      }
    }
  }

  // Rule 3: Assert no unclosed markers left on stack
  if (stack.isNotEmpty) {
    for (final unclosed in stack) {
      violations.add(
        '$filePath:${unclosed.line} Unclosed sentinel marker "${unclosed.marker}" '
        'opened at line ${unclosed.line} reaches end-of-file without matching :end.',
      );
    }
  }

  return violations;
}

String stripFeatureSentinels(String content, String feature) {
  final startNeedle = 'fst:feature:$feature:start';
  final endNeedle = 'fst:feature:$feature:end';
  final kept = <String>[];
  var skipping = false;

  for (final line in content.split('\n')) {
    if (skipping) {
      if (line.contains(endNeedle)) skipping = false;
      continue;
    }
    if (line.contains(startNeedle)) {
      skipping = true;
      continue;
    }
    kept.add(line);
  }
  return kept.join('\n');
}

List<String> checkBracketBalance(String source) {
  final errors = <String>[];
  final stack = <String>[];
  final pairs = {'(': ')', '[': ']', '{': '}'};

  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (pairs.containsKey(char)) {
      stack.add(char);
    } else if (pairs.containsValue(char)) {
      if (stack.isEmpty) {
        errors.add('Unexpected closing bracket "$char"');
        break;
      }
      final open = stack.removeLast();
      if (pairs[open] != char) {
        errors.add('Mismatched brackets: "$open" closed by "$char"');
        break;
      }
    }
  }

  if (stack.isNotEmpty) {
    errors.add('Unclosed brackets remaining: ${stack.join(", ")}');
  }

  return errors;
}
