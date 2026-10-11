import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import '../../analyze/presentation/analyze_controller.dart';
import 'widgets/activity_fingerprint.dart';
import 'widgets/feature_grid.dart';
import 'widgets/get_started_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_info.dart';
import 'widgets/next_step.dart';
import 'widgets/skill_profile.dart';
import 'widgets/unified_score.dart';

/// Home — rebuilt from scratch in liquid glass.
///
/// Every instrument is a refractive frosted panel and every action is
/// glass, floating on a solid AMOLED black canvas. Structure is
/// unchanged: what DevIQ does (hero) → unified score → activity
/// fingerprint → skill profile → next step → tools → about.
/// Sections 01–04 render LIVE data only: the session analysis when
/// present, the last persisted analysis otherwise, and honest
/// onboarding states when nothing exists. No fabricated scores,
/// no sample heatmaps, no decorative charts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyze = ref.watch(analyzeProvider);
    final history = ref.watch(historyProvider);
    final result =
        analyze.status == AnalyzeStatus.success ? analyze.result : null;
    final live = (result != null && result.hasData) ? result : null;
    final last = history.isNotEmpty ? history.first : null;

    // Solid AMOLED black canvas: content keeps its padding, safe
    // areas, and bottom-nav clearance from DevIQPage — nothing is
    // obscured. Glass lenses carry their own luminosity, so no
    // ambient glow field sits behind them.
    return DevIQPage(
      reserveNav: true,
      topPadding: 28,
      maxWidth: 960,
      children: [
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 900) {
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: HomeHeroSection()),
                      SizedBox(width: 48),
                      Expanded(flex: 9, child: UnifiedScoreSection()),
                    ],
                  );
                }
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeroSection(),
                    SizedBox(height: 44),
                    UnifiedScoreSection(),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            const HomeDivider(),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: ActivityFingerprint(result: live),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 5,
                        child: SkillProfile(result: live, last: last),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActivityFingerprint(result: live),
                    const SizedBox(height: 40),
                    SkillProfile(result: live, last: last),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            const HomeDivider(),
            const SizedBox(height: 28),
            NextStepSection(
              result: live,
              last: last,
              failedPlatforms: analyze.failedPlatforms,
            ),
            const SizedBox(height: 48),
            const HomeDivider(),
            const SizedBox(height: 28),
            const DevIQSectionLabel('TOOLS'),
            const SizedBox(height: 16),
            FeatureList(entries: buildFeatureCards()),
            const SizedBox(height: 48),
            const GetStartedBanner(),
            const SizedBox(height: 48),
            const HomeDivider(),
            const SizedBox(height: 28),
            const HomeInfoSection(),
          ],
        );
  }
}
