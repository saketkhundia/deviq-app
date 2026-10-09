import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/storage/app_storage.dart';
import '../../../data/models/analysis_models.dart';
import '../../app/providers/app_providers.dart';

/// Analyze state machine: idle → loading → success | error.
enum AnalyzeStatus { idle, loading, success, failure }

class AnalyzeState {
  const AnalyzeState({
    this.status = AnalyzeStatus.idle,
    this.result,
    this.error,
    this.failedPlatforms = const [],
  });

  final AnalyzeStatus status;
  final AnalysisResult? result;
  final String? error;
  final List<String> failedPlatforms;

  AnalyzeState copyWith({
    AnalyzeStatus? status,
    AnalysisResult? result,
    String? error,
    List<String>? failedPlatforms,
  }) => AnalyzeState(
    status: status ?? this.status,
    result: result ?? this.result,
    error: error,
    failedPlatforms: failedPlatforms ?? this.failedPlatforms,
  );
}

final analyzeProvider = StateNotifierProvider<AnalyzeController, AnalyzeState>(
  (ref) => AnalyzeController(ref),
);

class AnalyzeController extends StateNotifier<AnalyzeState> {
  AnalyzeController(this._ref) : super(const AnalyzeState());
  final Ref _ref;

  Future<void> run({
    required String github,
    required String leetcode,
    required String codeforces,
  }) async {
    final gh = github.trim();
    final lc = leetcode.trim();
    final cf = codeforces.trim();
    if (gh.isEmpty && lc.isEmpty && cf.isEmpty) {
      state = state.copyWith(
        status: AnalyzeStatus.failure,
        error: 'Enter at least one username to run an analysis.',
      );
      return;
    }
    state = const AnalyzeState(status: AnalyzeStatus.loading);
    await _ref
        .read(prefsStoreProvider)
        .saveUsernames(github: gh, leetcode: lc, codeforces: cf);
    try {
      final result = await _ref
          .read(analysisRepoProvider)
          .analyze(github: gh, leetcode: lc, codeforces: cf);
      if (!result.hasData) {
        state = state.copyWith(
          status: AnalyzeStatus.failure,
          error: 'No data found. Check the usernames — the platform may be unreachable or the account may not exist.',
        );
        return;
      }
      final failed = <String>[];
      if (gh.isNotEmpty && result.github == null) failed.add('GitHub');
      if (lc.isNotEmpty && result.leetcode == null) failed.add('LeetCode');
      if (cf.isNotEmpty && result.codeforces == null) {
        failed.add('Codeforces');
      }
      state = AnalyzeState(
        status: AnalyzeStatus.success,
        result: result,
        failedPlatforms: failed,
      );
      // Persist lightweight history + bump profile counter best-effort.
      await _ref.read(historyProvider.notifier).add(result);
    } on ApiException catch (e) {
      state = state.copyWith(status: AnalyzeStatus.failure, error: '$e');
    } catch (_) {
      state = state.copyWith(
        status: AnalyzeStatus.failure,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() => state = const AnalyzeState();
}

// ---- History (persisted lightweight records) ----
final historyProvider =
    StateNotifierProvider<HistoryController, List<HistoryRecord>>(
      (ref) => HistoryController(ref.watch(prefsStoreProvider)),
    );

class HistoryController extends StateNotifier<List<HistoryRecord>> {
  HistoryController(this._prefs) : super(const []) {
    _load();
  }
  final PrefsStore _prefs;
  static const _uuid = Uuid();

  Future<void> _load() async {
    try {
      final raw = await _prefs.historyJson();
      state =
          raw
              .map(
                (e) => HistoryRecord.fromJson(
                  (jsonDecode(e) as Map).cast<String, dynamic>(),
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      state = const [];
    }
  }

  Future<void> add(AnalysisResult r) async {
    final rec = HistoryRecord.fromJson({
      'id': _uuid.v4(),
      ...r.toHistoryJson(),
    });
    state = [rec, ...state].take(50).toList();
    await _prefs.saveHistoryJson(
      state.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> clear() async {
    state = const [];
    await _prefs.saveHistoryJson(const []);
  }
}
