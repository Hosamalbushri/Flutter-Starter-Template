import 'dart:convert';

import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  late DocumentDefinition schema;

  setUp(() {
    schema = DocumentDefinition(
      id: 'products',
      title: 'Products Catalog',
      columns: [
        DocumentColumn.integer(id: 'id', label: 'ID', isRequired: true),
        DocumentColumn.text(
          id: 'name',
          label: 'Product Name',
          isRequired: true,
        ),
        DocumentColumn.decimal(id: 'price', label: 'Price', isRequired: true),
        DocumentColumn.integer(id: 'stock', label: 'Stock Quantity'),
        DocumentColumn.boolean(id: 'active', label: 'Active'),
      ],
    );
  });

  group('CsvImportAdapter', () {
    const adapter = CsvImportAdapter();

    test(
      'inspectHeaders correctly extracts headers from comma-delimited input',
      () async {
        const csvData = 'id,name,price,stock,active\r\n1,Widget,10.50,100,true';
        final bytes = utf8.encode(csvData);

        final headers = await adapter.inspectHeaders(bytes);
        expect(headers, ['id', 'name', 'price', 'stock', 'active']);
      },
    );

    test(
      'inspectHeaders auto-detects semicolon delimiter and strips UTF-8 BOM',
      () async {
        const csvData = 'id;name;price;stock;active\r\n1;Widget;10.50;100;true';
        final rawBytes = utf8.encode(csvData);
        final bytesWithBom = <int>[0xEF, 0xBB, 0xBF, ...rawBytes];

        final headers = await adapter.inspectHeaders(bytesWithBom);
        expect(headers, ['id', 'name', 'price', 'stock', 'active']);
      },
    );

    test('throws DocumentParseFailure on empty input', () async {
      expect(
        () => adapter.inspectHeaders(const []),
        throwsA(isA<DocumentParseFailure>()),
      );
    });

    test('does not allow committing a header-only document', () async {
      final plan = await adapter.preparePlan(
        utf8.encode('id,name,price,stock,active'),
        ImportDefinition(targetDefinition: schema),
      );

      expect(plan.totalInspected, 0);
      expect(plan.validRows, isEmpty);
      expect(plan.canCommit, isFalse);
    });

    test('rejects duplicate headers instead of silently overwriting data', () {
      final bytes = utf8.encode('id,name,name\r\n1,first,second');

      expect(
        () => adapter.inspectHeaders(bytes),
        throwsA(
          isA<DocumentParseFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Duplicate CSV header "name"'),
          ),
        ),
      );
    });

    test(
      'parses and validates valid rows with Arabic text and exact decimals',
      () async {
        const csvData =
            'id,name,price,stock,active\r\n'
            '101,منتج تجريبي أول,450.75,25,نعم\r\n'
            '102,Second Item,1200.00,0,false';
        final bytes = utf8.encode(csvData);

        final definition = ImportDefinition(targetDefinition: schema);
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.totalInspected, 2);
        expect(plan.validCount, 2);
        expect(plan.invalidCount, 0);
        expect(plan.canCommit, isTrue);

        final firstRow = plan.validRows.first;
        expect(firstRow['id'].asInt, 101);
        expect(firstRow['name'].asString, 'منتج تجريبي أول');
        expect(firstRow['price'].asDecimal, DecimalNumber.parse('450.75'));
        expect(firstRow['active'].asBool, isTrue);
      },
    );

    test(
      'handles quoted CSV fields with embedded commas, quotes, and newlines',
      () async {
        const csvData =
            'id,name,price,stock,active\r\n'
            '201,"Item with, comma and ""quotes""",89.90,10,true\r\n'
            '202,"Item with\nmultiline name",15.00,5,false';
        final bytes = utf8.encode(csvData);

        final definition = ImportDefinition(targetDefinition: schema);
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.validCount, 2);
        expect(
          plan.validRows[0]['name'].asString,
          'Item with, comma and "quotes"',
        );
        expect(
          plan.validRows[1]['name'].asString,
          'Item with\nmultiline name',
        );
      },
    );

    test(
      'collects validation issues for missing required values and invalid types',
      () async {
        const csvData =
            'id,name,price,stock,active\r\n'
            ',Missing ID Item,50.00,10,true\r\n' // Missing required id
            '302,Invalid Price,not_a_number,5,false\r\n' // Invalid decimal
            '303,Valid Item,99.99,10,true';
        final bytes = utf8.encode(csvData);

        final definition = ImportDefinition(
          targetDefinition: schema,
          allowPartial: false,
        );
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.totalInspected, 3);
        expect(plan.validCount, 1);
        expect(plan.invalidCount, 2);
        expect(plan.canCommit, isFalse); // allowPartial is false

        final firstInvalid = plan.invalidRows[0];
        expect(firstInvalid.rowNumber, 2);
        expect(
          firstInvalid.issues.any(
            (i) => i.code == ValidationErrorCode.missingRequired,
          ),
          isTrue,
        );

        final secondInvalid = plan.invalidRows[1];
        expect(secondInvalid.rowNumber, 3);
        expect(
          secondInvalid.issues.any(
            (i) => i.code == ValidationErrorCode.invalidType,
          ),
          isTrue,
        );
      },
    );

    test(
      'allows partial commit when allowPartial is true and valid rows exist',
      () async {
        const csvData =
            'id,name,price,stock,active\r\n'
            ',Missing ID Item,50.00,10,true\r\n'
            '401,Valid Item,25.00,100,true';
        final bytes = utf8.encode(csvData);

        final definition = ImportDefinition(
          targetDefinition: schema,
          allowPartial: true,
        );
        final plan = await adapter.preparePlan(bytes, definition);

        expect(plan.validCount, 1);
        expect(plan.invalidCount, 1);
        expect(plan.canCommit, isTrue);
      },
    );

    test('aborts parsing when cancellation token is cancelled', () async {
      const csvData = 'id,name,price,stock,active\r\n1,Widget,10.50,100,true';
      final bytes = utf8.encode(csvData);
      final token = CancellationToken()..cancel('Test cancellation');

      expect(
        () => adapter.preparePlan(
          bytes,
          ImportDefinition(targetDefinition: schema),
          cancellationToken: token,
        ),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });

    test(
      'rejects input larger than the configured byte limit before parsing',
      () {
        final bytes = utf8.encode('id,name,price\n1,Widget,10.50');

        expect(
          () => adapter.preparePlan(
            bytes,
            ImportDefinition(targetDefinition: schema, maxFileBytes: 8),
          ),
          throwsA(isA<DocumentValidationFailure>()),
        );
      },
    );

    test('does not convert programming errors into parse failures', () async {
      final programmingErrorSchema = DocumentDefinition(
        id: 'programming-error',
        title: 'Programming Error',
        columns: [
          DocumentColumn.text(
            id: 'name',
            label: 'name',
            validator: (_) => throw StateError('validator defect'),
          ),
        ],
      );

      expect(
        () => adapter.preparePlan(
          utf8.encode('name\nvalue'),
          ImportDefinition(targetDefinition: programmingErrorSchema),
        ),
        throwsStateError,
      );
    });
  });

  group('CsvExportAdapter', () {
    late DocumentDataset dataset;

    setUp(() {
      final rows = [
        DocumentRow(
          index: 0,
          cells: {
            'id': DocumentValue.from(1),
            'name': DocumentValue.from('Laptop Pro'),
            'price': DocumentValue.from(DecimalNumber.parse('3499.50')),
            'stock': DocumentValue.from(15),
            'active': DocumentValue.from(true),
          },
        ),
        DocumentRow(
          index: 1,
          cells: {
            'id': DocumentValue.from(2),
            'name': DocumentValue.from('شاشة عرض فائقة الدقة'),
            'price': DocumentValue.from(DecimalNumber.parse('850.00')),
            'stock': DocumentValue.from(8),
            'active': DocumentValue.from(false),
          },
        ),
        DocumentRow(
          index: 2,
          cells: {
            'id': DocumentValue.from(3),
            'name': DocumentValue.from(
              '=SUM(A1:A10)',
            ), // Formula injection attempt
            'price': DocumentValue.from(DecimalNumber.parse('10.00')),
            'stock': const NullDocumentValue(ColumnType.integer),
            'active': const NullDocumentValue(ColumnType.boolean),
          },
        ),
      ];
      dataset = DocumentDataset(definition: schema, rows: rows);
    });

    test(
      'exports dataset to valid CSV with Arabic UTF-8 text and sanitized formula',
      () async {
        const adapter = CsvExportAdapter();
        const definition = ExportDefinition(protectFormulas: true);

        final bytes = await adapter.export(dataset, definition);
        final csvText = utf8.decode(bytes);

        expect(
          csvText,
          contains('ID,Product Name,Price,Stock Quantity,Active'),
        );
        expect(csvText, contains('1,Laptop Pro,3499.50,15,true'));
        expect(csvText, contains('شاشة عرض فائقة الدقة'));
        // Formula '=SUM(A1:A10)' must be prefixed with single quote
        expect(csvText, contains("'=SUM(A1:A10)"));
      },
    );

    test('prepends UTF-8 BOM when requested in options', () async {
      const adapter = CsvExportAdapter(
        options: CsvExportOptions(addUtf8Bom: true),
      );
      const definition = ExportDefinition();

      final bytes = await adapter.export(dataset, definition);
      expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
    });

    test('sanitizes formulas hidden behind leading whitespace', () {
      expect(ExportDefinition.sanitizeFormula('  =1+1'), "'  =1+1");
      expect(ExportDefinition.sanitizeFormula('\t@SUM(A1)'), "'\t@SUM(A1)");
    });

    test('respects specific column selection and ordering', () async {
      const adapter = CsvExportAdapter();
      const definition = ExportDefinition(columns: ['name', 'price']);

      final bytes = await adapter.export(dataset, definition);
      final csvText = utf8.decode(bytes);

      final lines = csvText.trim().split('\r\n');
      expect(lines.first, 'Product Name,Price');
      expect(lines[1], 'Laptop Pro,3499.50');
    });

    test('aborts export when cancellation token is cancelled', () async {
      const adapter = CsvExportAdapter();
      final token = CancellationToken()..cancel('Cancel export');

      expect(
        () => adapter.export(
          dataset,
          const ExportDefinition(),
          cancellationToken: token,
        ),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });
  });
}
