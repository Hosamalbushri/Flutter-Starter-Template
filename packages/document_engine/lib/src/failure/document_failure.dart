import 'package:architecture/architecture.dart';

/// Base class for all document processing failures.
abstract class DocumentFailure extends UnknownFailure implements Exception {
  const DocumentFailure(super.message);
}

/// Failure when an requested import/export/report format is not registered or supported.
class DocumentFormatNotSupportedFailure extends DocumentFailure {
  const DocumentFormatNotSupportedFailure(
    this.formatOrExtension, [
    String? message,
  ]) : super(message ?? 'Unsupported document format: "$formatOrExtension"');

  final String formatOrExtension;
}

/// Failure during parsing of raw file or stream content.
class DocumentParseFailure extends DocumentFailure {
  const DocumentParseFailure(
    super.message, {
    this.rowNumber,
    this.columnId,
    this.rawSnippet,
  });

  final int? rowNumber;
  final String? columnId;
  final String? rawSnippet;
}

/// Failure when document validation rules are violated.
class DocumentValidationFailure extends DocumentFailure {
  const DocumentValidationFailure(
    super.message, {
    this.issues = const [],
  });

  final List<String> issues;
}

/// Failure when an operation is cancelled via CancellationToken.
class DocumentCancellationFailure extends DocumentFailure {
  const DocumentCancellationFailure([
    super.message = 'The document operation was cancelled',
  ]);
}

/// Failure when generating or writing document output bytes.
class DocumentOutputFailure extends DocumentFailure {
  const DocumentOutputFailure(super.message, [this.cause]);

  final Object? cause;
}

/// Failure during database or persistence adapter transaction.
class DocumentPersistenceFailure extends DocumentFailure {
  const DocumentPersistenceFailure(
    super.message, {
    this.rolledBack = true,
    this.cause,
  });

  final bool rolledBack;
  final Object? cause;
}
