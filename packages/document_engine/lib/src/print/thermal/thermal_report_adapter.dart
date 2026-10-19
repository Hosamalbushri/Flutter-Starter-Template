import 'dart:typed_data';

import '../../progress/cancellation_token.dart';
import '../../report/evaluated_report.dart';
import '../print_adapter.dart';
import 'thermal_models.dart';
import 'thermal_receipt_builder.dart';

/// Transport interface for physical or network thermal printers (TCP, Bluetooth, USB, Memory).
abstract interface class ThermalPrinterTransport {
  /// Whether the transport is currently connected and operational.
  bool get isConnected;

  /// Sends raw ESC/POS bytes to the thermal printer hardware.
  Future<bool> sendBytes(List<int> bytes);
}

/// In-memory transport for testing and previewing thermal printer output.
class InMemoryThermalTransport implements ThermalPrinterTransport {
  final List<List<int>> sentJobs = [];

  @override
  bool get isConnected => true;

  @override
  Future<bool> sendBytes(List<int> bytes) async {
    sentJobs.add(List.unmodifiable(bytes));
    return true;
  }

  void clear() => sentJobs.clear();
}

/// Adapter converting evaluated reports into ESC/POS thermal receipt binary streams.
class ThermalReportAdapter implements DocumentPrintAdapter {
  ThermalReportAdapter({
    this.name = 'thermal_esc_pos',
    this.paperWidth = ThermalPaperWidth.mm80,
    this.transport,
  });

  @override
  final String name;

  final ThermalPaperWidth paperWidth;
  final ThermalPrinterTransport? transport;

  /// Compiles an [EvaluatedReport] into ESC/POS binary bytes.
  Uint8List renderReport(
    EvaluatedReport report, {
    CancellationToken? cancellationToken,
    bool cutAfterPrint = true,
  }) {
    cancellationToken?.throwIfCancelled();

    final builder = ThermalReceiptBuilder(paperWidth: paperWidth);

    // Header
    builder.text(
      report.definition.title,
      align: ThermalAlign.center,
      bold: true,
      size: ThermalTextSize.doubleBoth,
    );
    builder.feed(1);

    if (report.definition.subtitle != null) {
      builder.text(report.definition.subtitle!, align: ThermalAlign.center);
    }

    if (report.definition.parameters.isNotEmpty) {
      builder.divider();
      for (final entry in report.definition.parameters.entries) {
        cancellationToken?.throwIfCancelled();
        builder.text('${entry.key}: ${entry.value}');
      }
    }

    builder.doubleDivider();

    // Column headers
    final columns = report.definition.columns;
    if (columns.isNotEmpty) {
      final ratio = 1.0 / columns.length;
      final headerCols = columns
          .map((c) => ThermalColumn(text: c.label, widthRatio: ratio))
          .toList();
      builder.row(headerCols);
      builder.divider();
    }

    // Rows and groups
    for (final group in report.groups) {
      cancellationToken?.throwIfCancelled();
      if (group.groupLabel.isNotEmpty) {
        builder.text(
          '-- ${group.groupLabel} --',
          bold: true,
          align: ThermalAlign.center,
        );
      }

      for (final row in group.rows) {
        cancellationToken?.throwIfCancelled();
        final ratio = 1.0 / columns.length;
        final rowCols = <ThermalColumn>[];
        for (final col in columns) {
          final val = row[col.id].raw?.toString() ?? '';
          rowCols.add(ThermalColumn(text: val, widthRatio: ratio));
        }
        builder.row(rowCols);
      }

      if (group.subtotals.isNotEmpty) {
        builder.divider();
        for (final entry in group.subtotals.entries) {
          final subVal =
              entry.value.asDecimal?.toStringAsFixed(2) ??
              entry.value.raw?.toString() ??
              '';
          builder.text(
            'Subtotal (${entry.key}): $subVal',
            bold: true,
            align: ThermalAlign.right,
          );
        }
      }
    }

    // Grand totals
    if (report.grandTotals.isNotEmpty) {
      builder.doubleDivider();
      for (final entry in report.grandTotals.entries) {
        cancellationToken?.throwIfCancelled();
        final totVal =
            entry.value.asDecimal?.toStringAsFixed(2) ??
            entry.value.raw?.toString() ??
            '';
        builder.text(
          'TOTAL (${entry.key}): $totVal',
          bold: true,
          size: ThermalTextSize.doubleHeight,
          align: ThermalAlign.right,
        );
      }
    }

    // Footer note
    final footer = report.definition.footer;
    if (footer != null) {
      builder.feed(1);
      builder.divider();
      if (footer.centerText != null) {
        builder.text(footer.centerText!, align: ThermalAlign.center);
      }
      if (footer.leftText != null) {
        builder.text(footer.leftText!, align: ThermalAlign.left);
      }
      if (footer.rightText != null) {
        builder.text(footer.rightText!, align: ThermalAlign.right);
      }
    }

    if (cutAfterPrint) {
      builder.cut();
    }

    return builder.toBytes();
  }

  @override
  Future<bool> printDocument(
    List<int> bytes, {
    String? jobName,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    if (transport == null) {
      throw StateError(
        'ThermalReportAdapter has no configured ThermalPrinterTransport',
      );
    }
    return transport!.sendBytes(bytes);
  }
}
