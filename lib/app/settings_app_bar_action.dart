import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Settings gear for main-tab app bars.
class SettingsAppBarAction extends StatelessWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Symbols.settings),
      onPressed: () => context.push('/settings'),
    );
  }
}
