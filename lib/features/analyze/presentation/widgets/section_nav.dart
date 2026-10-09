import 'package:flutter/material.dart';

import '../../../../shared/widgets/deviq_widgets.dart';

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

/// Horizontally scrollable section chips. Tapping scrolls the page to
/// the matching section (handled by the screen via [onSelect]).
class SectionNav extends StatelessWidget {
  const SectionNav({super.key, required this.onSelect});

  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < analyzeSections.length; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == analyzeSections.length - 1 ? 0 : 8,
            ),
            child: DevIQPill(
              label: analyzeSections[i].label,
              onTap: () => onSelect(analyzeSections[i].id),
            ),
          ),
      ],
    ),
  );
}
