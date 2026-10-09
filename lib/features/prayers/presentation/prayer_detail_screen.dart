import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../../verses/domain/verse.dart';
import '../../verses/presentation/verse_picker_sheet.dart';
import '../application/prayer_share.dart';
import '../domain/prayer.dart';

class PrayerDetailScreen extends ConsumerStatefulWidget {
  const PrayerDetailScreen({super.key, required this.prayerId});

  final int prayerId;

  @override
  ConsumerState<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends ConsumerState<PrayerDetailScreen> {
  Prayer? _prayer;
  List<Verse> _verses = const [];
  bool _loading = true;
  bool _justPrayed = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prayer = await ref
        .read(prayerRepositoryProvider)
        .getPrayer(widget.prayerId);
    List<Verse> verses = const [];
    if (prayer != null) {
      verses = await ref.read(verseCatalogProvider).byIds(prayer.verseIds);
    }
    if (mounted) {
      setState(() {
        _prayer = prayer;
        _verses = verses;
        _loading = false;
      });
    }
  }

  Future<void> _prayed() async {
    await ref.read(eventLoggerProvider).prayed(widget.prayerId);
    HapticFeedback.lightImpact();
    setState(() => _justPrayed = true);
    await _load();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justPrayed = false);
  }

  Future<void> _share(String mode) async {
    final prayer = _prayer;
    if (prayer == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      const share = PrayerShare();
      if (mode == 'pdf') {
        await share.sharePdf(prayer, _verses);
      } else {
        await share.shareText(prayer, _verses);
      }
      if (mounted) {
        announceForAccessibility(context, 'Share sheet opened');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _toggleAnswered() async {
    final prayer = _prayer;
    if (prayer == null) return;

    if (!prayer.isAnswered) {
      final note = await _promptAnsweredNote();
      if (note == null || !mounted) return;
      await ref
          .read(prayerRepositoryProvider)
          .setAnswered(
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
      appBar: AppBar(
        title: Text(prayer?.name ?? 'Prayer'),
        actions: [
          if (prayer != null)
            PopupMenuButton<String>(
              tooltip: 'Share this prayer',
              enabled: !_sharing,
              icon: const Icon(Icons.share_outlined),
              onSelected: _share,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'text', child: Text('Share as text')),
                PopupMenuItem(value: 'pdf', child: Text('Share as PDF')),
              ],
            ),
        ],
      ),
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
                    const SizedBox(height: 8),
                    Text(
                      'Private on this device · share only when you choose',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (prayer.hasPerson) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'For ${prayer.person}',
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StatusChip(answered: prayer.isAnswered),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${prayer.request}"',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: AppTheme.scriptureFont,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                    ),
                    if (prayer.isAnswered &&
                        prayer.answeredNote != null &&
                        prayer.answeredNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.palette.answeredBadgeBg.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.chipRadius,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Praise Answer: ',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: context.palette.answeredBadgeFg,
                                ),
                              ),
                              TextSpan(
                                text: prayer.answeredNote!.trim(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (prayer.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in prayer.tags) Chip(label: Text(tag)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Verses',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final result = await showVersePickerSheet(
                              context: context,
                              requestText: prayer.request,
                              selectedIds: prayer.verseIds.toSet(),
                            );
                            if (result == null || !mounted) return;
                            await ref
                                .read(prayerRepositoryProvider)
                                .updatePrayer(
                                  prayer.id,
                                  PrayerUpdate(
                                    name: prayer.name,
                                    person: prayer.person,
                                    request: prayer.request,
                                    tags: prayer.tags,
                                    verseIds: result.toList(),
                                  ),
                                );
                            await _load();
                          },
                          child: const Text('Change verses'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_verses.isEmpty)
                      Text(
                        'No verses selected yet.',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      for (final verse in _verses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.palette.verseSurface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.controlRadius,
                              ),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  verse.ref,
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  verse.text,
                                  style: AppTheme.scripture(
                                    theme.colorScheme.onSurface,
                                  ),
                                ),
                                if (verse.note.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'NOTE: ${verse.note}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
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
                    OutlinedButton.icon(
                      onPressed: _sharing ? null : () => _share('text'),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share this prayer'),
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
                        prayer.isAnswered ? 'Mark unanswered' : 'Mark answered',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.answered});

  final bool answered;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final bg = answered ? palette.answeredBadgeBg : palette.selectedItemBg;
    final fg = answered ? palette.answeredBadgeFg : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (answered) ...[
            Icon(Icons.check, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            answered ? 'ANSWERED PRAISE' : 'ACTIVE PETITION',
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
