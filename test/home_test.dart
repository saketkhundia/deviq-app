import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/home/presentation/home_screen.dart';
import 'package:deviq/features/home/presentation/widgets/feature_grid.dart';
import 'package:deviq/features/home/presentation/widgets/score_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home page content + layout: spec copy, preview values, card count,
/// CTA presence, and no-overflow at phone widths.
Future<void> _pumpHome(
  WidgetTester t, {
  double width = 360,
  double height = 800,
  bool dark = true,
}) async {
  t.view.physicalSize = Size(width * 3, height * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: DevIQTheme.light(),
        darkTheme: DevIQTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(body: SafeArea(child: HomeScreen())),
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
  group('home content (spec copy)', () {
    testWidgets('hero copy + CTAs', (t) async {
      await _pumpHome(t);
      expect(find.text('DEVELOPER ANALYTICS PLATFORM'), findsOneWidget);
      expect(find.textContaining('Your developer'), findsOneWidget);
      expect(
        find.textContaining(
          'DevIQ unifies your GitHub, LeetCode, and Codeforces stats',
        ),
        findsOneWidget,
      );
      expect(find.text('Analyze Profile'), findsOneWidget);
      expect(find.text('Try Playground'), findsOneWidget);
      expect(find.text('Compare Developers'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('score preview values + pills + sample label', (t) async {
      await _pumpHome(t);
      expect(find.byType(DeveloperScorePreview), findsOneWidget);
      bool richContains(String s) => find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(s),
          )
          .evaluate()
          .isNotEmpty;
      for (final v in ['82 /100', '74 /100', '68 /100', '78 /100']) {
        expect(richContains(v), isTrue, reason: 'missing $v');
      }
      expect(find.text('PROGRESS TREND'), findsOneWidget);
      expect(find.text('Role Fit: Full-Stack'), findsOneWidget);
      expect(find.text('AI Plan Ready'), findsOneWidget);
      expect(find.text('Heatmap Active'), findsOneWidget);
      expect(find.text('Sample preview'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('eight feature cards + banner + info', (t) async {
      await _pumpHome(t);
      expect(find.byType(FeatureCard), findsNWidgets(8));
      for (final title in [
        'GitHub Analytics',
        'LeetCode Stats',
        'Codeforces Rating',
        'Unified Score',
        'AI Insights',
        'Compare Mode',
        'Code Playground',
        'AI Code Review',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Ready to measure your profile?'), findsOneWidget);
      expect(
        find.text('Connect your accounts and get your score in seconds.'),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(
        find.textContaining('free developer analytics platform'),
        findsOneWidget,
      );
      expect(find.textContaining('Competitive Programmer'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('home layout matrix', () {
    testWidgets('430 light', (t) async {
      await _pumpHome(t, width: 430, height: 932, dark: false);
      expect(find.text('Analyze Profile'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
    testWidgets('375 dark', (t) async {
      await _pumpHome(t, width: 375, height: 812);
      expect(find.byType(FeatureCard), findsNWidgets(8));
      expect(t.takeException(), isNull);
    });
  });
}
