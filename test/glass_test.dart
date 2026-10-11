import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/shared/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester t, Widget child, {bool dark = true}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: DevIQTheme.light(),
      darkTheme: DevIQTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

const _items = [
  PillNavItem(
    id: 'a',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Alpha',
  ),
  PillNavItem(
    id: 'b',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search_rounded,
    label: 'Beta',
  ),
  PillNavItem(
    id: 'c',
    icon: Icons.person_outlined,
    selectedIcon: Icons.person_rounded,
    label: 'Gamma',
  ),
];

void main() {
  group('glass components', () {
    testWidgets('GlassSurface renders child, fallback without blur', (t) async {
      await _pump(
        t,
        const GlassSurface(enabled: false, child: Text('glass child')),
      );
      expect(find.text('glass child'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('PrimaryActionButton loading + disabled', (t) async {
      await t.pumpWidget(
        MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PrimaryActionButton(
                    label: 'Go',
                    loading: true,
                    onPressed: null,
                  ),
                  PrimaryActionButton(label: 'Off', onPressed: null),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('sliding pill moves selection on tap', (t) async {
      String selected = 'a';
      await t.pumpWidget(
        MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SlidingPillNavigation(
                items: _items,
                selectedId: selected,
                onSelect: (id) => setState(() => selected = id),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      await t.tap(find.byIcon(Icons.search_outlined));
      await t.pumpAndSettle();
      expect(selected, 'b');
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('AuthTextField renders label + hint', (t) async {
      await _pump(
        t,
        const AuthTextField(label: 'Email address', hint: 'you@x.com'),
        dark: false,
      );
      expect(find.text('Email address'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
