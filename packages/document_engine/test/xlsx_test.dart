import 'package:document_engine/document_engine.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:test/test.dart';

void main() {
  late DocumentDefinition schema;

  setUp(() {
    schema = DocumentDefinition(
      id: 'inventory',
      title: 'Warehouse Inventory',
      columns: [
        DocumentColumn.integer(id: 'skuId', label: 'SKU ID', isRequired: true),
        DocumentColumn.text(id: 'title', label: 'Item Title', isRequired: true),
        DocumentColumn.decimal(
          id: 'unitCost',
          label: 'Unit Cost',
          isRequired: true,
        ),
        DocumentColumn.integer(id: 'quantity', label: 'Quantity Available'),
        DocumentColumn.date(id: 'restockDate', label: 'Restock Date'),
        DocumentColumn.boolean(id: 'inStock', label: 'In Stock'),
      ],
    );
  });

  group('XlsxExportAdapter & XlsxImportAdapter Round-Trip', () {
    const exportAdapter = XlsxExportAdapter();
    const importAdapter = XlsxImportAdapter();

    test(
      'exports and imports dataset preserving types, decimals, and Arabic text',
      () async {
        final rows = [
          DocumentRow(
            index: 0,
            cells: {
              'skuId': DocumentValue.from(1001),
              'title': DocumentValue.from('طابعة حرارية نقطية'),
              'unitCost': DocumentValue.from(DecimalNumber.parse('289.50')),
              'quantity': DocumentValue.from(40),
              'restockDate': DocumentValue.from(DateTime(2026, 8, 12)),
              'inStock': DocumentValue.from(true),
            },
          ),
          DocumentRow(
            index: 1,
            cells: {
              'skuId': DocumentValue.from(1002),
              'title': DocumentValue.from('Barcode Scanner Wireless'),
              'unitCost': DocumentValue.from(DecimalNumber.parse('95.00')),
              'quantity': DocumentValue.from(0),
              'restockDate': const NullDocumentValue(ColumnType.date),
              'inStock': DocumentValue.from(false),
            },
          ),
        ];
        final dataset = DocumentDataset(definition: schema, rows: rows);

        // 1. Export
        const definition = ExportDefinition(sheetName: 'المخزون');
        final bytes = await exportAdapter.export(dataset, definition);

        expect(bytes.isNotEmpty, isTrue);
        // ZIP magic bytes: PK (0x50, 0x4B)
        expect(bytes[0], 0x50);
        expect(bytes[1], 0x4B);

        // 2. Inspect Headers
        final headers = await importAdapter.inspectHeaders(bytes);
        expect(
          headers,
          [
            'SKU ID',
            'Item Title',
            'Unit Cost',
            'Quantity Available',
            'Restock Date',
            'In Stock',
          ],
        );

        // 3. Import Plan
        final importDef = ImportDefinition(
          targetDefinition: schema,
          allowPartial: false,
        );
        final plan = await importAdapter.preparePlan(bytes, importDef);

        expect(plan.totalInspected, 2);
        expect(plan.validCount, 2);
        expect(plan.invalidCount, 0);
        expect(plan.canCommit, isTrue);

        final row1 = plan.validRows[0];
        expect(row1['skuId'].asInt, 1001);
        expect(row1['title'].asString, 'طابعة حرارية نقطية');
        expect(row1['unitCost'].asDecimal, DecimalNumber.parse('289.5'));
        expect(row1['quantity'].asInt, 40);
        expect(row1['inStock'].asBool, isTrue);

        final row2 = plan.validRows[1];
        expect(row2['skuId'].asInt, 1002);
        expect(row2['title'].asString, 'Barcode Scanner Wireless');
        expect(row2['inStock'].asBool, isFalse);
      },
    );

    test('protects against formula injection in exported Excel cells', () async {
      final rows = [
        DocumentRow(
          index: 0,
          cells: {
            'skuId': DocumentValue.from(9999),
            'title': DocumentValue.from('=SUM(1, 2)'),
            'unitCost': DocumentValue.from(DecimalNumber.parse('1.00')),
            'quantity': DocumentValue.from(1),
            'restockDate': const NullDocumentValue(ColumnType.date),
            'inStock': DocumentValue.from(true),
          },
        ),
      ];
      final dataset = DocumentDataset(definition: schema, rows: rows);

      const exportAdapter = XlsxExportAdapter(
        options: XlsxExportOptions(sanitizeFormulaInjection: true),
      );
      final bytes = await exportAdapter.export(
        dataset,
        const ExportDefinition(),
      );

      final plan = await importAdapter.preparePlan(
        bytes,
        ImportDefinition(targetDefinition: schema),
      );

      expect(plan.validCount, 1);
      // The injected formula should have been neutralized with leading single quote
      expect(plan.validRows.first['title'].asString, "'=SUM(1, 2)");
    });

    test(
      'preserves decimals that are not exactly representable as doubles',
      () async {
        final dataset = DocumentDataset(
          definition: schema,
          rows: [
            DocumentRow(
              index: 0,
              cells: {
                'skuId': DocumentValue.from(1),
                'title': DocumentValue.from('Precision test'),
                'unitCost': DocumentValue.from(
                  DecimalNumber.parse('9007199254740993.01'),
                ),
              },
            ),
          ],
        );

        final bytes = await exportAdapter.export(
          dataset,
          const ExportDefinition(),
        );
        final plan = await importAdapter.preparePlan(
          bytes,
          ImportDefinition(targetDefinition: schema),
        );

        expect(
          plan.validRows.single['unitCost'].asDecimal,
          DecimalNumber.parse('9007199254740993.01'),
        );
      },
    );

    test(
      'throws DocumentParseFailure on corrupted or invalid Excel bytes',
      () async {
        final corruptBytes = <int>[1, 2, 3, 4, 5, 6, 7, 8];

        expect(
          () => importAdapter.inspectHeaders(corruptBytes),
          throwsA(isA<DocumentParseFailure>()),
        );
      },
    );

    test('rejects oversized bytes before attempting workbook decoding', () {
      expect(
        () => importAdapter.preparePlan(
          List<int>.filled(9, 0),
          ImportDefinition(targetDefinition: schema, maxFileBytes: 8),
        ),
        throwsA(isA<DocumentValidationFailure>()),
      );
    });

    test('rejects duplicate workbook headers', () async {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];
      sheet.appendRow([
        TextCellValue('skuId'),
        TextCellValue('title'),
        TextCellValue('title'),
      ]);
      final bytes = excel.encode()!;

      expect(
        () => importAdapter.inspectHeaders(bytes),
        throwsA(
          isA<DocumentParseFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Duplicate Excel header "title"'),
          ),
        ),
      );
    });

    test('aborts XLSX export when cancellation token is cancelled', () async {
      final rows = [
        DocumentRow(
          index: 0,
          cells: {
            'skuId': DocumentValue.from(1),
            'title': DocumentValue.from('Item'),
            'unitCost': DocumentValue.from(DecimalNumber.parse('10.00')),
            'quantity': DocumentValue.from(1),
            'restockDate': const NullDocumentValue(ColumnType.date),
            'inStock': DocumentValue.from(true),
          },
        ),
      ];
      final dataset = DocumentDataset(definition: schema, rows: rows);
      final token = CancellationToken()..cancel('Cancelled');

      expect(
        () => exportAdapter.export(
          dataset,
          const ExportDefinition(),
          cancellationToken: token,
        ),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });
  });
}
