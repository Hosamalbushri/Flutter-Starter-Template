/// Centralized corner-radius scale.
///
/// Use these tokens with `BorderRadius.circular` (or `Radius.circular`) instead
/// of hardcoded pixel values so rounding stays consistent across cards, inputs,
/// chips, and overlays, and can be tuned in one place.
abstract final class AppRadius {
  /// 4px - tiny indicators (e.g. carousel dots).
  static const double xs = 4;

  /// 8px - chips, thumbnails, small previews.
  static const double sm = 8;

  /// 10px - compact buttons and dense badges.
  static const double smd = 10;

  /// 12px - medium cards, link previews, and list tiles.
  static const double md = 12;

  /// 14px - standard interactive buttons.
  static const double button = 14;

  /// 16px - cards and text fields.
  static const double lg = 16;

  /// 20px - elevated overlays and dialogs.
  static const double xl = 20;

  /// Fully rounded controls whose radius should exceed their height.
  static const double full = 999;
}
