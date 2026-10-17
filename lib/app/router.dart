import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/liturgy/presentation/liturgy_screen.dart';
import '../features/metrics/presentation/metrics_screen.dart';
import '../features/prayers/presentation/add_edit_prayer_screen.dart';
import '../features/prayers/presentation/prayer_detail_screen.dart';
import '../features/prayers/presentation/prayer_list_screen.dart';
import '../features/reading/presentation/read_pray_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/silence/presentation/silence_screen.dart';
import 'app_shell.dart';

/// Navigator for screens under the bottom bar.
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const PrayerListScreen(),
        ),
        GoRoute(
          path: '/silence',
          name: 'silence',
          builder: (context, state) => const SilenceScreen(),
        ),
        GoRoute(
          path: '/read-pray',
          name: 'read-pray',
          builder: (context, state) => const ReadPrayScreen(),
        ),
        GoRoute(
          path: '/liturgy',
          name: 'liturgy',
          builder: (context, state) => const LiturgyScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/metrics',
          name: 'metrics',
          builder: (context, state) => const MetricsScreen(),
        ),
        GoRoute(
          path: '/prayers/new',
          name: 'prayer-new',
          builder: (context, state) => const AddEditPrayerScreen(),
        ),
        GoRoute(
          path: '/prayers/:id',
          name: 'prayer-detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PrayerDetailScreen(prayerId: id);
          },
        ),
        GoRoute(
          path: '/prayers/:id/edit',
          name: 'prayer-edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AddEditPrayerScreen(prayerId: id);
          },
        ),
      ],
    ),
  ],
);
