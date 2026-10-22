import 'dart:convert';

import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PdfReportRenderer', () {
    const renderer = PdfReportRenderer();

    test('renders Sales Report into valid PDF binary stream', () async {
      final (definition, dataset) = ReferenceReportFixtures.createSalesReport();
      final bytes = await renderer.render(definition, dataset);

      expect(bytes.isNotEmpty, isTrue);

      // Verify PDF magic header: %PDF-
      final headerStr = utf8.decode(bytes.sublist(0, 5));
      expect(headerStr, '%PDF-');

      // Verify EOF marker in trailer
      final trailerStr = utf8.decode(
        bytes.sublist(bytes.length - 30),
        allowMalformed: true,
      );
      expect(trailerStr, contains('%%EOF'));
    });

    test(
      'renders with custom A5 page size and landscape orientation',
      () async {
        const customRenderer = PdfReportRenderer(
          options: PdfReportOptions(
            pageSize: PdfPageSize.a5,
            orientation: PdfOrientation.landscape,
            margin: 20,
          ),
        );

        final (definition, dataset) =
            ReferenceReportFixtures.createSalesReport();
        final bytes = await customRenderer.render(definition, dataset);

        expect(bytes.isNotEmpty, isTrue);
        expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      },
    );

    test('renders Tax Invoice document with metadata and parameters', () async {
      final (definition, dataset) =
          ReferenceReportFixtures.createInvoiceDocumentReport();
      final bytes = await renderer.render(definition, dataset);

      expect(bytes.isNotEmpty, isTrue);
      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('embeds Unicode fonts when rendering an Arabic RTL report', () async {
      final (definition, dataset) =
          ReferenceReportFixtures.createSupplierStatementReport();

      expect(definition.textDirection, DocumentTextDirection.rtl);

      final bytes = await renderer.render(definition, dataset);
      final pdfSource = latin1.decode(bytes, allowInvalid: true);

      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(pdfSource, contains('/ToUnicode'));
      expect(pdfSource, contains('DejaVuSans'));
      expect(bytes.length, greaterThan(10000));
    });

    test('renders multi-page dataset across page boundaries', () async {
      final (baseDef, _) = ReferenceReportFixtures.createSalesReport();
      final manyRows = <DocumentRow>[];

      for (var i = 0; i < 80; i++) {
        manyRows.add(
          DocumentRow(
            index: i,
            cells: {
              'region': DocumentValue.from(
                i < 40 ? 'Region Alpha' : 'Region Beta',
              ),
              'rep': DocumentValue.from('Representative #$i'),
              'ordersCount': DocumentValue.from(i + 1),
              'revenue': DocumentValue.from(
                DecimalNumber.fromInt((i + 1) * 100),
              ),
              'commission': DocumentValue.from(
                DecimalNumber.fromInt((i + 1) * 10),
              ),
            },
          ),
        );
      }

      final schema = DocumentDefinition(
        id: 'multi_page_schema',
        title: 'Large Report',
        columns: baseDef.columns,
      );
      final dataset = DocumentDataset(definition: schema, rows: manyRows);

      final bytes = await renderer.render(baseDef, dataset);
      expect(bytes.length, greaterThan(1000));
      expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('aborts PDF rendering when cancellation token is cancelled', () async {
      final (definition, dataset) = ReferenceReportFixtures.createSalesReport();
      final token = CancellationToken()..cancel('User cancelled PDF');

      expect(
        () => renderer.render(definition, dataset, cancellationToken: token),
        throwsA(isA<DocumentCancellationFailure>()),
      );
    });
  });
}
