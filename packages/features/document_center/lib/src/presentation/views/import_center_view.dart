import 'package:app_ui/app_ui.dart';
import 'package:document_engine/document_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';

import '../bloc/document_center_cubit.dart';
import '../bloc/document_center_state.dart';

/// Tab view for importing CSV, XLSX, and JSON files with validation and preview.
class ImportCenterView extends StatelessWidget {
  const ImportCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DocumentCenterCubit>();

    return BlocBuilder<DocumentCenterCubit, DocumentCenterState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentCenterTabImport,
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

                    // Target Dataset Selection
                    Text(
                      l10n.documentImportDatasetLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ...cubit.registry.supportedImportDelegates.map((d) {
                          final isSelected =
                              state.selectedImportDataset == d.datasetId;
                          return ChoiceChip(
                            label: Text(d.datasetLabel),
                            selected: isSelected,
                            onSelected: (_) =>
                                cubit.setImportDataset(d.datasetId),
                          );
                        }),
                        ChoiceChip(
                          label: const Text('Sales (Demo)'),
                          selected:
                              state.selectedImportDataset == 'sales_target',
                          onSelected: (_) =>
                              cubit.setImportDataset('sales_target'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Duplicate Policy Selection
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
                          selected:
                              state.selectedDuplicatePolicy ==
                              DuplicatePolicy.skip,
                          onSelected: (_) =>
                              cubit.setDuplicatePolicy(DuplicatePolicy.skip),
                        ),
                        ChoiceChip(
                          label: Text(l10n.documentImportPolicyUpdate),
                          selected:
                              state.selectedDuplicatePolicy ==
                              DuplicatePolicy.update,
                          onSelected: (_) =>
                              cubit.setDuplicatePolicy(DuplicatePolicy.update),
                        ),
                        ChoiceChip(
                          label: Text(l10n.documentImportPolicyCreate),
                          selected:
                              state.selectedDuplicatePolicy ==
                              DuplicatePolicy.create,
                          onSelected: (_) =>
                              cubit.setDuplicatePolicy(DuplicatePolicy.create),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l10n.documentImportSelectFile,
                          onPressed: cubit.pickFile,
                          variant: AppButtonVariant.primary,
                        ),
                        if (state.selectedFileName != null)
                          Chip(
                            avatar: const Icon(Icons.attach_file, size: 18),
                            label: Text(state.selectedFileName!),
                          ),
                        if (state.detectedFormat != null)
                          Chip(
                            backgroundColor:
                                context.colorScheme.secondaryContainer,
                            label: Text(
                              state.detectedFormat!.toUpperCase(),
                              style: TextStyle(
                                color: context.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              if (state.isImporting) ...[
                LinearProgressIndicator(value: state.importProgress?.fraction),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(state.importProgress?.message ?? ''),
                    ),
                    TextButton(
                      onPressed: cubit.cancelImport,
                      child: Text(l10n.commonCancel),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Validation Error
              if (state.importErrorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    state.importErrorMessage!,
                    style: TextStyle(
                      color: context.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Commit Success Banner
              if (state.committedCount != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.documentImportSuccessMessage(
                            state.committedCount!,
                          ),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Detailed Report Breakdown
              if (state.importResultReport != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              state.importResultReport!.createdCount,
                            ),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            l10n.documentImportUpdatedCount(
                              state.importResultReport!.updatedCount,
                            ),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            l10n.documentImportSkippedCount(
                              state.importResultReport!.skippedCount,
                            ),
                            style: TextStyle(
                              color: context.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (state.importResultReport!.failedCount > 0)
                            Text(
                              l10n.documentImportFailedCount(
                                state.importResultReport!.failedCount,
                              ),
                              style: TextStyle(
                                color: context.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Validation Preview & Actions
              if (state.importPlan != null) ...[
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                l10n.documentImportValidRows(
                                  state.importPlan!.validCount,
                                ),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Text(
                                l10n.documentImportInvalidRows(
                                  state.importPlan!.invalidCount,
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
                      if (state.importPlan!.invalidCount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.documentImportErrorMessage(
                            state.importPlan!.invalidCount,
                          ),
                          style: TextStyle(
                            color: context.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.documentImportCommitButton,
                        isLoading: state.isImporting,
                        onPressed: state.importPlan!.canCommit
                            ? cubit.commitCurrentImport
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
