import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../groups/application/group_session_notifier.dart';
import '../application/read_pray_session_notifier.dart';
import '../domain/read_pray_phase.dart';
import 'study_notes_section.dart';

class ReadPrayScreen extends ConsumerWidget {
  const ReadPrayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(readPraySessionProvider);
    final notifier = ref.read(readPraySessionProvider.notifier);
    final inGroup =
        ref.watch(groupSessionProvider).session?.membership != null;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        if (session.running) notifier.stop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Read and pray',
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
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                children: [
                  _TimerCard(session: session, notifier: notifier),
                  if (inGroup) ...[
                    const SizedBox(height: 24),
                    const StudyNotesSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.session, required this.notifier});

  final ReadPraySessionState session;
  final ReadPraySessionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = session.remainingSeconds ~/ 60;
    final seconds = session.remainingSeconds % 60;
    final clock =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final title = switch (session.phase) {
      ReadPrayPhase.setup => 'Read, then pray',
      ReadPrayPhase.read => 'Read Scripture',
      ReadPrayPhase.pray => 'Pray',
      ReadPrayPhase.done => 'Finished',
    };
    final subtitle = switch (session.phase) {
      ReadPrayPhase.setup =>
        'Ten minutes to read Scripture, then ten minutes to pray.',
      ReadPrayPhase.read => 'Stay with the Word for ten minutes.',
      ReadPrayPhase.pray => 'Ask the Father according to His will.',
      ReadPrayPhase.done => 'You may stop here whenever you need to.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            if (session.phase == ReadPrayPhase.read ||
                session.phase == ReadPrayPhase.pray) ...[
              const SizedBox(height: 24),
              Text(
                clock,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium,
              ),
            ],
            const SizedBox(height: 24),
            if (session.phase == ReadPrayPhase.setup)
              FilledButton(
                onPressed: notifier.startReading,
                child: const Text('Start reading (10 min)'),
              )
            else if (session.phase == ReadPrayPhase.done)
              OutlinedButton(
                onPressed: notifier.stop,
                child: const Text('Close'),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          session.running ? notifier.pause : notifier.resume,
                      child: Text(session.running ? 'Pause' : 'Resume'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.stop,
                      child: const Text('Stop'),
                    ),
                  ),
                ],
              ),
              if (session.phase == ReadPrayPhase.read) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: notifier.skipToPray,
                  child: const Text('Skip to prayer'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
