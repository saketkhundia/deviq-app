import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/shared/widgets/deviq_widgets.dart';
import 'package:deviq/shared/widgets/score_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool dark = true}) => MaterialApp(
  theme: DevIQTheme.light(),
  darkTheme: DevIQTheme.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: Scaffold(body: child),
);

void main() {
  group('design system widgets', () {
    testWidgets('ScoreRing shows animated score', (t) async {
      await t.pumpWidget(_wrap(const ScoreRing(score: 82)));
      expect(find.text('0'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 1500));
      await t.pumpAndSettle();
      expect(find.text('82'), findsOneWidget);
    });

    testWidgets('DevIQCard + buttons render in both themes', (t) async {
      for (final dark in [true, false]) {
        await t.pumpWidget(
          _wrap(
            const DevIQCard(
              child: Column(
                children: [
                  DevIQSectionLabel('LABEL'),
                  MetricCard(label: 'Stars', value: '1.2k'),
                ],
              ),
            ),
            dark: dark,
          ),
        );
        expect(find.text('LABEL'), findsOneWidget);
        expect(find.text('1.2k'), findsOneWidget);
      }
    });

    testWidgets('loading/empty/error states render messages', (t) async {
      await t.pumpWidget(
        _wrap(
          const Column(
            children: [
              LoadingState(message: 'Busy…'),
              EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nothing',
                message: 'Empty here',
              ),
              ErrorState(message: 'Bad net'),
            ],
          ),
        ),
      );
      expect(find.text('Busy…'), findsOneWidget);
      expect(find.text('Nothing'), findsOneWidget);
      expect(find.text('Bad net'), findsOneWidget);
    });
  });
}
