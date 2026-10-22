import '../progress/cancellation_token.dart';

/// Contract for printing operations, separating transport and platform drivers from core engine.
abstract interface class DocumentPrintAdapter {
  /// Name or identifier of this print destination/adapter.
  String get name;

  /// Sends document [bytes] to the target printer or system print spooler.
  /// Returns `true` if printing succeeded.
  Future<bool> printDocument(
    List<int> bytes, {
    String? jobName,
    CancellationToken? cancellationToken,
  });
}
