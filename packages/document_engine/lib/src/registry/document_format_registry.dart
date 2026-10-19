import '../csv/csv_export_adapter.dart';
import '../csv/csv_import_adapter.dart';
import '../export/export_adapter.dart';
import '../failure/document_failure.dart';
import '../import/document_import_delegate.dart';
import '../import/import_adapter.dart';
import '../json/json_export_adapter.dart';
import '../json/json_import_adapter.dart';
import '../pdf/pdf_report_renderer.dart';
import '../print/print_adapter.dart';
import '../print/thermal/thermal_report_adapter.dart';
import '../report/csv_report_renderer.dart';
import '../report/report_renderer.dart';
import '../xlsx/xlsx_export_adapter.dart';
import '../xlsx/xlsx_import_adapter.dart';

/// Central registry managing available format adapters and renderers.
class DocumentFormatRegistry {
  DocumentFormatRegistry();

  /// Creates a registry pre-populated with standard CSV, JSON, XLSX, PDF, and Thermal adapters.
  factory DocumentFormatRegistry.standard() {
    final registry = DocumentFormatRegistry();
    registry.registerImportAdapter(const CsvImportAdapter());
    registry.registerExportAdapter(const CsvExportAdapter());
    registry.registerImportAdapter(const JsonImportAdapter());
    registry.registerExportAdapter(const JsonExportAdapter());
    registry.registerImportAdapter(const XlsxImportAdapter());
    registry.registerExportAdapter(const XlsxExportAdapter());
    registry.registerReportRenderer(const CsvReportRenderer());
    registry.registerReportRenderer(const PdfReportRenderer());
    registry.registerPrintAdapter(ThermalReportAdapter());
    return registry;
  }

  final Map<String, ImportAdapter> _importAdapters = {};
  final Map<String, ExportAdapter> _exportAdapters = {};
  final Map<String, ReportRenderer> _reportRenderers = {};
  final Map<String, DocumentPrintAdapter> _printAdapters = {};
  final Map<String, DocumentImportDelegate> _importDelegates = {};

  /// Registers an import adapter.
  void registerImportAdapter(ImportAdapter adapter) {
    _importAdapters[adapter.formatId.toLowerCase()] = adapter;
  }

  /// Registers a dataset-specific import delegate.
  void registerImportDelegate(DocumentImportDelegate delegate) {
    _importDelegates[delegate.datasetId.toLowerCase()] = delegate;
  }

  /// Registers an export adapter.
  void registerExportAdapter(ExportAdapter adapter) {
    _exportAdapters[adapter.formatId.toLowerCase()] = adapter;
  }

  /// Registers a report renderer.
  void registerReportRenderer(ReportRenderer renderer) {
    _reportRenderers[renderer.formatId.toLowerCase()] = renderer;
  }

  /// Registers a print adapter.
  void registerPrintAdapter(DocumentPrintAdapter adapter) {
    _printAdapters[adapter.name.toLowerCase()] = adapter;
  }

  /// Finds an import adapter by formatId or file extension.
  ImportAdapter getImportAdapter(String formatOrExtension) {
    final clean = formatOrExtension.toLowerCase().replaceFirst('.', '');
    final direct = _importAdapters[clean];
    if (direct != null) return direct;

    for (final adapter in _importAdapters.values) {
      if (adapter.supportedExtensions
          .map((e) => e.toLowerCase().replaceFirst('.', ''))
          .contains(clean)) {
        return adapter;
      }
    }
    throw DocumentFormatNotSupportedFailure(
      formatOrExtension,
      'No import adapter registered for "$formatOrExtension". Available: ${_importAdapters.keys.join(", ")}',
    );
  }

  /// Finds an export adapter by formatId or file extension.
  ExportAdapter getExportAdapter(String formatOrExtension) {
    final clean = formatOrExtension.toLowerCase().replaceFirst('.', '');
    final direct = _exportAdapters[clean];
    if (direct != null) return direct;

    for (final adapter in _exportAdapters.values) {
      if (adapter.primaryExtension.toLowerCase().replaceFirst('.', '') ==
          clean) {
        return adapter;
      }
    }
    throw DocumentFormatNotSupportedFailure(
      formatOrExtension,
      'No export adapter registered for "$formatOrExtension". Available: ${_exportAdapters.keys.join(", ")}',
    );
  }

  /// Finds a report renderer by formatId or extension.
  ReportRenderer getReportRenderer(String formatOrExtension) {
    final clean = formatOrExtension.toLowerCase().replaceFirst('.', '');
    final direct = _reportRenderers[clean];
    if (direct != null) return direct;

    for (final renderer in _reportRenderers.values) {
      if (renderer.primaryExtension.toLowerCase().replaceFirst('.', '') ==
          clean) {
        return renderer;
      }
    }
    throw DocumentFormatNotSupportedFailure(
      formatOrExtension,
      'No report renderer registered for "$formatOrExtension". Available: ${_reportRenderers.keys.join(", ")}',
    );
  }

  /// Finds a print adapter by name.
  DocumentPrintAdapter? getPrintAdapter(String name) =>
      _printAdapters[name.toLowerCase()];

  /// Finds an import delegate by dataset ID.
  DocumentImportDelegate? getImportDelegate(String datasetId) =>
      _importDelegates[datasetId.toLowerCase()];

  /// List of registered import format IDs.
  List<String> get supportedImportFormats => _importAdapters.keys.toList();

  /// List of registered export format IDs.
  List<String> get supportedExportFormats => _exportAdapters.keys.toList();

  /// List of registered report formats.
  List<String> get supportedReportFormats => _reportRenderers.keys.toList();

  /// List of registered dataset import delegates.
  List<DocumentImportDelegate> get supportedImportDelegates =>
      _importDelegates.values.toList();
}
