import 'package:meta/meta.dart';

import '../model/document_row.dart';
import '../model/document_value.dart';
import '../progress/cancellation_token.dart';
import '../progress/document_progress.dart';
import 'import_definition.dart';
import 'import_plan.dart';
import 'import_validation.dart';

/// Shared tabular processor that maps and validates raw rows into an [ImportPlan].
@immutable
class TableImportProcessor {
  const TableImportProcessor();

  /// Processes raw rows (represented as maps of source header/key to raw value)
  /// against an [ImportDefinition].
  ImportPlan processRows({
    required List<Map<String, Object?>> rawRows,
    required ImportDefinition definition,
    CancellationToken? cancellationToken,
    DocumentProgressCallback? onProgress,
  }) {
    cancellationToken?.throwIfCancelled();

    final targetDef = definition.targetDefinition;
    final totalToProcess =
        definition.maxRows != null && definition.maxRows! < rawRows.length
        ? definition.maxRows!
        : rawRows.length;

    final validRows = <DocumentRow>[];
    final invalidRows = <RowValidationResult>[];
    final allWarnings = <CellValidationIssue>[];

    // Pre-build a map from source header to resolved target column id.
    final headerCache = <String, String?>{};

    for (var i = 0; i < totalToProcess; i++) {
      if (i % 50 == 0) {
        cancellationToken?.throwIfCancelled();
        onProgress?.call(
          DocumentProgress(
            phase: DocumentPhase.validating,
            current: i,
            total: totalToProcess,
            message: 'Validating row ${i + 1} of $totalToProcess...',
          ),
        );
      }

      final rawMap = rawRows[i];
      final rowNumber = i + 1 + definition.skipHeaderRows;
      final issues = <CellValidationIssue>[];
      final parsedCells = <String, DocumentValue>{};

      // Map raw entries to target columns
      final resolvedRaw = <String, Object?>{};
      for (final entry in rawMap.entries) {
        final srcHeader = entry.key;
        final targetColId = headerCache.putIfAbsent(
          srcHeader,
          () => definition.resolveTargetColumnId(srcHeader),
        );
        if (targetColId != null) {
          resolvedRaw[targetColId] = entry.value;
        }
      }

      // Validate each target column in schema
      for (final col in targetDef.columns) {
        final rawVal = resolvedRaw[col.id];

        // Check required
        if (col.isRequired) {
          final isMissing =
              rawVal == null || (rawVal is String && rawVal.trim().isEmpty);
          if (isMissing) {
            issues.add(
              CellValidationIssue(
                rowNumber: rowNumber,
                columnId: col.id,
                severity: ValidationSeverity.error,
                code: ValidationErrorCode.missingRequired,
                message:
                    'Field "${col.label}" is required and cannot be empty.',
                rawValue: rawVal,
              ),
            );
            continue;
          }
        }

        // Parse and validate type
        if (rawVal != null) {
          try {
            final docVal = col.parseValue(rawVal);
            if (col.isRequired && docVal.isNull) {
              issues.add(
                CellValidationIssue(
                  rowNumber: rowNumber,
                  columnId: col.id,
                  severity: ValidationSeverity.error,
                  code: ValidationErrorCode.missingRequired,
                  message:
                      'Field "${col.label}" is required and cannot be empty.',
                  rawValue: rawVal,
                ),
              );
              continue;
            }

            // Custom validator
            if (col.validator != null) {
              final validatorErr = col.validator!(docVal);
              if (validatorErr != null) {
                issues.add(
                  CellValidationIssue(
                    rowNumber: rowNumber,
                    columnId: col.id,
                    severity: ValidationSeverity.error,
                    code: ValidationErrorCode.customRuleFailed,
                    message: validatorErr,
                    rawValue: rawVal,
                  ),
                );
                continue;
              }
            }

            parsedCells[col.id] = docVal;
          } on FormatException catch (e) {
            issues.add(
              CellValidationIssue(
                rowNumber: rowNumber,
                columnId: col.id,
                severity: ValidationSeverity.error,
                code: ValidationErrorCode.invalidType,
                message: e.message,
                rawValue: rawVal,
              ),
            );
          } on Exception catch (e) {
            issues.add(
              CellValidationIssue(
                rowNumber: rowNumber,
                columnId: col.id,
                severity: ValidationSeverity.error,
                code: ValidationErrorCode.invalidType,
                message: e.toString(),
                rawValue: rawVal,
              ),
            );
          }
        } else {
          parsedCells[col.id] = NullDocumentValue(col.type);
        }
      }

      final hasErrors = issues.any(
        (iss) => iss.severity == ValidationSeverity.error,
      );
      if (hasErrors) {
        invalidRows.add(
          RowValidationResult(
            rowNumber: rowNumber,
            issues: List.unmodifiable(issues),
          ),
        );
      } else {
        final row = DocumentRow(
          index: validRows.length,
          cells: parsedCells,
        );
        validRows.add(row);
      }

      // Collect warnings
      final rowWarnings = issues.where(
        (iss) => iss.severity == ValidationSeverity.warning,
      );
      allWarnings.addAll(rowWarnings);
    }

    final canCommit = definition.allowPartial
        ? validRows.isNotEmpty
        : invalidRows.isEmpty;

    return ImportPlan(
      totalInspected: totalToProcess,
      validRows: List.unmodifiable(validRows),
      invalidRows: List.unmodifiable(invalidRows),
      warnings: List.unmodifiable(allWarnings),
      canCommit: canCommit,
    );
  }
}
