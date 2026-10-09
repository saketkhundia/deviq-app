import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/deviq_theme.dart';
import 'features/app/providers/app_providers.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DevIQApp()));
}

class DevIQApp extends ConsumerStatefulWidget {
  const DevIQApp({super.key});

  @override
  ConsumerState<DevIQApp> createState() => _DevIQAppState();
}

class _DevIQAppState extends ConsumerState<DevIQApp> {
  late final GoRouterRefresh _authTick = GoRouterRefresh();
  late final _router = buildRouter(
    authStatus: () => ref.read(authProvider).status,
    refresh: _authTick,
  );
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    // Subscribed post-frame: container lookup isn't ready in initState,
    // and every auth transition happens strictly after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual(authProvider, (_, _) => _authTick.bump());
    });
    ref.read(authProvider.notifier).bootstrap().whenComplete(() {
      if (mounted) setState(() => _booted = true);
    });
  }

  ThemeMode _material(AppThemeMode m) => switch (m) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'DevIQ',
      debugShowCheckedModeBanner: false,
      theme: DevIQTheme.light(),
      darkTheme: DevIQTheme.dark(),
      themeMode: _material(mode),
      routerConfig: _router,
      builder: (context, child) {
        if (!_booted) return const _Splash();
        return child!;
      },
    );
  }
}

/// Minimal branded launch screen while the session restores.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'D',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'DevIQ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bumpable Listenable that pokes go_router's redirect on auth changes.
class GoRouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}
