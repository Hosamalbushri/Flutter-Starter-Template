import 'dart:convert';

import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  late DocumentDefinition schema;

  setUp(() {
    schema = DocumentDefinition(
      id: 'invoices',
      title: 'Customer Invoices',
      columns: [
        DocumentColumn.integer(
          id: 'invoiceNumber',
          label: 'Invoice #',
          isRequired: true,
        ),
        DocumentColumn.text(
          id: 'customerName',
          label: 'Customer Name',
          isRequired: true,
        ),
        DocumentColumn.decimal(
          id: 'amount',
          label: 'Total Amount',
          isRequired: true,
        ),
        DocumentColumn.date(id: 'dueDate', label: 'Due Date'),
        DocumentColumn.boolean(id: 'paid', label: 'Is Paid'),
      ],
    );
  });

  group('JsonImportAdapter', () {
    const adapter = JsonImportAdapter();

    test('inspectHeaders inspects keys from JSON array of objects', () async {
      const jsonStr = '''
      [
        {"invoiceNumber": 1001, "customerName": "Alice", "amount": 150.00, "dueDate": "2026-05-01", "paid": true},
        {"invoiceNumber": 1002, "customerName": "Bob", "amount": 299.99}
      ]
      ''';
      final bytes = utf8.encode(jsonStr);

      final headers = await adapter.inspectHeaders(bytes);
      expect(
        headers,
        containsAll([
          'invoiceNumber',
          'customerName',
          'amount',
          'dueDate',
          'paid',
        ]),
      );
    });

    test('inspectHeaders inspects keys from nested data object', () async {
      const jsonStr = '''
      {
        "status": "success",
        "data": [
          {"invoiceNumber": 2001, "customerName": "شركة النور للتجارة", "amount": 5400.50}
        ]
      }
      ''';
      final bytes = utf8.encode(jsonStr);

      final headers = await adapter.inspectHeaders(bytes);
      expect(headers, containsAll(['invoiceNumber', 'customerName', 'amount']));
    });

    test(
      'parses and validates JSON records with Arabic names and dates',
      () async {
        const jsonStr = '''
      [
        {
          "invoiceNumber": 3001,
          "customerName": "مؤسسة الأمل",
          "amount": 1250.75,
          "dueDate": "2026-11-20",
          "paid": true
        },
        {
          "invoiceNumber": 3002,
          "customerName": "Tech Corp Ltd",
          "amount": 890.00,
          "dueDate": "2026-12-01",
          "paid": false
        }
      ]
      ''';
        final bytes = utf8.encode(jsonStr);

        final definition = ImportDefinition(targetDefinition: schema);
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.totalInspected, 2);
        expect(plan.validCount, 2);
        expect(plan.invalidCount, 0);
        expect(plan.canCommit, isTrue);

        final row1 = plan.validRows[0];
        expect(row1['invoiceNumber'].asInt, 3001);
        expect(row1['customerName'].asString, 'مؤسسة الأمل');
        expect(row1['amount'].asDecimal, DecimalNumber.parse('1250.75'));
        expect(row1['dueDate'].asDate?.toUtc(), DateTime.utc(2026, 11, 20));
        expect(row1['paid'].asBool, isTrue);
      },
    );

    test('catches malformed JSON syntax with DocumentParseFailure', () async {
      final bytes = utf8.encode('{ invalid json syntax ');

      expect(
        () => adapter.preparePlan(
          bytes,
          ImportDefinition(targetDefinition: schema),
        ),
        throwsA(isA<DocumentParseFailure>()),
      );
    });

    test(
      'validates required fields in JSON rows and rejects invalid ones',
      () async {
        const jsonStr = '''
      [
        {"invoiceNumber": 4001, "amount": 500.00},
        {"invoiceNumber": 4002, "customerName": "Valid Customer", "amount": 750.00}
      ]
      ''';
        final bytes = utf8.encode(jsonStr);

        final definition = ImportDefinition(
          targetDefinition: schema,
          allowPartial: false,
        );
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.validCount, 1);
        expect(plan.invalidCount, 1);
        expect(plan.canCommit, isFalse);

        final invalidRow = plan.invalidRows.first;
        expect(
          invalidRow.issues.any(
            (i) => i.code == ValidationErrorCode.missingRequired,
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects input larger than the configured byte limit before parsing',
      () {
        final bytes = utf8.encode('[{"invoiceNumber": 1}]');

        expect(
          () => adapter.preparePlan(
            bytes,
            ImportDefinition(targetDefinition: schema, maxFileBytes: 8),
          ),
          throwsA(isA<DocumentValidationFailure>()),
        );
      },
    );
  });

  group('JsonExportAdapter', () {
    late DocumentDataset dataset;

    setUp(() {
      final rows = [
        DocumentRow(
          index: 0,
          cells: {
            'invoiceNumber': DocumentValue.from(5001),
            'customerName': DocumentValue.from('Global Supplies Inc'),
            'amount': DocumentValue.from(DecimalNumber.parse('2100.50')),
            'dueDate': DocumentValue.from(DateTime(2026, 6, 15)),
            'paid': DocumentValue.from(true),
          },
        ),
        DocumentRow(
          index: 1,
          cells: {
            'invoiceNumber': DocumentValue.from(5002),
            'customerName': DocumentValue.from('مكتبة المعرفة'),
            'amount': DocumentValue.from(DecimalNumber.parse('430.00')),
            'dueDate': const NullDocumentValue(ColumnType.date),
            'paid': DocumentValue.from(false),
          },
        ),
      ];
      dataset = DocumentDataset(definition: schema, rows: rows);
    });

    test('exports dataset to valid formatted JSON array', () async {
      const adapter = JsonExportAdapter();
      const definition = ExportDefinition();

      final bytes = await adapter.export(dataset, definition);
      final jsonString = utf8.decode(bytes);

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      expect(decoded.length, 2);

      final item1 = decoded[0] as Map<String, dynamic>;
      expect(item1['invoiceNumber'], 5001);
      expect(item1['customerName'], 'Global Supplies Inc');
      expect(item1['amount'], 2100.50);
      expect(item1['dueDate'], '2026-06-15');
      expect(item1['paid'], true);

      final item2 = decoded[1] as Map<String, dynamic>;
      expect(item2['customerName'], 'مكتبة المعرفة');
      expect(item2['dueDate'], isNull);
    });

    test(
      'exports with metadata when options.includeMetadata is true',
      () async {
        const adapter = JsonExportAdapter(
          options: JsonExportOptions(includeMetadata: true),
        );
        const definition = ExportDefinition();

        final bytes = await adapter.export(dataset, definition);
        final jsonString = utf8.decode(bytes);

        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        expect(decoded.containsKey('metadata'), isTrue);
        expect(decoded.containsKey('rows'), isTrue);

        final meta = decoded['metadata'] as Map<String, dynamic>;
        expect(meta['title'], 'Customer Invoices');
        expect(meta['totalRows'], 2);

        final rows = decoded['rows'] as List<dynamic>;
        expect(rows.length, 2);
      },
    );

    test('aborts JSON export when cancellation token is cancelled', () async {
      const adapter = JsonExportAdapter();
      final token = CancellationToken()..cancel('User cancelled');

      expect(
        () => adapter.export(
          dataset,
          const ExportDefinition(),
          cancellationToken: token,
        ),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });

    test(
      'preserves decimals that cannot be represented exactly as doubles',
      () async {
        final preciseDataset = DocumentDataset(
          definition: schema,
          rows: [
            DocumentRow(
              index: 0,
              cells: {
                'invoiceNumber': DocumentValue.from(1),
                'customerName': DocumentValue.from('Precision test'),
                'amount': DocumentValue.from(
                  DecimalNumber.parse('9007199254740993.01'),
                ),
              },
            ),
          ],
        );

        final bytes = await const JsonExportAdapter().export(
          preciseDataset,
          const ExportDefinition(),
        );
        final decoded = jsonDecode(utf8.decode(bytes)) as List<dynamic>;

        expect(
          (decoded.single as Map<String, dynamic>)['amount'],
          '9007199254740993.01',
        );
      },
    );
  });
}
