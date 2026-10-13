import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  group('Step 3 & 4 — Responsive widths, text scaling, RTL/LTR & themes', () {
    const widths = <double>[320, 360, 390, 600, 800, 1200];
    const scales = <double>[1, 1.5, 2];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets(
          'AppAdaptiveScaffold and core components render without overflow at ${width.toInt()}px and ${scale}x text scale (LTR & RTL)',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
              await tester.pumpWidget(
                MaterialApp(
                  key: ValueKey('app_${width}_${scale}_$direction'),
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  builder: (context, child) => Directionality(
                    textDirection: direction,
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                  ),
                  home: AppAdaptiveScaffold(
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    destinations: const [
                      AppDestination(
                        icon: FontAwesomeIcons.house,
                        label: 'Home Dashboard',
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.bookmark,
                        label: 'Saved Bookmarks',
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.bell,
                        label: 'Notifications',
                        hasBadge: true,
                      ),
                      AppDestination(
                        icon: FontAwesomeIcons.user,
                        label: 'User Profile',
                      ),
                    ],
                    body: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        AppButton(
                          label: 'Primary Action Button',
                          icon: FontAwesomeIcons.plus,
                          expand: true,
                          onPressed: () {},
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const AppTextField(
                          label: 'Search Query',
                          hint: 'Type to filter items...',
                          errorText: 'Please enter at least 3 characters',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          semanticLabel: 'Summary Card',
                          onTap: () {},
                          child: const Text(
                            'Responsive card content that wraps across multiple lines without clipping.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 220,
                          child: AppEmptyView(
                            title: 'No items found',
                            message:
                                'Create a new entry or adjust your active filters.',
                            action: AppButton(
                              label: 'Create New',
                              size: AppButtonSize.small,
                              onPressed: () {},
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 240,
                          child: AppErrorView(
                            title: 'Connection interrupted',
                            message:
                                'Unable to reach the server. Check your connection and retry.',
                            retryLabel: 'Retry Now',
                            onRetry: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }

    testWidgets(
      'AppConfirmDialog stacks actions cleanly at 320px width and 2.0x text scale in RTL without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: AppButton(
                    label: 'حذف الحساب',
                    onPressed: () {
                      AppConfirmDialog.show(
                        context,
                        title: 'تأكيد حذف العنصر النهائي؟',
                        message:
                            'سيتم إزالة هذا العنصر نهائياً ولا يمكن التراجع عن هذا الإجراء.',
                        confirmLabel: 'تأكيد الحذف النهائي',
                        cancelLabel: 'إلغاء العملية',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('حذف الحساب'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('تأكيد حذف العنصر النهائي؟'), findsOneWidget);
        expect(find.text('تأكيد الحذف النهائي'), findsOneWidget);
        expect(find.text('إلغاء العملية'), findsOneWidget);
      },
    );
  });

  group('Step 6 — Component contracts, accessibility semantics & lifecycle', () {
    testWidgets(
      'AppButton preserves accessible semantics label while loading and resets pressed state when disabled via didUpdateWidget',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    label: 'Save Changes',
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(find.bySemanticsLabel('Save Changes'), findsOneWidget);

          // Verify didUpdateWidget when transitioning from enabled (pressed) to disabled.
          var enabled = true;
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, setState) => MaterialApp(
                theme: AppTheme.light(),
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton(
                          label: 'Submit',
                          onPressed: enabled ? () {} : null,
                        ),
                        TextButton(
                          onPressed: () => setState(() => enabled = false),
                          child: const Text('Disable'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final gesture = await tester.startGesture(
            tester.getCenter(find.text('Submit')),
          );
          await tester.pump(AppDurations.xfast);

          await tester.tap(find.text('Disable'));
          await tester.pumpAndSettle();
          await gesture.up();
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        } finally {
          semanticsHandle.dispose();
        }
      },
    );

    testWidgets(
      'AppCarousel clamps page index on didUpdateWidget when item count shrinks and handles empty items safely',
      (tester) async {
        var items = <Widget>[
          const Text('Slide 1'),
          const Text('Slide 2'),
          const Text('Slide 3'),
        ];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AppCarousel(height: 120, items: items),
                    TextButton(
                      onPressed: () =>
                          setState(() => items = const [Text('Slide 1')]),
                      child: const Text('Shrink'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => items = const []),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Swipe to later slide
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Shrink items list and verify no range error
        await tester.tap(find.text('Shrink'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Clear items list and verify empty guard
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppCard and AppLoading expose accessibility semantics',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Column(
                  children: [
                    AppCard(
                      semanticLabel: 'Open Bookmark Details',
                      onTap: () {},
                      child: const Text('Card Body'),
                    ),
                    const AppLoading(label: 'Synchronizing items'),
                  ],
                ),
              ),
            ),
          );
          await tester.pump(AppDurations.fast);

          expect(
            find.bySemanticsLabel('Open Bookmark Details'),
            findsOneWidget,
          );
          expect(find.bySemanticsLabel('Synchronizing items'), findsOneWidget);
        } finally {
          semanticsHandle.dispose();
        }
      },
    );
  });

  group('Step 7 — Performance regression verification (aspect-specific MediaQuery)', () {
    testWidgets(
      'BuildContextBreakpoints (MediaQuery.sizeOf) does not rebuild when keyboard viewInsets change',
      (tester) async {
        _BreakpointProbe.buildCount = 0;
        var viewInsets = EdgeInsets.zero;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                final baseMedia = MediaQuery.of(context);
                return MediaQuery(
                  data: baseMedia.copyWith(
                    size: const Size(390, 844),
                    viewInsets: viewInsets,
                  ),
                  child: Scaffold(
                    body: Column(
                      children: [
                        const _BreakpointProbe(),
                        TextButton(
                          onPressed: () => setState(
                            () => viewInsets = const EdgeInsets.only(
                              bottom: 320,
                            ),
                          ),
                          child: const Text('Show Keyboard'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(_BreakpointProbe.buildCount, 1);

        // Simulate keyboard inset animation frame — size has not changed!
        await tester.tap(find.text('Show Keyboard'));
        await tester.pump();

        expect(
          _BreakpointProbe.buildCount,
          1,
          reason:
              'Widgets reading context.isCompact / MediaQuery.sizeOf must not '
              'rebuild when only MediaQuery.viewInsets changes.',
        );
      },
    );
  });

  group('Step 9 — AppUiShowcaseScreen interactive controls', () {
    testWidgets(
      'switches between Light/Dark theme, EN/AR directionality, text scales, and widths without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const AppUiShowcaseScreen(),
          ),
        );
        await tester.pump(AppDurations.medium);

        expect(find.text('App UI Design System Showcase'), findsOneWidget);

        // Switch to Dark theme
        await tester.tap(find.byKey(const ValueKey('showcase_theme_dark')));
        await tester.pump(AppDurations.medium);
        expect(tester.takeException(), isNull);

        // Switch to Arabic (RTL)
        await tester.tap(find.byKey(const ValueKey('showcase_locale_ar')));
        await tester.pump(AppDurations.medium);
        expect(find.text('معرض نظام التصميم (App UI)'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch to 1.5x text scale and 320px width
        final scaleChip = find.byKey(const ValueKey('showcase_scale_1.5'));
        await tester.ensureVisible(scaleChip);
        await tester.tap(scaleChip);
        await tester.pump(AppDurations.medium);

        final widthChip = find.byKey(const ValueKey('showcase_width_320'));
        await tester.ensureVisible(widthChip);
        await tester.tap(widthChip);
        await tester.pump(AppDurations.medium);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _BreakpointProbe extends StatelessWidget {
  const _BreakpointProbe();

  static int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    buildCount++;
    final isCompact = context.isCompact;
    return Text('isCompact: $isCompact');
  }
}
