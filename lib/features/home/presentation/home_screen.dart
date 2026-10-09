import 'package:flutter/material.dart';

import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/deviq_widgets.dart';
import 'widgets/feature_grid.dart';
import 'widgets/get_started_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_info.dart';
import 'widgets/score_preview.dart';

/// Home: hero → score preview → features → banner → info.
/// Thin assembly over focused section widgets; layout via [DevIQPage].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => DevIQPage(
    reserveNav: true,
    children: [
      const HomeHeroSection(),
      const SizedBox(height: 20),
      const DeveloperScorePreview(),
      const SizedBox(height: 24),
      const HomeDivider(),
      const SizedBox(height: 16),
      const DevIQSectionLabel('PLATFORM'),
      const SizedBox(height: 12),
      FeatureGrid(cards: buildFeatureCards()),
      const SizedBox(height: 24),
      const GetStartedBanner(),
      const SizedBox(height: 24),
      const HomeDivider(),
      const SizedBox(height: 16),
      const HomeInfoSection(),
    ],
  );
}
