import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android delegates cold and warm links to Flutter exactly once', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:launchMode="singleTop"'));
    expect(
      manifest,
      contains('android:name="flutter_deeplinking_enabled"'),
    );
    expect(manifest, contains('android:value="true"'));
    expect(
      'android.intent.action.VIEW'.allMatches(manifest),
      hasLength(1),
      reason: 'A second VIEW handler can deliver each deep link twice.',
    );
    expect(
      manifest,
      contains('android:scheme="https" android:host="yourdomain.com"'),
    );
  });
}
