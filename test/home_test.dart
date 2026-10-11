import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/home/presentation/home_screen.dart';
import 'package:deviq/features/home/presentation/widgets/feature_grid.dart';
import 'package:deviq/features/home/presentation/widgets/unified_score.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Home page content + layout: identity copy, live-data-only score
/// states, section order, CTA presence, no-overflow at phone widths.
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
  group('home content (developer intelligence)', () {
    testWidgets('hero copy + CTAs', (t) async {
      await _pumpHome(t);
      expect(find.text('DEVELOPER INTELLIGENCE'), findsOneWidget);
      expect(find.textContaining('Your developer'), findsOneWidget);
      expect(
        find.textContaining('one developer intelligence profile'),
        findsOneWidget,
      );
      expect(find.text('Analyze Profile'), findsWidgets);
      expect(find.text('Try Playground'), findsOneWidget);
      expect(find.text('Compare Developers'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('onboarding score shows no fabricated numbers', (t) async {
      await _pumpHome(t);
      expect(find.byType(UnifiedScoreSection), findsOneWidget);
      expect(find.text('UNIFIED SCORE'), findsOneWidget);
      expect(find.text('No profile yet'), findsOneWidget);
      // No invented scores, no sample captions, no decorative trend.
      expect(find.text('Sample preview'), findsNothing);
      expect(find.text('PROGRESS TREND'), findsNothing);
      bool richContains(String s) => find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(s),
          )
          .evaluate()
          .isNotEmpty;
      expect(richContains('/ 100'), isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets('workspace sections in order', (t) async {
      await _pumpHome(t);
      for (final h in [
        'UNIFIED SCORE',
        'ACTIVITY FINGERPRINT',
        'SKILL PROFILE',
        'NEXT STEP',
      ]) {
        expect(find.text(h), findsOneWidget, reason: 'missing $h');
      }
      expect(find.text('No activity mapped yet'), findsOneWidget);
      expect(
        find.text('Analyze your developer profile'),
        findsOneWidget,
      );
      expect(find.text('Start analysis'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('eight tools + banner + info', (t) async {
      await _pumpHome(t);
      expect(find.byType(FeatureList), findsOneWidget);
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
      expect(find.text('Analyze Profile'), findsWidgets);
      expect(t.takeException(), isNull);
    });
    testWidgets('375 dark', (t) async {
      await _pumpHome(t, width: 375, height: 812);
      expect(find.byType(FeatureList), findsOneWidget);
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
      expect(t.takeException(), isNull);
    });
  });
}
