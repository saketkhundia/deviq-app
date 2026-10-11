import 'package:deviq/core/routing/app_router.dart';
import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/auth/presentation/auth_controller.dart';
import 'package:deviq/shared/widgets/app_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Bottom nav: frosted capsule bar with Home · Interview · Play ·
/// Review · More, continuous finger-tracking capsule, spring settle.
/// Taps, scrubs, reversals and clamps all route by finger position.
Future<void> _pumpNav(
  WidgetTester t,
  DevIQBottomNav nav, {
  bool dark = true,
}) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
  await t.pumpWidget(
    MaterialApp(
      theme: DevIQTheme.light(),
      darkTheme: DevIQTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: SafeArea(child: ProviderScope(child: nav))),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

Future<void> _settle(WidgetTester t) => t.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);

void main() {
  group('bottom nav reference behavior', () {
    testWidgets('active tab shows filled icon + label', (t) async {
      await _pumpNav(t, const DevIQBottomNav(active: 'review', onTab: null));
      expect(find.byIcon(Icons.rate_review), findsOneWidget);
      expect(find.byIcon(Icons.rate_review_outlined), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.work_outlined), findsOneWidget);
      expect(find.byIcon(Icons.terminal_outlined), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Interview'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      // Liquid-glass bar: real backdrop blur beneath the lens.
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('tap routes to the right tab id', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      await t.tap(find.byIcon(Icons.work_outlined));
      expect(tapped, 'interview');
      await t.tap(find.byIcon(Icons.terminal_outlined));
      expect(tapped, 'play');
      await t.tap(find.byIcon(Icons.apps_outlined));
      expect(tapped, 'more');
      expect(t.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (t) async {
      await _pumpNav(
        t,
        const DevIQBottomNav(active: 'interview', onTab: null),
        dark: false,
      );
      expect(find.byIcon(Icons.work_rounded), findsOneWidget);
      expect(find.text('Interview'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('indicator stays inside the bar in production shell', (
      t,
    ) async {
      // Regression: the sliding indicator once stretched to full screen
      // because an expanding wrapper met the bottom-nav slot's
      // finite-loose maxHeight. Pump the exact production tree.
      t.view.physicalSize = const Size(1170, 2532); // 390x844 @3x
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: const SizedBox.expand(),
            bottomNavigationBar: ProviderScope(
              child: DevIQBottomNav(
                active: 'home',
                onTab: (_) {},
              ),
            ),
          ),
        ),
      );
      await _settle(t);
      expect(t.takeException(), isNull);
      final indicator = find.byType(AnimatedPositioned);
      expect(indicator, findsOneWidget);
      expect(t.getSize(indicator).height, lessThan(120));
    });
  });

  group('hold-and-slide capsule', () {
    testWidgets('slide tracks finger and routes on release', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      // Press on Home, slide two cells right, lift: routes to Play.
      final start = t.getCenter(find.text('Home'));
      await t.dragFrom(start, const Offset(150, 0));
      await _settle(t);
      expect(tapped, 'play');
      expect(t.takeException(), isNull);
    });

    testWidgets('scrub ending on the active tab routes nowhere', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      final start = t.getCenter(find.text('Home'));
      await t.dragFrom(start, const Offset(20, 0));
      await _settle(t);
      expect(tapped, isNull);
      expect(t.takeException(), isNull);
    });

    testWidgets('capsule follows the finger with zero easing', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      // Hold on Home and slide: the travelling capsule appears under
      // the finger with no routing until lift.
      final gesture = await t.startGesture(t.getCenter(find.text('Home')));
      await gesture.moveBy(const Offset(60, 0));
      await t.pump();
      final capsule = find.byKey(const Key('nav-capsule'));
      expect(capsule, findsOneWidget);
      expect(tapped, isNull);
      // Bar starts at x=12 with 4px padding; cell is 65.6 wide, so
      // the capsule's left edge tracks fingerX - 16 - pillW/2 = ~79.
      expect(t.getTopLeft(capsule).dx, closeTo(79, 8));
      await gesture.up();
      await _settle(t);
      // Finger landed on Interview: spring settles there and routes.
      expect(tapped, 'interview');
      expect(find.byKey(const Key('nav-capsule')), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('direction reversal routes the final tab', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      final gesture = await t.startGesture(t.getCenter(find.text('Home')));
      await gesture.moveBy(const Offset(150, 0));
      await t.pump();
      // Drag back left before lifting: ends on Interview.
      await gesture.moveBy(const Offset(-80, 0));
      await t.pump();
      await gesture.up();
      await _settle(t);
      expect(tapped, 'interview');
      expect(t.takeException(), isNull);
    });

    testWidgets('far swipe clamps to the last tab', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      final start = t.getCenter(find.text('Home'));
      await t.dragFrom(start, const Offset(1000, 0));
      await _settle(t);
      // Never overshoots: clamps to More and routes there.
      expect(tapped, 'more');
      expect(t.takeException(), isNull);
    });
  });

  group('shell branch alignment', () {
    test('branch paths match tab ids in order', () {
      // Regression: a stale /analyze branch once shifted every tab by
      // one (Interview→Analyze, Play→Interview, Review→Play). The
      // branch table must stay exactly [home, interview, playground,
      // review] to match AppShell._ids.
      final refresh = ChangeNotifier();
      addTearDown(refresh.dispose);
      final router = buildRouter(
        authStatus: () => AuthStatus.authenticated,
        refresh: refresh,
      );
      final shellRoute =
          router.configuration.routes.whereType<StatefulShellRoute>().single;
      final paths = [
        for (final branch in shellRoute.branches)
          (branch.routes.single as GoRoute).path,
      ];
      expect(paths, ['/home', '/interview', '/playground', '/review']);
    });
  });

  group('more sheet destinations', () {    testWidgets('secondary destinations live in More', (t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(
        MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: MoreSheet()),
        ),
      );
      await t.pumpAndSettle();
      for (final label in [
        'Ask AI',
        'Analyze',
        'Compare',
        'Profile',
        'History',
        'Settings',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Review'), findsNothing);
      expect(find.text('Playground'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });
}
