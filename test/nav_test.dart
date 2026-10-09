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
  await t.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
}

void main() {
  group('bottom nav reference behavior', () {
    testWidgets('active pill shows label, others icon-only', (t) async {
      await _pumpNav(
          t, const DevIQBottomNav(active: 'analyze', onTab: null));
      expect(find.text('Analyze'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Interview'), findsNothing);
      expect(find.text('Ask AI'), findsNothing);
      expect(find.text('More'), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('tap routes to the right tab id', (t) async {
      String? tapped;
      await _pumpNav(
        t,
        DevIQBottomNav(
          active: 'home',
          onTab: (id) => tapped = id,
        ),
      );
      await t.tap(find.byIcon(Icons.work_outline));
      expect(tapped, 'interview');
      await t.tap(find.byIcon(Icons.smart_toy_outlined));
      expect(tapped, 'ai');
      await t.tap(find.byIcon(Icons.apps_outlined));
      expect(tapped, 'more');
      expect(t.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (t) async {
      await _pumpNav(
        t,
        const DevIQBottomNav(active: 'ai', onTab: null),
        dark: false,
      );
      expect(find.text('Ask AI'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('more sheet destinations', () {
    testWidgets('compare + playground live in More', (t) async {
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
        'Compare',
        'Playground',
        'Review',
        'Profile',
        'History',
        'Settings',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Ask AI'), findsNothing);
      expect(find.text('Interview Prep'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });
}
