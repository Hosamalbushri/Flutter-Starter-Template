import 'package:feature_document_center/feature_document_center.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('documentCenterRoutes', () {
    final paths = documentCenterRoutes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    test('contributes the feature route', () {
      expect(paths, [DocumentCenterRoutes.root]);
    });

    test('uses stable names and contributes a nested details route', () {
      final root = documentCenterRoutes.single as GoRoute;
      final details = root.routes.single as GoRoute;
      expect(root.name, DocumentCenterRoutes.name);
      expect(details.name, DocumentCenterRoutes.detailsName);
      expect(details.path, DocumentCenterRoutes.detailsSegment);
    });
  });
}
