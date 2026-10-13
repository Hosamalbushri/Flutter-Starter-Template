import 'package:firebase_performance/firebase_performance.dart'
    as firebase_perf;

/// HTTP methods supported by [PerformanceTracker].
enum PerformanceHttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
  trace,
  connect;

  /// Parses a case-insensitive HTTP method string, defaulting to [get] for
  /// unrecognized values.
  static PerformanceHttpMethod fromString(String method) =>
      switch (method.toUpperCase()) {
        'GET' => PerformanceHttpMethod.get,
        'POST' => PerformanceHttpMethod.post,
        'PUT' => PerformanceHttpMethod.put,
        'DELETE' => PerformanceHttpMethod.delete,
        'PATCH' => PerformanceHttpMethod.patch,
        'HEAD' => PerformanceHttpMethod.head,
        'OPTIONS' => PerformanceHttpMethod.options,
        'TRACE' => PerformanceHttpMethod.trace,
        'CONNECT' => PerformanceHttpMethod.connect,
        _ => PerformanceHttpMethod.get,
      };
}

/// A Firebase-independent handle for an individual HTTP request metric.
abstract class HttpPerformanceMetric {
  /// Marks the start of the HTTP request.
  Future<void> start();

  /// Marks the end of the HTTP request and flushes the recorded metric.
  Future<void> stop();

  /// The recorded HTTP response status code, if any.
  int? get httpResponseCode;

  /// Records the HTTP response status code (e.g. `200`, `500`).
  set httpResponseCode(int? value);
}

/// Tracks network performance metrics (e.g. HTTP request latency and status
/// codes).
abstract class PerformanceTracker {
  /// Creates a new [HttpPerformanceMetric] for the given [url] and [method].
  HttpPerformanceMetric newHttpMetric(String url, PerformanceHttpMethod method);

  /// Enables or disables performance monitoring collection.
  Future<void> setPerformanceCollectionEnabled({required bool enabled});
}

/// A [PerformanceTracker] backed by Firebase Performance Monitoring.
class FirebasePerformanceTracker implements PerformanceTracker {
  FirebasePerformanceTracker(this._performance);

  final firebase_perf.FirebasePerformance _performance;

  @override
  HttpPerformanceMetric newHttpMetric(
    String url,
    PerformanceHttpMethod method,
  ) {
    final metric = _performance.newHttpMetric(url, _toFirebaseMethod(method));
    return FirebaseHttpPerformanceMetric(metric);
  }

  @override
  Future<void> setPerformanceCollectionEnabled({required bool enabled}) =>
      _performance.setPerformanceCollectionEnabled(enabled);

  static firebase_perf.HttpMethod _toFirebaseMethod(
    PerformanceHttpMethod method,
  ) => switch (method) {
    PerformanceHttpMethod.get => firebase_perf.HttpMethod.Get,
    PerformanceHttpMethod.post => firebase_perf.HttpMethod.Post,
    PerformanceHttpMethod.put => firebase_perf.HttpMethod.Put,
    PerformanceHttpMethod.delete => firebase_perf.HttpMethod.Delete,
    PerformanceHttpMethod.patch => firebase_perf.HttpMethod.Patch,
    PerformanceHttpMethod.head => firebase_perf.HttpMethod.Head,
    PerformanceHttpMethod.options => firebase_perf.HttpMethod.Options,
    PerformanceHttpMethod.trace => firebase_perf.HttpMethod.Trace,
    PerformanceHttpMethod.connect => firebase_perf.HttpMethod.Connect,
  };
}

/// An [HttpPerformanceMetric] backed by Firebase Performance's
/// [firebase_perf.HttpMetric].
class FirebaseHttpPerformanceMetric implements HttpPerformanceMetric {
  FirebaseHttpPerformanceMetric(this._metric);

  final firebase_perf.HttpMetric _metric;

  @override
  Future<void> start() => _metric.start();

  @override
  Future<void> stop() => _metric.stop();

  @override
  int? get httpResponseCode => _metric.httpResponseCode;

  @override
  set httpResponseCode(int? value) => _metric.httpResponseCode = value;
}

/// A [PerformanceTracker] that records nothing.
///
/// The default binding when performance monitoring is disabled (e.g. a project
/// scaffolded with `fst create --no-firebase`). To enable performance
/// monitoring, point the `// fst:performance-impl` binding in
/// `performance_module.dart` at a real adapter.
class NoOpPerformanceTracker implements PerformanceTracker {
  const NoOpPerformanceTracker();

  @override
  HttpPerformanceMetric newHttpMetric(
    String url,
    PerformanceHttpMethod method,
  ) => const NoOpHttpPerformanceMetric();

  @override
  Future<void> setPerformanceCollectionEnabled({required bool enabled}) async {}
}

/// An [HttpPerformanceMetric] that records nothing.
class NoOpHttpPerformanceMetric implements HttpPerformanceMetric {
  const NoOpHttpPerformanceMetric();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  int? get httpResponseCode => null;

  @override
  set httpResponseCode(int? value) {}
}
