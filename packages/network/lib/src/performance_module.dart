import 'package:firebase_performance/firebase_performance.dart';
import 'package:injectable/injectable.dart';

import 'performance_tracker.dart';

@module
abstract class PerformanceModule {
  /// Binds the app's [PerformanceTracker].
  ///
  /// `fst create --no-firebase` rewrites the expression at the
  /// `// fst:performance-impl` marker to `const NoOpPerformanceTracker()`. To
  /// use a non-Firebase backend, replace it with your own [PerformanceTracker].
  @lazySingleton
  PerformanceTracker providePerformance() =>
      FirebasePerformanceTracker(FirebasePerformance.instance); // fst:performance-impl
}
