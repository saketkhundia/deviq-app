import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_nav.dart';

/// Shell hosting the 4 primary tabs + custom bottom nav + header.
/// Tabs: Home · Analyze · Interview Prep · Ask AI. Everything else
/// (Compare, Playground, Review, …) lives in the More sheet or pushes.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _ids = ['home', 'analyze', 'interview', 'ai'];

  String get _active {
    final i = shell.currentIndex.clamp(0, _ids.length - 1);
    return _ids[i];
  }

  void _onTab(BuildContext context, String id) {
    if (id == 'more') {
      showModalBottomSheet(context: context, builder: (_) => const MoreSheet());
      return;
    }
    final index = _ids.indexOf(id);
    if (index >= 0) shell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const DevIQHeader(),
          Expanded(child: shell),
        ],
      ),
    ),
    bottomNavigationBar: DevIQBottomNav(
      active: _active,
      onTab: (id) => _onTab(context, id),
    ),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}
