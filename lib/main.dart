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
  late final _router = buildRouter();
  bool _booted = false;

  @override
  void initState() {
    super.initState();
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
        if (!_booted) {
          return Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.2)),
            ),
          );
        }
        return child!;
      },
    );
  }
}
