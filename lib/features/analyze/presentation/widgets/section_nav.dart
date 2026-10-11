import 'package:flutter/material.dart';

import '../../../../shared/widgets/liquid_glass.dart';

/// Analyze section destinations. Order matches the page top-to-bottom.
class AnalyzeSection {
  const AnalyzeSection({required this.id, required this.label});
  final String id;
  final String label;
}

const analyzeSections = [
  AnalyzeSection(id: 'score', label: 'Score'),
  AnalyzeSection(id: 'platforms', label: 'Platforms'),
  AnalyzeSection(id: 'ai', label: 'AI'),
  AnalyzeSection(id: 'activity', label: 'Activity'),
  AnalyzeSection(id: 'role', label: 'Role'),
  AnalyzeSection(id: 'repos', label: 'Repos'),
];

/// Horizontally scrollable frosted section chips. Tapping scrolls the
/// page to the matching section (handled by the screen via [onSelect]).
class SectionNav extends StatelessWidget {
  const SectionNav({super.key, required this.onSelect});

  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < analyzeSections.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == analyzeSections.length - 1 ? 0 : 8,
              ),
              child: GestureDetector(
                onTap: () => onSelect(analyzeSections[i].id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: dark
                          ? [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.04),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: LiquidGlassTokens.edge(dark)),
                  ),
                  child: Text(
                    analyzeSections[i].label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
