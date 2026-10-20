import 'dart:convert';

import 'package:document_engine/document_engine.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:test/test.dart';

void main() {
  final schema = DocumentDefinition(
    id: 'performance',
    title: 'Performance',
    columns: [
      DocumentColumn.integer(id: 'id', label: 'id', isRequired: true),
      DocumentColumn.text(id: 'name', label: 'name', isRequired: true),
      DocumentColumn.decimal(id: 'amount', label: 'amount', isRequired: true),
    ],
  );
  final definition = ImportDefinition(targetDefinition: schema);

  test('measures CSV parsing at representative sizes', () async {
    for (final rows in [1000, 10000, 50000]) {
      final source = StringBuffer('id,name,amount\n');
      for (var i = 0; i < rows; i++) {
        source.writeln('$i,Item $i,123.45');
      }
      final bytes = utf8.encode(source.toString());
      final stopwatch = Stopwatch()..start();
      final plan = await const CsvImportAdapter().preparePlan(
        bytes,
        definition,
      );
      stopwatch.stop();

      expect(plan.validCount, rows);
      // Measurements are intentionally emitted for the certification report.
      // ignore: avoid_print
      print(
        'PERF csv rows=$rows bytes=${bytes.length} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
  });

  test('large CSV parsing yields the caller isolate', () async {
    final source = StringBuffer('id,name,amount\n');
    for (var i = 0; i < 50000; i++) {
      source.writeln('$i,Item $i,123.45');
    }
    var completed = false;
    final parsing = const CsvImportAdapter()
        .preparePlan(utf8.encode(source.toString()), definition)
        .then((plan) {
          completed = true;
          return plan;
        });

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect((await parsing).validCount, 50000);
  });

  test('measures XLSX parsing at representative sizes', () async {
    for (final rows in [1000, 5000]) {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!]
        ..appendRow([
          TextCellValue('id'),
          TextCellValue('name'),
          TextCellValue('amount'),
        ]);
      for (var i = 0; i < rows; i++) {
        sheet.appendRow([
          IntCellValue(i),
          TextCellValue('Item $i'),
          const DoubleCellValue(123.45),
        ]);
      }
      final bytes = excel.encode()!;
      final stopwatch = Stopwatch()..start();
      final plan = await const XlsxImportAdapter().preparePlan(
        bytes,
        definition,
      );
      stopwatch.stop();

      expect(plan.validCount, rows);
      // Measurements are intentionally emitted for the certification report.
      // ignore: avoid_print
      print(
        'PERF xlsx rows=$rows bytes=${bytes.length} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
  });

  test('default row ceiling rejects expansion beyond the configured limit', () {
    final bytes = utf8.encode(
      'id,name,amount\n1,One,1\n2,Two,2\n3,Three,3',
    );
    expect(
      () => const CsvImportAdapter().preparePlan(
        bytes,
        ImportDefinition(targetDefinition: schema, maxRows: 2),
      ),
      throwsA(isA<DocumentValidationFailure>()),
    );
  });
}
