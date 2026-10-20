import 'package:app_ui/app_ui.dart';
import 'package:feature_bookmarks/src/presentation/widgets/detail/bookmark_detail_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

import '../../support.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets(
        'detail sections use tokens without overflow: $brightness/$locale',
        (tester) async {
          tester.view
            ..physicalSize = const Size(320, 640)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                brightness: brightness,
                extensions: [
                  SemanticColors.from(
                    ColorScheme.fromSeed(
                      seedColor: Colors.indigo,
                      brightness: brightness,
                    ),
                  ),
                ],
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SourceSection(bookmark: testBookmark),
                      TagsSection(tags: testBookmark.tags),
                      DetailsSection(bookmark: testBookmark),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(
            Directionality.of(tester.element(find.byType(SourceSection))),
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
        },
      );
    }
  }
}
