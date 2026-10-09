import 'github_models.dart';

/// File-tree entry from GET /repo-tree/{owner}/{repo}.
/// Backend returns a flat entry list: {path, type} where type is
/// 'blob' (file) or 'tree' (directory). Hierarchy is rebuilt client-side.
class RepoEntry {
  const RepoEntry({required this.path, required this.isDir});

  final String path;
  final bool isDir;

  String get name => path.split('/').last;

  factory RepoEntry.fromJson(Map<String, dynamic> j) {
    final type = parseString(j['type']).toLowerCase();
    return RepoEntry(
      path: parseString(j['path']),
      isDir: type == 'tree' || type == 'dir' || type == 'directory',
    );
  }
}

class RepoTree {
  const RepoTree({
    required this.owner,
    required this.repo,
    required this.branch,
    required this.truncated,
    required this.totalFiles,
    required this.totalDirs,
    required this.entries,
  });

  final String owner;
  final String repo;
  final String branch;
  final bool truncated;
  final int totalFiles;
  final int totalDirs;
  final List<RepoEntry> entries;

  factory RepoTree.fromJson(Map<String, dynamic> j) => RepoTree(
    owner: parseString(j['owner']),
    repo: parseString(j['repo']),
    branch: parseString(j['branch'] ?? j['default_branch']),
    truncated: j['truncated'] == true,
    totalFiles: parseInt(j['total_files']),
    totalDirs: parseInt(j['total_dirs']),
    entries: asList(j['entries'])
        .whereType<Map<String, dynamic>>()
        .map(RepoEntry.fromJson)
        .where((e) => e.path.isNotEmpty)
        .toList(),
  );

  /// Builds a nested directory structure from flat slash paths.
  TreeNode get root {
    final root = TreeNode(name: '', isDir: true);
    final sorted = entries.toList()..sort((a, b) => a.path.compareTo(b.path));
    for (final e in sorted) {
      final parts = e.path.split('/');
      var node = root;
      for (var i = 0; i < parts.length; i++) {
        final last = i == parts.length - 1;
        final existing = node.child(parts[i]);
        if (existing != null) {
          node = existing;
        } else {
          final created = TreeNode(
            name: parts[i],
            isDir: last ? e.isDir : true,
          );
          node.children.add(created);
          node = created;
        }
      }
    }
    root.sort();
    return root;
  }
}

/// Client-side tree node for the explorer UI.
class TreeNode {
  TreeNode({required this.name, required this.isDir});

  final String name;
  final bool isDir;
  final List<TreeNode> children = [];

  TreeNode? child(String name) {
    for (final c in children) {
      if (c.name == name) return c;
    }
    return null;
  }

  void sort() {
    children.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    for (final c in children) {
      c.sort();
    }
  }
}
