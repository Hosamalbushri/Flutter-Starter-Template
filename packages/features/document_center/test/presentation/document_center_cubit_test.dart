import 'dart:convert';

import 'package:feature_document_center/feature_document_center.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentCenterCubit', () {
    late DocumentCenterCubit cubit;

    setUp(() {
      cubit = DocumentCenterCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.isReady, isFalse);
      expect(cubit.state.currentTabIndex, 0);
      expect(cubit.state.selectedExportDataset, 'sales');
      expect(cubit.state.selectedExportFormat, 'csv');
      expect(cubit.state.neutralizeFormulas, isTrue);
    });

    test(
      'load() marks state as ready and generates initial PDF preview',
      () async {
        await cubit.load();
        expect(cubit.state.isReady, isTrue);
        expect(cubit.state.generatedPdfBytes, isNotNull);
        expect(cubit.state.generatedPdfBytes, isNotEmpty);
      },
    );

    test('changeTab() updates currentTabIndex and clears notices', () {
      cubit.changeTab(1);
      expect(cubit.state.currentTabIndex, 1);

      cubit.changeTab(2);
      expect(cubit.state.currentTabIndex, 2);
    });

    group('Import Workflow', () {
      test('selectFileManually validates valid CSV content', () async {
        const csvContent =
            'Region,Sales Rep,Orders,Total Revenue,Commission\n'
            'North,Alice Smith,14,45000.00,4500.00\n'
            'South,Bob Jones,8,22500.00,2250.00\n';

        cubit.selectFileManually(
          fileName: 'sales_data.csv',
          bytes: utf8.encode(csvContent),
        );

        // Allow microtasks to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.selectedFileName, 'sales_data.csv');
        expect(cubit.state.detectedFormat, 'csv');
        expect(cubit.state.importPlan, isNotNull);
        expect(cubit.state.importPlan!.validCount, 2);
        expect(cubit.state.importPlan!.invalidCount, 0);
        expect(cubit.state.importPlan!.canCommit, isTrue);
      });

      test('commitCurrentImport persists valid rows transactionally', () async {
        const csvContent =
            'Region,Sales Rep,Orders,Total Revenue,Commission\n'
            'North,Alice Smith,14,45000.00,4500.00\n';

        cubit.selectFileManually(
          fileName: 'test.csv',
          bytes: utf8.encode(csvContent),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await cubit.commitCurrentImport();

        expect(cubit.state.committedCount, 1);
        expect(cubit.persistenceAdapter.committedRows.length, 1);
      });
    });

    group('Export Workflow', () {
      test('setExportDataset and setExportFormat update state', () {
        cubit.setExportDataset('inventory');
        expect(cubit.state.selectedExportDataset, 'inventory');

        cubit.setExportFormat('xlsx');
        expect(cubit.state.selectedExportFormat, 'xlsx');

        cubit.toggleNeutralizeFormulas(value: false);
        expect(cubit.state.neutralizeFormulas, isFalse);
      });

      test('executeExport generates non-empty output bytes', () async {
        cubit.setExportDataset('sales');
        cubit.setExportFormat('csv');

        final bytes = await cubit.executeExport();

        expect(bytes, isNotNull);
        expect(bytes, isNotEmpty);
        expect(cubit.state.lastExportedBytes, bytes!.length);
        expect(cubit.state.generatedExportBytes, orderedEquals(bytes));
        expect(cubit.state.isExporting, isFalse);
      });

      test('executeExport generates PDF through the report renderer', () async {
        cubit.setExportDataset('sales');
        cubit.setExportFormat('pdf');

        final bytes = await cubit.executeExport();

        expect(bytes, isNotNull);
        expect(utf8.decode(bytes!.sublist(0, 5)), '%PDF-');
        expect(cubit.state.exportFailure, isNull);
        expect(cubit.state.generatedExportBytes, orderedEquals(bytes));
      });

      test('changing export options clears stale generated output', () async {
        await cubit.executeExport();
        expect(cubit.state.generatedExportBytes, isNotNull);

        cubit.setExportFormat('json');

        expect(cubit.state.generatedExportBytes, isNull);
        expect(cubit.state.lastExportedBytes, isNull);
      });
    });

    group('Reports & Printing Workflow', () {
      test('selectReport updates key and regenerates PDF bytes', () async {
        cubit.selectReport('invoice');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(cubit.state.selectedReportKey, 'invoice');
        expect(cubit.state.generatedPdfBytes, isNotNull);
      });

      test(
        'printThermalReceipt generates ESC/POS bytes and logs notice',
        () async {
          await cubit.printThermalReceipt();

          expect(cubit.thermalTransport.sentJobs, isNotEmpty);
          expect(
            cubit.state.reportNotice,
            DocumentCenterNotice.thermalSuccess,
          );
          expect(cubit.state.reportNoticeBytes, isPositive);
        },
      );
    });
  });
}
