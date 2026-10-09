import 'package:flutter/material.dart';

/// Informational sections mirroring the web reference copy and hierarchy:
/// large "What is DevIQ?" heading, medium sub-headings, indented steps,
/// and a platforms paragraph with bold names.
class HomeInfoSection extends StatelessWidget {
  const HomeInfoSection({super.key});

  static const _steps = [
    'Enter your GitHub, LeetCode, or Codeforces username',
    'DevIQ fetches your repositories, solved problems, ratings, and contributions',
    'Get an instant developer score out of 100 with detailed breakdowns',
    'See which developer roles fit your skill profile',
    'Receive AI-generated insights and a 7-day improvement plan',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.secondary,
      height: 1.65,
    );
    final h2 = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.01,
    );
    final h3 = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is DevIQ?', style: h2),
        const SizedBox(height: 12),
        Text(
          'DevIQ is a free developer analytics platform that measures your coding profile across GitHub, LeetCode, and Codeforces. Get a unified developer score, discover which role fits you best, track your progress over time, and receive AI-powered improvement plans.',
          style: body,
        ),
        const SizedBox(height: 24),
        Text('How it works', style: h3),
        const SizedBox(height: 10),
        for (final s in _steps)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(s, style: body),
          ),
        const SizedBox(height: 16),
        Text('Supported Platforms', style: h3),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: body,
            children: [
              _b(theme, 'GitHub'),
              TextSpan(
                text: ' — Repository analysis, language distribution, stars, forks, contribution heatmap, streak tracking, and coding hour patterns. ',
              ),
              _b(theme, 'LeetCode'),
              TextSpan(
                text: ' — Total problems solved (easy, medium, hard), contest rating, global ranking, and badges. ',
              ),
              _b(theme, 'Codeforces'),
              const TextSpan(
                text: ' — Current and max rating, rank, problems solved, contests participated, and contribution score.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Developer Role Detection', style: h3),
        const SizedBox(height: 10),
        Text(
          'DevIQ scans your repository names, descriptions, topics, and language distribution to suggest matching roles:',
          style: body,
        ),
        const SizedBox(height: 8),
        Text(
          'Frontend Developer, Backend Developer, Full-Stack Developer, Mobile Developer, Application Developer, ML/Data Engineer, DevOps/Cloud Engineer, Game Developer, Security Engineer, Embedded/IoT Developer, Blockchain Developer, and Competitive Programmer.',
          style: body,
        ),
      ],
    );
  }

  TextSpan _b(ThemeData theme, String text) => TextSpan(
    text: text,
    style: TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}
