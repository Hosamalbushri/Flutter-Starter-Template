// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:config/config.dart' as _i259;
import 'package:dio/dio.dart' as _i361;
import 'package:injectable/injectable.dart' as _i526;
import 'package:network/src/network_module.dart' as _i794;
import 'package:network/src/performance_module.dart' as _i87;
import 'package:network/src/performance_tracker.dart' as _i420;
import 'package:network/src/session_termination_notifier.dart' as _i129;
import 'package:network/src/token_refresher.dart' as _i277;
import 'package:storage/storage.dart' as _i431;

class NetworkPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    final performanceModule = _$PerformanceModule();
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i420.PerformanceTracker>(
      () => performanceModule.providePerformance(),
    );
    gh.lazySingleton<_i129.SessionTerminationNotifier>(
      () => _i129.SessionTerminationNotifier(),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.providePlainDio(gh<_i259.EnvConfig>()),
      instanceName: 'plain',
    );
    gh.lazySingleton<_i277.TokenRefresher>(
      () => _i277.TokenRefresher(
        gh<_i431.AuthTokenStore>(),
        gh<_i361.Dio>(instanceName: 'plain'),
        gh<_i129.SessionTerminationNotifier>(),
      ),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.provideDio(
        gh<_i431.AuthTokenStore>(),
        gh<_i277.TokenRefresher>(),
        gh<_i259.EnvConfig>(),
        gh<_i420.PerformanceTracker>(),
      ),
    );
  }
}

class _$PerformanceModule extends _i87.PerformanceModule {}

class _$NetworkModule extends _i794.NetworkModule {}
