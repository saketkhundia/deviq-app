import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/shared/widgets/app_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bottom nav in the reference style: active tab is a filled pill with
/// icon + label, inactive tabs are muted icons. Tabs: Home · Analyze ·
/// Interview · Ask AI · More (Compare/Playground live in More).
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
      home: Scaffold(body: SafeArea(child: nav)),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

void main() {
  group('bottom nav reference behavior', () {
    testWidgets('active tab shows filled icon + label', (t) async {
      await _pumpNav(t, const DevIQBottomNav(active: 'compare', onTab: null));
      expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows_outlined), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.terminal_outlined), findsOneWidget);
      expect(find.byIcon(Icons.apps_outlined), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('tap routes to the right tab id', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(active: 'home', onTab: (id) => tapped = id),
      );
      await t.tap(find.byIcon(Icons.compare_arrows_outlined));
      expect(tapped, 'compare');
      await t.tap(find.byIcon(Icons.terminal_outlined));
      expect(tapped, 'play');
      await t.tap(find.byIcon(Icons.apps_outlined));
      expect(tapped, 'more');
      expect(t.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (t) async {
      await _pumpNav(
        t,
        const DevIQBottomNav(active: 'play', onTab: null),
        dark: false,
      );
      expect(find.byIcon(Icons.terminal_rounded), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('more sheet destinations', () {
    testWidgets('interview + ask ai live in More', (t) async {
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
        'Interview Prep',
        'Ask AI',
        'Review',
        'Profile',
        'History',
        'Settings',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Compare'), findsNothing);
      expect(find.text('Playground'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });
}
