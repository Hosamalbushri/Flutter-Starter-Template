import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [LocalFileComparator] that allows a specified tolerance threshold
/// (default 4.0% / 0.04) for cross-platform font rasterization differences
/// (such as FreeType on Linux vs CoreText on macOS).
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.04});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Configures [goldenFileComparator] with [tolerance] if running with
/// [LocalFileComparator].
void setUpTolerantGoldenComparator(Uri testUri, {double tolerance = 0.04}) {
  if (goldenFileComparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(
      testUri,
      tolerance: tolerance,
    );
  }
}

/// Loads DejaVuSans.ttf from candidate paths.
Future<Uint8List> loadGoldenFontBytes() async {
  const candidates = [
    'test/widgets/golden/fonts/DejaVuSans.ttf',
    'packages/app_ui/test/widgets/golden/fonts/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsBytes();
    }
  }
  throw StateError('Could not find DejaVuSans.ttf in candidates: $candidates');
}

/// Loads a bundled font asset into the Flutter test font loader.
Future<void> loadBundledFont(String family, String asset) async {
  final data = await rootBundle.load(asset);
  await (FontLoader(family)..addFont(Future.value(data))).load();
}
