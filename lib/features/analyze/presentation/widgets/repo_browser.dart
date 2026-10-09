import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/deviq_colors.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/models/github_models.dart';
import '../../../../data/models/repo_models.dart';
import '../../../../shared/widgets/deviq_widgets.dart';
import '../../../app/providers/app_providers.dart';

enum _Sort { stars, updated, name }

/// Repository browser mirroring the web reference: count + stars header
/// pills, search with inline sort selector, language chips with counts,
/// and rich repo cards with an expandable bounded tree explorer.
/// Pagination ("show more") keeps long lists cheap without nesting
/// scrollables inside the page scroll.
class RepositoryBrowser extends ConsumerStatefulWidget {
  const RepositoryBrowser({super.key, required this.github});

  final GithubStats github;

  @override
  ConsumerState<RepositoryBrowser> createState() => _RepositoryBrowserState();
}

class _RepositoryBrowserState extends ConsumerState<RepositoryBrowser> {
  final _search = TextEditingController();
  _Sort _sort = _Sort.stars;
  String _lang = 'All';
  int _shown = 9;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GithubRepo> _filtered() {
    final q = _search.text.trim().toLowerCase();
    var list = widget.github.repositories.where((r) {
      if (_lang != 'All' && r.language != _lang) return false;
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.topics.any((t) => t.toLowerCase().contains(q));
    }).toList();
    switch (_sort) {
      case _Sort.stars:
        list.sort((a, b) => b.stars.compareTo(a.stars));
      case _Sort.updated:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _Sort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return list;
  }

  String _sortLabel() => switch (_sort) {
    _Sort.stars => 'Top starred',
    _Sort.updated => 'Recently updated',
    _Sort.name => 'Name A–Z',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dist = widget.github.languageDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final list = _filtered();
    final visible = list.take(_shown).toList();
    return DevIQCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'REPOSITORIES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                _CountPill(
                  text: Formatters.integer(widget.github.totalProjects),
                ),
                _CountPill(
                  text:
                      '★ ${Formatters.integer(widget.github.totalStars)} stars',
                  accent: DevIQColors.warning,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() => _shown = 9),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search repositories…',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                _SortMenu(
                  label: _sortLabel(),
                  value: _sort,
                  onPick: (v) => setState(() => _sort = v),
                ),
                if (dist.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _LangChip(
                          label: 'All',
                          selected: _lang == 'All',
                          onTap: () => setState(() {
                            _lang = 'All';
                            _shown = 9;
                          }),
                        ),
                        for (final e in dist)
                          _LangChip(
                            label: e.key,
                            count: e.value,
                            selected: _lang == e.key,
                            onTap: () => setState(() {
                              _lang = e.key;
                              _shown = 9;
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visible.isEmpty)
                  EmptyState(
                    icon: Icons.folder_outlined,
                    title: 'No repositories match',
                    message: _search.text.trim().isEmpty
                        ? 'Try a different language filter.'
                        : 'No repositories match "${_search.text.trim()}".',
                  )
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth > 700
                          ? 3
                          : (c.maxWidth > 460 ? 2 : 1);
                      if (cols == 1) {
                        return Column(
                          children: [
                            for (var i = 0; i < visible.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == visible.length - 1 ? 0 : 10,
                                ),
                                child: RepositoryCard(repo: visible[i]),
                              ),
                          ],
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 218,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (context, i) =>
                            RepositoryCard(repo: visible[i]),
                      );
                    },
                  ),
                if (list.length > visible.length) ...[
                  const SizedBox(height: 10),
                  DevIQSecondaryButton(
                    label: 'Show more (${list.length - visible.length} left)',
                    icon: Icons.expand_more,
                    onPressed: () => setState(
                      () => _shown = (_shown + 18).clamp(0, list.length),
                    ),
                  ),
                ],
                if (_search.text.trim().isNotEmpty || _lang != 'All') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${list.length} of ${widget.github.repositories.length} shown',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.text, this.accent});

  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = accent ?? theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DevIQRadius.pill),
        border: Border.all(color: a.withValues(alpha: 0.35)),
        color: a.withValues(alpha: 0.08),
      ),
      child: Text(
        text,
        style: TextStyle(color: a, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final _Sort value;
  final ValueChanged<_Sort> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_Sort>(
      initialValue: value,
      onSelected: onPick,
      tooltip: 'Sort repositories',
      itemBuilder: (context) => const [
        PopupMenuItem(value: _Sort.stars, child: Text('Top starred')),
        PopupMenuItem(value: _Sort.updated, child: Text('Recently updated')),
        PopupMenuItem(value: _Sort.name, child: Text('Name A–Z')),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(DevIQRadius.button),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DevIQRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(DevIQRadius.pill),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : _langDot(label),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                count == null ? label : '$label  $count',
                style: TextStyle(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _langDot(String lang) {
    switch (lang.toLowerCase()) {
      case 'kotlin':
        return DevIQColors.codeforces;
      case 'java':
        return DevIQColors.warning;
      case 'python':
        return DevIQColors.github;
      case 'typescript':
      case 'javascript':
        return DevIQColors.github;
      case 'html':
        return const Color(0xFFF43F5E);
      case 'ruby':
        return const Color(0xFFF43F5E);
      case 'go':
        return const Color(0xFF22D3EE);
      case 'c':
      case 'c++':
        return const Color(0xFF737373);
      default:
        return DevIQColors.teal;
    }
  }
}

class RepositoryCard extends ConsumerStatefulWidget {
  const RepositoryCard({super.key, required this.repo});

  final GithubRepo repo;

  @override
  ConsumerState<RepositoryCard> createState() => _RepositoryCardState();
}

class _RepositoryCardState extends ConsumerState<RepositoryCard> {
  bool _open = false;
  RepoTree? _tree;
  String? _treeError;
  bool _treeLoading = false;

  Future<void> _toggle() async {
    final next = !_open;
    setState(() => _open = next);
    if (!next || _tree != null || _treeLoading) return;
    final parts = widget.repo.fullName.split('/');
    if (parts.length != 2) {
      setState(() => _treeError = 'Repository path unavailable.');
      return;
    }
    setState(() => _treeLoading = true);
    try {
      final tree = await ref
          .read(analysisRepoProvider)
          .repoTree(parts[0], parts[1]);
      if (mounted) {
        setState(() {
          _tree = tree;
          _treeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _treeError = '$e';
          _treeLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.repo;
    return DevIQCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DevIQColors.github.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: DevIQColors.github.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  size: 16,
                  color: DevIQColors.github,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (Formatters.timeAgo(r.updatedAt).isNotEmpty)
                      Text(
                        'Updated ${Formatters.timeAgo(r.updatedAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _open ? 'Hide files' : 'Browse files',
                onPressed: _toggle,
                icon: Icon(
                  _open ? Icons.folder_open_outlined : Icons.folder_outlined,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Open on GitHub',
                onPressed: r.htmlUrl.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(r.htmlUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                icon: Icon(
                  Icons.open_in_new,
                  size: 17,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (r.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
          if (r.topics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in r.topics.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: DevIQColors.github.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: DevIQColors.github,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              if (r.language.isNotEmpty) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: DevIQColors.codeforces,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    r.language,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              const Icon(Icons.star, size: 14, color: DevIQColors.warning),
              const SizedBox(width: 3),
              Text(
                Formatters.integer(r.stars),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.fork_right,
                size: 14,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 3),
              Text(
                Formatters.integer(r.forks),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            _TreeBody(
              loading: _treeLoading,
              error: _treeError,
              tree: _tree,
              onRetry: () {
                setState(() {
                  _treeError = null;
                  _tree = null;
                });
                _toggle();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Bounded file-tree explorer with its own scrolling — never grows the page.
class _TreeBody extends StatefulWidget {
  const _TreeBody({
    required this.loading,
    required this.error,
    required this.tree,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final RepoTree? tree;
  final VoidCallback onRetry;

  @override
  State<_TreeBody> createState() => _TreeBodyState();
}

class _TreeBodyState extends State<_TreeBody> {
  final _expanded = <String>{'/'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Builder(
        builder: (context) {
          if (widget.loading) {
            return const LoadingState(message: 'Loading file tree…');
          }
          if (widget.error != null) {
            return ErrorState(message: widget.error!, onRetry: widget.onRetry);
          }
          final root = widget.tree?.root;
          if (root == null || root.children.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_outlined,
              title: 'Empty tree',
              message: 'No files returned for this repository.',
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((widget.tree?.truncated ?? false))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Truncated preview.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                for (final c in root.children)
                  _NodeRow(
                    node: c,
                    depth: 0,
                    path: '/${c.name}',
                    expanded: _expanded,
                    onToggle: (p) => setState(() {
                      if (_expanded.contains(p)) {
                        _expanded.remove(p);
                      } else {
                        _expanded.add(p);
                      }
                    }),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.node,
    required this.depth,
    required this.path,
    required this.expanded,
    required this.onToggle,
  });

  final TreeNode node;
  final int depth;
  final String path;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = expanded.contains(path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: node.isDir ? () => onToggle(path) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: EdgeInsets.only(
              left: depth * 14.0,
              top: 4,
              bottom: 4,
              right: 4,
            ),
            child: Row(
              children: [
                Icon(
                  node.isDir
                      ? (open
                            ? Icons.folder_open_outlined
                            : Icons.folder_outlined)
                      : Icons.description_outlined,
                  size: 15,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (node.isDir && open)
          for (final c in node.children)
            _NodeRow(
              node: c,
              depth: depth + 1,
              path: '$path/${c.name}',
              expanded: expanded,
              onToggle: onToggle,
            ),
      ],
    );
  }
}
