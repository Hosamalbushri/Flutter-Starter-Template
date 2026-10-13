// Architecture guardrail: enforces localization, design-system, RTL/LTR, and
// domain-layer UI isolation boundaries across the workspace.

import 'dart:convert';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:localization/localization.dart';

void main() {
  test('domain-only packages and feature domain/ layers never import UI, localization, routing, or BLoC', () {
    final violations = <String>[];

    final domainDirectories = <Directory>[
      Directory('packages/architecture/lib'),
      Directory('packages/shared_contracts/lib'),
      Directory('published/rev_sync/lib'),
    ];
    final featuresDir = Directory('packages/features');
    if (featuresDir.existsSync()) {
      for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
        domainDirectories.add(Directory('${featureDir.path}/lib/src/domain'));
      }
    }

    for (final dir in domainDirectories) {
      if (!dir.existsSync()) continue;
      for (final file
          in dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        violations.addAll(
          scanDomainFileForUiImports(
            filePath: _posix(file.path),
            lines: file.readAsLinesSync(),
          ),
        );
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Domain-only packages and feature domain/ layers must remain free '
          'of UI, design-system, localization, routing, and presentation '
          'imports:\n\n${violations.map((v) => '  $v').join('\n')}',
    );
  });

  test('app_ui does not contain application-specific business domain strings', () {
    final violations = <String>[];
    final appUiLib = Directory('packages/app_ui/lib');
    for (final file
        in appUiLib
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      violations.addAll(
        scanSharedUiForBusinessTerms(
          filePath: _posix(file.path),
          lines: file.readAsLinesSync(),
        ),
      );
    }
    expect(
      violations,
      isEmpty,
      reason:
          'packages/app_ui must remain a generic design-system package without '
          'application-specific business copy:\n\n'
          '${violations.map((v) => '  $v').join('\n')}',
    );
  });

  test('feature packages do not duplicate design token classes or ThemeExtensions', () {
    final violations = <String>[];
    final featuresDir = Directory('packages/features');
    for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
      final libDir = Directory('${featureDir.path}/lib');
      if (!libDir.existsSync()) continue;
      for (final file
          in libDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        violations.addAll(
          scanFeatureFileForDuplicateTokens(
            filePath: _posix(file.path),
            lines: file.readAsLinesSync(),
          ),
        );
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Feature packages must use tokens from `package:app_ui` and '
          '`package:theme` instead of defining duplicate token classes:\n\n'
          '${violations.map((v) => '  $v').join('\n')}',
    );
  });

  test('every feature package uses app_ui and localization in its presentation layer', () {
    final violations = <String>[];
    final featuresDir = Directory('packages/features');
    for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
      final pubspecFile = File('${featureDir.path}/pubspec.yaml');
      if (!pubspecFile.existsSync()) continue;
      final pubspec = pubspecFile.readAsStringSync();
      final pkgName = _packageName(pubspec.split('\n')) ?? featureDir.path;

      if (!pubspec.contains('app_ui:')) {
        violations.add('$pkgName pubspec.yaml does not depend on app_ui');
      }
      if (!pubspec.contains('localization:')) {
        violations.add('$pkgName pubspec.yaml does not depend on localization');
      }

      final presentationDir = Directory(
        '${featureDir.path}/lib/src/presentation',
      );
      if (presentationDir.existsSync()) {
        final presentationSources = presentationDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map((f) => f.readAsStringSync())
            .join('\n');
        if (!presentationSources.contains(
          "import 'package:localization/localization.dart';",
        )) {
          violations.add(
            '$pkgName presentation layer does not import package:localization/localization.dart',
          );
        }
        if (!presentationSources.contains(
          "import 'package:app_ui/app_ui.dart';",
        )) {
          violations.add(
            '$pkgName presentation layer does not import package:app_ui/app_ui.dart',
          );
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('ARB localization catalogs maintain key parity, non-empty values, and placeholder parity across en, vi, and ar', () {
    final l10nDir = Directory('packages/localization/lib/l10n');
    final enMap = _decodeArb(File('${l10nDir.path}/app_en.arb'));
    final viMap = _decodeArb(File('${l10nDir.path}/app_vi.arb'));
    final arMap = _decodeArb(File('${l10nDir.path}/app_ar.arb'));

    final violations = scanArbCatalogsForIntegrity(
      referenceLocale: 'en',
      referenceArb: enMap,
      localizedArbs: {'vi': viMap, 'ar': arMap},
    );
    expect(
      violations,
      isEmpty,
      reason:
          'ARB catalogs must have complete, non-empty translations with '
          'matching placeholders:\n\n${violations.map((v) => '  $v').join('\n')}',
    );

    final supportedCodes = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    expect(supportedCodes, containsAll(['en', 'vi', 'ar']));
  });

  test('resolveSupportedLocale deterministically resolves exact, language-only, and unsupported locales', () {
    const supported = AppLocalizations.supportedLocales;

    expect(
      resolveSupportedLocale(const [Locale('ar')], supported),
      const Locale('ar'),
    );
    expect(
      resolveSupportedLocale(const [Locale('ar', 'EG')], supported),
      const Locale('ar'),
    );
    expect(
      resolveSupportedLocale(const [Locale('vi', 'VN')], supported),
      const Locale('vi'),
    );
    expect(
      resolveSupportedLocale(const [Locale('fr', 'FR'), Locale('ar')], supported),
      const Locale('ar'),
    );
    expect(
      resolveSupportedLocale(const [Locale('de', 'DE')], supported),
      const Locale('en'),
    );
    expect(
      resolveSupportedLocale(null, supported),
      const Locale('en'),
    );
    expect(
      resolveSupportedLocale(const [], supported),
      const Locale('en'),
    );
  });

  test('feature presentation layers do not introduce hard-coded user-facing UI strings', () {
    final violations = <String>[];
    final featuresDir = Directory('packages/features');
    for (final featureDir in featuresDir.listSync().whereType<Directory>()) {
      final presentationDir = Directory(
        '${featureDir.path}/lib/src/presentation',
      );
      if (!presentationDir.existsSync()) continue;
      for (final file
          in presentationDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        violations.addAll(
          scanPresentationForHardcodedText(
            filePath: _posix(file.path),
            lines: file.readAsLinesSync(),
          ),
        );
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature presentation widgets must use `context.l10n.*` instead of '
          'hard-coded user-facing string literals:\n\n'
          '${violations.map((v) => '  $v').join('\n')}',
    );
  });

  testWidgets('AppScaffold renders direction-aware back icon in LTR and RTL', (
    tester,
  ) async {
    Future<void> pumpWithDirection(TextDirection direction) async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Directionality(
                          textDirection: direction,
                          child: const AppScaffold(
                            title: 'Child',
                            body: SizedBox.shrink(),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
    }

    await pumpWithDirection(TextDirection.ltr);
    final ltrIcon = tester.widget<FaIcon>(find.byType(FaIcon));
    expect(ltrIcon.icon?.codePoint, FontAwesomeIcons.chevronLeft.codePoint);

    await pumpWithDirection(TextDirection.rtl);
    final rtlIcon = tester.widget<FaIcon>(find.byType(FaIcon));
    expect(rtlIcon.icon?.codePoint, FontAwesomeIcons.chevronRight.codePoint);
  });

  group('localization & UI boundary regression tests', () {
    test('accepts pure Dart / foundation imports in domain layer and rejects UI/routing/bloc imports', () {
      expect(
        scanDomainFileForUiImports(
          filePath:
              'packages/features/bookmarks/lib/src/domain/entities/bookmark.dart',
          lines: const [
            "import 'package:architecture/architecture.dart';",
            "import 'package:flutter/foundation.dart';",
          ],
        ),
        isEmpty,
      );

      final violations = scanDomainFileForUiImports(
        filePath:
            'packages/features/bookmarks/lib/src/domain/entities/bookmark.dart',
        lines: const [
          "import 'package:flutter/material.dart';",
          "import 'package:app_ui/app_ui.dart';",
          "import 'package:localization/localization.dart';",
          "import 'package:go_router/go_router.dart';",
          "import 'package:flutter_bloc/flutter_bloc.dart';",
        ],
      );
      expect(violations, hasLength(5));
    });

    test('detects duplicate design token classes and ThemeExtensions in feature packages', () {
      expect(
        scanFeatureFileForDuplicateTokens(
          filePath:
              'packages/features/bookmarks/lib/src/presentation/widgets/card.dart',
          lines: const [
            'class BookmarkCard extends StatelessWidget {}',
          ],
        ),
        isEmpty,
      );

      final violations = scanFeatureFileForDuplicateTokens(
        filePath:
            'packages/features/bookmarks/lib/src/presentation/tokens.dart',
        lines: const [
          'abstract final class BookmarkSpacing {}',
          'class BookmarkPalette extends ThemeExtension<BookmarkPalette> {}',
        ],
      );
      expect(
        violations,
        containsAll([
          contains('defines duplicate design token class BookmarkSpacing'),
          contains('defines custom ThemeExtension outside package:theme'),
        ]),
      );
    });

    test('detects application-specific business copy inside shared UI package', () {
      expect(
        scanSharedUiForBusinessTerms(
          filePath: 'packages/app_ui/lib/src/widgets/app_empty_state.dart',
          lines: const [
            'class AppEmptyState extends StatelessWidget {}',
          ],
        ),
        isEmpty,
      );

      final violations = scanSharedUiForBusinessTerms(
        filePath: 'packages/app_ui/lib/src/widgets/app_empty_state.dart',
        lines: const [
          "const label = 'No bookmarks saved in collection';",
        ],
      );
      expect(violations, isNotEmpty);
    });

    test('detects missing keys, empty values, and mismatched placeholders in ARB catalogs', () {
      expect(
        scanArbCatalogsForIntegrity(
          referenceLocale: 'en',
          referenceArb: const {
            'helloUser': 'Hello {name}',
          },
          localizedArbs: const {
            'ar': {'helloUser': 'مرحباً {name}'},
          },
        ),
        isEmpty,
      );

      final violations = scanArbCatalogsForIntegrity(
        referenceLocale: 'en',
        referenceArb: const {
          'helloUser': 'Hello {name}',
          'saveLabel': 'Save',
        },
        localizedArbs: const {
          'ar': {
            'helloUser': 'مرحباً {username}',
            'saveLabel': '   ',
          },
        },
      );
      expect(
        violations,
        containsAll([
          contains('has empty translation for key "saveLabel"'),
          contains('placeholder mismatch for key "helloUser"'),
        ]),
      );
    });

    test('detects hard-coded user-facing UI text in feature presentation layers', () {
      expect(
        scanPresentationForHardcodedText(
          filePath:
              'packages/features/bookmarks/lib/src/presentation/widgets/card.dart',
          lines: const [
            'Text(context.l10n.bookmarksTitle)',
            'tooltip: context.l10n.commonDelete,',
          ],
        ),
        isEmpty,
      );

      final violations = scanPresentationForHardcodedText(
        filePath:
            'packages/features/bookmarks/lib/src/presentation/widgets/card.dart',
        lines: const [
          "Text('Attached Video'),",
          "tooltip: 'Playback speed',",
        ],
      );
      expect(violations, hasLength(2));
    });
  });
}

const Set<String> _forbiddenDomainPackages = {
  'app_ui',
  'flutter_bloc',
  'go_router',
  'localization',
  'shared_ui',
  'theme',
};

const Set<String> _forbiddenDomainFlutterUris = {
  'package:flutter/cupertino.dart',
  'package:flutter/material.dart',
  'package:flutter/painting.dart',
  'package:flutter/rendering.dart',
  'package:flutter/widgets.dart',
};

final RegExp _directiveRegex = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

List<String> scanDomainFileForUiImports({
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final match = _directiveRegex.firstMatch(lines[i]);
    if (match == null) continue;
    final uri = match.group(1)!;
    if (_forbiddenDomainFlutterUris.contains(uri)) {
      violations.add(
        '$filePath:${i + 1} domain file imports Flutter UI library: $uri',
      );
      continue;
    }
    if (uri.startsWith('package:')) {
      final slash = uri.indexOf('/');
      if (slash == -1) continue;
      final pkg = uri.substring('package:'.length, slash);
      if (_forbiddenDomainPackages.contains(pkg)) {
        violations.add(
          '$filePath:${i + 1} domain file imports presentation/UI package $pkg: $uri',
        );
      }
    }
  }
  return violations;
}

final RegExp _duplicateTokenClassRegex = RegExp(
  r'\bclass\s+([A-Za-z0-9_]*(?:Spacing|Radius|Elevation|IconSize|Durations|Breakpoints))\b',
);

List<String> scanFeatureFileForDuplicateTokens({
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final tokenMatch = _duplicateTokenClassRegex.firstMatch(line);
    if (tokenMatch != null) {
      violations.add(
        '$filePath:${i + 1} defines duplicate design token class ${tokenMatch.group(1)}',
      );
    }
    if (RegExp(r'extends\s+ThemeExtension\b').hasMatch(line)) {
      violations.add(
        '$filePath:${i + 1} defines custom ThemeExtension outside package:theme',
      );
    }
  }
  return violations;
}

final RegExp _businessStringLiteralRegex = RegExp(
  r'''['"][^'"]*\b(?:bookmark|bookmarks|collection|collections)\b[^'"]*['"]''',
  caseSensitive: false,
);

List<String> scanSharedUiForBusinessTerms({
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.startsWith('//') || line.startsWith('///')) continue;
    final match = _businessStringLiteralRegex.firstMatch(line);
    if (match != null) {
      violations.add(
        '$filePath:${i + 1} contains application-specific business string literal: ${match.group(0)}',
      );
    }
  }
  return violations;
}

List<String> scanArbCatalogsForIntegrity({
  required String referenceLocale,
  required Map<String, Object?> referenceArb,
  required Map<String, Map<String, Object?>> localizedArbs,
}) {
  final violations = <String>[];
  final refKeys = referenceArb.keys.where((k) => !k.startsWith('@')).toSet();
  if (refKeys.isEmpty) {
    violations.add('Reference ARB ($referenceLocale) has no message keys');
    return violations;
  }

  for (final key in refKeys) {
    final refVal = referenceArb[key];
    if (refVal is! String || refVal.trim().isEmpty) {
      violations.add(
        'app_$referenceLocale.arb has empty translation for key "$key"',
      );
    }
  }

  for (final entry in localizedArbs.entries) {
    final locale = entry.key;
    final arb = entry.value;
    final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();

    for (final missing in refKeys.difference(keys)) {
      violations.add(
        'app_$locale.arb is missing key "$missing" from app_$referenceLocale.arb',
      );
    }
    for (final extra in keys.difference(refKeys)) {
      violations.add(
        'app_$locale.arb has extra key "$extra" not in app_$referenceLocale.arb',
      );
    }

    for (final key in refKeys.intersection(keys)) {
      final refVal = referenceArb[key];
      final locVal = arb[key];
      if (locVal is! String || locVal.trim().isEmpty) {
        violations.add(
          'app_$locale.arb has empty translation for key "$key"',
        );
        continue;
      }
      if (refVal is String) {
        final refPlaceholders = _extractPlaceholders(refVal);
        final locPlaceholders = _extractPlaceholders(locVal);
        if (refPlaceholders.length != locPlaceholders.length ||
            !refPlaceholders.containsAll(locPlaceholders)) {
          violations.add(
            'app_$locale.arb placeholder mismatch for key "$key": '
            'expected $refPlaceholders, found $locPlaceholders',
          );
        }
      }
    }
  }

  return violations;
}

Set<String> _extractPlaceholders(String message) {
  // Ignore ICU plural/select headers like `{count, plural, ...}` by still
  // capturing the variable name before the comma or closing brace.
  return RegExp(r'\{([A-Za-z0-9_]+)(?:,|\})')
      .allMatches(message)
      .map((m) => m.group(1)!)
      .toSet();
}

final RegExp _hardcodedUiPropRegex = RegExp(
  r'''(?:Text\(\s*|(?:tooltip|label|hintText|errorText|semanticLabel)\s*:\s*)['"]([A-Za-z][A-Za-z0-9 ,.!?/-]{2,})['"]''',
);

const Set<String> _allowedTechnicalUiLiterals = {
  'Mock Video Player View',
};

List<String> scanPresentationForHardcodedText({
  required String filePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.startsWith('//') || line.startsWith('///')) continue;
    final match = _hardcodedUiPropRegex.firstMatch(line);
    if (match == null) continue;
    final literal = match.group(1)!;
    if (literal.startsWith('http://') || literal.startsWith('https://')) {
      continue;
    }
    if (_allowedTechnicalUiLiterals.contains(literal)) continue;
    violations.add(
      '$filePath:${i + 1} contains hard-coded user-facing UI string: "$literal"',
    );
  }
  return violations;
}

Map<String, Object?> _decodeArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

String? _packageName(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1);
  }
  return null;
}

String _posix(String path) => path.replaceAll(r'\', '/');
