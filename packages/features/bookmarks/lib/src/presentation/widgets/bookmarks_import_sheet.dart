import 'package:app_ui/app_ui.dart';
import 'package:architecture/architecture.dart';
import 'package:document_engine/document_engine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

import '../../domain/services/bookmarks_import_delegate.dart';
import '../../domain/usecases/import_bookmarks.dart';
import '../../locator.dart';

/// Modal bottom sheet guiding the user through importing Bookmarks from
/// CSV, XLSX, or JSON files, while maintaining relationships with Collections.
class BookmarksImportSheet extends StatefulWidget {
  const BookmarksImportSheet({
    super.key,
    this.onImportCompleted,
    this.initialBytes,
    this.initialFileName,
  });

  /// Callback invoked after an import is committed successfully.
  final VoidCallback? onImportCompleted;

  /// Optional pre-loaded bytes for testing or headless execution.
  final List<int>? initialBytes;

  /// Optional pre-loaded file name.
  final String? initialFileName;

  /// Displays the sheet modally.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onImportCompleted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookmarksImportSheet(
        onImportCompleted: onImportCompleted,
      ),
    );
  }

  @override
  State<BookmarksImportSheet> createState() => _BookmarksImportSheetState();
}

class _BookmarksImportSheetState extends State<BookmarksImportSheet> {
  final DocumentFormatRegistry _registry = DocumentFormatRegistry.standard();

  String? _fileName;
  List<int>? _fileBytes;
  String? _detectedFormat;
  ImportPlan? _plan;
  ImportResultReport? _report;
  DuplicatePolicy _policy = DuplicatePolicy.skip;
  bool _isLoading = false;
  String? _errorMessage;
  CancellationToken? _activeCancellationToken;
  DocumentProgress? _progress;

  @override
  void dispose() {
    _activeCancellationToken?.cancel();
    super.dispose();
  }

  void _cancelActiveOperation() {
    _activeCancellationToken?.cancel();
  }

  void _updateProgress(
    CancellationToken token,
    DocumentProgress progress,
  ) {
    if (!mounted || !identical(_activeCancellationToken, token)) return;
    setState(() => _progress = progress);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialBytes != null && widget.initialFileName != null) {
      _loadFile(widget.initialFileName!, widget.initialBytes!);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
      );

      if (result.isEmpty) return;
      final file = result.first;
      final bytes = await file.readAsBytes();
      await _loadFile(file.name, bytes);
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadFile(String fileName, List<int> bytes) async {
    final ext = fileName.split('.').last.toLowerCase();
    _activeCancellationToken?.cancel();
    final token = CancellationToken();
    _activeCancellationToken = token;
    setState(() {
      _fileName = fileName;
      _fileBytes = bytes;
      _detectedFormat = ext;
      _isLoading = true;
      _errorMessage = null;
      _report = null;
      _plan = null;
      _progress = null;
    });

    try {
      final adapter = _registry.getImportAdapter(ext);
      final def = getIt<BookmarksImportDelegate>().importDefinition;
      final plan = await adapter.preparePlan(
        bytes,
        def,
        cancellationToken: token,
        onProgress: (progress) => _updateProgress(token, progress),
      );

      if (mounted && identical(_activeCancellationToken, token)) {
        setState(() {
          _plan = plan;
          _isLoading = false;
          _activeCancellationToken = null;
        });
      }
    } on Exception catch (e) {
      if (mounted && identical(_activeCancellationToken, token)) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _activeCancellationToken = null;
        });
      }
    }
  }

  Future<void> _commitImport() async {
    if (_isLoading || _report != null) return;
    final bytes = _fileBytes;
    final format = _detectedFormat;
    if (bytes == null || format == null) return;

    _activeCancellationToken?.cancel();
    final token = CancellationToken();
    _activeCancellationToken = token;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = null;
    });

    final useCase = getIt<ImportBookmarksUseCase>();
    final result = await useCase(
      ImportBookmarksParams(
        bytes: bytes,
        format: format,
        duplicatePolicy: _policy,
        registry: _registry,
        cancellationToken: token,
        onProgress: (progress) => _updateProgress(token, progress),
      ),
    );

    if (!mounted || !identical(_activeCancellationToken, token)) return;

    switch (result) {
      case Ok(value: final report):
        setState(() {
          _isLoading = false;
          _report = report;
          _activeCancellationToken = null;
        });
        widget.onImportCompleted?.call();
      case Err(failure: final f):
        setState(() {
          _isLoading = false;
          _errorMessage = f.message;
          _activeCancellationToken = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: mediaQuery.viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Text(
              l10n.bookmarksImportAction,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.documentImportSelectFileHint,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // File selection row
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: l10n.documentImportSelectFile,
                  onPressed: _isLoading ? null : _pickFile,
                  variant: AppButtonVariant.primary,
                ),
                if (_fileName != null)
                  Chip(
                    avatar: const Icon(Icons.attach_file, size: 18),
                    label: Text(_fileName!),
                  ),
                if (_detectedFormat != null)
                  Chip(
                    backgroundColor: context.colorScheme.secondaryContainer,
                    label: Text(
                      _detectedFormat!.toUpperCase(),
                      style: TextStyle(
                        color: context.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            if (_isLoading) ...[
              LinearProgressIndicator(value: _progress?.fraction),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _progress?.message ?? '',
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _cancelActiveOperation,
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Error display
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: context.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Validation preview
            if (_plan != null && _report == null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentImportPreviewTitle,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              l10n.documentImportValidRows(_plan!.validCount),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              l10n.documentImportInvalidRows(
                                _plan!.invalidCount,
                              ),
                              style: TextStyle(
                                color: context.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Duplicate Policy
                    Text(
                      l10n.documentImportDuplicatePolicyLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.documentImportPolicySkip),
                          selected: _policy == DuplicatePolicy.skip,
                          onSelected: (_) =>
                              setState(() => _policy = DuplicatePolicy.skip),
                        ),
                        ChoiceChip(
                          label: Text(l10n.documentImportPolicyUpdate),
                          selected: _policy == DuplicatePolicy.update,
                          onSelected: (_) =>
                              setState(() => _policy = DuplicatePolicy.update),
                        ),
                        ChoiceChip(
                          label: Text(l10n.documentImportPolicyCreate),
                          selected: _policy == DuplicatePolicy.create,
                          onSelected: (_) =>
                              setState(() => _policy = DuplicatePolicy.create),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppButton(
                      label: l10n.documentImportCommitButton,
                      isLoading: _isLoading,
                      onPressed: _plan!.canCommit && !_isLoading
                          ? _commitImport
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Final Report display
            if (_report != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.documentImportSuccessMessage(
                              _report!.importedCount,
                            ),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.documentImportSummaryTitle,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          l10n.documentImportCreatedCount(
                            _report!.createdCount,
                          ),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.documentImportUpdatedCount(
                            _report!.updatedCount,
                          ),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.documentImportSkippedCount(
                            _report!.skippedCount,
                          ),
                          style: TextStyle(
                            color: context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_report!.failedCount > 0)
                          Text(
                            l10n.documentImportFailedCount(
                              _report!.failedCount,
                            ),
                            style: TextStyle(
                              color: context.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.documentImportCloseButton,
                      onPressed: () => Navigator.of(context).pop(),
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}
