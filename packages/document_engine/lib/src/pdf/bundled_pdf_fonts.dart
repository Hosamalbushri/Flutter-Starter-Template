import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'bundled_dejavu_sans.dart';

/// Offline Unicode fonts used when callers do not provide their own PDF fonts.
///
/// DejaVu Sans covers Arabic shaping and the Latin characters used by the
/// built-in reports. The decoded fonts are cached for the process lifetime.
abstract final class BundledPdfFonts {
  static final RegExp _whitespace = RegExp(r'\s');
  static pw.Font? _regular;
  static pw.Font? _bold;

  static pw.Font get regular => _regular ??= pw.Font.ttf(
    _decodeFont(bundledDejaVuSansRegularBase64),
  );

  static pw.Font get bold => _bold ??= pw.Font.ttf(
    _decodeFont(bundledDejaVuSansBoldBase64),
  );

  static ByteData _decodeFont(String encoded) {
    final bytes = base64Decode(encoded.replaceAll(_whitespace, ''));
    return ByteData.sublistView(bytes);
  }
}
