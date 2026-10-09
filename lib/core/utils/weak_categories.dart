/// Weak-category estimation for Interview Prep.
///
/// The backend exposes per-user difficulty totals but no per-topic
/// breakdown, so per-topic solved counts are *estimated* deterministically
/// by distributing the user's solved totals across topics in proportion
/// to each topic's difficulty composition. Topic totals below mirror the
/// web reference taxonomy. The UI captions the section as estimated —
/// percentages are directional, never server data.
class TopicStat {
  const TopicStat({
    required this.name,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  final String name;
  final int easy;
  final int medium;
  final int hard;

  int get total => easy + medium + hard;
}

const List<TopicStat> topicTable = [
  TopicStat(name: 'Graphs', easy: 8, medium: 16, hard: 16),
  TopicStat(name: 'Binary Search', easy: 8, medium: 12, hard: 5),
  TopicStat(name: 'Dynamic Programming', easy: 5, medium: 13, hard: 27),
  TopicStat(name: 'Linked Lists', easy: 10, medium: 15, hard: 5),
  TopicStat(name: 'Trees', easy: 15, medium: 25, hard: 10),
  TopicStat(name: 'Arrays & Hashing', easy: 20, medium: 30, hard: 10),
  TopicStat(name: 'Sliding Window', easy: 8, medium: 10, hard: 2),
  TopicStat(name: 'Strings', easy: 12, medium: 18, hard: 5),
];

class WeakCategory {
  const WeakCategory({
    required this.name,
    required this.solved,
    required this.total,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  final String name;
  final int solved;
  final int total;
  final int easy;
  final int medium;
  final int hard;

  double get percent => total == 0 ? 0 : solved / total * 100;
}

/// Estimates per-topic progress, weakest first (matching web order).
List<WeakCategory> estimateWeakCategories({
  required int easySolved,
  required int mediumSolved,
  required int hardSolved,
}) {
  final totalEasy = topicTable.fold<int>(0, (a, t) => a + t.easy);
  final totalMedium = topicTable.fold<int>(0, (a, t) => a + t.medium);
  final totalHard = topicTable.fold<int>(0, (a, t) => a + t.hard);
  final cats = topicTable.map((t) {
    var solved = 0;
    if (totalEasy > 0) {
      solved += (easySolved * t.easy / totalEasy).round();
    }
    if (totalMedium > 0) {
      solved += (mediumSolved * t.medium / totalMedium).round();
    }
    if (totalHard > 0) {
      solved += (hardSolved * t.hard / totalHard).round();
    }
    return WeakCategory(
      name: t.name,
      solved: solved.clamp(0, t.total),
      total: t.total,
      easy: t.easy,
      medium: t.medium,
      hard: t.hard,
    );
  }).toList();
  cats.sort((a, b) => a.percent.compareTo(b.percent));
  return cats;
}
