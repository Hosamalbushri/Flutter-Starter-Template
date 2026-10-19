/// Standard ESC/POS printer byte codes.
abstract final class EscPosCommands {
  /// ESC @ - Initialize printer
  static const List<int> init = [0x1B, 0x40];

  /// LF - Line feed
  static const List<int> lf = [0x0A];

  /// ESC a n - Select justification (0 = Left, 1 = Center, 2 = Right)
  static const int escA = 0x61;

  /// ESC E n - Turn emphasized (bold) mode on/off
  static const int escE = 0x45;

  /// ESC - n - Turn underline mode on/off
  static const int escDash = 0x2D;

  /// GS ! n - Select character size
  static const int gsExclamation = 0x21;

  /// ESC d n - Print and feed n lines
  static const int escD = 0x64;

  /// GS V m - Full cut: [0x1D, 0x56, 0x00] or [0x1D, 0x56, 0x41, 0x03]
  static const List<int> fullCut = [0x1D, 0x56, 0x41, 0x03];

  /// GS V m - Partial cut: [0x1D, 0x56, 0x01] or [0x1D, 0x56, 0x42, 0x03]
  static const List<int> partialCut = [0x1D, 0x56, 0x42, 0x03];
}
