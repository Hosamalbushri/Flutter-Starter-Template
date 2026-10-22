/// Paper width specification for thermal receipt printers.
enum ThermalPaperWidth {
  /// 58mm thermal paper, typically 32 characters per line with standard font.
  mm58(charsPerLine: 32, printableWidthDots: 384),

  /// 80mm thermal paper, typically 48 characters per line with standard font.
  mm80(charsPerLine: 48, printableWidthDots: 576);

  const ThermalPaperWidth({
    required this.charsPerLine,
    required this.printableWidthDots,
  });

  /// Maximum characters per line for standard 12x24 font.
  final int charsPerLine;

  /// Width in dots.
  final int printableWidthDots;
}

/// Text alignment on thermal paper.
enum ThermalAlign {
  left,
  center,
  right,
}

/// Text size scaling for thermal printing.
enum ThermalTextSize {
  normal,
  doubleHeight,
  doubleWidth,
  doubleBoth,
}

/// Column definition for multi-column receipt line layout.
class ThermalColumn {
  const ThermalColumn({
    required this.text,
    required this.widthRatio,
    this.align = ThermalAlign.left,
  }) : assert(
         widthRatio > 0 && widthRatio <= 1.0,
         'widthRatio must be between 0 and 1.0',
       );

  final String text;
  final double widthRatio;
  final ThermalAlign align;
}
