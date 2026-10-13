import 'package:config/config.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';
import 'package:test_utils/test_utils.dart';

class _MockPerformanceTracker extends Mock implements PerformanceTracker {}

class _MockHttpPerformanceMetric extends Mock
    implements HttpPerformanceMetric {}

class _MockFirebasePerformance extends Mock implements FirebasePerformance {}

class _MockHttpMetric extends Mock implements HttpMetric {}

class _MockAuthTokenStore extends Mock implements AuthTokenStore {}

class _TestNetworkModule extends NetworkModule {}

class _TestEnvConfig extends EnvConfig {
  const _TestEnvConfig(this._flavor);

  final String _flavor;

  @override
  String get flavor => _flavor;

  @override
  String get apiBaseUrl => 'https://example.test';
}

/// Returns a fixed response or throws a fixed error for any request.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.outcome);

  final Object outcome;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = outcome;
    if (result is DioException) throw result;
    return result as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(PerformanceHttpMethod.get);
    registerFallbackValue(HttpMethod.Get);
  });

  ResponseBody ok() => ResponseBody.fromString('{}', 200);

  group('PerformanceInterceptor with PerformanceTracker', () {
    late _MockPerformanceTracker tracker;
    late _MockHttpPerformanceMetric metric;

    setUp(() {
      tracker = _MockPerformanceTracker();
      metric = _MockHttpPerformanceMetric();
      when(() => tracker.newHttpMetric(any(), any())).thenReturn(metric);
      when(metric.start).thenAnswer((_) async {});
      when(metric.stop).thenAnswer((_) async {});
      when(() => metric.httpResponseCode = any()).thenReturn(null);
    });

    Dio buildDio(Object outcome) {
      return Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _StubAdapter(outcome)
        ..interceptors.add(PerformanceInterceptor(tracker));
    }

    test(
      'starts and stops a metric with the response code on success',
      () async {
        final dio = buildDio(ok());

        await dio.get<dynamic>('/thing');

        verify(
          () => tracker.newHttpMetric(any(), PerformanceHttpMethod.get),
        ).called(1);
        verify(metric.start).called(1);
        verify(() => metric.httpResponseCode = 200).called(1);
        verify(metric.stop).called(1);
      },
    );

    test('stops the metric with the status code on error', () async {
      // A 500 response: Dio's default validateStatus rejects it and raises a
      // DioException carrying the original request options (and our metric).
      final dio = buildDio(ResponseBody.fromString('{}', 500));

      await expectLater(
        dio.get<dynamic>('/thing'),
        throwsA(isA<DioException>()),
      );

      verify(metric.start).called(1);
      verify(() => metric.httpResponseCode = 500).called(1);
      verify(metric.stop).called(1);
    });
  });

  group('PerformanceInterceptor with NoOpPerformanceTracker', () {
    test(
      'executes requests and errors without Firebase initialized',
      () async {
        const tracker = NoOpPerformanceTracker();
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = _StubAdapter(ok())
          ..interceptors.add(PerformanceInterceptor(tracker));

        final response = await dio.get<dynamic>('/thing');
        expect(response.statusCode, 200);

        dio.httpClientAdapter = _StubAdapter(
          ResponseBody.fromString('{}', 500),
        );
        await expectLater(
          dio.get<dynamic>('/thing'),
          throwsA(isA<DioException>()),
        );

        await tracker.setPerformanceCollectionEnabled(enabled: false);
        final metric = tracker.newHttpMetric(
          'https://example.test/thing',
          PerformanceHttpMethod.fromString('unknown'),
        )..httpResponseCode = 204;
        expect(metric.httpResponseCode, isNull);
      },
    );
  });

  group('FirebasePerformanceTracker', () {
    late _MockFirebasePerformance firebasePerformance;
    late _MockHttpMetric firebaseMetric;
    late FirebasePerformanceTracker tracker;

    setUp(() {
      firebasePerformance = _MockFirebasePerformance();
      firebaseMetric = _MockHttpMetric();
      when(
        () => firebasePerformance.newHttpMetric(any(), any()),
      ).thenReturn(firebaseMetric);
      when(firebaseMetric.start).thenAnswer((_) async {});
      when(firebaseMetric.stop).thenAnswer((_) async {});
      when(() => firebaseMetric.httpResponseCode = any()).thenReturn(null);
      when(() => firebaseMetric.httpResponseCode).thenReturn(201);
      when(
        () => firebasePerformance.setPerformanceCollectionEnabled(any()),
      ).thenAnswer((_) async {});
      tracker = FirebasePerformanceTracker(firebasePerformance);
    });

    test('delegates metric lifecycle to FirebasePerformance', () async {
      final metric = tracker.newHttpMetric(
        'https://example.test/items',
        PerformanceHttpMethod.post,
      );

      await metric.start();
      metric.httpResponseCode = 201;
      expect(metric.httpResponseCode, 201);
      await metric.stop();
      await tracker.setPerformanceCollectionEnabled(enabled: true);

      verify(
        () => firebasePerformance.newHttpMetric(
          'https://example.test/items',
          HttpMethod.Post,
        ),
      ).called(1);
      verify(firebaseMetric.start).called(1);
      verify(() => firebaseMetric.httpResponseCode = 201).called(1);
      verify(firebaseMetric.stop).called(1);
      verify(
        () => firebasePerformance.setPerformanceCollectionEnabled(true),
      ).called(1);
    });
  });

  group('NetworkModule & flavors (Firebase disabled vs enabled)', () {
    late _MockAuthTokenStore tokenStore;

    setUp(() {
      tokenStore = _MockAuthTokenStore();
      when(() => tokenStore.accessToken).thenReturn(null);
    });

    for (final flavor in ['dev', 'staging', 'prod']) {
      test(
        'resolves Dio and executes requests in $flavor flavor without Firebase '
        'when bound to NoOpPerformanceTracker',
        () async {
          final env = _TestEnvConfig(flavor);
          final module = _TestNetworkModule();
          final plainDio = module.providePlainDio(env);
          final refresher = TokenRefresher(tokenStore, plainDio);

          final dio = module.provideDio(
            tokenStore,
            refresher,
            env,
            const NoOpPerformanceTracker(),
          )..httpClientAdapter = _StubAdapter(ok());

          final response = await dio.get<dynamic>('/health');
          expect(response.statusCode, 200);
        },
      );
    }

    test(
      'skips PerformanceInterceptor in dev flavor even when bound to '
      'FirebasePerformanceTracker',
      () async {
        final firebasePerformance = _MockFirebasePerformance();
        const env = _TestEnvConfig('dev');
        final module = _TestNetworkModule();
        final plainDio = module.providePlainDio(env);
        final refresher = TokenRefresher(tokenStore, plainDio);

        final dio = module.provideDio(
          tokenStore,
          refresher,
          env,
          FirebasePerformanceTracker(firebasePerformance),
        )..httpClientAdapter = _StubAdapter(ok());

        final response = await dio.get<dynamic>('/health');
        expect(response.statusCode, 200);
        verifyNever(() => firebasePerformance.newHttpMetric(any(), any()));
      },
    );

    for (final flavor in ['staging', 'prod']) {
      test(
        'records metrics in $flavor flavor when bound to '
        'FirebasePerformanceTracker',
        () async {
          final firebasePerformance = _MockFirebasePerformance();
          final firebaseMetric = _MockHttpMetric();
          when(
            () => firebasePerformance.newHttpMetric(any(), any()),
          ).thenReturn(firebaseMetric);
          when(firebaseMetric.start).thenAnswer((_) async {});
          when(firebaseMetric.stop).thenAnswer((_) async {});
          when(() => firebaseMetric.httpResponseCode = any()).thenReturn(null);

          final env = _TestEnvConfig(flavor);
          final module = _TestNetworkModule();
          final plainDio = module.providePlainDio(env);
          final refresher = TokenRefresher(tokenStore, plainDio);

          final dio = module.provideDio(
            tokenStore,
            refresher,
            env,
            FirebasePerformanceTracker(firebasePerformance),
          )..httpClientAdapter = _StubAdapter(ok());

          final response = await dio.get<dynamic>('/health');
          expect(response.statusCode, 200);

          verify(
            () => firebasePerformance.newHttpMetric(
              'https://example.test/health',
              HttpMethod.Get,
            ),
          ).called(1);
          verify(firebaseMetric.start).called(1);
          verify(() => firebaseMetric.httpResponseCode = 200).called(1);
          verify(firebaseMetric.stop).called(1);
        },
      );
    }
  });
}
