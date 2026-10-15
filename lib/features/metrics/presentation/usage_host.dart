import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/metrics_providers.dart';
import '../application/usage_tracker.dart';

/// Starts and stops foreground timing for the whole app.
class UsageHost extends ConsumerStatefulWidget {
  const UsageHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsageHost> createState() => _UsageHostState();
}

class _UsageHostState extends ConsumerState<UsageHost>
    with WidgetsBindingObserver {
  UsageTracker? _tracker;

  UsageTracker _trackerOf() {
    final existing = _tracker;
    if (existing != null) return existing;
    final created = ref.read(usageTrackerProvider);
    _tracker = created;
    return created;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        _resume();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final tracker = _tracker;
    if (tracker != null) {
      unawaited(tracker.onBackgrounded());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resume();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pause();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _resume() {
    unawaited(_trackerOf().onResumed());
  }

  void _pause() {
    unawaited(_trackerOf().onBackgrounded());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
