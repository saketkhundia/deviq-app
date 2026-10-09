import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/analysis_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/execution_repository.dart';
import '../../../data/repositories/misc_repositories.dart';

// ---- Low-level singletons ----
final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());
final prefsStoreProvider = Provider<PrefsStore>((_) => PrefsStore());

// ---- Repositories ----
final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  ),
);
final analysisRepoProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(ref.watch(apiClientProvider)),
);
final aiRepoProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(apiClientProvider)),
);
final execRepoProvider = Provider<ExecutionRepository>(
  (ref) => ExecutionRepository(ref.watch(apiClientProvider)),
);
final interviewRepoProvider = Provider<InterviewRepository>(
  (ref) => InterviewRepository(ref.watch(apiClientProvider)),
);
final profileRepoProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

// ---- Theme ----
enum AppThemeMode { system, dark, light }

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, AppThemeMode>(
      (ref) => ThemeModeController(ref.watch(prefsStoreProvider)),
    );

class ThemeModeController extends StateNotifier<AppThemeMode> {
  ThemeModeController(this._prefs) : super(AppThemeMode.dark) {
    _load();
  }
  final PrefsStore _prefs;

  Future<void> _load() async {
    final v = await _prefs.themeMode();
    state = switch (v) {
      'light' => AppThemeMode.light,
      'system' => AppThemeMode.system,
      _ => AppThemeMode.dark,
    };
  }

  Future<void> set(AppThemeMode m) async {
    state = m;
    await _prefs.setThemeMode(m.name);
  }

  ThemeMode get material => switch (state) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };
}
