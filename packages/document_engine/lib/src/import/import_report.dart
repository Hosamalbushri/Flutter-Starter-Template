import 'package:meta/meta.dart';

/// Policy deciding how to handle duplicate records during import.
enum DuplicatePolicy {
  /// Skip the existing record without modifying it (safe default).
  skip,

  /// Update the existing record with values from the imported record.
  update,

  /// Create a new record with a newly generated identifier if constraints permit.
  create,
}

/// Comprehensive report produced after an import execution.
@immutable
class ImportResultReport {
  const ImportResultReport({
    required this.totalRead,
    required this.validCount,
    required this.invalidCount,
    required this.duplicateCount,
    required this.importedCount,
    required this.failedCount,
    this.errors = const [],
    this.warnings = const [],
    this.createdIds = const [],
    this.updatedIds = const [],
    this.skippedIds = const [],
  });

  /// Total count of rows read from the source file.
  final int totalRead;

  /// Count of rows that passed schema validation.
  final int validCount;

  /// Count of rows that failed schema validation.
  final int invalidCount;

  /// Count of records detected as duplicates of existing entities.
  final int duplicateCount;

  /// Count of records successfully imported (created or updated).
  final int importedCount;

  /// Count of records that failed during persistence or relationship wiring.
  final int failedCount;

  /// Error messages encountered during parsing, validation, or persistence.
  final List<String> errors;

  /// Non-fatal warnings encountered.
  final List<String> warnings;

  /// IDs of newly created records.
  final List<String> createdIds;

  /// IDs of updated records.
  final List<String> updatedIds;

  /// IDs or keys of skipped duplicate records.
  final List<String> skippedIds;

  /// Convenient count of created records.
  int get createdCount => createdIds.length;

  /// Convenient count of updated records.
  int get updatedCount => updatedIds.length;

  /// Convenient count of skipped records.
  int get skippedCount => skippedIds.length;

  bool get isSuccess => failedCount == 0 && invalidCount == 0;
  bool get hasPartialSuccess =>
      importedCount > 0 && (failedCount > 0 || invalidCount > 0);
}
