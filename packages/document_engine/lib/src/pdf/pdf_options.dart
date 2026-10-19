import 'package:meta/meta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Standard paper sizes supported for PDF reports.
enum PdfPageSize {
  a4,
  a5,
  letter,
}

/// Paper orientation for PDF document layout.
enum PdfOrientation {
  portrait,
  landscape,
}

/// Layout and styling configuration options for PDF report rendering.
@immutable
class PdfReportOptions {
  const PdfReportOptions({
    this.pageSize = PdfPageSize.a4,
    this.orientation = PdfOrientation.portrait,
    this.margin = 32.0,
    this.includePageNumbers = true,
    this.includeTimestamp = true,
    this.baseFont,
    this.boldFont,
    this.primaryColor = const PdfColor.fromInt(0xFF1E88E5),
    this.headerBackgroundColor = const PdfColor.fromInt(0xFFF5F5F5),
    this.subtotalBackgroundColor = const PdfColor.fromInt(0xFFFAFAFA),
  });

  /// Standard paper dimension.
  final PdfPageSize pageSize;

  /// Page orientation (portrait or landscape).
  final PdfOrientation orientation;

  /// Outer page margin in PDF points.
  final double margin;

  /// Whether to render running page numbers in the footer ('Page X of Y').
  final bool includePageNumbers;

  /// Whether to render generation timestamp in the footer.
  final bool includeTimestamp;

  /// Custom regular Unicode/Arabic font.
  final pw.Font? baseFont;

  /// Custom bold Unicode/Arabic font.
  final pw.Font? boldFont;

  /// Primary accent color for title and dividers.
  final PdfColor primaryColor;

  /// Background color for table column headers.
  final PdfColor headerBackgroundColor;

  /// Background color for group subtotal rows.
  final PdfColor subtotalBackgroundColor;

  /// Resolves the concrete [PdfPageFormat] combining size, orientation, and margins.
  PdfPageFormat resolvePageFormat() {
    var format = switch (pageSize) {
      PdfPageSize.a4 => PdfPageFormat.a4,
      PdfPageSize.a5 => PdfPageFormat.a5,
      PdfPageSize.letter => PdfPageFormat.letter,
    };

    if (orientation == PdfOrientation.landscape) {
      format = format.landscape;
    }

    return format.copyWith(
      marginTop: margin,
      marginBottom: margin,
      marginLeft: margin,
      marginRight: margin,
    );
  }
}
