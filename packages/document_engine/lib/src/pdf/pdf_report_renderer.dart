import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/document_column.dart';
import '../model/document_dataset.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import '../report/evaluated_report.dart';
import '../report/report_definition.dart';
import '../report/report_engine.dart';
import '../report/report_renderer.dart';
import 'bundled_pdf_fonts.dart';
import 'pdf_options.dart';

/// Professional multi-page PDF document renderer supporting headers, footers,
/// repeated column headers, grouping subtotals, grand totals, and Arabic RTL shaping.
class PdfReportRenderer implements ReportRenderer {
  const PdfReportRenderer({
    this.options = const PdfReportOptions(),
    this.engine = const ReportEngine(),
  });

  final PdfReportOptions options;
  final ReportEngine engine;

  @override
  String get formatId => 'pdf';

  @override
  String get primaryExtension => 'pdf';

  @override
  Future<List<int>> render(
    ReportDefinition definition,
    DocumentDataset dataset, {
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();

    final evaluated = engine.evaluate(
      definition,
      dataset,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );

    cancellationToken?.throwIfCancelled();

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.rendering,
        current: 0,
        total: 100,
        message: 'Composing PDF layout...',
      ),
    );

    final doc = pw.Document(
      title: definition.title,
      author: definition.metadata.author,
      subject: definition.subtitle,
      theme: pw.ThemeData.withFont(
        base: options.baseFont ?? BundledPdfFonts.regular,
        bold: options.boldFont ?? BundledPdfFonts.bold,
      ),
    );

    final pageFormat = options.resolvePageFormat();
    final textDirection = definition.isRtl
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        textDirection: textDirection,
        header: (context) => _buildPageHeader(context, definition),
        footer: (context) =>
            _buildPageFooter(context, definition, textDirection),
        build: (context) => [
          _buildReportTable(definition, evaluated, textDirection),
        ],
      ),
    );

    cancellationToken?.throwIfCancelled();

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.writing,
        current: 50,
        total: 100,
        message: 'Writing PDF binary stream...',
      ),
    );

    final pdfBytes = await doc.save();
    cancellationToken?.throwIfCancelled();

    onProgress?.call(
      const DocumentProgress(
        phase: DocumentPhase.completed,
        current: 100,
        total: 100,
        message: 'PDF generation complete.',
      ),
    );

    return pdfBytes;
  }

  pw.Widget _buildPageHeader(
    pw.Context context,
    ReportDefinition definition,
  ) {
    if (context.pageNumber > 1 && definition.header == null) {
      return pw.SizedBox(height: 12);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            definition.title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: options.primaryColor,
            ),
          ),
          if (definition.subtitle case final sub? when sub.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              sub,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ],
          if (definition.parameters.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 12,
              runSpacing: 4,
              children: definition.parameters.entries.map((e) {
                return pw.Text(
                  '${e.key}: ${e.value}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                );
              }).toList(),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Divider(color: options.primaryColor, thickness: 1),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(
    pw.Context context,
    ReportDefinition definition,
    pw.TextDirection textDirection,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (options.includeTimestamp)
            _buildGeneratedAt(definition)
          else
            pw.SizedBox(),
          if (options.includePageNumbers)
            pw.Text(
              definition.isRtl
                  ? 'الصفحة ${context.pageNumber} من ${context.pagesCount}'
                  : 'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildGeneratedAt(ReportDefinition definition) {
    final generatedAt =
        '${DateTime.now().toUtc().toIso8601String().substring(0, 16).replaceFirst('T', ' ')} UTC';
    const style = pw.TextStyle(fontSize: 8, color: PdfColors.grey600);

    if (!definition.isRtl) {
      return pw.Text('Generated: $generatedAt', style: style);
    }

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('تاريخ الإنشاء:', style: style),
        pw.SizedBox(width: 3),
        pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Text(generatedAt, style: style),
        ),
      ],
    );
  }

  pw.Widget _buildReportTable(
    ReportDefinition definition,
    EvaluatedReport evaluated,
    pw.TextDirection textDirection,
  ) {
    final tableRows = <pw.TableRow>[];
    final displayColumns = definition.isRtl
        ? definition.columns.reversed
        : definition.columns;

    // 1. Column Headers
    final headerCells = displayColumns.map((col) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        alignment: _resolveAlignment(col.alignment, textDirection),
        child: pw.Text(
          col.label,
          style: const pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.black,
          ),
        ),
      );
    }).toList();

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: options.headerBackgroundColor),
        children: headerCells,
      ),
    );

    // 2. Groups & Data Rows
    for (final group in evaluated.groups) {
      // Group header banner
      if (group.groupLabel.isNotEmpty) {
        tableRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: pw.Text(
                  group.groupLabel,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    color: options.primaryColor,
                  ),
                ),
              ),
              for (var i = 1; i < definition.columns.length; i++) pw.SizedBox(),
            ],
          ),
        );
      }

      // Individual data rows
      for (final row in group.rows) {
        final rowCells = displayColumns.map((col) {
          final val = row[col.id];
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: _resolveAlignment(col.alignment, textDirection),
            child: pw.Text(
              val.isNull ? '-' : val.displayValue,
              style: const pw.TextStyle(fontSize: 9),
            ),
          );
        }).toList();

        tableRows.add(pw.TableRow(children: rowCells));
      }

      // Group Subtotal row
      if (group.subtotals.isNotEmpty) {
        final subtotalCells = displayColumns.map((col) {
          final hasSubtotal = group.subtotals.containsKey(col.id);
          final text = hasSubtotal
              ? group.subtotals[col.id]!.displayValue
              : (col == definition.columns.first
                    ? (definition.isRtl ? 'الإجمالي الفرعي' : 'Subtotal')
                    : '');

          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: _resolveAlignment(col.alignment, textDirection),
            child: pw.Text(
              text,
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.grey900,
              ),
            ),
          );
        }).toList();

        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: options.subtotalBackgroundColor,
            ),
            children: subtotalCells,
          ),
        );
      }
    }

    // 3. Grand Totals Row
    if (evaluated.grandTotals.isNotEmpty) {
      final grandTotalCells = displayColumns.map((col) {
        final hasTotal = evaluated.grandTotals.containsKey(col.id);
        final text = hasTotal
            ? evaluated.grandTotals[col.id]!.displayValue
            : (col == definition.columns.first
                  ? (definition.isRtl ? 'الإجمالي الكلي' : 'Grand Total')
                  : '');

        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: _resolveAlignment(col.alignment, textDirection),
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        );
      }).toList();

      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: grandTotalCells,
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: tableRows,
    );
  }

  pw.Alignment _resolveAlignment(
    ColumnAlignment alignment,
    pw.TextDirection textDirection,
  ) {
    final isRtl = textDirection == pw.TextDirection.rtl;

    switch (alignment) {
      case ColumnAlignment.start:
        return isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft;
      case ColumnAlignment.center:
        return pw.Alignment.center;
      case ColumnAlignment.end:
        return isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight;
    }
  }
}
