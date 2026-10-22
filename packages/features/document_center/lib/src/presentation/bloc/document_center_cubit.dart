import 'dart:typed_data';

import 'package:document_engine/document_engine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'document_center_state.dart';

/// Manages state and workflows for Document Center (import, export, reports, printing).
@injectable
class DocumentCenterCubit extends Cubit<DocumentCenterState> {
  DocumentCenterCubit([DocumentFormatRegistry? registry])
    : registry = registry ?? DocumentFormatRegistry.standard(),
      super(const DocumentCenterState());

  final DocumentFormatRegistry registry;
  final InMemoryThermalTransport thermalTransport = InMemoryThermalTransport();
  final MemoryImportPersistenceAdapter persistenceAdapter =
      MemoryImportPersistenceAdapter();
  CancellationToken? _activeImportToken;

  /// Requests cooperative cancellation of validation or persistence.
  void cancelImport() => _activeImportToken?.cancel();

  @override
  Future<void> close() {
    _activeImportToken?.cancel();
    return super.close();
  }

  /// Loads initial state and pre-generates the initial report preview.
  Future<void> load() async {
    emit(state.copyWith(isReady: true));
    await generatePdfReport();
  }

  /// Switches active tab in dashboard.
  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index, clearNotice: true));
  }

  // ===========================================================================
  // IMPORT WORKFLOW
  // ===========================================================================

  /// Default import target schema used in the document center demo.
  ImportDefinition get defaultImportDefinition => ImportDefinition(
    targetDefinition: DocumentDefinition(
      id: 'sales_target',
      title: 'Imported Sales Records',
      columns: ReferenceReportFixtures.createSalesReport().$1.columns,
    ),
    allowPartial: true,
  );

  /// Active import definition according to the selected dataset.
  ImportDefinition get activeImportDefinition {
    final delegate = registry.getImportDelegate(state.selectedImportDataset);
    if (delegate != null) {
      return delegate.importDefinition;
    }
    return defaultImportDefinition;
  }

  /// Selects the target dataset for import.
  void setImportDataset(String datasetId) {
    emit(
      state.copyWith(
        selectedImportDataset: datasetId,
        clearImportError: true,
      ),
    );
    if (state.selectedFileBytes != null) {
      validateCurrentImport();
    }
  }

  /// Selects the duplicate resolution policy for import.
  void setDuplicatePolicy(DuplicatePolicy policy) {
    emit(state.copyWith(selectedDuplicatePolicy: policy));
  }

  /// Opens the system file picker to select a document for import.
  Future<void> pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
      );

      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();

      selectFileManually(fileName: file.name, bytes: bytes);
    } on Exception {
      emit(state.copyWith(importFailure: DocumentCenterFailure.fileRead));
    }
  }

  /// Sets selected file manually (useful for testing or programmatic feeds).
  void selectFileManually({
    required String fileName,
    required List<int> bytes,
  }) {
    final ext = fileName.split('.').last.toLowerCase();
    emit(
      state.copyWith(
        selectedFileName: fileName,
        selectedFileBytes: bytes,
        detectedFormat: ext,
        clearImportError: true,
        clearImportResult: true,
      ),
    );
    validateCurrentImport();
  }

  /// Validates the currently selected import file against the active schema.
  Future<void> validateCurrentImport() async {
    final bytes = state.selectedFileBytes;
    final format = state.detectedFormat;
    if (bytes == null || format == null) return;

    _activeImportToken?.cancel();
    final token = CancellationToken();
    _activeImportToken = token;
    emit(
      state.copyWith(
        isImporting: true,
        clearImportError: true,
        clearImportResult: true,
        clearImportProgress: true,
      ),
    );
    try {
      final adapter = registry.getImportAdapter(format);
      final plan = await adapter.preparePlan(
        bytes,
        activeImportDefinition,
        cancellationToken: token,
        onProgress: (progress) {
          if (!isClosed && identical(_activeImportToken, token)) {
            emit(state.copyWith(importProgress: progress));
          }
        },
      );

      if (!identical(_activeImportToken, token)) return;

      emit(
        state.copyWith(
          isImporting: false,
          importPlan: plan,
          clearImportProgress: true,
        ),
      );
      _activeImportToken = null;
    } on DocumentCancellationFailure {
      if (!identical(_activeImportToken, token)) return;
      emit(
        state.copyWith(
          isImporting: false,
          clearImportProgress: true,
          clearImportError: true,
        ),
      );
      _activeImportToken = null;
    } on DocumentFailure {
      if (!identical(_activeImportToken, token)) return;
      emit(
        state.copyWith(
          isImporting: false,
          importFailure: DocumentCenterFailure.importValidation,
          clearImportProgress: true,
        ),
      );
      _activeImportToken = null;
    }
  }

  /// Commits the validated import dataset transactionally.
  Future<void> commitCurrentImport() async {
    if (state.isImporting) return;
    final plan = state.importPlan;
    if (plan == null || !plan.canCommit) return;

    _activeImportToken?.cancel();
    final token = CancellationToken();
    _activeImportToken = token;
    emit(
      state.copyWith(
        isImporting: true,
        clearImportError: true,
        importProgress: DocumentProgress(
          phase: DocumentPhase.committing,
          current: 0,
          total: plan.validCount,
        ),
      ),
    );
    try {
      final delegate = registry.getImportDelegate(state.selectedImportDataset);
      if (delegate != null) {
        final report = await delegate.executeImport(
          validRows: plan.validRows,
          duplicatePolicy: state.selectedDuplicatePolicy,
          cancellationToken: token,
        );
        if (!identical(_activeImportToken, token)) return;
        emit(
          state.copyWith(
            isImporting: false,
            committedCount: report.importedCount,
            importResultReport: report,
            clearImportProgress: true,
          ),
        );
        _activeImportToken = null;
        return;
      }

      token.throwIfCancelled();
      await persistenceAdapter.beginTransaction();
      final count = await persistenceAdapter.saveChunk(plan.validRows);
      token.throwIfCancelled();
      await persistenceAdapter.commitTransaction();

      emit(
        state.copyWith(
          isImporting: false,
          committedCount: count,
          clearImportProgress: true,
        ),
      );
      _activeImportToken = null;
    } on Exception {
      await persistenceAdapter.rollbackTransaction();
      if (!identical(_activeImportToken, token)) return;
      emit(
        state.copyWith(
          isImporting: false,
          importFailure: DocumentCenterFailure.importCommit,
          clearImportProgress: true,
        ),
      );
      _activeImportToken = null;
    }
  }

  // ===========================================================================
  // EXPORT WORKFLOW
  // ===========================================================================

  void setExportDataset(String key) {
    emit(
      state.copyWith(
        selectedExportDataset: key,
        clearExportError: true,
        clearExportResult: true,
      ),
    );
  }

  void setExportFormat(String format) {
    emit(
      state.copyWith(
        selectedExportFormat: format,
        clearExportError: true,
        clearExportResult: true,
      ),
    );
  }

  void toggleNeutralizeFormulas({required bool value}) {
    emit(state.copyWith(neutralizeFormulas: value));
  }

  /// Executes data export into the selected format.
  Future<Uint8List?> executeExport() async {
    emit(
      state.copyWith(
        isExporting: true,
        clearExportError: true,
        clearExportResult: true,
      ),
    );
    try {
      final format = state.selectedExportFormat;
      final List<int> bytes;
      if (format == 'pdf') {
        final (definition, dataset) = _resolveReport(
          state.selectedExportDataset,
        );
        final renderer = registry.getReportRenderer(format);
        bytes = await renderer.render(definition, dataset);
      } else {
        final dataset = _resolveDataset(state.selectedExportDataset);
        final adapter = registry.getExportAdapter(format);
        final exportDef = ExportDefinition(
          protectFormulas: state.neutralizeFormulas,
        );
        bytes = await adapter.export(dataset, exportDef);
      }

      emit(
        state.copyWith(
          isExporting: false,
          lastExportedBytes: bytes.length,
          generatedExportBytes: Uint8List.fromList(bytes),
        ),
      );
      return Uint8List.fromList(bytes);
    } on DocumentFailure {
      emit(
        state.copyWith(
          isExporting: false,
          exportFailure: DocumentCenterFailure.export,
        ),
      );
      return null;
    }
  }

  /// Opens the platform save dialog for the most recently generated export.
  Future<Uri?> saveLastExport() async {
    final bytes = state.generatedExportBytes;
    if (bytes == null) return null;

    emit(state.copyWith(isExporting: true, clearExportError: true));
    try {
      final format = state.selectedExportFormat;
      final uri = await FilePicker.saveFile(
        fileName: '${state.selectedExportDataset}_export.$format',
        bytes: bytes,
        mimeType: _mimeTypeFor(format),
      );
      emit(state.copyWith(isExporting: false, savedExportUri: uri));
      return uri;
    } on Exception {
      emit(
        state.copyWith(
          isExporting: false,
          exportFailure: DocumentCenterFailure.save,
        ),
      );
      return null;
    }
  }

  // ===========================================================================
  // REPORTS & PRINTING WORKFLOW
  // ===========================================================================

  void selectReport(String key) {
    emit(state.copyWith(selectedReportKey: key, clearNotice: true));
    generatePdfReport();
  }

  /// Evaluates the active report and generates PDF bytes.
  Future<void> generatePdfReport() async {
    emit(state.copyWith(isGeneratingReport: true));
    try {
      final (definition, dataset) = _resolveReport(state.selectedReportKey);
      const renderer = PdfReportRenderer();
      final bytes = await renderer.render(definition, dataset);

      emit(
        state.copyWith(
          isGeneratingReport: false,
          generatedPdfBytes: Uint8List.fromList(bytes),
        ),
      );
    } on Exception {
      emit(
        state.copyWith(
          isGeneratingReport: false,
          reportNotice: DocumentCenterNotice.pdfFailure,
        ),
      );
    }
  }

  /// Compiles report into ESC/POS thermal receipt commands and sends to printer.
  Future<void> printThermalReceipt() async {
    try {
      final (definition, dataset) = _resolveReport(state.selectedReportKey);
      const engine = ReportEngine();
      final evaluated = engine.evaluate(definition, dataset);

      final adapter = ThermalReportAdapter(
        paperWidth: ThermalPaperWidth.mm80,
        transport: thermalTransport,
      );

      final bytes = adapter.renderReport(evaluated);
      await adapter.printDocument(bytes, jobName: definition.title);

      emit(
        state.copyWith(
          reportNotice: DocumentCenterNotice.thermalSuccess,
          reportNoticeBytes: bytes.length,
        ),
      );
    } on Exception {
      emit(
        state.copyWith(
          reportNotice: DocumentCenterNotice.thermalFailure,
        ),
      );
    }
  }

  // --- Internal Helpers ---

  (ReportDefinition, DocumentDataset) _resolveReport(String key) {
    return switch (key) {
      'sales' => ReferenceReportFixtures.createSalesReport(),
      'inventory' => ReferenceReportFixtures.createInventoryMovementReport(),
      'statement' => ReferenceReportFixtures.createSupplierStatementReport(),
      'invoice' => ReferenceReportFixtures.createInvoiceDocumentReport(),
      'general' => ReferenceReportFixtures.createGeneralTabularReport(),
      _ => ReferenceReportFixtures.createSalesReport(),
    };
  }

  DocumentDataset _resolveDataset(String key) {
    return _resolveReport(key).$2;
  }

  String _mimeTypeFor(String format) => switch (format) {
    'csv' => 'text/csv',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'json' => 'application/json',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
