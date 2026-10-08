import 'package:go_router/go_router.dart';

import '../features/prayers/presentation/prayer_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const PrayerListScreen(),
    ),
  ],
);
