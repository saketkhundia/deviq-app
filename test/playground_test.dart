import 'package:deviq/core/theme/deviq_theme.dart';
import 'package:deviq/data/models/ai_models.dart';
import 'package:deviq/data/repositories/execution_repository.dart';
import 'package:deviq/features/app/providers/app_providers.dart';
import 'package:deviq/features/playground/presentation/playground_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExecRepo extends Mock implements ExecutionRepository {}

/// Playground in the web reference shape: hero, toolbar, stdin panel,
/// editor + terminal frames, tips — and a real mocked run surfacing
/// the command line, output and SUCCESS status.
void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('run shows command, output and status at 360px', (t) async {
    final repo = _FakeExecRepo();
    when(() => repo.reachable()).thenAnswer((_) async {});
    when(
      () => repo.execute(
        language: any(named: 'language'),
        code: any(named: 'code'),
        stdin: any(named: 'stdin'),
      ),
    ).thenAnswer(
      (_) async => const ExecutionResult(
        output: 'Hello from DevIQ Playground!',
        error: '',
        exitCode: 0,
        elapsedMs: 4,
        timedOut: false,
      ),
    );
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
    expect(find.text('INTERACTIVE CODE PLAYGROUND'), findsOneWidget);
    expect(find.text('Write code. Run it. See output.'), findsOneWidget);
    expect(find.text('INPUT · STDIN'), findsOneWidget);
    expect(find.text('TERMINAL'), findsOneWidget);
    expect(find.text('TIPS'), findsOneWidget);
    expect(find.text('Live'), findsNWidgets(2));
    await t.drag(
      find.ancestor(
        of: find.text('INTERACTIVE CODE PLAYGROUND'),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(0, -600),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Run'));
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.textContaining('Hello from DevIQ Playground!'), findsWidgets);
    expect(find.text('SUCCESS'), findsOneWidget);
    expect(find.textContaining('exit 0'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
