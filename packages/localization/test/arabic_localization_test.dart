import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:localization/localization.dart';

void main() {
  test('Document Center counts use the active locale number format', () async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    const count = 12000;

    expect(
      ar.documentImportValidRows(count),
      contains(intl.NumberFormat.decimalPattern('ar').format(count)),
    );
    expect(
      en.documentImportValidRows(count),
      contains(intl.NumberFormat.decimalPattern('en').format(count)),
    );
  });

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
