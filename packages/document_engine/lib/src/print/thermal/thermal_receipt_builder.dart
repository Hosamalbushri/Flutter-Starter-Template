import 'dart:convert';
import 'dart:typed_data';

import 'esc_pos_commands.dart';
import 'thermal_models.dart';

/// Builder to construct raw ESC/POS binary receipt streams.
class ThermalReceiptBuilder {
  ThermalReceiptBuilder({
    this.paperWidth = ThermalPaperWidth.mm80,
    this.encoding = utf8,
  }) {
    initialize();
  }

  final ThermalPaperWidth paperWidth;
  final Encoding encoding;
  final List<int> _bytes = [];

  /// Number of characters per single line.
  int get charsPerLine => paperWidth.charsPerLine;

  /// Resets printer settings to default.
  void initialize() {
    _bytes.addAll(EscPosCommands.init);
  }

  /// Sets text alignment (left, center, right).
  void setAlign(ThermalAlign align) {
    final code = switch (align) {
      ThermalAlign.left => 0,
      ThermalAlign.center => 1,
      ThermalAlign.right => 2,
    };
    _bytes.addAll([0x1B, EscPosCommands.escA, code]);
  }

  /// Sets bold/emphasized mode on or off.
  void setBold({required bool bold}) {
    _bytes.addAll([0x1B, EscPosCommands.escE, if (bold) 1 else 0]);
  }

  /// Sets underline mode on or off.
  void setUnderline({required bool underline}) {
    _bytes.addAll([0x1B, EscPosCommands.escDash, if (underline) 1 else 0]);
  }

  /// Sets font magnification.
  void setTextSize(ThermalTextSize size) {
    final code = switch (size) {
      ThermalTextSize.normal => 0x00,
      ThermalTextSize.doubleHeight => 0x01,
      ThermalTextSize.doubleWidth => 0x10,
      ThermalTextSize.doubleBoth => 0x11,
    };
    _bytes.addAll([0x1D, EscPosCommands.gsExclamation, code]);
  }

  /// Prints a single line of text with optional styling, followed by LF.
  void text(
    String content, {
    ThermalAlign align = ThermalAlign.left,
    bool bold = false,
    bool underline = false,
    ThermalTextSize size = ThermalTextSize.normal,
  }) {
    setAlign(align);
    if (bold) setBold(bold: true);
    if (underline) setUnderline(underline: true);
    if (size != ThermalTextSize.normal) setTextSize(size);

    _bytes.addAll(encoding.encode(content));
    _bytes.addAll(EscPosCommands.lf);

    // Reset styles
    if (bold) setBold(bold: false);
    if (underline) setUnderline(underline: false);
    if (size != ThermalTextSize.normal) setTextSize(ThermalTextSize.normal);
    if (align != ThermalAlign.left) setAlign(ThermalAlign.left);
  }

  /// Formats a tabular line partitioned into columns based on width ratios.
  void row(List<ThermalColumn> columns) {
    if (columns.isEmpty) return;

    final totalLineChars = charsPerLine;
    final columnWidths = <int>[];
    var allocatedChars = 0;

    for (var i = 0; i < columns.length; i++) {
      if (i == columns.length - 1) {
        columnWidths.add(totalLineChars - allocatedChars);
      } else {
        final w = (columns[i].widthRatio * totalLineChars).floor();
        columnWidths.add(w);
        allocatedChars += w;
      }
    }

    final sb = StringBuffer();
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      final width = columnWidths[i];
      final text = col.text;

      String formatted;
      if (text.length >= width) {
        formatted = text.substring(0, width);
      } else {
        final pad = width - text.length;
        formatted = switch (col.align) {
          ThermalAlign.left => text.padRight(width),
          ThermalAlign.right => text.padLeft(width),
          ThermalAlign.center =>
            ' ' * (pad ~/ 2) + text + ' ' * (pad - (pad ~/ 2)),
        };
      }
      sb.write(formatted);
    }

    _bytes.addAll(encoding.encode(sb.toString()));
    _bytes.addAll(EscPosCommands.lf);
  }

  /// Prints a horizontal separator rule spanning the full width.
  void divider({String char = '-'}) {
    final line = (char.isEmpty ? '-' : char[0]) * charsPerLine;
    _bytes.addAll(encoding.encode(line));
    _bytes.addAll(EscPosCommands.lf);
  }

  /// Prints a double-line separator rule.
  void doubleDivider() => divider(char: '=');

  /// Feeds [lines] blank lines.
  void feed([int lines = 1]) {
    if (lines <= 0) return;
    _bytes.addAll([0x1B, EscPosCommands.escD, lines]);
  }

  /// Sends cut command.
  void cut({bool partial = false}) {
    feed(3);
    _bytes.addAll(partial ? EscPosCommands.partialCut : EscPosCommands.fullCut);
  }

  /// Returns compiled ESC/POS byte sequence.
  Uint8List toBytes() => Uint8List.fromList(_bytes);
}
