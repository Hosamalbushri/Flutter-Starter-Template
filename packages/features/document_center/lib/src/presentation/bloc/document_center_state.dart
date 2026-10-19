import 'package:document_engine/document_engine.dart';
import 'package:flutter/foundation.dart';

/// Immutable state for the Document Center feature.
@immutable
class DocumentCenterState {
  const DocumentCenterState({
    this.isReady = false,
    this.currentTabIndex = 0,
    this.selectedImportDataset = 'collections',
    this.selectedDuplicatePolicy = DuplicatePolicy.skip,
    this.selectedFileName,
    this.selectedFileBytes,
    this.detectedFormat,
    this.importPlan,
    this.committedCount,
    this.importResultReport,
    this.isImporting = false,
    this.importProgress,
    this.importErrorMessage,
    this.selectedExportDataset = 'sales',
    this.selectedExportFormat = 'csv',
    this.neutralizeFormulas = true,
    this.isExporting = false,
    this.lastExportedBytes,
    this.generatedExportBytes,
    this.savedExportUri,
    this.exportErrorMessage,
    this.selectedReportKey = 'sales',
    this.isGeneratingReport = false,
    this.generatedPdfBytes,
    this.reportNoticeMessage,
  });

  /// Whether the screen has finished its initial load.
  final bool isReady;

  /// Currently selected tab index (0: Import, 1: Export, 2: Reports).
  final int currentTabIndex;

  // --- Import State ---
  final String selectedImportDataset;
  final DuplicatePolicy selectedDuplicatePolicy;
  final String? selectedFileName;
  final List<int>? selectedFileBytes;
  final String? detectedFormat;
  final ImportPlan? importPlan;
  final int? committedCount;
  final ImportResultReport? importResultReport;
  final bool isImporting;
  final DocumentProgress? importProgress;
  final String? importErrorMessage;

  // --- Export State ---
  final String selectedExportDataset;
  final String selectedExportFormat;
  final bool neutralizeFormulas;
  final bool isExporting;
  final int? lastExportedBytes;
  final Uint8List? generatedExportBytes;
  final Uri? savedExportUri;
  final String? exportErrorMessage;

  // --- Reports & Print State ---
  final String selectedReportKey;
  final bool isGeneratingReport;
  final Uint8List? generatedPdfBytes;
  final String? reportNoticeMessage;

  DocumentCenterState copyWith({
    bool? isReady,
    int? currentTabIndex,
    String? selectedImportDataset,
    DuplicatePolicy? selectedDuplicatePolicy,
    String? selectedFileName,
    List<int>? selectedFileBytes,
    String? detectedFormat,
    ImportPlan? importPlan,
    int? committedCount,
    ImportResultReport? importResultReport,
    bool? isImporting,
    DocumentProgress? importProgress,
    String? importErrorMessage,
    String? selectedExportDataset,
    String? selectedExportFormat,
    bool? neutralizeFormulas,
    bool? isExporting,
    int? lastExportedBytes,
    Uint8List? generatedExportBytes,
    Uri? savedExportUri,
    String? exportErrorMessage,
    String? selectedReportKey,
    bool? isGeneratingReport,
    Uint8List? generatedPdfBytes,
    String? reportNoticeMessage,
    bool clearFile = false,
    bool clearNotice = false,
    bool clearImportError = false,
    bool clearImportResult = false,
    bool clearImportProgress = false,
    bool clearExportError = false,
    bool clearExportResult = false,
  }) {
    return DocumentCenterState(
      isReady: isReady ?? this.isReady,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      selectedImportDataset:
          selectedImportDataset ?? this.selectedImportDataset,
      selectedDuplicatePolicy:
          selectedDuplicatePolicy ?? this.selectedDuplicatePolicy,
      selectedFileName: clearFile
          ? null
          : (selectedFileName ?? this.selectedFileName),
      selectedFileBytes: clearFile
          ? null
          : (selectedFileBytes ?? this.selectedFileBytes),
      detectedFormat: clearFile
          ? null
          : (detectedFormat ?? this.detectedFormat),
      importPlan: clearFile || clearImportResult
          ? null
          : (importPlan ?? this.importPlan),
      committedCount: clearFile || clearImportResult
          ? null
          : (committedCount ?? this.committedCount),
      importResultReport: clearFile || clearImportResult
          ? null
          : (importResultReport ?? this.importResultReport),
      isImporting: isImporting ?? this.isImporting,
      importProgress: clearImportProgress
          ? null
          : (importProgress ?? this.importProgress),
      importErrorMessage: clearImportError
          ? null
          : (importErrorMessage ?? this.importErrorMessage),
      selectedExportDataset:
          selectedExportDataset ?? this.selectedExportDataset,
      selectedExportFormat: selectedExportFormat ?? this.selectedExportFormat,
      neutralizeFormulas: neutralizeFormulas ?? this.neutralizeFormulas,
      isExporting: isExporting ?? this.isExporting,
      lastExportedBytes: clearExportResult
          ? null
          : (lastExportedBytes ?? this.lastExportedBytes),
      generatedExportBytes: clearExportResult
          ? null
          : (generatedExportBytes ?? this.generatedExportBytes),
      savedExportUri: clearExportResult
          ? null
          : (savedExportUri ?? this.savedExportUri),
      exportErrorMessage: clearExportError
          ? null
          : (exportErrorMessage ?? this.exportErrorMessage),
      selectedReportKey: selectedReportKey ?? this.selectedReportKey,
      isGeneratingReport: isGeneratingReport ?? this.isGeneratingReport,
      generatedPdfBytes: generatedPdfBytes ?? this.generatedPdfBytes,
      reportNoticeMessage: clearNotice
          ? null
          : (reportNoticeMessage ?? this.reportNoticeMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentCenterState &&
          other.isReady == isReady &&
          other.currentTabIndex == currentTabIndex &&
          other.selectedImportDataset == selectedImportDataset &&
          other.selectedDuplicatePolicy == selectedDuplicatePolicy &&
          other.selectedFileName == selectedFileName &&
          other.detectedFormat == detectedFormat &&
          other.importPlan == importPlan &&
          other.committedCount == committedCount &&
          other.importResultReport == importResultReport &&
          other.isImporting == isImporting &&
          other.importProgress == importProgress &&
          other.importErrorMessage == importErrorMessage &&
          other.selectedExportDataset == selectedExportDataset &&
          other.selectedExportFormat == selectedExportFormat &&
          other.neutralizeFormulas == neutralizeFormulas &&
          other.isExporting == isExporting &&
          other.lastExportedBytes == lastExportedBytes &&
          other.generatedExportBytes == generatedExportBytes &&
          other.savedExportUri == savedExportUri &&
          other.exportErrorMessage == exportErrorMessage &&
          other.selectedReportKey == selectedReportKey &&
          other.isGeneratingReport == isGeneratingReport &&
          other.reportNoticeMessage == reportNoticeMessage);

  @override
  int get hashCode => Object.hashAll([
    isReady,
    currentTabIndex,
    selectedImportDataset,
    selectedDuplicatePolicy,
    selectedFileName,
    detectedFormat,
    importPlan,
    committedCount,
    importResultReport,
    isImporting,
    importProgress,
    importErrorMessage,
    selectedExportDataset,
    selectedExportFormat,
    neutralizeFormulas,
    isExporting,
    lastExportedBytes,
    generatedExportBytes,
    savedExportUri,
    exportErrorMessage,
    selectedReportKey,
    isGeneratingReport,
    reportNoticeMessage,
  ]);
}
