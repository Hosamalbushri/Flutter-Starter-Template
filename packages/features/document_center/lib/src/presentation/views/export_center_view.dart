import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';

import '../bloc/document_center_cubit.dart';
import '../bloc/document_center_state.dart';

/// Tab view for exporting datasets into CSV, XLSX, JSON, and PDF formats.
class ExportCenterView extends StatelessWidget {
  const ExportCenterView({super.key});

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
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentCenterTabExport,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dataset Selector
                    Text(
                      l10n.documentExportDatasetLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedExportDataset,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'sales',
                          child: Text(l10n.documentReportsSales),
                        ),
                        DropdownMenuItem(
                          value: 'inventory',
                          child: Text(l10n.documentReportsInventory),
                        ),
                        DropdownMenuItem(
                          value: 'statement',
                          child: Text(l10n.documentReportsStatement),
                        ),
                        DropdownMenuItem(
                          value: 'invoice',
                          child: Text(l10n.documentReportsInvoice),
                        ),
                        DropdownMenuItem(
                          value: 'general',
                          child: Text(l10n.documentReportsGeneral),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) cubit.setExportDataset(val);
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Format Picker
                    Text(
                      l10n.documentExportFormatLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ['csv', 'xlsx', 'json', 'pdf'].map((fmt) {
                        final selected = state.selectedExportFormat == fmt;
                        return ChoiceChip(
                          label: Text(fmt.toUpperCase()),
                          selected: selected,
                          onSelected: (_) => cubit.setExportFormat(fmt),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Formula Protection Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.documentExportNeutralizeFormulas,
                        style: context.textTheme.bodyMedium,
                      ),
                      value: state.neutralizeFormulas,
                      onChanged: (val) =>
                          cubit.toggleNeutralizeFormulas(value: val),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppButton(
                      label: l10n.documentExportButton,
                      isLoading: state.isExporting,
                      onPressed: cubit.executeExport,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Export Success Banner
              if (state.lastExportedBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download_done, color: Colors.green),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.documentExportSuccess(state.lastExportedBytes!),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: state.isExporting
                            ? null
                            : cubit.saveLastExport,
                        icon: const Icon(Icons.save_alt),
                        label: Text(l10n.commonSave),
                      ),
                    ],
                  ),
                ),
              ],

              // Export Error Banner
              if (state.exportErrorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    state.exportErrorMessage!,
                    style: TextStyle(
                      color: context.colorScheme.onErrorContainer,
                    ),
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
