# document_engine

A high-performance, modular, and framework-independent Dart document processing engine for tabular data import/export, dynamic report composition, PDF document rendering, and ESC/POS thermal receipt printing.

---

## Features

- **Pure Dart Core:** Zero Flutter framework dependencies; fully executable on Dart VM, server, CLI, and mobile/desktop clients.
- **Exact Decimal Arithmetic:** Powered by `DecimalNumber`, eliminating binary floating-point representation errors for mission-critical financial calculations.
- **Formula Injection Mitigation:** Built-in spreadsheet formula neutralization (OWASP-compliant prefixing for `=`, `+`, `-`, `@`, `\t`, `\r`) across CSV and XLSX exports.
- **Extensible Import Pipeline:**
  - Standard support for CSV, JSON, and XLSX.
  - Two-phase execution: Schema inspection & validation into an `ImportPlan`, followed by transactional commit via `ImportPersistenceAdapter`.
  - Fine-grained progress reporting and cooperative cancellation via `CancellationToken`.
- **Extensible Export Pipeline:**
  - Streaming tabular data serialization to CSV, JSON, and XLSX.
  - Format-specific optimizations, such as native RTL worksheets (`sheet.isRTL = true`) for Arabic data in Excel.
- **Dynamic Report Composition:**
  - Separation of report definitions from output renderers.
  - Declarative filtering, multi-level sorting, grouping, subtotals, and grand totals (`sum`, `average`, `count`, `min`, `max`).
  - Reference fixtures for Sales, Inventory Movements, Supplier Statements, and Tax Invoices.
- **PDF Report Rendering:**
  - Multi-page document generation with repeated headers, running footers, dynamic page numbering (`Page X of Y`), and RTL/Arabic text shaping.
- **Thermal Receipt Printing:**
  - Native binary ESC/POS receipt generation supporting 58mm (32 columns) and 80mm (48 columns).
  - Emphasized text, text scaling, alignments, dashed separators, and full/partial paper cutting commands.

---

## Installation

Add `document_engine` to your `pubspec.yaml`:

```yaml
dependencies:
  document_engine:
    path: packages/document_engine
```

---

## Core Architecture

The package is organized into distinct domain areas:

```
packages/document_engine/lib/
├── document_engine.dart            # Public library contract
└── src/
    ├── common/                     # DecimalNumber, CancellationToken, DocumentProgress
    ├── dataset/                    # DocumentValue, DocumentColumn, DocumentRow, DocumentDataset
    ├── definition/                 # DocumentDefinition, DocumentDataSource
    ├── errors/                     # DocumentFailure hierarchy (Parse, Validation, Unsupported, Cancelled)
    ├── export/                     # ExportDefinition, ExportAdapter, CsvExportAdapter, JsonExportAdapter, XlsxExportAdapter
    ├── format/                     # DocumentFormat, DocumentFormatRegistry
    ├── import/                     # ImportDefinition, ImportAdapter, ImportPlan, ImportPersistenceAdapter
    ├── pdf/                        # PdfReportRenderer, PdfDocumentOptions, PdfPageSize, PdfPageOrientation
    ├── print/                      # PrintAdapter, PrintJob, ThermalReportAdapter, EscPosCommands
    └── report/                     # ReportDefinition, ReportSection, EvaluatedReport, ReportEngine
```

---

## Usage Examples

### 1. Parsing & Validating CSV Import

```dart
import 'package:document_engine/document_engine.dart';

void main() async {
  final csvAdapter = CsvImportAdapter();
  final csvData = '''
Code,Name,Price,Stock
P-001,Widget A,150.50,10
P-002,Widget B,invalid_price,-5
''';

  final definition = ImportDefinition(
    targetDataset: 'products',
    fields: [
      ImportFieldMapping(
        sourceColumn: 'Code',
        targetField: 'code',
        type: DocumentValueType.string,
        isRequired: true,
      ),
      ImportFieldMapping(
        sourceColumn: 'Price',
        targetField: 'price',
        type: DocumentValueType.decimal,
        isRequired: true,
      ),
      ImportFieldMapping(
        sourceColumn: 'Stock',
        targetField: 'stock',
        type: DocumentValueType.integer,
        customValidator: (val) {
          final intVal = (val as DocumentValueInteger).value;
          return intVal >= 0 ? null : 'Stock cannot be negative';
        },
      ),
    ],
  );

  final plan = await csvAdapter.createPlan(
    definition: definition,
    source: DocumentDataSource.fromString(csvData),
  );

  print('Total rows: ${plan.totalRows}');
  print('Valid rows: ${plan.validRows.length}');
  print('Invalid rows: ${plan.invalidRows.length}');

  for (final error in plan.errors) {
    print('Row ${error.rowIndex}: ${error.field} - ${error.message}');
  }
}
```

### 2. Exporting to XLSX with Formula Protection & RTL

```dart
import 'dart:io';
import 'package:document_engine/document_engine.dart';

void main() async {
  final dataset = DocumentDataset(
    name: 'Sales',
    columns: const [
      DocumentColumn(id: 'sku', label: 'SKU', type: DocumentValueType.string),
      DocumentColumn(id: 'name', label: 'الاسم', type: DocumentValueType.string),
      DocumentColumn(id: 'total', label: 'المجموع', type: DocumentValueType.decimal),
    ],
    rows: [
      DocumentRow({
        'sku': const DocumentValueString('SKU-100'),
        'name': const DocumentValueString('منتج تجريبي'),
        'total': DocumentValueDecimal(DecimalNumber.fromNum(1250.75)),
      }),
      DocumentRow({
        'sku': const DocumentValueString('=SUM(A1:A10)'), // Untrusted formula
        'name': const DocumentValueString('صيغة غير آمنة'),
        'total': DocumentValueDecimal(DecimalNumber.fromNum(0)),
      }),
    ],
  );

  final xlsxAdapter = XlsxExportAdapter();
  final exportBytes = await xlsxAdapter.export(
    definition: ExportDefinition(
      dataset: dataset,
      selectedColumnIds: ['sku', 'name', 'total'],
      sanitizeFormulas: true, // Neutralizes spreadsheet formula injection
    ),
    options: const ExportOptions(isRTL: true),
  );

  await File('sales_report.xlsx').writeAsBytes(exportBytes);
}
```

### 3. Report Composition with Grouping & Subtotals

```dart
import 'package:document_engine/document_engine.dart';

void main() async {
  final reportDefinition = ReportDefinition(
    id: 'sales_summary',
    title: 'Sales by Region',
    dataset: salesDataset,
    columns: const [
      ReportColumn(id: 'salesperson', label: 'Salesperson'),
      ReportColumn(id: 'amount', label: 'Amount', aggregate: AggregateType.sum),
    ],
    groupByField: 'region',
    sortByFields: const [
      ReportSort(field: 'amount', descending: true),
    ],
    showSubtotals: true,
    showGrandTotal: true,
  );

  final engine = ReportEngine();
  final evaluated = await engine.evaluate(reportDefinition);

  for (final group in evaluated.groups) {
    print('Region: ${group.key}');
    for (final row in group.rows) {
      print('  ${row.values['salesperson']}: ${row.values['amount']}');
    }
    print('  Subtotal: ${group.subtotals['amount']}');
  }
  print('Grand Total: ${evaluated.grandTotals['amount']}');
}
```

### 4. ESC/POS Thermal Receipt Printing

```dart
import 'package:document_engine/document_engine.dart';

void main() async {
  final evaluatedReport = await ReportEngine().evaluate(referenceTaxInvoiceReport);
  final transport = InMemoryThermalTransport();

  final thermalAdapter = ThermalReportAdapter(
    paperWidth: ThermalPaperWidth.mm80,
    transport: transport,
  );

  await thermalAdapter.printReport(evaluatedReport);

  print('Receipt generated: ${transport.sentBytes.length} bytes');
}
```

---

## Testing & Quality Gates

Run all automated unit tests:

```bash
fvm dart test
```

Verify formatting and static analysis:

```bash
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
```

