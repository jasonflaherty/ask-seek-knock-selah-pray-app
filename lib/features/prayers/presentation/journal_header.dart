import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';

/// Journal masthead matching the Selah PDF summary layout.
class JournalHeader extends StatelessWidget {
  const JournalHeader({
    super.key,
    required this.activeCount,
    required this.answeredCount,
  });

  final int activeCount;
  final int answeredCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = DateFormat.yMMMM().format(DateTime.now()).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'S E L A H',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PRAYER JOURNAL & MEDITATION SUMMARY',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          month,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 14),
        Text(
          'Active Petitions: $activeCount  ·  Answered: $answeredCount',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class JournalMeditationVerse extends StatelessWidget {
  const JournalMeditationVerse({
    super.key,
    required this.text,
    required this.ref,
  });

  final String text;
  final String ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.verseSurface,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            '"$text"',
            textAlign: TextAlign.center,
            style: AppTheme.scripture(theme.colorScheme.onSurface)
                .copyWith(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            '— $ref',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
