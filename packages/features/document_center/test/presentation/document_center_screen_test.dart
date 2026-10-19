import 'package:feature_document_center/feature_document_center.dart';
import 'package:feature_document_center/src/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

Widget wrapWithDependencies(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

void main() {
  group('DocumentCenterScreen Widget Tests', () {
    late DocumentCenterCubit cubit;

    setUp(() {
      cubit = DocumentCenterCubit();
      if (getIt.isRegistered<DocumentCenterCubit>()) {
        getIt.unregister<DocumentCenterCubit>();
      }
      getIt.registerSingleton<DocumentCenterCubit>(cubit);
    });

    tearDown(() {
      if (getIt.isRegistered<DocumentCenterCubit>()) {
        getIt.unregister<DocumentCenterCubit>();
      }
      cubit.close();
    });

    testWidgets('renders tabs: Import, Export, Reports', (tester) async {
      await tester.pumpWidget(
        wrapWithDependencies(const DocumentCenterScreen()),
      );
      await tester.pump();

      expect(find.text('Document Center'), findsOneWidget);
      expect(find.text('Import Data'), findsWidgets);
      expect(find.text('Export Data'), findsWidgets);
      expect(find.text('Reports & Printing'), findsWidgets);
    });

    testWidgets('switching tabs updates displayed view', (tester) async {
      await tester.pumpWidget(
        wrapWithDependencies(const DocumentCenterScreen()),
      );
      await tester.pump();

      // Tap Export Tab
      await tester.tap(find.text('Export Data').first);
      await tester.pump();

      expect(find.text('Export Format'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('XLSX'), findsOneWidget);

      // Tap Reports Tab
      await tester.tap(find.text('Reports & Printing').first);
      await tester.pump();

      expect(find.text('Report Template'), findsOneWidget);
    });
  });
}
