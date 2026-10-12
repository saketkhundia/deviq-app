import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/analyze/presentation/analyze_screen.dart';
import 'package:deviq/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responsive smoke coverage beyond the 375–430 phone band: narrow
/// 320px phones, 768px tablets and 1440px desktops render Home
/// (both stacked and two-column assemblies) and the idle Analyze
/// workspace with no overflow, no clipped actions and no exceptions.
Future<void> _pumpAt(
  WidgetTester t,
  Widget child,
  double width, {
  bool dark = true,
}) async {
  t.view.physicalSize = Size(width * 3, 2400);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: DevIQTheme.light(),
        darkTheme: DevIQTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(body: SafeArea(child: child)),
      ),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

void main() {
  group('responsive smoke', () {
    for (final w in [320.0, 768.0, 1440.0]) {
      testWidgets('home fits at ${w}px', (t) async {
        await _pumpAt(t, const HomeScreen(), w);
        expect(t.takeException(), isNull);
        expect(find.text('Analyze Profile'), findsWidgets);
        expect(find.text('UNIFIED SCORE'), findsOneWidget);
        expect(find.text('NEXT STEP'), findsOneWidget);
      });

      testWidgets('analyze idle fits at ${w}px', (t) async {
        await _pumpAt(t, const AnalyzeScreen(), w);
        expect(t.takeException(), isNull);
        expect(find.text('Run Analysis'), findsOneWidget);
        expect(find.text('No analysis yet'), findsOneWidget);
      });
    }

    testWidgets('home fits at 320px light', (t) async {
      await _pumpAt(t, const HomeScreen(), 320, dark: false);
      expect(t.takeException(), isNull);
      expect(find.text('Compare Developers'), findsOneWidget);
    });
  });
}
