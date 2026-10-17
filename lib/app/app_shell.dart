import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'router.dart';

/// Persistent bottom navigation around every routed screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations =
      <({String path, String label, String tooltip, IconData icon})>[
    (
      path: '/',
      label: 'Journal',
      tooltip: 'Journal',
      icon: Symbols.menu_book,
    ),
    (
      path: '/read-pray',
      label: '10/10',
      tooltip: 'Read and pray',
      icon: Symbols.auto_stories,
    ),
    (
      path: '/silence',
      label: 'Timer',
      tooltip: 'Prayer timer',
      icon: Symbols.timer,
    ),
    (
      path: '/liturgy',
      label: 'Liturgy',
      tooltip: 'Liturgical prayers',
      icon: Symbols.folded_hands,
    ),
  ];

  /// Last main tab, kept when visiting Settings / Metrics / prayer detail.
  int _lastMainIndex = 0;

  static int? mainIndexForLocation(String location) {
    if (location.startsWith('/read-pray')) return 1;
    if (location.startsWith('/silence')) return 2;
    if (location.startsWith('/liturgy')) return 3;
    if (location == '/' || location.startsWith('/prayers')) return 0;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final mainIndex = mainIndexForLocation(location);
    if (mainIndex != null) {
      _lastMainIndex = mainIndex;
    }
    final selected = mainIndex ?? _lastMainIndex;

    return Scaffold(
      body: NavigatorPopHandler(
        onPopWithResult: (result) {
          shellNavigatorKey.currentState?.maybePop(result);
        },
        child: PopScope(
          // Keep the shell on screen when the journal is the only route.
          canPop: false,
          child: widget.child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          final path = _destinations[index].path;
          if (location == path) return;
          context.push(path);
        },
        destinations: [
          for (final dest in _destinations)
            NavigationDestination(
              icon: Icon(dest.icon),
              label: dest.label,
              tooltip: dest.tooltip,
            ),
        ],
      ),
    );
  }
}
