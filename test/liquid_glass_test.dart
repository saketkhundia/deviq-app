import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/features/home/presentation/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Liquid-glass system: refractive surfaces, aurora field, press
/// physics, and mobile fit in both brightnesses.
Widget _wrap(Widget child, {bool dark = true, double width = 375}) =>
    MaterialApp(
      theme: DevIQTheme.light(),
      darkTheme: DevIQTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

void _setSurface(WidgetTester t, double width, [double height = 1600]) {
  t.view.physicalSize = Size(width * 3, height * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void _noop() {}

void main() {
  group('liquid glass material', () {
    testWidgets('panel refracts with real backdrop blur', (t) async {
      _setSurface(t, 375);
      await t.pumpWidget(_wrap(const LiquidGlass(child: Text('lens'))));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('lens'), findsOneWidget);
      final filters = find.byWidgetPredicate((w) => w is BackdropFilter);
      expect(filters, findsWidgets);
    });

    testWidgets('aurora backdrop paints without semantics noise', (t) async {
      _setSurface(t, 375);
      // Backdrop is a fill widget: bound it like the production
      // Stack (Positioned.fill) does.
      await t.pumpWidget(
        _wrap(const SizedBox(height: 800, child: LiquidBackdrop())),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
      // The backdrop carries its own exclusion (the scroll view adds
      // one more of its own, so match the one inside the backdrop).
      expect(
        find.descendant(
          of: find.byType(LiquidBackdrop),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('primary button fires, loads, and disables', (t) async {
      _setSurface(t, 375);
      var taps = 0;
      await t.pumpWidget(
        _wrap(
          GlassPrimaryButton(
            label: 'Analyze Profile',
            icon: Icons.arrow_forward,
            onPressed: () => taps++,
          ),
        ),
      );
      await t.pump();
      expect(find.text('Analyze Profile'), findsOneWidget);
      await t.tap(find.text('Analyze Profile'));
      await t.pump();
      expect(taps, 1);
      // Edge-light refraction cue present on the primary lens.
      expect(find.byKey(const Key('glass-edge-light')), findsOneWidget);

      // Loading replaces the label with a spinner and blocks taps.
      await t.pumpWidget(
        _wrap(
          GlassPrimaryButton(
            label: 'Analyze Profile',
            onPressed: () => taps++,
            loading: true,
          ),
        ),
      );
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Disabled action dims and ignores taps.
      await t.pumpWidget(
        _wrap(
          const GlassPrimaryButton(label: 'Analyze Profile', onPressed: null),
        ),
      );
      await t.pump();
      await t.tap(find.text('Analyze Profile'));
      await t.pump();
      expect(taps, 1);
      expect(t.takeException(), isNull);
    });

    testWidgets('ghost button keeps full labels untampered', (t) async {
      _setSurface(t, 375);
      var taps = 0;
      await t.pumpWidget(
        _wrap(
          GlassGhostButton(
            label: 'Compare Developers',
            icon: Icons.compare_arrows_rounded,
            onTap: () => taps++,
          ),
        ),
      );
      await t.pump();
      expect(find.text('Compare Developers'), findsOneWidget);
      await t.tap(find.text('Compare Developers'));
      await t.pump();
      expect(taps, 1);
      // Ghost lens carries blur + top edge light, not a flat slab.
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byKey(const Key('glass-edge-light')), findsOneWidget);
      // Expanded by default: forces full width like the primary lens.
      final wideLens = find.ancestor(
        of: find.text('Compare Developers'),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == double.infinity,
        ),
      );
      expect(wideLens, findsOneWidget);
      // Opt-out stays inline for tight placements.
      await t.pumpWidget(
        _wrap(
          GlassGhostButton(
            label: 'Compare Developers',
            onTap: () {},
            expanded: false,
          ),
        ),
      );
      await t.pump();
      expect(
        find.ancestor(
          of: find.text('Compare Developers'),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == double.infinity,
          ),
        ),
        findsNothing,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('section header uppercases with glass index chip', (t) async {
      _setSurface(t, 375);
      await t.pumpWidget(
        _wrap(
          const GlassSectionHeader(
            index: '01',
            title: 'Unified score',
            caption: 'caption copy',
          ),
        ),
      );
      await t.pump();
      expect(find.text('01'), findsOneWidget);
      expect(find.text('UNIFIED SCORE'), findsOneWidget);
      expect(find.text('caption copy'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('inline ghost survives unbounded Row width', (t) async {
      _setSurface(t, 375);
      await t.pumpWidget(
        _wrap(
          Row(
            children: [
              const Expanded(child: TextField()),
              const SizedBox(width: 8),
              GlassGhostButton(
                label: 'Send ↵',
                expanded: false,
                height: 42,
                onTap: _noop,
              ),
            ],
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Send ↵'), findsOneWidget);
    });

    testWidgets('press physics respect reduced motion', (t) async {      _setSurface(t, 375);
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _wrap(GlassGhostButton(label: 'Try Playground', onTap: () {})),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Try Playground'), findsOneWidget);
    });

    testWidgets('glass button is keyboard-focusable with ring + action',
        (t) async {
      _setSurface(t, 375);
      var taps = 0;
      await t.pumpWidget(
        _wrap(GlassGhostButton(label: 'Focus me', onTap: () => taps++)),
      );
      await t.pump();
      // Exposed as a button to assistive tech.
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
        findsWidgets,
      );
      // Tab traversal lands keyboard focus and draws a visible ring…
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.border?.top.width == 2,
        ),
        findsOneWidget,
      );
      // …and Enter activates.
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(taps, 1);
      expect(t.takeException(), isNull);
    });

    testWidgets('disabled glass button takes no focus or input', (t) async {
      _setSurface(t, 375);
      var taps = 0;
      await t.pumpWidget(
        _wrap(
          GlassPrimaryButton(
            label: 'Blocked',
            onPressed: () => taps++,
            loading: true,
          ),
        ),
      );
      await t.pump();
      // Traversal skips the disabled lens: no ring…
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.border?.top.width == 2,
        ),
        findsNothing,
      );
      // …and Enter does nothing.
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(taps, 0);
      expect(t.takeException(), isNull);
    });

  });

  group('glass home fits phones', () {
    for (final w in [375.0, 390.0, 430.0]) {
      for (final dark in [true, false]) {
        testWidgets(
          'glass bar + divider calm at ${w}px ${dark ? 'dark' : 'light'}',
          (t) async {
            _setSurface(t, w);
            await t.pumpWidget(
              _wrap(
                const Column(
                  children: [
                    GlassBar(value: 0.72, color: Color(0xFF42E58B)),
                    GlassDivider(),
                  ],
                ),
                dark: dark,
                width: w,
              ),
            );
            await t.pump();
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  });
}
