import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  group('theme foundation', () {
    for (final brightness in Brightness.values) {
      test(
        '$brightness exposes complete semantic roles with readable statuses',
        () {
          final theme = brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light();
          final semantic = theme.extension<SemanticColors>();

          expect(semantic, isNotNull);
          expect(theme.useMaterial3, isTrue);
          expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
          expect(theme.textTheme.bodyLarge?.height, 1.5);
          expect(theme.textTheme.headlineSmall?.fontWeight, FontWeight.w700);
          expect(
            theme.scaffoldBackgroundColor.computeLuminance(),
            brightness == Brightness.dark ? lessThan(0.03) : greaterThan(0.7),
          );

          expect(
            _contrast(semantic!.success, semantic.onSuccess),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(semantic.warning, semantic.onWarning),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(semantic.info, semantic.onInfo),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }

    test('custom brand palette drives light and dark ColorScheme', () {
      const palette = AppColorPalette.red;
      final light = AppTheme.light(palette: palette);
      final dark = AppTheme.dark(palette: palette);

      expect(
        light.colorScheme.primary,
        isNot(AppTheme.light().colorScheme.primary),
      );
      expect(
        dark.colorScheme.primary,
        isNot(AppTheme.dark().colorScheme.primary),
      );
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });
  });

  group('shared component contracts', () {
    testWidgets('small buttons retain a 48dp interactive target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppButton(
              label: 'Action',
              size: AppButtonSize.small,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets(
      'selector, search clear action, and snackbar remain interactive',
      (tester) async {
        final controller = TextEditingController(text: 'query');
        addTearDown(controller.dispose);
        String? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: ListView(
                children: [
                  AppSelector<String>(
                    label: 'Language',
                    items: const ['English', 'Arabic'],
                    itemLabel: (item) => item,
                    onChanged: (value) => selected = value,
                  ),
                  AppSearchField(
                    controller: controller,
                    label: 'Search',
                    clearTooltip: 'Clear search',
                  ),
                  Builder(
                    builder: (context) => AppButton(
                      label: 'Notify',
                      onPressed: () => AppSnackbar.show(
                        context,
                        message: 'Saved',
                        variant: AppSnackbarVariant.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Arabic').last);
        await tester.pumpAndSettle();
        expect(selected, 'Arabic');

        await tester.tap(find.byTooltip('Clear search'));
        await tester.pump();
        expect(controller.text, isEmpty);

        await tester.tap(find.text('Notify'));
        await tester.pump();
        expect(find.text('Saved'), findsOneWidget);
      },
    );

    testWidgets('skeleton honors reduced-motion preference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: AppShimmer(child: AppSkeleton()),
          ),
        ),
      );

      await tester.pump(AppDurations.shimmer * 2);
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive, scaled, and bidirectional components', () {
    const widths = <double>[320, 360, 390, 600, 840, 1200];
    const scales = <double>[1, 1.5, 2];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('${width.toInt()}px at ${scale}x renders in LTR and RTL', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          for (final direction in TextDirection.values) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light(),
                home: Directionality(
                  textDirection: direction,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 900),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: ListView(
                        padding: const EdgeInsets.all(AppSpacing.pageCompact),
                        children: [
                          AppButton(
                            label: direction == TextDirection.rtl
                                ? 'إجراء أساسي طويل'
                                : 'Long primary action',
                            icon: FontAwesomeIcons.check,
                            expand: true,
                            onPressed: () {},
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppSearchField(
                            label: direction == TextDirection.rtl
                                ? 'بحث'
                                : 'Search',
                            hint: direction == TextDirection.rtl
                                ? 'ابحث في جميع العناصر'
                                : 'Search all available items',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppSelector<String>(
                            label: direction == TextDirection.rtl
                                ? 'اللغة'
                                : 'Language',
                            items: const ['English', 'العربية'],
                            itemLabel: (item) => item,
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Text(
                              direction == TextDirection.rtl
                                  ? 'بطاقة متجاوبة تدعم النص العربي وتكبير الخط.'
                                  : 'A responsive card supporting scaled English text.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
