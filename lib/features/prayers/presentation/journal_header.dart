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
    this.onRotate,
  });

  final String text;
  final String ref;
  final VoidCallback? onRotate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: context.palette.verseSurface,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '"$text"',
              textAlign: TextAlign.center,
              style: AppTheme.scripture(theme.colorScheme.onSurface)
                  .copyWith(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '— $ref',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (onRotate != null)
                IconButton(
                  tooltip: 'Show another verse',
                  onPressed: onRotate,
                  icon: Icon(
                    Icons.autorenew,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
