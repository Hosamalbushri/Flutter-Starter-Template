import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Foundation Phase 02 Regression Guards', () {
    test(
      'lib/app/features.dart: document_center is not nested in notifications sentinel (FND-004)',
      () {
        final file = File('lib/app/features.dart');
        expect(file.existsSync(), isTrue);
        final lines = file.readAsLinesSync();

        var insideNotifications = false;
        var docCenterInsideNotifications = false;

        for (final line in lines) {
          if (line.contains('fst:feature:notifications:start')) {
            insideNotifications = true;
          } else if (line.contains('fst:feature:notifications:end')) {
            insideNotifications = false;
          } else if (line.contains('feature_document_center') &&
              insideNotifications) {
            docCenterInsideNotifications = true;
          }
        }

        expect(
          docCenterInsideNotifications,
          isFalse,
          reason:
              'feature_document_center import must not be nested within notifications sentinel (FND-004).',
        );
      },
    );

    test(
      'lib/app/widgets/app_shell.dart: collections import is guarded by fst:feature:collections (NEW-001)',
      () {
        final file = File('lib/app/widgets/app_shell.dart');
        expect(file.existsSync(), isTrue);
        final lines = file.readAsLinesSync();

        final hasCollectionsImport = lines.any(
          (l) => l.contains(
            "import 'package:feature_collections/feature_collections.dart';",
          ),
        );
        if (!hasCollectionsImport) {
          // Feature collections import was cleanly stripped in this scaffold.
          return;
        }

        final isTemplate = File('.gitmodules').existsSync();
        if (isTemplate) {
          var insideCollections = false;
          var collectionsImportGuarded = false;

          for (final line in lines) {
            if (line.contains('fst:feature:collections:start')) {
              insideCollections = true;
            } else if (line.contains('fst:feature:collections:end')) {
              insideCollections = false;
            } else if (line.contains(
              "import 'package:feature_collections/feature_collections.dart';",
            )) {
              if (insideCollections) collectionsImportGuarded = true;
            }
          }

          expect(
            collectionsImportGuarded,
            isTrue,
            reason:
                'feature_collections import in app_shell.dart must be guarded by fst:feature:collections (NEW-001).',
          );
        }
      },
    );

    test(
      'lib/app/di/injection.dart: document engine delegates are guarded by feature sentinels (FND-002)',
      () {
        final file = File('lib/app/di/injection.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        final isTemplate = File('.gitmodules').existsSync();

        if (isTemplate) {
          expect(
            content,
            matches(
              RegExp(
                r'//\s*fst:feature:collections:start[\s\S]*?CollectionsImportDelegate[\s\S]*?//\s*fst:feature:collections:end',
              ),
            ),
            reason:
                'CollectionsImportDelegate must be guarded by fst:feature:collections sentinels (FND-002).',
          );

          expect(
            content,
            matches(
              RegExp(
                r'//\s*fst:feature:bookmarks:start[\s\S]*?BookmarksImportDelegate[\s\S]*?//\s*fst:feature:bookmarks:end',
              ),
            ),
            reason:
                'BookmarksImportDelegate must be guarded by fst:feature:bookmarks sentinels (FND-002).',
          );
        } else {
          final hasCollectionsPkg = Directory(
            'packages/features/collections',
          ).existsSync();
          if (!hasCollectionsPkg) {
            expect(content.contains('CollectionsImportDelegate'), isFalse);
          }
          final hasBookmarksPkg = Directory(
            'packages/features/bookmarks',
          ).existsSync();
          if (!hasBookmarksPkg) {
            expect(content.contains('BookmarksImportDelegate'), isFalse);
          }
        }
      },
    );

    test(
      'lib/app/di/injection.dart: PerformanceTracker is guarded by fst:network in configureFirebaseRuntimeBindings',
      () {
        final file = File('lib/app/di/injection.dart');
        expect(file.existsSync(), isTrue);
        final content = file.readAsStringSync();
        final isTemplate = File('.gitmodules').existsSync();

        if (isTemplate) {
          expect(
            content,
            matches(
              RegExp(
                r'//\s*fst:network:start[\s\S]*?PerformanceTracker[\s\S]*?//\s*fst:network:end',
              ),
            ),
            reason:
                'PerformanceTracker registration must be guarded by fst:network sentinels.',
          );
        } else {
          final hasNetwork = Directory('packages/network').existsSync();
          if (!hasNetwork) {
            expect(content.contains('PerformanceTracker'), isFalse);
          }
        }
      },
    );

    test(
      'packages/features/profile/pubspec.yaml: go_router is not wrapped in fst:auth',
      () {
        final file = File('packages/features/profile/pubspec.yaml');
        if (!file.existsSync()) return;
        final lines = file.readAsLinesSync();

        var insideAuth = false;
        var goRouterInsideAuth = false;

        for (final line in lines) {
          if (line.contains(['fst', 'auth', 'start'].join(':'))) {
            insideAuth = true;
          } else if (line.contains(['fst', 'auth', 'end'].join(':'))) {
            insideAuth = false;
          } else if (line.trim().startsWith('go_router:') && insideAuth) {
            goRouterInsideAuth = true;
          }
        }

        expect(
          goRouterInsideAuth,
          isFalse,
          reason:
              'go_router in profile pubspec.yaml must not be wrapped in fst:auth since profile_appearance uses it.',
        );
      },
    );
  });
}
