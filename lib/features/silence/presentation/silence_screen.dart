import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../application/silence_session_notifier.dart';
import '../application/silence_session_state.dart';
import '../domain/silence_duration.dart';
import '../domain/silence_name_pace.dart';
import 'fading_petition_name.dart';

class SilenceScreen extends ConsumerWidget {
  const SilenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(silenceSessionProvider);
    final notifier = ref.read(silenceSessionProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        if (ref.read(silenceSessionProvider).isRunning) {
          notifier.stop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Prayer timer',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.maxContentWidth,
              ),
              child: session.isRunning
                  ? _RunningView(
                      session: session,
                      onStop: () {
                        notifier.stop();
                      },
                      onSkip: notifier.skipName,
                      onFaster: notifier.decreasePace,
                      onSlower: notifier.increasePace,
                    )
                  : _SetupView(
                      minutes: session.durationMinutes,
                      paceSeconds: session.paceSeconds,
                      onDecrease: notifier.decreaseDuration,
                      onIncrease: notifier.increaseDuration,
                      onFaster: notifier.decreasePace,
                      onSlower: notifier.increasePace,
                      onStart: () {
                        notifier.start();
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.minutes,
    required this.paceSeconds,
    required this.onDecrease,
    required this.onIncrease,
    required this.onFaster,
    required this.onSlower,
    required this.onStart,
  });

  final int minutes;
  final int paceSeconds;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onFaster;
  final VoidCallback onSlower;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canDecrease = SilenceDuration.canDecrease(minutes);
    final canIncrease = SilenceDuration.canIncrease(minutes);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'Sit in silence.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppTheme.scriptureFont,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Decrease by 5 minutes',
                onPressed: canDecrease ? onDecrease : null,
                icon: const Icon(Symbols.remove),
                constraints: const BoxConstraints(
                  minWidth: AppTheme.minTapTarget,
                  minHeight: AppTheme.minTapTarget,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$minutes min',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase by 5 minutes',
                onPressed: canIncrease ? onIncrease : null,
                icon: const Icon(Symbols.add),
                constraints: const BoxConstraints(
                  minWidth: AppTheme.minTapTarget,
                  minHeight: AppTheme.minTapTarget,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Names',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _PaceControls(
            paceSeconds: paceSeconds,
            onFaster: onFaster,
            onSlower: onSlower,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: const Text('Start'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    required this.session,
    required this.onStop,
    required this.onSkip,
    required this.onFaster,
    required this.onSlower,
  });

  final SilenceSessionState session;
  final VoidCallback onStop;
  final VoidCallback onSkip;
  final VoidCallback onFaster;
  final VoidCallback onSlower;

  String get _remainingLabel {
    final totalSeconds = session.remaining.inSeconds;
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSkip = session.names.length > 1;
    final nameWidget = FadingPetitionName(
      name: session.currentName,
      fadeDuration: session.nameFade,
    );

    return Padding(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            label: 'Time remaining $_remainingLabel',
            child: Text(
              _remainingLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: canSkip
                  ? Semantics(
                      button: true,
                      label: session.currentName == null
                          ? 'Next name'
                          : 'Next name, currently ${session.currentName}',
                      child: InkWell(
                        onTap: onSkip,
                        borderRadius: BorderRadius.circular(
                          AppTheme.controlRadius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: nameWidget,
                        ),
                      ),
                    )
                  : nameWidget,
            ),
          ),
          _PaceControls(
            paceSeconds: session.paceSeconds,
            onFaster: onFaster,
            onSlower: onSlower,
          ),
          const SizedBox(height: 8),
          if (canSkip) ...[
            TextButton(
              onPressed: onSkip,
              child: const Text('Next name'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: onStop,
            child: const Text('Stop'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PaceControls extends StatelessWidget {
  const _PaceControls({
    required this.paceSeconds,
    required this.onFaster,
    required this.onSlower,
  });

  final int paceSeconds;
  final VoidCallback onFaster;
  final VoidCallback onSlower;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canFaster = SilenceNamePace.canDecrease(paceSeconds);
    final canSlower = SilenceNamePace.canIncrease(paceSeconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Faster names',
          onPressed: canFaster ? onFaster : null,
          icon: const Icon(Symbols.fast_forward),
          constraints: const BoxConstraints(
            minWidth: AppTheme.minTapTarget,
            minHeight: AppTheme.minTapTarget,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Semantics(
            liveRegion: true,
            label: '$paceSeconds seconds per name',
            child: Text(
              '$paceSeconds s each',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Slower names',
          onPressed: canSlower ? onSlower : null,
          icon: const Icon(Symbols.slow_motion_video),
          constraints: const BoxConstraints(
            minWidth: AppTheme.minTapTarget,
            minHeight: AppTheme.minTapTarget,
          ),
        ),
      ],
    );
  }
}
