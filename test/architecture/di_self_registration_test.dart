// Architecture guardrail: enforces micro-package DI self-registration,
// ensures that every concrete DataSource, Repository, and SyncController
// carries a DI annotation in its owning feature package, checks for duplicate
// interface bindings, and verifies that generated `di.module.dart` files are in
// sync with class definitions.
//
// Rules enforced:
// 1. Concrete feature data sources and repository implementations must self-register
//    via `@LazySingleton(as: Interface)` or `@injectable`.
// 2. When registering `as: Interface`, the class must actually implement or extend that Interface.
// 3. Every feature micro-package module must be included in `lib/app/di/injection.dart`.
// 4. No duplicate registrations for the same interface within the same package.
// 5. Generated `di.module.dart` files must be in sync with declared annotations.
//
// Pure AST file-scan, runs in normal `fvm flutter test` / CI flow.
// The analyzer package is resolved transitively via build_runner;
// used here solely for static AST parsing in architecture test fixtures.
// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live feature packages DI self-registration', () {
    test(
      'all concrete feature data sources and repositories carry valid DI annotations',
      () {
        final violations = <String>[];
        final featuresDir = Directory('packages/features');
        if (!featuresDir.existsSync()) return;

        for (final entity in featuresDir.listSync().whereType<Directory>()) {
          final libDir = Directory('${entity.path}/lib/src');
          if (!libDir.existsSync()) continue;

          final pkgName = _packageName(File('${entity.path}/pubspec.yaml'));
          if (pkgName == null) continue;

          final dartFiles = libDir
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (f) =>
                    f.path.endsWith('.dart') &&
                    !f.path.endsWith('.g.dart') &&
                    !f.path.endsWith('.module.dart'),
              );

          for (final file in dartFiles) {
            final relPath = file.path.replaceAll(r'\', '/');
            // Scan data sources and repository implementations
            if (relPath.contains('/data/local/') ||
                relPath.contains('/data/datasources/') ||
                relPath.contains('/data/repositories/')) {
              violations.addAll(
                validateClassSelfRegistration(
                  filePath: relPath,
                  packageName: pkgName,
                  content: file.readAsStringSync(),
                ),
              );
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Feature classes missing or having invalid self-registration annotations:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );

    test(
      'every feature micro-package module is registered in app DI injection.dart',
      () {
        final injectionFile = File('lib/app/di/injection.dart');
        if (!injectionFile.existsSync()) return;

        final injectionContent = injectionFile.readAsStringSync();
        final featuresDir = Directory('packages/features');
        if (!featuresDir.existsSync()) return;

        final violations = <String>[];

        for (final entity in featuresDir.listSync().whereType<Directory>()) {
          final diModule = File('${entity.path}/lib/src/di.module.dart');
          if (!diModule.existsSync()) continue;

          // Expect Feature*PackageModule in injection.dart
          final dirName = entity.path.split('/').last;
          final pascalFeature = dirName
              .split('_')
              .map(
                (w) =>
                    w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
              )
              .join();
          final expectedModule = 'Feature${pascalFeature}PackageModule';

          if (!injectionContent.contains(expectedModule)) {
            violations.add(
              'Feature module "$expectedModule" from ${entity.path} is missing from '
              'lib/app/di/injection.dart externalPackageModulesBefore list',
            );
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Feature DI modules omitted from app assembly:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );

    test(
      'no duplicate DI interface registrations exist within the same package',
      () {
        final violations = <String>[];
        final featuresDir = Directory('packages/features');
        if (!featuresDir.existsSync()) return;

        for (final entity in featuresDir.listSync().whereType<Directory>()) {
          final pkgName = _packageName(File('${entity.path}/pubspec.yaml'));
          if (pkgName == null) continue;

          final diModule = File('${entity.path}/lib/src/di.module.dart');
          if (!diModule.existsSync()) continue;

          violations.addAll(
            validateNoDuplicateRegistrations(
              packageName: pkgName,
              diModulePath: diModule.path.replaceAll(r'\', '/'),
              lines: diModule.readAsLinesSync(),
            ),
          );
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Duplicate DI registrations detected:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );

    test(
      'generated di.module.dart files are in sync with declared DI annotations',
      () {
        final violations = <String>[];
        final featuresDir = Directory('packages/features');
        if (!featuresDir.existsSync()) return;

        for (final entity in featuresDir.listSync().whereType<Directory>()) {
          final pkgName = _packageName(File('${entity.path}/pubspec.yaml'));
          if (pkgName == null) continue;

          final diModuleFile = File('${entity.path}/lib/src/di.module.dart');
          if (!diModuleFile.existsSync()) continue;

          final diModuleContent = diModuleFile.readAsStringSync();
          final libDir = Directory('${entity.path}/lib/src');

          for (final file
              in libDir
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where(
                    (f) =>
                        f.path.endsWith('.dart') &&
                        !f.path.endsWith('.g.dart') &&
                        !f.path.endsWith('.module.dart'),
                  )) {
            final content = file.readAsStringSync();
            final annotatedClasses = _extractAnnotatedClasses(content);

            for (final cls in annotatedClasses) {
              if (!diModuleContent.contains(cls)) {
                violations.add(
                  '${file.path.replaceAll(r"\", "/")}: Class "$cls" is annotated with @injectable/@LazySingleton '
                  'but is missing from generated di.module.dart. Run "tool/codegen.sh" to synchronize.',
                );
              }
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Generated DI modules out of sync with declared annotations:\n\n'
              '${violations.map((v) => '  $v').join('\n')}',
        );
      },
    );
  });

  group('DI self-registration regression tests (mutations)', () {
    test(
      'passes on concrete class with valid @LazySingleton implementing interface',
      () {
        const code = '''
import 'package:injectable/injectable.dart';

@LazySingleton(as: BookmarksLocalDataSource)
class ObjectBoxBookmarksDataSource implements BookmarksLocalDataSource {
  const ObjectBoxBookmarksDataSource();
}
''';
        final violations = validateClassSelfRegistration(
          filePath: 'lib/src/data/local/bookmarks_local_data_source.dart',
          packageName: 'feature_bookmarks',
          content: code,
        );
        expect(violations, isEmpty);
      },
    );

    test(
      'rejects concrete repository implementation missing DI annotation',
      () {
        const code = '''
class UnregisteredBookmarksRepositoryImpl implements BookmarksRepository {
  const UnregisteredBookmarksRepositoryImpl();
}
''';
        final violations = validateClassSelfRegistration(
          filePath: 'lib/src/data/repositories/bookmarks_repository_impl.dart',
          packageName: 'feature_bookmarks',
          content: code,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first,
          contains('is missing a DI self-registration annotation'),
        );
      },
    );

    test(
      'rejects class registering as: Interface without actually implementing it',
      () {
        const code = '''
import 'package:injectable/injectable.dart';

@LazySingleton(as: UnimplementedInterface)
class BadDataSource implements DifferentInterface {
  const BadDataSource();
}
''';
        final violations = validateClassSelfRegistration(
          filePath: 'lib/src/data/local/bad_data_source.dart',
          packageName: 'feature_test',
          content: code,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first,
          contains(
            'registers as "UnimplementedInterface", but does not implement or extend it',
          ),
        );
      },
    );

    test('ignores abstract interfaces and fake/test classes', () {
      const code = '''
abstract interface class BookmarksLocalDataSource {}

class FakeBookmarksLocalDataSource implements BookmarksLocalDataSource {}
''';
      final violations = validateClassSelfRegistration(
        filePath: 'lib/src/data/local/bookmarks_local_data_source.dart',
        packageName: 'feature_bookmarks',
        content: code,
      );
      expect(violations, isEmpty);
    });

    test(
      'detects duplicate registration for the same interface in di.module.dart',
      () {
        const moduleLines = [
          'gh.lazySingleton<_i1.BookmarksLocalDataSource>(() => _i2.FirstDataSource());',
          'gh.lazySingleton<_i1.BookmarksLocalDataSource>(() => _i3.SecondDataSource());',
        ];
        final violations = validateNoDuplicateRegistrations(
          packageName: 'feature_bookmarks',
          diModulePath: 'lib/src/di.module.dart',
          lines: moduleLines,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first,
          contains(
            'Duplicate registration for type "BookmarksLocalDataSource"',
          ),
        );
      },
    );

    test(
      'false negative test: comment containing @LazySingleton does not fool AST',
      () {
        const codeWithComment = '''
// @LazySingleton(as: BookmarksLocalDataSource)
class CommentedDataSource implements BookmarksLocalDataSource {
  const CommentedDataSource();
}
''';
        final violations = validateClassSelfRegistration(
          filePath: 'lib/src/data/local/comment_data_source.dart',
          packageName: 'feature_bookmarks',
          content: codeWithComment,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first,
          contains('is missing a DI self-registration annotation'),
        );
      },
    );
  });
}

List<String> validateClassSelfRegistration({
  required String filePath,
  required String packageName,
  required String content,
}) {
  final violations = <String>[];
  final parseResult = parseString(content: content, throwIfDiagnostics: false);
  final unit = parseResult.unit;

  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    final className = declaration.name.lexeme;

    // Ignore test doubles, mock fixtures, and abstract interfaces
    if (declaration.abstractKeyword != null ||
        className.startsWith('_') ||
        className.startsWith('Fake') ||
        className.startsWith('Mock') ||
        className.startsWith('NoOp') ||
        className.startsWith('Test')) {
      continue;
    }

    // Must implement an interface or be a repository/datasource
    final implementsList =
        declaration.implementsClause?.interfaces
            .map((i) => i.toSource().split('<').first.trim())
            .toList() ??
        const [];
    final extendsClass = declaration.extendsClause?.superclass
        .toSource()
        .split('<')
        .first
        .trim();

    final isDataComponent =
        implementsList.isNotEmpty ||
        className.endsWith('RepositoryImpl') ||
        className.endsWith('DataSource') ||
        className.endsWith('SyncController');

    if (!isDataComponent) continue;

    // Check DI annotations
    Annotation? diAnnotation;
    for (final meta in declaration.metadata) {
      final name = meta.name.toSource();
      if (name == 'LazySingleton' ||
          name == 'injectable' ||
          name == 'singleton' ||
          name == 'Singleton') {
        diAnnotation = meta;
        break;
      }
    }

    if (diAnnotation == null) {
      violations.add(
        '$filePath: Concrete class "$className" in $packageName is missing a DI '
        'self-registration annotation (@LazySingleton, @injectable, or @singleton).',
      );
      continue;
    }

    // If @LazySingleton(as: Interface) or @Singleton(as: Interface) is used,
    // verify the class actually implements or extends Interface
    final args = diAnnotation.arguments?.arguments ?? const [];
    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'as') {
        final asInterface = arg.expression.toSource().trim();
        final implementsOrExtends =
            implementsList.contains(asInterface) || extendsClass == asInterface;

        if (!implementsOrExtends) {
          violations.add(
            '$filePath: Class "$className" registers as "$asInterface", '
            'but does not implement or extend it.',
          );
        }
      }
    }
  }

  return violations;
}

List<String> validateNoDuplicateRegistrations({
  required String packageName,
  required String diModulePath,
  required List<String> lines,
}) {
  final violations = <String>[];
  final registeredTypes = <String, int>{};
  final registrationRegex = RegExp(
    r'gh\.(?:lazySingleton|factory|singleton)<([^>]+)>',
  );

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = registrationRegex.firstMatch(line);
    if (match == null) continue;

    var rawType = match.group(1)!;
    if (rawType.contains('.')) {
      rawType = rawType.split('.').last;
    }

    if (registeredTypes.containsKey(rawType)) {
      violations.add(
        '$diModulePath:${i + 1} Duplicate registration for type "$rawType" in $packageName. '
        'First registered at line ${registeredTypes[rawType]}.',
      );
    } else {
      registeredTypes[rawType] = i + 1;
    }
  }

  return violations;
}

List<String> _extractAnnotatedClasses(String content) {
  final parseResult = parseString(content: content, throwIfDiagnostics: false);
  final annotated = <String>[];

  for (final declaration
      in parseResult.unit.declarations.whereType<ClassDeclaration>()) {
    for (final meta in declaration.metadata) {
      final name = meta.name.toSource();
      if (name == 'LazySingleton' ||
          name == 'injectable' ||
          name == 'singleton' ||
          name == 'Singleton') {
        annotated.add(declaration.name.lexeme);
        break;
      }
    }
  }

  return annotated;
}

String? _packageName(File pubspec) {
  if (!pubspec.existsSync()) return null;
  for (final line in pubspec.readAsLinesSync()) {
    if (line.startsWith('name:')) {
      return line.substring('name:'.length).trim();
    }
  }
  return null;
}
