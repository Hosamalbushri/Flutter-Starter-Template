import 'package:flutter/widgets.dart';

/// Convenience accessors for the ambient [MediaQuery] of a [BuildContext].
///
/// Prefer reading sizing from a [LayoutBuilder]'s constraints when laying out
/// a specific subtree; use these getters for whole-screen decisions.
extension BuildContextMedia on BuildContext {
  /// The nearest [MediaQueryData] for this context.
  ///
  /// Prefer the aspect-specific getters ([screenSize], [viewPadding],
  /// [viewInsets], [bottomInset], [orientation], [textScaler]) so widgets only
  /// rebuild when that specific aspect changes.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// The size of the media (e.g. the window or screen).
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Padding obscured by system UI (e.g. notches, status bars).
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Safe-area padding around the media.
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Insets obscured by system UI such as the on-screen keyboard.
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// The bottom view inset, typically the on-screen keyboard height.
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  /// The current [TextScaler] for this context.
  TextScaler get textScaler => MediaQuery.textScalerOf(this);

  /// The current device [Orientation].
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// Whether the device is in landscape orientation.
  bool get isLandscape => orientation == Orientation.landscape;

  /// Whether the device is in portrait orientation.
  bool get isPortrait => orientation == Orientation.portrait;
}
