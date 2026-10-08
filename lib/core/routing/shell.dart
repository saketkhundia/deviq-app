import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_nav.dart';

/// Shell hosting the 5 primary tabs + custom bottom nav + header.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _ids = ['home', 'analyze', 'compare', 'play', 'more'];

  String get _active {
    final i = shell.currentIndex.clamp(0, _ids.length - 1);
    return _ids[i];
  }

  void _onTab(BuildContext context, String id) {
    if (id == 'more') {
      showModalBottomSheet(
          context: context, builder: (_) => const MoreSheet());
      return;
    }
    if (id == 'play') {
      shell.goBranch(3);
      return;
    }
    shell.goBranch(_ids.indexOf(id).clamp(0, 3));
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
