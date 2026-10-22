import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:printing/printing.dart';

import '../bloc/document_center_cubit.dart';
import '../bloc/document_center_state.dart';

/// Tab view for previewing business reports, generating PDFs, and thermal printing.
class ReportCenterView extends StatelessWidget {
  const ReportCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DocumentCenterCubit>();

    return BlocBuilder<DocumentCenterCubit, DocumentCenterState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentCenterTabReports,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Template Selector
                    Text(
                      l10n.documentReportsSelectTemplate,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedReportKey,
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
                        if (val != null) cubit.selectReport(val);
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l10n.documentReportsGeneratePdf,
                          isLoading: state.isGeneratingReport,
                          onPressed: cubit.generatePdfReport,
                          variant: AppButtonVariant.primary,
                        ),
                        AppButton(
                          label: l10n.documentReportsPrintThermal,
                          onPressed: cubit.printThermalReceipt,
                          variant: AppButtonVariant.outlined,
                        ),
                      ],
                    ),

                    if (state.reportNotice != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          _localizedNotice(context, state),
                          style: TextStyle(
                            color: context.colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Live PDF Preview Container
            Expanded(
              child: state.generatedPdfBytes != null
                  ? PdfPreview(
                      build: (format) => state.generatedPdfBytes!,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

String _localizedNotice(
  BuildContext context,
  DocumentCenterState state,
) => switch (state.reportNotice) {
  DocumentCenterNotice.pdfFailure => context.l10n.documentReportPdfFailure,
  DocumentCenterNotice.thermalSuccess =>
    context.l10n.documentThermalSuccessBytes(state.reportNoticeBytes ?? 0),
  DocumentCenterNotice.thermalFailure => context.l10n.documentThermalFailure,
  null => '',
};
