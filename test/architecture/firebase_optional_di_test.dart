// fst:auth:start
import 'dart:io';

// fst:auth:end
import 'package:analytics/analytics.dart';
import 'package:app_platform/app_platform.dart';
import 'package:config/config.dart';
// fst:auth:start
import 'package:feature_auth/feature_auth.dart';
// fst:auth:end
import 'package:flutter_starter_template/app/firebase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' show GetItHelper;
// fst:network:start
import 'package:network/network.dart';
// fst:network:end
import 'package:storage/storage.dart';

void main() {
  test(
    'DI graph resolves tracking ports, Dio, and AuthBloc without Firebase',
    () async {
      SharedPreferences.setMockInitialValues({});
      final locator = GetIt.asNewInstance()
        ..allowReassignment = kFirebaseEnabled;
      final helper = GetItHelper(locator);
      addTearDown(locator.reset);

      await AnalyticsPackageModule().init(helper);
      await ConfigPackageModule().init(helper);
      await StoragePackageModule().init(helper);
      // fst:network:start
      await NetworkPackageModule().init(helper);
      // fst:network:end
      await AppPlatformPackageModule().init(helper);
      // fst:auth:start
      await FeatureAuthPackageModule().init(helper);
      // fst:auth:end

      if (kFirebaseEnabled) {
        // In a Firebase-enabled project, the generated modules bind the
        // Firebase adapters at the `// fst:*-impl` markers. Verify the default
        // performance binding delegates to FirebasePerformance (which throws
        // when Firebase.initializeApp has not run), then swap in the no-op
        // implementations to verify the rest of the DI chain resolves cleanly
        // without Firebase.
        // fst:network:start
        expect(locator.call<PerformanceTracker>, throwsA(anything));
        locator.registerLazySingleton<PerformanceTracker>(
          NoOpPerformanceTracker.new,
        );
        // fst:network:end
        locator
          ..registerLazySingleton<AnalyticsService>(NoOpAnalyticsService.new)
          ..registerLazySingleton<CrashReporter>(NoOpCrashReporter.new);
      }

      expect(locator<AnalyticsService>(), isA<NoOpAnalyticsService>());
      expect(locator<CrashReporter>(), isA<NoOpCrashReporter>());
      // fst:network:start
      expect(locator<PerformanceTracker>(), isA<NoOpPerformanceTracker>());
      expect(locator<Dio>(), isA<Dio>());
      // fst:network:end
      // fst:auth:start
      final usesFirebaseAuth = File(
        'packages/features/auth/lib/src/data/firebase_auth_module.dart',
      ).existsSync();
      if (!usesFirebaseAuth) {
        final authBloc = locator<AuthBloc>();
        addTearDown(authBloc.close);
        expect(authBloc, isA<AuthBloc>());
      }
      // fst:auth:end
    },
  );
}
