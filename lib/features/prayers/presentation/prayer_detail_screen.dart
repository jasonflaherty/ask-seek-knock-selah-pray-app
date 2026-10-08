import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../domain/prayer.dart';
import '../domain/prayer_event.dart';

class PrayerDetailScreen extends ConsumerStatefulWidget {
  const PrayerDetailScreen({super.key, required this.prayerId});

  final int prayerId;

  @override
  ConsumerState<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends ConsumerState<PrayerDetailScreen> {
  Prayer? _prayer;
  bool _loading = true;
  bool _justPrayed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prayer =
        await ref.read(prayerRepositoryProvider).getPrayer(widget.prayerId);
    if (mounted) {
      setState(() {
        _prayer = prayer;
        _loading = false;
      });
    }
  }

  Future<void> _prayed() async {
    await ref
        .read(prayerRepositoryProvider)
        .logEvent(widget.prayerId, PrayerEventType.prayed);
    HapticFeedback.lightImpact();
    setState(() => _justPrayed = true);
    await _load();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justPrayed = false);
  }

  Future<void> _toggleAnswered() async {
    final prayer = _prayer;
    if (prayer == null) return;

    if (!prayer.isAnswered) {
      final note = await _promptAnsweredNote();
      if (note == null || !mounted) return;
      await ref.read(prayerRepositoryProvider).setAnswered(
            widget.prayerId,
            answered: true,
            note: note.isEmpty ? null : note,
          );
      if (mounted) {
        announceForAccessibility(context, 'Marked answered');
      }
    } else {
      await ref
          .read(prayerRepositoryProvider)
          .setAnswered(widget.prayerId, answered: false);
    }
    await _load();
  }

  Future<String?> _promptAnsweredNote() async {
    final controller = TextEditingController();
    final result = await showDialog<Object>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark answered'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'How did God answer? (optional)',
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == false || result == null) return null;
    return result as String;
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete prayer?'),
        content: const Text('This cannot be undone from here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(prayerRepositoryProvider).deletePrayer(widget.prayerId);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prayer = _prayer;
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(prayer?.name ?? 'Prayer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : prayer == null
              ? const Center(child: Text('Prayer not found'))
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.maxContentWidth,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            prayer.name,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ),
                        if (prayer.isAnswered) ...[
                          const SizedBox(height: 12),
                          const _AnsweredBadge(),
                        ],
                        const SizedBox(height: 16),
                        Text(prayer.request, style: theme.textTheme.bodyLarge),
                        if (prayer.tags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in prayer.tags)
                                Chip(label: Text(tag)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            'Verses',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (prayer.verseIds.isEmpty)
                          Text(
                            'No verses selected yet.',
                            style: theme.textTheme.bodyMedium,
                          )
                        else
                          Text(
                            '${prayer.verseIds.length} verse(s) selected. Full text arrives in Phase 3.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 24),
                        Text(
                          [
                            'Added ${dateFmt.format(prayer.createdAt)}',
                            if (prayer.lastPrayedAt != null)
                              'Last prayed ${dateFmt.format(prayer.lastPrayedAt!)}'
                            else
                              'Not prayed yet',
                            'Viewed ${prayer.timesViewed} times',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _prayed,
                          icon: Icon(
                            _justPrayed ? Icons.check : Icons.favorite_outline,
                          ),
                          label: Text(_justPrayed ? 'Prayed' : 'I prayed'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () async {
                            await context.push('/prayers/${prayer.id}/edit');
                            await _load();
                          },
                          child: const Text('Edit'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _toggleAnswered,
                          child: Text(
                            prayer.isAnswered
                                ? 'Mark unanswered'
                                : 'Mark answered',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _delete,
                          child: Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _AnsweredBadge extends StatelessWidget {
  const _AnsweredBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.answeredBadgeBg,
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: palette.answeredBadgeFg,
            ),
            const SizedBox(width: 6),
            Text(
              'Answered',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: palette.answeredBadgeFg),
            ),
          ],
        ),
      ),
    );
  }
}
