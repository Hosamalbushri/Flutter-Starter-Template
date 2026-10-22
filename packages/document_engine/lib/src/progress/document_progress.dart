import 'package:meta/meta.dart';

/// Lifecycle phases of document operations.
enum DocumentPhase {
  reading,
  parsing,
  validating,
  transforming,
  rendering,
  writing,
  committing,
  completed,
}

/// Progress notification emitted during long-running import, export, or reporting operations.
@immutable
class DocumentProgress {
  const DocumentProgress({
    required this.phase,
    required this.current,
    this.total,
    this.message,
  }) : assert(current >= 0, 'current must be non-negative');

  final DocumentPhase phase;
  final int current;
  final int? total;
  final String? message;

  /// Progress fraction between 0.0 and 1.0 (null if total is unknown or zero).
  double? get fraction {
    if (total == null || total! <= 0) return null;
    final f = current / total!;
    return f.clamp(0.0, 1.0);
  }

  /// Percentage integer between 0 and 100.
  int? get percentage {
    final frac = fraction;
    return frac == null ? null : (frac * 100).round();
  }

  @override
  String toString() =>
      'DocumentProgress(phase: ${phase.name}, current: $current/$total, message: $message)';
}

/// Callback for observing document operation progress.
typedef DocumentProgressCallback = void Function(DocumentProgress progress);
