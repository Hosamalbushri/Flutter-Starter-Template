// Widget tests for the home dashboard body. home_bloc_test covers the
// stats-to-state mapping; these assert that HomeBody renders that state for the
// branches that don't pull network thumbnails — the empty dashboard and the
// featured-collections row.
//
// Populated bookmark cards are intentionally not exercised here: each renders
// an AppLinkPreviewThumbnail whose link-preview fetch schedules a real 5s
// timeout timer, which would leak past the test and fail it. The bloc test
// already verifies the bookmark-stats mapping.

import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:architecture/architecture.dart';
import 'package:feature_home/feature_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:shared_contracts/shared_contracts.dart';

import '../../support.dart';

void main() {
  Future<HomeBloc> loadedBloc({
    BookmarkStats stats = const BookmarkStats(),
    List<CollectionSummary> collections = const [],
  }) async {
    final statsReader = MockBookmarkStatsReader();
    when(statsReader.call).thenAnswer((_) async => Ok(stats));
    final collectionsReader = MockCollectionsReader();
    when(collectionsReader.call).thenAnswer((_) async => Ok(collections));

    final bloc = HomeBloc(statsReader, collectionsReader)
      ..add(const HomeLoadRequested());
    // Wait for the load to settle. When collections are expected, also wait for
    // the (separate) collections emit that follows the stats emit.
    await bloc.stream.firstWhere(
      (s) => !s.isLoading && (collections.isEmpty || s.collections.isNotEmpty),
    );
    return bloc;
  }

  Future<(HomeBloc, Completer<Result<BookmarkStats>>)> loadingBloc() async {
    final completer = Completer<Result<BookmarkStats>>();
    final statsReader = MockBookmarkStatsReader();
    when(statsReader.call).thenAnswer((_) => completer.future);
    final collectionsReader = MockCollectionsReader();
    when(collectionsReader.call).thenAnswer((_) async => const Ok([]));
    final bloc = HomeBloc(statsReader, collectionsReader)
      ..add(const HomeLoadRequested());
    await bloc.stream.firstWhere((state) => state.isLoading);
    return (bloc, completer);
  }

  Future<HomeBloc> failedBloc() async {
    final statsReader = MockBookmarkStatsReader();
    when(statsReader.call).thenAnswer((_) async => const Err(testFailure));
    final collectionsReader = MockCollectionsReader();
    when(collectionsReader.call).thenAnswer((_) async => const Ok([]));
    final bloc = HomeBloc(statsReader, collectionsReader)
      ..add(const HomeLoadRequested());
    await bloc.stream.firstWhere((state) => state.failure != null);
    return bloc;
  }

  Future<void> pumpHome(
    WidgetTester tester,
    HomeBloc bloc, {
    double width = 1200,
    double height = 2400,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    // A tall, wide surface so the whole scrolling dashboard lays out and is
    // hit-testable without scrolling.
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<HomeBloc>.value(
          value: bloc,
          child: const HomeBody(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the empty dashboard with no bookmark thumbnails', (
    tester,
  ) async {
    final bloc = await loadedBloc();
    await pumpHome(tester, bloc);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget); // identity fallback
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      find.byKey(const ValueKey('home-dashboard-identity')),
      findsOneWidget,
    );
    expect(find.text('No bookmarks yet. Tap + to add one.'), findsOneWidget);
    expect(find.byType(AppLinkPreviewThumbnail), findsNothing);

    await bloc.close();
  });

  testWidgets('renders featured collections from state', (tester) async {
    final bloc = await loadedBloc(
      collections: const [
        CollectionSummary(
          id: 'c1',
          name: 'Reading list',
          icon: 'book',
          color: 0xFF2196F3,
          itemCount: 4,
        ),
      ],
    );
    await pumpHome(tester, bloc);

    expect(find.text('Reading list'), findsOneWidget);
    // Collection cards are gradient tiles, not link-preview thumbnails.
    expect(find.byType(AppLinkPreviewThumbnail), findsNothing);

    await bloc.close();
  });

  testWidgets('renders deterministic loading skeletons', (tester) async {
    final (bloc, completer) = await loadingBloc();
    await pumpHome(tester, bloc);

    expect(find.byType(AppShimmer), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);

    completer.complete(const Ok(BookmarkStats()));
    await bloc.stream.firstWhere((state) => !state.isLoading);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await bloc.close();
  });

  testWidgets('renders a localized error state with retry', (tester) async {
    final bloc = await failedBloc();
    await pumpHome(tester, bloc);

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(
      find.text('We could not load your dashboard. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await bloc.close();
  });

  testWidgets('top bar search action focuses the real search field', (
    tester,
  ) async {
    final bloc = await loadedBloc();
    await pumpHome(tester, bloc);

    await tester.tap(find.byKey(const ValueKey('home-top-bar-search')));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('home-search-field')),
    );
    expect(field.focusNode?.hasFocus, isTrue);

    await bloc.close();
  });

  testWidgets('renders all certified widths in RTL at 2.0x text scale', (
    tester,
  ) async {
    final bloc = await loadedBloc();
    for (final width in [320.0, 360.0, 390.0, 600.0, 840.0, 1200.0]) {
      await pumpHome(
        tester,
        bloc,
        width: width,
        height: 1000,
        textScale: 2,
        locale: const Locale('ar'),
      );
      expect(find.byType(HomeBody), findsOneWidget, reason: 'width $width');
    }

    await bloc.close();
  });
}
