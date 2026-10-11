import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/repositories/execution_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/playground/presentation/playground_screen.dart';
import 'package:deviq/shared/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExecRepo extends Mock implements ExecutionRepository {}

/// Optical audit: the terminal Send lens must share the input pill's
/// vertical center within 1px, and its label must share the lens
/// center within 1px — no eyeballing screenshots.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('send lens is concentric with input pill', (t) async {
    final repo = _FakeExecRepo();
    when(() => repo.reachable()).thenAnswer((_) async {});
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [execRepoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          darkTheme: DevIQTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: SafeArea(child: PlaygroundScreen())),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    final sendLens = find.byWidgetPredicate(
      (w) => w is GlassGhostButton && w.label == 'Send ↵',
    );
    expect(sendLens, findsOneWidget);

    // The 48px pill wrapping prompt + field + send.
    final pill = find.ancestor(
      of: sendLens,
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 48,
      ),
    );
    expect(pill, findsOneWidget);

    final lensDy = t.getCenter(sendLens).dy;
    final pillDy = t.getCenter(pill).dy;
    // ignore: avoid_print
    print('send dy=$lensDy pill dy=$pillDy label dy=${t.getCenter(find.text('Send ↵')).dy}');
    expect((lensDy - pillDy).abs(), lessThanOrEqualTo(1.0));
    expect(
      (t.getCenter(find.text('Send ↵')).dy - lensDy).abs(),
      lessThanOrEqualTo(1.0),
    );
  });
}
