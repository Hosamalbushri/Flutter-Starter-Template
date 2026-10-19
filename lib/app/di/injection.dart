import 'package:analytics/analytics.dart';
import 'package:app_platform/app_platform.dart';
import 'package:config/config.dart';
import 'package:document_engine/document_engine.dart';
// fst:auth:start
import 'package:feature_auth/feature_auth.dart';
// fst:auth:end
// fst:feature:bookmarks:start
import 'package:feature_bookmarks/feature_bookmarks.dart';
// fst:feature:bookmarks:end
// fst:feature:collections:start
import 'package:feature_collections/feature_collections.dart';
// fst:feature:collections:end
import 'package:feature_document_center/feature_document_center.dart';
import 'package:feature_home/feature_home.dart';
// fst:feature:notifications:start
import 'package:feature_notifications/feature_notifications.dart';
// fst:feature:notifications:end
import 'package:feature_profile/feature_profile.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
// fst:network:start
import 'package:network/network.dart';
// fst:network:end
import 'package:shared_contracts/shared_contracts.dart';
import 'package:storage/storage.dart';
// fst:backend:start
import 'package:sync_connectivity_plus/sync_connectivity_plus.dart';
// fst:backend:end
import 'package:theme/theme.dart';

import '../firebase.dart';
import 'injection.config.dart';
import 'reader_fallbacks.dart';

final GetIt getIt = GetIt.instance;

/// Async because core database modules use `@preResolve` to open native
/// resources before any consumer is constructed. Must be awaited from `main`.
///
/// Ordering: `storage` provides the `AuthTokenStore` + `FlutterSecureStorage`
/// that `network` builds the authenticated `Dio` on, so it is listed before
/// `network`. `shared_contracts` registers `ActivityNotifier`, consumed by a
/// feature BLoC, so it precedes the feature modules. The authenticated `Dio` is
/// now provided by `network` (not by `feature_auth`), so no feature module
/// needs to be ordered relative to `feature_auth` for it.
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(AnalyticsPackageModule),
    ExternalModule(ConfigPackageModule),
    ExternalModule(StoragePackageModule),
    // fst:network:start
    ExternalModule(NetworkPackageModule),
    // fst:network:end
    ExternalModule(AppPlatformPackageModule),
    ExternalModule(ThemePackageModule),
    // fst:backend:start
    ExternalModule(SyncConnectivityPlusPackageModule),
    // fst:backend:end
    ExternalModule(SharedContractsPackageModule),
    // fst:auth:start
    ExternalModule(FeatureAuthPackageModule),
    // fst:auth:end
    // fst:feature:notifications:start
    ExternalModule(FeatureNotificationsPackageModule),
    // fst:feature:notifications:end
    // fst:feature:collections:start
    ExternalModule(FeatureCollectionsPackageModule),
    // fst:feature:collections:end
    // fst:feature:bookmarks:start
    ExternalModule(FeatureBookmarksPackageModule),
    // fst:feature:bookmarks:end
    ExternalModule(FeatureHomePackageModule),
    ExternalModule(FeatureProfilePackageModule),
    ExternalModule(FeatureDocumentCenterPackageModule),
    // fst:feature-modules — `fst add-feature` inserts new feature modules above
  ],
)
Future<void> configureDependencies() async {
  await getIt.init();
  configureFirebaseRuntimeBindings(getIt);
  // Fill in Null-Object readers for any feature dropped at scaffold time, so
  // `home` keeps working when bookmarks/collections were excluded.
  registerReaderFallbacks(getIt);
  _configureDocumentEngine(getIt);
}

/// Replaces Firebase-backed tracking adapters with inert implementations when
/// Firebase is not explicitly enabled for the current build.
void configureFirebaseRuntimeBindings(GetIt sl) {
  if (kFirebaseEnabled) return;

  if (sl.isRegistered<AnalyticsService>()) {
    sl.unregister<AnalyticsService>();
  }
  if (sl.isRegistered<CrashReporter>()) {
    sl.unregister<CrashReporter>();
  }
  if (sl.isRegistered<PerformanceTracker>()) {
    sl.unregister<PerformanceTracker>();
  }

  sl
    ..registerLazySingleton<AnalyticsService>(NoOpAnalyticsService.new)
    ..registerLazySingleton<CrashReporter>(NoOpCrashReporter.new)
    ..registerLazySingleton<PerformanceTracker>(NoOpPerformanceTracker.new);
}

void _configureDocumentEngine(GetIt sl) {
  final registry = DocumentFormatRegistry.standard();
  if (sl.isRegistered<CollectionsImportDelegate>()) {
    registry.registerImportDelegate(sl<CollectionsImportDelegate>());
  }
  if (sl.isRegistered<BookmarksImportDelegate>()) {
    registry.registerImportDelegate(sl<BookmarksImportDelegate>());
  }
  if (!sl.isRegistered<DocumentFormatRegistry>()) {
    sl.registerSingleton<DocumentFormatRegistry>(registry);
  }
}
