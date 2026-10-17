import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Persistent bottom navigation around every routed screen.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

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
      label: 'Read',
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
    (
      path: '/settings',
      label: 'Settings',
      tooltip: 'Settings',
      icon: Symbols.settings,
    ),
  ];

  static int indexForLocation(String location) {
    if (location.startsWith('/read-pray')) return 1;
    if (location.startsWith('/silence')) return 2;
    if (location.startsWith('/liturgy')) return 3;
    if (location.startsWith('/settings') || location.startsWith('/metrics')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          final path = _destinations[index].path;
          if (index == selected && location == path) return;
          context.go(path);
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
