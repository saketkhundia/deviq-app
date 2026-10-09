import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/weak_categories.dart';
import '../../../data/models/ai_models.dart';
import '../../../data/models/analysis_models.dart';
import 'app_providers.dart';
import '../../analyze/presentation/analyze_controller.dart';

// ---- Compare ----
enum CompareStatus { idle, loading, success, failure }

class CompareState {
  const CompareState({
    this.status = CompareStatus.idle,
    this.a,
    this.b,
    this.error,
  });
  final CompareStatus status;
  final AnalysisResult? a;
  final AnalysisResult? b;
  final String? error;
}

final compareProvider = StateNotifierProvider<CompareController, CompareState>(
  (ref) => CompareController(ref),
);

class CompareController extends StateNotifier<CompareState> {
  CompareController(this._ref) : super(const CompareState());
  final Ref _ref;

  Future<void> run({
    required ({String github, String leetcode, String codeforces}) devA,
    required ({String github, String leetcode, String codeforces}) devB,
  }) async {
    state = const CompareState(status: CompareStatus.loading);
    try {
      final repo = _ref.read(analysisRepoProvider);
      final results = await Future.wait<AnalysisResult>([
        repo.analyze(
          github: devA.github.trim(),
          leetcode: devA.leetcode.trim(),
          codeforces: devA.codeforces.trim(),
        ),
        repo.analyze(
          github: devB.github.trim(),
          leetcode: devB.leetcode.trim(),
          codeforces: devB.codeforces.trim(),
        ),
      ]);
      if (!results[0].hasData && !results[1].hasData) {
        state = const CompareState(
          status: CompareStatus.failure,
          error: 'No data found for either developer.',
        );
        return;
      }
      state = CompareState(
        status: CompareStatus.success,
        a: results[0],
        b: results[1],
      );
    } catch (e) {
      state = CompareState(status: CompareStatus.failure, error: '$e');
    }
  }

  void reset() => state = const CompareState();
}

// ---- Playground ----
class PlaygroundState {
  const PlaygroundState({
    this.language = 'javascript',
    this.code = '',
    this.stdin = '',
    this.filename,
    this.running = false,
    this.result,
    this.error,
    this.runnerLive = false,
  });

  final String language;
  final String code;
  final String stdin;
  final String? filename;
  final bool running;
  final ExecutionResult? result;
  final String? error;

  /// True once the backend runner answered a probe (web "Live" badge).
  final bool runnerLive;

  PlaygroundState copyWith({
    String? language,
    String? code,
    String? stdin,
    String? filename,
    bool? running,
    ExecutionResult? result,
    String? error,
    bool? runnerLive,
  }) => PlaygroundState(
    language: language ?? this.language,
    code: code ?? this.code,
    stdin: stdin ?? this.stdin,
    filename: filename ?? this.filename,
    running: running ?? this.running,
    result: result ?? this.result,
    error: error,
    runnerLive: runnerLive ?? this.runnerLive,
  );

  /// Explicit clear (copyWith cannot null [result] by design).
  PlaygroundState cleared() => PlaygroundState(
    language: language,
    code: code,
    stdin: stdin,
    filename: filename,
    runnerLive: runnerLive,
  );
}

final playgroundProvider =
    StateNotifierProvider<PlaygroundController, PlaygroundState>(
      (ref) => PlaygroundController(ref),
    );

class PlaygroundController extends StateNotifier<PlaygroundState> {
  PlaygroundController(this._ref) : super(const PlaygroundState()) {
    _loadDraft();
  }
  final Ref _ref;

  Future<void> _loadDraft() async {
    final p = _ref.read(prefsStoreProvider);
    final lang = await p.playgroundLang() ?? 'javascript';
    final code = await p.playgroundCode(lang);
    final stdin = await p.playgroundStdin() ?? '';
    state = state.copyWith(language: lang, code: code ?? '', stdin: stdin);
    try {
      await _ref.read(execRepoProvider).reachable();
      if (mounted) state = state.copyWith(runnerLive: true);
    } catch (_) {
      if (mounted) state = state.copyWith(runnerLive: false);
    }
  }

  void setLanguage(String id, String template) {
    _ref
        .read(prefsStoreProvider)
        .savePlaygroundCode(state.language, state.code);
    final cached = _ref.read(prefsStoreProvider).playgroundCode(id);
    cached.then(
      (c) => state = state.copyWith(
        language: id,
        code: c ?? template,
        result: null,
        error: null,
      ),
    );
    _ref.read(prefsStoreProvider).savePlaygroundLang(id);
  }

  void setCode(String c) {
    state = state.copyWith(code: c);
    _ref.read(prefsStoreProvider).savePlaygroundCode(state.language, c);
  }

  void setStdin(String v) {
    state = state.copyWith(stdin: v);
    _ref.read(prefsStoreProvider).savePlaygroundStdin(v);
  }

  void clearResult() {
    state = state.cleared();
  }

  Future<void> run() async {
    if (state.running || state.code.trim().isEmpty) return;
    state = state.copyWith(running: true, error: null, result: null);
    try {
      final r = await _ref
          .read(execRepoProvider)
          .execute(
            language: state.language,
            code: state.code,
            stdin: state.stdin,
          );
      state = state.copyWith(running: false, result: r);
    } catch (e) {
      state = state.copyWith(running: false, error: '$e');
    }
  }
}

// ---- Code review ----
enum ReviewStatus { idle, loading, success, failure }

class ReviewState {
  const ReviewState({
    this.status = ReviewStatus.idle,
    this.result,
    this.optimized,
    this.error,
  });
  final ReviewStatus status;
  final CodeReviewResult? result;
  final String? optimized;
  final String? error;
}

final reviewProvider = StateNotifierProvider<ReviewController, ReviewState>(
  (ref) => ReviewController(ref),
);

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._ref) : super(const ReviewState());
  final Ref _ref;

  Future<void> review({required String code, required String language}) async {
    if (code.trim().isEmpty) {
      state = const ReviewState(
        status: ReviewStatus.failure,
        error: 'Paste some code first.',
      );
      return;
    }
    state = const ReviewState(status: ReviewStatus.loading);
    try {
      final r = await _ref
          .read(aiRepoProvider)
          .review(code: code, language: language);
      state = ReviewState(status: ReviewStatus.success, result: r);
    } catch (e) {
      state = ReviewState(status: ReviewStatus.failure, error: '$e');
    }
  }

  Future<void> optimize({
    required String code,
    required String language,
  }) async {
    try {
      final r = await _ref
          .read(aiRepoProvider)
          .optimize(code: code, language: language);
      state = ReviewState(
        status: state.status,
        result: state.result,
        optimized: r,
      );
    } catch (e) {
      state = ReviewState(
        status: state.status,
        result: state.result,
        error: '$e',
      );
    }
  }
}

// ---- AI chat ----
class ChatState {
  const ChatState({this.messages = const [], this.sending = false, this.error});
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
}

final chatProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(ref),
);

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref) : super(const ChatState());
  final Ref _ref;

  /// Clears the visible conversation (web "Clear chat" action).
  void clear() => state = const ChatState();

  String _profileContext() {
    final a = _ref.read(analyzeProvider).result;
    if (a == null) return '';
    final b = StringBuffer('\n\nDeveloper profile context:\n');
    if (a.github != null) {
      b.writeln(
        '- GitHub ${a.github!.username}: ${a.github!.totalProjects} repos, ${a.github!.totalStars} stars, top language ${a.github!.mostUsedLanguage}.',
      );
    }
    if (a.leetcode != null) {
      b.writeln(
        '- LeetCode ${a.leetcode!.username}: ${a.leetcode!.totalSolved} solved (E${a.leetcode!.easySolved}/M${a.leetcode!.mediumSolved}/H${a.leetcode!.hardSolved}), rank ${a.leetcode!.ranking}.',
      );
    }
    if (a.codeforces != null) {
      b.writeln(
        '- Codeforces ${a.codeforces!.username}: rating ${a.codeforces!.rating}, rank ${a.codeforces!.rank}.',
      );
    }
    return b.toString();
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sending) return;
    final user = ChatMessage(role: 'user', content: t);
    state = ChatState(messages: [...state.messages, user], sending: true);
    try {
      final reply = await _ref
          .read(aiRepoProvider)
          .insights(prompt: t + _profileContext(), history: state.messages);
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(role: 'assistant', content: reply),
        ],
      );
    } catch (e) {
      state = ChatState(messages: state.messages, error: '$e');
    }
  }
}

// ---- Interview prep ----
class InterviewState {
  const InterviewState({
    this.leetcodeUser = '',
    this.company = 'google',
    this.loading = false,
    this.problems = const [],
    this.solved = const {},
    this.error,
    this.weak = const [],
    this.analyzing = false,
    this.weakUser = '',
    this.weakError,
  });

  final String leetcodeUser;
  final String company;
  final bool loading;
  final List<CompanyProblem> problems;
  final Set<String> solved;
  final String? error;

  /// Estimated weak categories for [weakUser] (see weak_categories.dart).
  final List<WeakCategory> weak;
  final bool analyzing;
  final String weakUser;
  final String? weakError;

  InterviewState copyWith({
    String? leetcodeUser,
    String? company,
    bool? loading,
    List<CompanyProblem>? problems,
    Set<String>? solved,
    String? error,
    List<WeakCategory>? weak,
    bool? analyzing,
    String? weakUser,
    String? weakError,
  }) => InterviewState(
    leetcodeUser: leetcodeUser ?? this.leetcodeUser,
    company: company ?? this.company,
    loading: loading ?? this.loading,
    problems: problems ?? this.problems,
    solved: solved ?? this.solved,
    error: error,
    weak: weak ?? this.weak,
    analyzing: analyzing ?? this.analyzing,
    weakUser: weakUser ?? this.weakUser,
    weakError: weakError,
  );
}

final interviewProvider =
    StateNotifierProvider<InterviewController, InterviewState>(
      (ref) => InterviewController(ref),
    );

class InterviewController extends StateNotifier<InterviewState> {
  InterviewController(this._ref) : super(const InterviewState()) {
    _loadSolved();
  }
  final Ref _ref;

  Future<void> _loadSolved() async {
    final s = await _ref.read(prefsStoreProvider).solvedProblems();
    state = state.copyWith(solved: s.toSet());
  }

  Future<void> loadCompany(String slug) async {
    state = state.copyWith(company: slug, loading: true, error: null);
    try {
      final problems = await _ref
          .read(interviewRepoProvider)
          .companyProblems(slug);
      state = state.copyWith(loading: false, problems: problems);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> toggleSolved(String slug, bool v) async {
    await _ref.read(prefsStoreProvider).setSolved(slug, v);
    final next = Set<String>.of(state.solved);
    if (v) {
      next.add(slug);
    } else {
      next.remove(slug);
    }
    state = state.copyWith(solved: next);
  }

  /// Fetches the LeetCode profile and estimates weak categories from the
  /// difficulty mix (see weak_categories.dart for the estimator contract).
  Future<void> analyzeWeak(String username) async {
    final u = username.trim();
    if (u.isEmpty || state.analyzing) return;
    state = state.copyWith(analyzing: true, weakError: null, leetcodeUser: u);
    try {
      final lc = await _ref.read(analysisRepoProvider).leetcode(u);
      if (!mounted) return;
      state = state.copyWith(
        analyzing: false,
        weakUser: lc.username.isEmpty ? u : lc.username,
        weak: estimateWeakCategories(
          easySolved: lc.easySolved,
          mediumSolved: lc.mediumSolved,
          hardSolved: lc.hardSolved,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        analyzing: false,
        weakError: '$e',
        weak: const [],
        weakUser: '',
      );
    }
  }
}
