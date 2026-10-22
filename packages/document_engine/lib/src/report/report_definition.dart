import 'package:meta/meta.dart';

import '../model/document_column.dart';
import '../model/document_metadata.dart';
import '../model/document_row.dart';

/// Aggregation functions for report column summaries.
enum SummaryFunction {
  sum,
  count,
  average,
  min,
  max,
}

/// Text direction for report rendering.
enum DocumentTextDirection {
  ltr,
  rtl,
}

/// Sort direction for report columns.
enum ReportSortDirection {
  ascending,
  descending,
}

/// Sort rule for ordering report rows.
@immutable
class ReportSortDescriptor {
  const ReportSortDescriptor({
    required this.columnId,
    this.direction = ReportSortDirection.ascending,
  });

  final String columnId;
  final ReportSortDirection direction;
}

/// Predicate function for filtering report rows.
typedef ReportFilterPredicate = bool Function(DocumentRow row);

/// Defines a summary aggregation to display in group footers or report grand totals.
@immutable
class ReportSummary {
  const ReportSummary({
    required this.columnId,
    required this.function,
    this.label,
  });

  final String columnId;
  final SummaryFunction function;
  final String? label;
}

/// Defines a hierarchical grouping dimension for report rows.
@immutable
class ReportGrouping {
  const ReportGrouping({
    required this.columnId,
    this.showSubtotals = true,
    this.headerTemplate,
  });

  final String columnId;
  final bool showSubtotals;
  final String? headerTemplate;
}

/// Configuration for running headers or footers in paginated reports.
@immutable
class ReportHeaderFooter {
  const ReportHeaderFooter({
    this.leftText,
    this.centerText,
    this.rightText,
    this.includePageNumber = false,
    this.includeDate = false,
  });

  final String? leftText;
  final String? centerText;
  final String? rightText;
  final bool includePageNumber;
  final bool includeDate;
}

/// Comprehensive specification for generating business reports.
@immutable
class ReportDefinition {
  ReportDefinition({
    required this.id,
    required this.title,
    required List<DocumentColumn> columns,
    this.subtitle,
    this.parameters = const {},
    this.groupings = const [],
    this.summaries = const [],
    this.sortDescriptors = const [],
    this.filter,
    this.header,
    this.footer,
    this.textDirection = DocumentTextDirection.ltr,
    this.metadata = const DocumentMetadata(),
  }) : columns = List.unmodifiable(columns);

  final String id;
  final String title;
  final String? subtitle;
  final List<DocumentColumn> columns;
  final Map<String, Object?> parameters;
  final List<ReportGrouping> groupings;
  final List<ReportSummary> summaries;
  final List<ReportSortDescriptor> sortDescriptors;
  final ReportFilterPredicate? filter;
  final ReportHeaderFooter? header;
  final ReportHeaderFooter? footer;
  final DocumentTextDirection textDirection;
  final DocumentMetadata metadata;

  /// Whether the report content is primarily Right-to-Left (e.g. Arabic).
  bool get isRtl => textDirection == DocumentTextDirection.rtl;

  ReportDefinition copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<DocumentColumn>? columns,
    Map<String, Object?>? parameters,
    List<ReportGrouping>? groupings,
    List<ReportSummary>? summaries,
    List<ReportSortDescriptor>? sortDescriptors,
    ReportFilterPredicate? filter,
    ReportHeaderFooter? header,
    ReportHeaderFooter? footer,
    DocumentTextDirection? textDirection,
    DocumentMetadata? metadata,
  }) => ReportDefinition(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    columns: columns ?? this.columns,
    parameters: parameters ?? this.parameters,
    groupings: groupings ?? this.groupings,
    summaries: summaries ?? this.summaries,
    sortDescriptors: sortDescriptors ?? this.sortDescriptors,
    filter: filter ?? this.filter,
    header: header ?? this.header,
    footer: footer ?? this.footer,
    textDirection: textDirection ?? this.textDirection,
    metadata: metadata ?? this.metadata,
  );
}
