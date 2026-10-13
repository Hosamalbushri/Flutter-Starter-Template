import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

void main() {
  test(
    'Arabic bookmark plurals cover zero, one, two, few, many, and other',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

      expect(l10n.collectionItemsCount(0), 'لا توجد إشارات مرجعية');
      expect(l10n.collectionItemsCount(1), 'إشارة مرجعية واحدة');
      expect(l10n.collectionItemsCount(2), 'إشارتان مرجعيتان');
      expect(l10n.collectionItemsCount(3), '3 إشارات مرجعية');
      expect(l10n.collectionItemsCount(11), '11 إشارة مرجعية');
      expect(l10n.collectionItemsCount(102), '102 إشارة مرجعية');
    },
  );

  testWidgets('Arabic is supported and renders right-to-left', (tester) async {
    late TextDirection textDirection;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            textDirection = Directionality.of(context);
            return Text(context.l10n.loginSubmit);
          },
        ),
      ),
    );

    expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
    expect(textDirection, TextDirection.rtl);
    expect(find.text('دخول'), findsOneWidget);
  });
}
