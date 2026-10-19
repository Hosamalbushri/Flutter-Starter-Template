import '../../model/document_column.dart';
import '../../model/document_dataset.dart';
import '../../model/document_definition.dart';
import '../../model/document_row.dart';
import '../../model/document_value.dart';
import '../../numerics/decimal_number.dart';
import '../report_definition.dart';

/// Test fixtures and reference report definitions illustrating standard business reporting use cases.
abstract final class ReferenceReportFixtures {
  /// Reference Report 1: Sales Summary Report
  static (ReportDefinition, DocumentDataset) createSalesReport() {
    final definition = ReportDefinition(
      id: 'sales_summary',
      title: 'Sales Performance Report',
      subtitle: 'Q3 Regional Sales Performance',
      textDirection: DocumentTextDirection.ltr,
      columns: [
        DocumentColumn.text(id: 'region', label: 'Region'),
        DocumentColumn.text(id: 'rep', label: 'Sales Rep'),
        DocumentColumn.integer(id: 'ordersCount', label: 'Orders'),
        DocumentColumn.decimal(id: 'revenue', label: 'Total Revenue'),
        DocumentColumn.decimal(id: 'commission', label: 'Commission'),
      ],
      groupings: const [
        ReportGrouping(columnId: 'region', showSubtotals: true),
      ],
      summaries: const [
        ReportSummary(columnId: 'ordersCount', function: SummaryFunction.sum),
        ReportSummary(columnId: 'revenue', function: SummaryFunction.sum),
        ReportSummary(columnId: 'commission', function: SummaryFunction.sum),
      ],
      sortDescriptors: const [
        ReportSortDescriptor(columnId: 'region'),
        ReportSortDescriptor(
          columnId: 'revenue',
          direction: ReportSortDirection.descending,
        ),
      ],
    );

    final schema = DocumentDefinition(
      id: 'sales_data',
      title: 'Sales Raw Data',
      columns: definition.columns,
    );

    final rows = [
      DocumentRow(
        index: 0,
        cells: {
          'region': DocumentValue.from('North'),
          'rep': DocumentValue.from('Alice Smith'),
          'ordersCount': DocumentValue.from(14),
          'revenue': DocumentValue.from(DecimalNumber.parse('45000.00')),
          'commission': DocumentValue.from(DecimalNumber.parse('4500.00')),
        },
      ),
      DocumentRow(
        index: 1,
        cells: {
          'region': DocumentValue.from('North'),
          'rep': DocumentValue.from('Bob Jones'),
          'ordersCount': DocumentValue.from(8),
          'revenue': DocumentValue.from(DecimalNumber.parse('22500.00')),
          'commission': DocumentValue.from(DecimalNumber.parse('2250.00')),
        },
      ),
      DocumentRow(
        index: 2,
        cells: {
          'region': DocumentValue.from('South'),
          'rep': DocumentValue.from('Charlie Brown'),
          'ordersCount': DocumentValue.from(20),
          'revenue': DocumentValue.from(DecimalNumber.parse('78000.00')),
          'commission': DocumentValue.from(DecimalNumber.parse('7800.00')),
        },
      ),
    ];

    return (definition, DocumentDataset(definition: schema, rows: rows));
  }

  /// Reference Report 2: Inventory Movement Report
  static (ReportDefinition, DocumentDataset) createInventoryMovementReport() {
    final definition = ReportDefinition(
      id: 'inventory_movements',
      title: 'Inventory Movement Log',
      subtitle: 'Central Warehouse In/Out Transactions',
      columns: [
        DocumentColumn.text(id: 'sku', label: 'SKU Code'),
        DocumentColumn.text(id: 'description', label: 'Description'),
        DocumentColumn.text(id: 'movementType', label: 'Type'),
        DocumentColumn.integer(id: 'quantity', label: 'Quantity'),
        DocumentColumn.date(id: 'date', label: 'Transaction Date'),
      ],
      groupings: const [
        ReportGrouping(columnId: 'movementType', showSubtotals: true),
      ],
      summaries: const [
        ReportSummary(columnId: 'quantity', function: SummaryFunction.sum),
      ],
    );

    final schema = DocumentDefinition(
      id: 'inv_schema',
      title: 'Inventory Data',
      columns: definition.columns,
    );

    final rows = [
      DocumentRow(
        index: 0,
        cells: {
          'sku': DocumentValue.from('ITEM-001'),
          'description': DocumentValue.from('Thermal Paper Roll 80mm'),
          'movementType': DocumentValue.from('INBOUND'),
          'quantity': DocumentValue.from(500),
          'date': DocumentValue.from(DateTime(2026, 9, 1)),
        },
      ),
      DocumentRow(
        index: 1,
        cells: {
          'sku': DocumentValue.from('ITEM-002'),
          'description': DocumentValue.from('Barcode Ribbon Resin'),
          'movementType': DocumentValue.from('INBOUND'),
          'quantity': DocumentValue.from(120),
          'date': DocumentValue.from(DateTime(2026, 9, 2)),
        },
      ),
      DocumentRow(
        index: 2,
        cells: {
          'sku': DocumentValue.from('ITEM-001'),
          'description': DocumentValue.from('Thermal Paper Roll 80mm'),
          'movementType': DocumentValue.from('OUTBOUND'),
          'quantity': DocumentValue.from(80),
          'date': DocumentValue.from(DateTime(2026, 9, 5)),
        },
      ),
    ];

    return (definition, DocumentDataset(definition: schema, rows: rows));
  }

  /// Reference Report 3: Supplier Account Statement (Arabic/RTL)
  static (ReportDefinition, DocumentDataset) createSupplierStatementReport() {
    final definition = ReportDefinition(
      id: 'supplier_statement',
      title: 'كشف حساب مورد',
      subtitle: 'شركة التوريدات العالمية المحدودة',
      textDirection: DocumentTextDirection.rtl,
      columns: [
        DocumentColumn.date(id: 'transDate', label: 'التاريخ'),
        DocumentColumn.text(id: 'refNo', label: 'رقم المرجع'),
        DocumentColumn.text(id: 'details', label: 'البيان'),
        DocumentColumn.decimal(id: 'debit', label: 'مدين'),
        DocumentColumn.decimal(id: 'credit', label: 'دائن'),
        DocumentColumn.decimal(id: 'balance', label: 'الرصيد'),
      ],
      summaries: const [
        ReportSummary(columnId: 'debit', function: SummaryFunction.sum),
        ReportSummary(columnId: 'credit', function: SummaryFunction.sum),
      ],
    );

    final schema = DocumentDefinition(
      id: 'supplier_statement_schema',
      title: 'Supplier Statement',
      columns: definition.columns,
    );

    final rows = [
      DocumentRow(
        index: 0,
        cells: {
          'transDate': DocumentValue.from(DateTime(2026, 8, 1)),
          'refNo': DocumentValue.from('INV-8812'),
          'details': DocumentValue.from('فاتورة مشتريات بضاعة'),
          'debit': DocumentValue.from(DecimalNumber.zero),
          'credit': DocumentValue.from(DecimalNumber.parse('14500.00')),
          'balance': DocumentValue.from(DecimalNumber.parse('14500.00')),
        },
      ),
      DocumentRow(
        index: 1,
        cells: {
          'transDate': DocumentValue.from(DateTime(2026, 8, 15)),
          'refNo': DocumentValue.from('PAY-1044'),
          'details': DocumentValue.from('سند صرف دفعة نقدية'),
          'debit': DocumentValue.from(DecimalNumber.parse('10000.00')),
          'credit': DocumentValue.from(DecimalNumber.zero),
          'balance': DocumentValue.from(DecimalNumber.parse('4500.00')),
        },
      ),
    ];

    return (definition, DocumentDataset(definition: schema, rows: rows));
  }

  /// Reference Report 4: Commercial Invoice Document
  static (ReportDefinition, DocumentDataset) createInvoiceDocumentReport() {
    final definition = ReportDefinition(
      id: 'tax_invoice',
      title: 'Tax Invoice',
      subtitle: 'Invoice #INV-2026-9041',
      parameters: const {
        'customer': 'Global Logistics Services',
        'issueDate': '2026-10-15',
        'currency': 'USD',
      },
      columns: [
        DocumentColumn.integer(id: 'lineNo', label: '#'),
        DocumentColumn.text(id: 'item', label: 'Description'),
        DocumentColumn.integer(id: 'quantity', label: 'Qty'),
        DocumentColumn.decimal(id: 'unitPrice', label: 'Unit Price'),
        DocumentColumn.decimal(id: 'lineTotal', label: 'Total'),
      ],
      summaries: const [
        ReportSummary(
          columnId: 'lineTotal',
          function: SummaryFunction.sum,
          label: 'Subtotal',
        ),
      ],
    );

    final schema = DocumentDefinition(
      id: 'invoice_schema',
      title: 'Invoice Lines',
      columns: definition.columns,
    );

    final rows = [
      DocumentRow(
        index: 0,
        cells: {
          'lineNo': DocumentValue.from(1),
          'item': DocumentValue.from('Enterprise Software License'),
          'quantity': DocumentValue.from(5),
          'unitPrice': DocumentValue.from(DecimalNumber.parse('1200.00')),
          'lineTotal': DocumentValue.from(DecimalNumber.parse('6000.00')),
        },
      ),
      DocumentRow(
        index: 1,
        cells: {
          'lineNo': DocumentValue.from(2),
          'item': DocumentValue.from('Implementation & Consulting Hours'),
          'quantity': DocumentValue.from(20),
          'unitPrice': DocumentValue.from(DecimalNumber.parse('150.00')),
          'lineTotal': DocumentValue.from(DecimalNumber.parse('3000.00')),
        },
      ),
    ];

    return (definition, DocumentDataset(definition: schema, rows: rows));
  }

  /// Reference Report 5: General Purpose Tabular Report with filtering and custom sorting
  static (ReportDefinition, DocumentDataset) createGeneralTabularReport() {
    final definition = ReportDefinition(
      id: 'system_audit_log',
      title: 'System Activity Audit Log',
      columns: [
        DocumentColumn.dateTime(id: 'timestamp', label: 'Timestamp'),
        DocumentColumn.text(id: 'userId', label: 'User ID'),
        DocumentColumn.text(id: 'action', label: 'Action'),
        DocumentColumn.text(id: 'status', label: 'Status'),
      ],
      filter: (row) => row['status'].asString == 'SUCCESS',
      sortDescriptors: const [
        ReportSortDescriptor(
          columnId: 'timestamp',
          direction: ReportSortDirection.descending,
        ),
      ],
      summaries: const [
        ReportSummary(columnId: 'action', function: SummaryFunction.count),
      ],
    );

    final schema = DocumentDefinition(
      id: 'audit_schema',
      title: 'Audit Logs',
      columns: definition.columns,
    );

    final rows = [
      DocumentRow(
        index: 0,
        cells: {
          'timestamp': DocumentValue.from(DateTime(2026, 10, 18, 14, 30)),
          'userId': DocumentValue.from('user_101'),
          'action': DocumentValue.from('EXPORT_DATASET'),
          'status': DocumentValue.from('SUCCESS'),
        },
      ),
      DocumentRow(
        index: 1,
        cells: {
          'timestamp': DocumentValue.from(DateTime(2026, 10, 18, 15, 0)),
          'userId': DocumentValue.from('user_102'),
          'action': DocumentValue.from('IMPORT_DATASET'),
          'status': DocumentValue.from('FAILED'),
        },
      ),
      DocumentRow(
        index: 2,
        cells: {
          'timestamp': DocumentValue.from(DateTime(2026, 10, 18, 15, 45)),
          'userId': DocumentValue.from('user_103'),
          'action': DocumentValue.from('PRINT_DOCUMENT'),
          'status': DocumentValue.from('SUCCESS'),
        },
      ),
    ];

    return (definition, DocumentDataset(definition: schema, rows: rows));
  }
}
