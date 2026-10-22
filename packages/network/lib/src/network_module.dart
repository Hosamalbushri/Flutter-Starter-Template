import 'dart:developer' as developer;

import 'package:config/config.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:storage/storage.dart';

import 'auth_interceptor.dart';
import 'performance_interceptor.dart';
import 'performance_tracker.dart';
import 'retry_interceptor.dart';
import 'token_refresher.dart';

BaseOptions apiBaseOptions(
  String baseUrl, {
  Duration timeout = const Duration(seconds: 10),
}) => BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: timeout,
  receiveTimeout: timeout,
  contentType: 'application/json',
);

/// Metadata-only request logging for development builds.
///
/// Headers, query strings, request/response bodies, and exception messages are
/// deliberately excluded because they frequently contain credentials or user
/// data. Gate the call site on [EnvConfig.isDev].
Interceptor devLogInterceptor({void Function(String message)? logPrint}) {
  final write =
      logPrint ?? (String message) => developer.log(message, name: 'dio');

  return InterceptorsWrapper(
    onRequest: (options, handler) {
      write('HTTP ${options.method} ${options.uri.path}');
      handler.next(options);
    },
    onResponse: (response, handler) {
      final request = response.requestOptions;
      write(
        'HTTP ${request.method} ${request.uri.path} '
        '-> ${response.statusCode ?? 'unknown'}',
      );
      handler.next(response);
    },
    onError: (error, handler) {
      final request = error.requestOptions;
      write(
        'HTTP ${request.method} ${request.uri.path} failed '
        '(${error.type.name}, status ${error.response?.statusCode ?? 'none'})',
      );
      handler.next(error);
    },
  );
}

@module
abstract class NetworkModule {
  /// Plain Dio with no auth/refresh wiring. Used by callers that must bypass
  /// application-level interceptors.
  @lazySingleton
  @Named('plain')
  Dio providePlainDio(EnvConfig env) =>
      Dio(apiBaseOptions(env.apiBaseUrl, timeout: env.apiTimeout));

  /// Authenticated Dio used by the app: attaches the Bearer token and, on 401,
  /// transparently refreshes once and retries the request.
  ///
  /// Interceptor order matters. [PerformanceInterceptor] runs first (outside
  /// dev) so it times the full request including retries; [AuthInterceptor]
  /// owns the 401 → refresh path; [RetryInterceptor] handles transient failures
  /// with backoff. In dev a [devLogInterceptor] is appended last so it observes
  /// the final, token-bearing requests.
  @lazySingleton
  Dio provideDio(
    AuthTokenStore tokens,
    TokenRefresher refresher,
    EnvConfig env,
    PerformanceTracker performance,
  ) {
    final dio = Dio(apiBaseOptions(env.apiBaseUrl, timeout: env.apiTimeout));
    if (!env.isDev) {
      dio.interceptors.add(PerformanceInterceptor(performance));
    }
    dio.interceptors.add(AuthInterceptor(tokens, refresher, dio));
    dio.interceptors.add(RetryInterceptor(dio));
    if (env.isDev) {
      dio.interceptors.add(devLogInterceptor());
    }
    return dio;
  }
}
