import 'package:flutter/material.dart';

import 'liquid_glass.dart';

/// About block rebuilt from scratch in liquid glass: the full
/// editorial copy on one frosted panel, glass index chips for the
/// steps, hairline separators throughout. Copy is unchanged.
class HomeInfoSection extends StatelessWidget {
  const HomeInfoSection({super.key});

  static const _steps = [
    'Enter your GitHub, LeetCode, or Codeforces username',
    'DevIQ fetches your repositories, solved problems, ratings, and contributions',
    'Get an instant developer score out of 100 with detailed breakdowns',
    'See which developer roles fit your skill profile',
    'Receive AI-generated insights and a 7-day improvement plan',
  ];

  static const _platforms = [
    ('GitHub', 'Repository analysis, language distribution, stars, forks, contribution heatmap, streak tracking, and coding hour patterns.'),
    ('LeetCode', 'Total problems solved (easy, medium, hard), contest rating, global ranking, and badges.'),
    ('Codeforces', 'Current and max rating, rank, problems solved, contests participated, and contribution score.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: secondary,
      height: 1.65,
      fontSize: 14.5,
    );
    final h2 = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01,
      fontSize: 20,
      height: 1.25,
    );
    final h3 = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    return LiquidGlass(
      blur: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is DevIQ?', style: h2),
          const SizedBox(height: 12),
          Text(
            'DevIQ is a free developer analytics platform that measures your coding profile across GitHub, LeetCode, and Codeforces. Get a unified developer score, discover which role fits you best, track your progress over time, and receive AI-powered improvement plans.',
            style: body,
          ),
          const SizedBox(height: 28),
          Text('How it works', style: h3),
          const SizedBox(height: 6),
          for (var i = 0; i < _steps.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: LiquidGlassTokens.edge(
                      theme.brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiquidGlass(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    borderRadius: 8,
                    blur: 8,
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child:
                          Text(_steps[i], style: body?.copyWith(height: 1.55)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Text('Supported platforms', style: h3),
          const SizedBox(height: 6),
          for (final (name, desc) in _platforms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text.rich(
                TextSpan(
                  style: body,
                  children: [
                    TextSpan(
                      text: '$name  ',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: desc),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text('Developer role detection', style: h3),
          const SizedBox(height: 10),
          Text(
            'DevIQ scans your repository names, descriptions, topics, and language distribution to suggest matching roles:',
            style: body,
          ),
          const SizedBox(height: 10),
          Text(
            'Frontend Developer, Backend Developer, Full-Stack Developer, Mobile Developer, Application Developer, ML/Data Engineer, DevOps/Cloud Engineer, Game Developer, Security Engineer, Embedded/IoT Developer, Blockchain Developer, and Competitive Programmer.',
            style: body,
          ),
        ],
      ),
    );
  }
}
