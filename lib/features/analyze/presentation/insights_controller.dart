import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/analysis_models.dart';
import '../../app/providers/app_providers.dart';

/// AI insight modes offered by the Analyze page.
enum InsightMode { quick, roast, plan, gaps, interview }

extension InsightModeX on InsightMode {
  String get label => switch (this) {
    InsightMode.quick => 'Quick Take',
    InsightMode.roast => 'Roast Me',
    InsightMode.plan => '7-Day Plan',
    InsightMode.gaps => 'Skill Gaps',
    InsightMode.interview => 'Interview',
  };
}

enum InsightStatus { idle, loading, ready, error }

class InsightEntry {
  const InsightEntry({this.status = InsightStatus.idle, this.text = ''});

  final InsightStatus status;
  final String text;

  InsightEntry copyWith({InsightStatus? status, String? text}) =>
      InsightEntry(status: status ?? this.status, text: text ?? this.text);
}

class InsightsState {
  const InsightsState({
    this.entries = const {},
    this.hindi = false,
    this.generatingAll = false,
  });

  final Map<InsightMode, InsightEntry> entries;
  final bool hindi;
  final bool generatingAll;

  InsightEntry entry(InsightMode m) => entries[m] ?? const InsightEntry();
}

/// Builds the profile context appended to every insight prompt so the
/// model answers from the user's REAL analysis data.
String profileContext(AnalysisResult r) {
  final b = StringBuffer('\n\nDeveloper profile (DevIQ analysis):\n');
  b.writeln('Unified score: ${r.unifiedScore.toStringAsFixed(1)}/100.');
  final g = r.github;
  if (g != null) {
    b.writeln(
      '- GitHub ${g.username}: ${g.totalProjects} repos, ${g.totalStars} stars, top language ${g.mostUsedLanguage}.',
    );
  }
  final lc = r.leetcode;
  if (lc != null) {
    final solved = lc.totalSolved > 0
        ? lc.totalSolved
        : lc.easySolved + lc.mediumSolved + lc.hardSolved;
    b.writeln(
      '- LeetCode ${lc.username}: $solved solved (E${lc.easySolved}/M${lc.mediumSolved}/H${lc.hardSolved}), rank ${lc.ranking}.',
    );
  }
  final cf = r.codeforces;
  if (cf != null) {
    b.writeln(
      '- Codeforces ${cf.username}: rating ${cf.rating} (${cf.rank}), ${cf.contestsParticipated} contests.',
    );
  }
  return b.toString();
}

String insightPrompt(InsightMode mode, AnalysisResult r, {bool hindi = false}) {
  final ctx = profileContext(r);
  final base = switch (mode) {
    InsightMode.quick => 'Give a concise 3-sentence assessment of this developer profile: biggest strength, biggest weakness, one next action. No fluff.',
    InsightMode.roast => 'Roast this developer profile: funny but constructive, then one genuinely useful tip. Keep it good-natured.',
    InsightMode.plan => 'Give a focused 7-day improvement plan for this developer: one concrete task per day, building on their weak areas.',
    InsightMode.gaps => 'List the top 3 skill gaps in this developer profile with a one-line fix for each. Be specific and technical.',
    InsightMode.interview => 'Is this developer interview-ready? Give a yes/no-leaning verdict plus a short readiness checklist.',
  };
  final lang = hindi
      ? ' Respond in Hindi (keep code terms and usernames in English).'
      : '';
  return '$base$lang$ctx';
}

final insightsProvider =
    StateNotifierProvider<InsightsController, InsightsState>(
      (ref) => InsightsController(ref),
    );

class InsightsController extends StateNotifier<InsightsState> {
  InsightsController(this._ref) : super(const InsightsState());

  final Ref _ref;

  void setHindi(bool v) {
    if (state.hindi == v) return;
    state = InsightsState(
      entries: state.entries,
      hindi: v,
      generatingAll: state.generatingAll,
    );
  }

  void reset() => state = const InsightsState();

  /// Generates one mode. Guards against duplicate concurrent requests.
  Future<void> generate(InsightMode mode, AnalysisResult r) async {
    final cur = state.entry(mode);
    if (cur.status == InsightStatus.loading || state.generatingAll) {
      return;
    }
    state = InsightsState(
      entries: {
        ...state.entries,
        mode: cur.copyWith(status: InsightStatus.loading),
      },
      hindi: state.hindi,
      generatingAll: state.generatingAll,
    );
    try {
      final text = await _ref
          .read(aiRepoProvider)
          .insights(prompt: insightPrompt(mode, r, hindi: state.hindi));
      if (!mounted) return;
      state = InsightsState(
        entries: {
          ...state.entries,
          mode: InsightEntry(status: InsightStatus.ready, text: text),
        },
        hindi: state.hindi,
        generatingAll: state.generatingAll,
      );
    } catch (e) {
      if (!mounted) return;
      state = InsightsState(
        entries: {
          ...state.entries,
          mode: InsightEntry(status: InsightStatus.error, text: '$e'),
        },
        hindi: state.hindi,
        generatingAll: state.generatingAll,
      );
    }
  }

  /// Sequential generation of every mode. Single-flight guarded.
  Future<void> generateAll(AnalysisResult r) async {
    if (state.generatingAll) return;
    state = InsightsState(
      entries: state.entries,
      hindi: state.hindi,
      generatingAll: true,
    );
    for (final mode in InsightMode.values) {
      final cur = state.entry(mode);
      state = InsightsState(
        entries: {
          ...state.entries,
          mode: cur.copyWith(status: InsightStatus.loading),
        },
        hindi: state.hindi,
        generatingAll: true,
      );
      try {
        final text = await _ref
            .read(aiRepoProvider)
            .insights(prompt: insightPrompt(mode, r, hindi: state.hindi));
        if (!mounted) return;
        final after = state.entry(mode);
        state = InsightsState(
          entries: {
            ...state.entries,
            mode: after.copyWith(status: InsightStatus.ready, text: text),
          },
          hindi: state.hindi,
          generatingAll: true,
        );
      } catch (e) {
        if (!mounted) return;
        final after = state.entry(mode);
        state = InsightsState(
          entries: {
            ...state.entries,
            mode: after.copyWith(status: InsightStatus.error, text: '$e'),
          },
          hindi: state.hindi,
          generatingAll: true,
        );
      }
    }
    if (!mounted) return;
    state = InsightsState(
      entries: state.entries,
      hindi: state.hindi,
      generatingAll: false,
    );
  }
}
