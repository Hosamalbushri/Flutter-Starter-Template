import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android pins the dynamic integration_test runner dependency', () {
    final buildScript = File('android/build.gradle.kts').readAsStringSync();

    expect(
      buildScript,
      contains('requested.group == "androidx.test"'),
    );
    expect(buildScript, contains('requested.name == "runner"'));
    expect(buildScript, contains('useVersion("1.7.0")'));
    expect(
      buildScript,
      isNot(contains('androidx.test:runner:1.2+')),
      reason: 'Dynamic Android dependencies reintroduce network-only builds.',
    );
  });

  test('Firebase Gradle plugins are optional without local configuration', () {
    final source = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final firebaseSource = File('lib/app/firebase.dart').readAsStringSync();

    const conditionalPlugin =
        'apply(plugin = "com.google.gms.google-services")';
    if (source.contains(conditionalPlugin)) {
      expect(source, contains('val googleServicesFile'));
      expect(source, contains('if (googleServicesFile.exists())'));
      expect(firebaseSource, contains('bool.fromEnvironment('));
      expect(firebaseSource, contains("'FIREBASE_ENABLED'"));
      expect(firebaseSource, contains('defaultValue: false'));
    } else {
      expect(firebaseSource, contains('const bool kFirebaseEnabled = false;'));
    }
    expect(
      RegExp(r'id\("com\.google\.gms\.google-services"\)').hasMatch(source),
      isFalse,
      reason: 'The plugins block would make google-services.json mandatory.',
    );
  });

  test('production release never falls back to the debug signing key', () {
    final source = File('android/app/build.gradle.kts').readAsStringSync();

    expect(source, isNot(contains('signingConfigs.getByName("debug")')));
    expect(source, contains('requestedProdRelease'));
    expect(source, contains('throw GradleException('));
  });
}
