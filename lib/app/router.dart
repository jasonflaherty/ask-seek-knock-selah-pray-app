import 'package:go_router/go_router.dart';

import '../features/prayers/presentation/add_edit_prayer_screen.dart';
import '../features/prayers/presentation/prayer_detail_screen.dart';
import '../features/prayers/presentation/prayer_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const PrayerListScreen(),
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
);
