import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/reading/data/morning_reminder.dart';
import 'app_config.dart';
import 'router.dart';
import 'theme.dart';

class SelahApp extends ConsumerStatefulWidget {
  const SelahApp({super.key});

  @override
  ConsumerState<SelahApp> createState() => _SelahAppState();
}

class _SelahAppState extends ConsumerState<SelahApp> {
  @override
  void initState() {
    super.initState();
    MorningReminder.onOpened = () => appRouter.go('/read-pray');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(morningReminderProvider).openIfLaunchedFromReminder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
