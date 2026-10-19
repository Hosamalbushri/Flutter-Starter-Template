import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  group('ThermalReceiptBuilder', () {
    test('initializes with ESC @', () {
      final builder = ThermalReceiptBuilder(paperWidth: ThermalPaperWidth.mm80);
      final bytes = builder.toBytes();
      expect(bytes.sublist(0, 2), [0x1B, 0x40]);
    });

    test('formats text with alignment, bold, and line feed', () {
      final builder = ThermalReceiptBuilder();
      builder.text('CENTER HEADER', align: ThermalAlign.center, bold: true);
      final bytes = builder.toBytes();
      expect(bytes, containsAllInOrder([0x1B, 0x61, 1])); // Align center
      expect(bytes, containsAllInOrder([0x1B, 0x45, 1])); // Bold on
      expect(bytes, contains(0x0A)); // LF
      expect(bytes, containsAllInOrder([0x1B, 0x45, 0])); // Bold reset
    });

    test('formats multi-column rows adhering to 58mm 32-char width', () {
      final builder = ThermalReceiptBuilder(paperWidth: ThermalPaperWidth.mm58);
      builder.row([
        const ThermalColumn(
          text: 'Item',
          widthRatio: 0.5,
          align: ThermalAlign.left,
        ),
        const ThermalColumn(
          text: 'Price',
          widthRatio: 0.5,
          align: ThermalAlign.right,
        ),
      ]);
      final bytes = builder.toBytes();
      expect(bytes, isNotEmpty);
      expect(builder.charsPerLine, 32);
    });

    test('generates dividers and cut commands', () {
      final builder = ThermalReceiptBuilder();
      builder.divider();
      builder.doubleDivider();
      builder.cut();
      final bytes = builder.toBytes();
      // Cut command sequence
      expect(bytes, containsAllInOrder([0x1D, 0x56, 0x41, 0x03]));
    });
  });

  group('ThermalReportAdapter', () {
    test('renders evaluated report to ESC/POS binary stream', () {
      final (definition, dataset) =
          ReferenceReportFixtures.createInvoiceDocumentReport();
      const engine = ReportEngine();
      final evaluated = engine.evaluate(definition, dataset);

      final adapter = ThermalReportAdapter(paperWidth: ThermalPaperWidth.mm80);
      final bytes = adapter.renderReport(evaluated);

      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 2), [0x1B, 0x40]); // ESC @
      expect(bytes, containsAllInOrder([0x1D, 0x56, 0x41, 0x03])); // Cut
    });

    test(
      'sends bytes to InMemoryThermalTransport when printDocument called',
      () async {
        final transport = InMemoryThermalTransport();
        final adapter = ThermalReportAdapter(transport: transport);

        final testBytes = [1, 2, 3, 4];
        final result = await adapter.printDocument(
          testBytes,
          jobName: 'Receipt #1001',
        );

        expect(result, isTrue);
        expect(transport.sentJobs.length, 1);
        expect(transport.sentJobs.first, testBytes);
      },
    );

    test('throws DocumentCancellationFailure when cancelled', () {
      final (definition, dataset) =
          ReferenceReportFixtures.createInvoiceDocumentReport();
      const engine = ReportEngine();
      final evaluated = engine.evaluate(definition, dataset);

      final token = CancellationToken()..cancel();
      final adapter = ThermalReportAdapter();

      expect(
        () => adapter.renderReport(evaluated, cancellationToken: token),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });

    test('registered in DocumentFormatRegistry.standard()', () {
      final registry = DocumentFormatRegistry.standard();
      final adapter = registry.getPrintAdapter('thermal_esc_pos');
      expect(adapter, isNotNull);
      expect(adapter, isA<ThermalReportAdapter>());
    });
  });
}
