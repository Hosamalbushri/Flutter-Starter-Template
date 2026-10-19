import 'package:go_router/go_router.dart';

import 'screens/document_center_details_screen.dart';
import 'screens/document_center_screen.dart';

/// Canonical navigation paths owned by the document_center feature.
abstract final class DocumentCenterRoutes {
  /// Stable GoRouter name for the feature root.
  static const name = 'feature-document-center';

  /// The document_center screen.
  static const root = '/document-center';

  /// Stable GoRouter name for the nested details page.
  static const detailsName = 'feature-document-center-details';

  /// Relative path mounted below the feature root.
  static const detailsSegment = 'details';

  /// Absolute location for imperative navigation and deep links.
  static const details = '$root/$detailsSegment';
}

/// The document_center feature's routes, mounted by the host app.
List<RouteBase> get documentCenterRoutes => [
  GoRoute(
    name: DocumentCenterRoutes.name,
    path: DocumentCenterRoutes.root,
    builder: (context, state) => const DocumentCenterScreen(),
    routes: [
      GoRoute(
        name: DocumentCenterRoutes.detailsName,
        path: DocumentCenterRoutes.detailsSegment,
        builder: (context, state) => const DocumentCenterDetailsScreen(),
      ),
    ],
  ),
];
