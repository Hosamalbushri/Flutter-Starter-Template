import 'dart:convert';

import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  group('ReportEngine Evaluation', () {
    const engine = ReportEngine();

    test(
      'evaluates Sales Report with grouping, subtotals, and grand totals',
      () {
        final (definition, dataset) =
            ReferenceReportFixtures.createSalesReport();
        final evaluated = engine.evaluate(definition, dataset);

        expect(evaluated.totalRowCount, 3);
        expect(evaluated.groups.length, 2); // 'North' and 'South'

        // Check North Group
        final northGroup = evaluated.groups.firstWhere(
          (g) => g.groupLabel == 'North',
        );
        expect(northGroup.rowCount, 2);
        expect(northGroup.subtotals['ordersCount']?.asInt, 22); // 14 + 8
        expect(
          northGroup.subtotals['revenue']?.asDecimal,
          DecimalNumber.parse('67500.00'), // 45000 + 22500
        );
        expect(
          northGroup.subtotals['commission']?.asDecimal,
          DecimalNumber.parse('6750.00'),
        );

        // Check South Group
        final southGroup = evaluated.groups.firstWhere(
          (g) => g.groupLabel == 'South',
        );
        expect(southGroup.rowCount, 1);
        expect(southGroup.subtotals['ordersCount']?.asInt, 20);
        expect(
          southGroup.subtotals['revenue']?.asDecimal,
          DecimalNumber.parse('78000.00'),
        );

        // Check Grand Totals
        expect(evaluated.grandTotals['ordersCount']?.asInt, 42); // 22 + 20
        expect(
          evaluated.grandTotals['revenue']?.asDecimal,
          DecimalNumber.parse('145500.00'), // 67500 + 78000
        );
      },
    );

    test(
      'evaluates Inventory Movement Report with INBOUND and OUTBOUND partitions',
      () {
        final (definition, dataset) =
            ReferenceReportFixtures.createInventoryMovementReport();
        final evaluated = engine.evaluate(definition, dataset);

        expect(evaluated.totalRowCount, 3);
        expect(evaluated.groups.length, 2);

        final inbound = evaluated.groups.firstWhere(
          (g) => g.groupLabel == 'INBOUND',
        );
        expect(inbound.rowCount, 2);
        expect(inbound.subtotals['quantity']?.asInt, 620); // 500 + 120

        final outbound = evaluated.groups.firstWhere(
          (g) => g.groupLabel == 'OUTBOUND',
        );
        expect(outbound.rowCount, 1);
        expect(outbound.subtotals['quantity']?.asInt, 80);

        expect(evaluated.grandTotals['quantity']?.asInt, 700);
      },
    );

    test('evaluates Supplier Statement in Arabic with debit/credit totals', () {
      final (definition, dataset) =
          ReferenceReportFixtures.createSupplierStatementReport();
      final evaluated = engine.evaluate(definition, dataset);

      expect(evaluated.definition.isRtl, isTrue);
      expect(evaluated.totalRowCount, 2);

      expect(
        evaluated.grandTotals['debit']?.asDecimal,
        DecimalNumber.parse('10000.00'),
      );
      expect(
        evaluated.grandTotals['credit']?.asDecimal,
        DecimalNumber.parse('14500.00'),
      );
    });

    test('evaluates Commercial Invoice Line Items and computes subtotal', () {
      final (definition, dataset) =
          ReferenceReportFixtures.createInvoiceDocumentReport();
      final evaluated = engine.evaluate(definition, dataset);

      expect(evaluated.totalRowCount, 2);
      expect(
        evaluated.grandTotals['lineTotal']?.asDecimal,
        DecimalNumber.parse('9000.00'), // 6000 + 3000
      );
    });

    test(
      'evaluates General Tabular Report applying filter and sort descending',
      () {
        final (definition, dataset) =
            ReferenceReportFixtures.createGeneralTabularReport();
        final evaluated = engine.evaluate(definition, dataset);

        // Only SUCCESS status rows should be retained (2 of 3)
        expect(evaluated.totalRowCount, 2);

        // Sorted descending by timestamp
        final rows = evaluated.allRows;
        final time1 = rows[0]['timestamp'].asDateTime!;
        final time2 = rows[1]['timestamp'].asDateTime!;
        expect(time1.isAfter(time2), isTrue);

        expect(evaluated.grandTotals['action']?.asInt, 2);
      },
    );

    test('aborts evaluation when cancellation token is cancelled', () {
      final (definition, dataset) = ReferenceReportFixtures.createSalesReport();
      final token = CancellationToken()..cancel('Cancel evaluation');

      expect(
        () => engine.evaluate(definition, dataset, cancellationToken: token),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });
  });

  group('CsvReportRenderer', () {
    const renderer = CsvReportRenderer();

    test('renders Sales Report into formatted CSV table bytes', () async {
      final (definition, dataset) = ReferenceReportFixtures.createSalesReport();
      final bytes = await renderer.render(definition, dataset);
      final text = utf8.decode(bytes);

      expect(text, contains('Sales Performance Report'));
      expect(text, contains('Q3 Regional Sales Performance'));
      expect(
        text,
        contains('Region,Sales Rep,Orders,Total Revenue,Commission'),
      );
      expect(text, contains('--- North ---'));
      expect(text, contains('Subtotal (North),,22,67500,6750'));
      expect(text, contains('--- South ---'));
      expect(text, contains('Grand Total,,42,145500,14550'));
    });
  });
}
