// Architecture guardrail: enforces Domain UseCase contracts across all feature
// packages, ensuring that use cases extend `UseCase` or `NoParamUseCase`, return
// `Future<Result<Output>>`, and do not throw uncaught exceptions.
//
// Rules enforced:
// 1. Every UseCase class in `packages/features/*/lib/src/domain/usecases/`
//    must extend `UseCase<Param, Output>` or `NoParamUseCase<Output>`.
// 2. The `call` method must return `Future<Result<...>>`.
// 3. UseCase `call` implementations must not throw raw exceptions; all failures
//    must be returned as `Err(Failure)` or handled via `runGuarded` /
//    `runResultGuarded`.
// 4. Legitimate architectural exceptions (validation helpers, parameter records/classes)
//    are recognized and exempted from UseCase base-class requirements.
//
// Pure AST file-scan, runs in normal `fvm flutter test` / CI flow.
// The analyzer package is resolved transitively via build_runner;
// used here solely for static AST parsing in architecture test fixtures.
// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Live workspace domain UseCase contract conformance', () {
    test('all feature use case classes adhere to the UseCase contract', () {
      final violations = <String>[];
      final featuresDir = Directory('packages/features');
      if (!featuresDir.existsSync()) return;

      for (final entity in featuresDir.listSync().whereType<Directory>()) {
        final usecasesDir = Directory('${entity.path}/lib/src/domain/usecases');
        if (!usecasesDir.existsSync()) continue;

        final pkgName =
            _packageName(File('${entity.path}/pubspec.yaml')) ?? entity.path;

        for (final file
            in usecasesDir
                .listSync(recursive: true)
                .whereType<File>()
                .where(
                  (f) =>
                      f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
                )) {
          final relPath = file.path.replaceAll(r'\', '/');
          violations.addAll(
            validateUseCaseFile(
              filePath: relPath,
              packageName: pkgName,
              content: file.readAsStringSync(),
            ),
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'UseCase contract violations found:\n\n'
            '${violations.map((v) => '  $v').join('\n')}',
      );
    });
  });

  group('UseCase contract regression tests (mutations)', () {
    test('passes on compliant UseCase extending UseCase', () {
      const code = '''
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

typedef SignInParams = ({String username, String password});

@injectable
class SignInUseCase extends UseCase<SignInParams, AuthUser> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(SignInParams param) {
    return runResultGuarded(() => _repository.signIn(param.username, param.password));
  }
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/sign_in.dart',
        packageName: 'feature_auth',
        content: code,
      );
      expect(violations, isEmpty);
    });

    test('passes on compliant NoParamUseCase', () {
      const code = '''
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

@injectable
class ListBookmarksUseCase extends NoParamUseCase<List<Bookmark>> {
  const ListBookmarksUseCase(this._repository);

  final BookmarksRepository _repository;

  @override
  Future<Result<List<Bookmark>>> call([NoParams param = noParams]) {
    return runResultGuarded(_repository.list);
  }
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/list_bookmarks.dart',
        packageName: 'feature_bookmarks',
        content: code,
      );
      expect(violations, isEmpty);
    });

    test('exempts parameter records and private validator helpers', () {
      const code = '''
class UpdateCollectionParams {
  const UpdateCollectionParams({required this.id, required this.name});
  final String id;
  final String name;
}

String? validateTitle(String? value) => value == null || value.isEmpty ? 'Required' : null;
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/_collection_validation.dart',
        packageName: 'feature_collections',
        content: code,
      );
      expect(violations, isEmpty);
    });

    test('rejects UseCase class not extending UseCase or NoParamUseCase', () {
      const code = '''
@injectable
class BadCustomUseCase {
  const BadCustomUseCase();

  Future<Result<void>> call() async => const Ok(null);
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/bad_custom_use_case.dart',
        packageName: 'feature_custom',
        content: code,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'Class "BadCustomUseCase" must extend "UseCase<Param, Output>" or "NoParamUseCase<Output>"',
        ),
      );
    });

    test('rejects UseCase call() with return type not wrapped in Result', () {
      const code = '''
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

@injectable
class NonResultUseCase extends NoParamUseCase<String> {
  const NonResultUseCase();

  @override
  Future<String> call([NoParams param = noParams]) async {
    return "raw string without Result";
  }
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/non_result_use_case.dart',
        packageName: 'feature_custom',
        content: code,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains('must return Future<Result<Output>>'),
      );
    });

    test('rejects UseCase call() with raw uncaught throw statement', () {
      const code = '''
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

@injectable
class ThrowingUseCase extends NoParamUseCase<String> {
  const ThrowingUseCase();

  @override
  Future<Result<String>> call([NoParams param = noParams]) async {
    if (true) {
      throw Exception("Unexpected raw error!");
    }
    return const Ok("success");
  }
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/throwing_use_case.dart',
        packageName: 'feature_custom',
        content: code,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains(
          'contains raw "throw" in call(). Use cases must return Err(Failure) or use runGuarded()',
        ),
      );
    });

    test('allows throw statement inside runGuarded or runResultGuarded', () {
      const code = '''
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

@injectable
class GuardedThrowUseCase extends NoParamUseCase<String> {
  const GuardedThrowUseCase();

  @override
  Future<Result<String>> call([NoParams param = noParams]) {
    return runResultGuarded(() {
      if (true) {
        throw Exception("Caught by runResultGuarded");
      }
      return "safe";
    });
  }
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/guarded_throw_use_case.dart',
        packageName: 'feature_custom',
        content: code,
      );
      expect(violations, isEmpty);
    });

    test('false negative test: comment mentioning class is ignored by AST', () {
      const codeWithComment = '''
// class FakeUseCase extends UseCase<NoParams, void> { Future<Result<void>> call() ... }
// The actual class in this file violates the rule:
class UnimplementedUseCase {
  void doWork() {}
}
''';
      final violations = validateUseCaseFile(
        filePath: 'lib/src/domain/usecases/comment_test_use_case.dart',
        packageName: 'feature_custom',
        content: codeWithComment,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.first,
        contains('Class "UnimplementedUseCase" must extend'),
      );
    });
  });
}

class _ThrowVisitor extends RecursiveAstVisitor<void> {
  final rawThrows = <ThrowExpression>[];

  @override
  void visitThrowExpression(ThrowExpression node) {
    var current = node.parent;
    var isGuarded = false;

    while (current != null) {
      if (current is MethodInvocation) {
        final methodName = current.methodName.name;
        if (methodName == 'runGuarded' || methodName == 'runResultGuarded') {
          isGuarded = true;
          break;
        }
      } else if (current is FunctionExpressionInvocation) {
        final target = current.function.toSource();
        if (target == 'runGuarded' || target == 'runResultGuarded') {
          isGuarded = true;
          break;
        }
      }
      current = current.parent;
    }

    if (!isGuarded) {
      rawThrows.add(node);
    }

    super.visitThrowExpression(node);
  }
}

List<String> validateUseCaseFile({
  required String filePath,
  required String packageName,
  required String content,
}) {
  final violations = <String>[];
  final fileName = filePath.split('/').last;

  // Exempt private helper and validation files (e.g. `_bookmark_validation.dart`)
  if (fileName.startsWith('_')) {
    return violations;
  }

  final parseResult = parseString(content: content, throwIfDiagnostics: false);
  final unit = parseResult.unit;

  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    final className = declaration.name.lexeme;

    // Exempt parameter classes, DTOs, or mock fixtures
    if (className.endsWith('Params') ||
        className.endsWith('Input') ||
        className.endsWith('Helper') ||
        className.startsWith('Mock') ||
        className.startsWith('Fake')) {
      continue;
    }

    // Only apply contract to classes ending in UseCase or primary domain operations
    final isUseCaseClass =
        className.endsWith('UseCase') ||
        (!className.endsWith('Params') && !className.endsWith('Helper'));
    if (!isUseCaseClass) continue;

    // Rule 1: Must extend UseCase or NoParamUseCase
    final superclassName =
        declaration.extendsClause?.superclass
            .toSource()
            .split('<')
            .first
            .trim() ??
        '';

    if (superclassName != 'UseCase' && superclassName != 'NoParamUseCase') {
      violations.add(
        '$filePath: Class "$className" must extend "UseCase<Param, Output>" or "NoParamUseCase<Output>" '
        'from package:architecture.',
      );
      continue;
    }

    // Rule 2 & 3: Check call() method return type and body
    MethodDeclaration? callMethod;
    for (final member in declaration.members.whereType<MethodDeclaration>()) {
      if (member.name.lexeme == 'call') {
        callMethod = member;
        break;
      }
    }

    if (callMethod != null) {
      final returnType = callMethod.returnType?.toSource() ?? '';
      if (!returnType.contains('Result<')) {
        violations.add(
          '$filePath: UseCase "$className.call()" return type "$returnType" must return Future<Result<Output>>.',
        );
      }

      final throwVisitor = _ThrowVisitor();
      callMethod.body.accept(throwVisitor);

      if (throwVisitor.rawThrows.isNotEmpty) {
        violations.add(
          '$filePath: UseCase "$className" contains raw "throw" in call(). '
          'Use cases must return Err(Failure) or use runGuarded() to prevent unhandled UI crashes.',
        );
      }
    }
  }

  return violations;
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
