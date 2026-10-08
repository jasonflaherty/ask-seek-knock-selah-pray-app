import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_config.dart';
import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../application/prayer_list_notifier.dart';
import '../application/prayer_list_state.dart';
import '../domain/prayer.dart';
import '../domain/sort_mode.dart';
import 'prayer_card.dart';
import 'sort_bar.dart';

class PrayerListScreen extends ConsumerWidget {
  const PrayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listState = ref.watch(prayerListProvider);
    final notifier = ref.read(prayerListProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final today = DateFormat.yMMMMEEEEd().format(DateTime.now());
    final items = notifier.displayItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onSelected: (mode) =>
                ref.read(themeModeProvider.notifier).setMode(mode),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: ThemeMode.system,
                checked: themeMode == ThemeMode.system,
                child: const Text('System'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.light,
                checked: themeMode == ThemeMode.light,
                child: const Text('Light'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.dark,
                checked: themeMode == ThemeMode.dark,
                child: const Text('Dark'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/prayers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add prayer'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPadding,
                    AppTheme.screenPadding,
                    AppTheme.screenPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('Today', style: theme.textTheme.headlineLarge),
                      ),
                      const SizedBox(height: 4),
                      Text(today, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      SegmentedButton<AnswerFilter>(
                        segments: const [
                          ButtonSegment(
                            value: AnswerFilter.active,
                            label: Text('Active'),
                          ),
                          ButtonSegment(
                            value: AnswerFilter.answered,
                            label: Text('Answered'),
                          ),
                          ButtonSegment(
                            value: AnswerFilter.all,
                            label: Text('All'),
                          ),
                        ],
                        selected: {listState.filter},
                        onSelectionChanged: (s) =>
                            notifier.setFilter(s.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 12),
                      SortBar(
                        selected: listState.sortMode,
                        onSelected: (mode) async {
                          await notifier.setSortMode(mode);
                          if (mode == SortMode.shuffle && context.mounted) {
                            announceForAccessibility(context, 'List shuffled');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: listState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : listState.prayers.isEmpty
                          ? _EmptyState(
                              onAdd: () => context.push('/prayers/new'),
                            )
                          : AnimatedSwitcher(
                              duration: motion(context),
                              child: ListView.builder(
                                key: ValueKey(
                                  '${listState.sortMode}-${listState.reshuffleCount}-${listState.filter}',
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.screenPadding,
                                  8,
                                  AppTheme.screenPadding,
                                  100,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return switch (item) {
                                    PrayerSectionHeader(:final title) => Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          bottom: 8,
                                        ),
                                        child: Semantics(
                                          header: true,
                                          child: Text(
                                            title,
                                            style: theme.textTheme.labelLarge,
                                          ),
                                        ),
                                      ),
                                    PrayerListEntry(:final prayer) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppTheme.cardGap,
                                        ),
                                        child: _SwipeablePrayerCard(
                                          prayer: prayer,
                                        ),
                                      ),
                                  };
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Nothing here yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add a prayer request and we will suggest promises to pray with it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAdd,
              child: const Text('Add your first prayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeablePrayerCard extends ConsumerWidget {
  const _SwipeablePrayerCard({required this.prayer});

  final Prayer prayer;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete prayer?'),
        content: Text('Delete “${prayer.name}”?'),
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
    if (ok != true || !context.mounted) return;

    final snapshot = NewPrayer(
      name: prayer.name,
      request: prayer.request,
      tags: prayer.tags,
      verseIds: prayer.verseIds,
    );
    final wasAnswered = prayer.isAnswered;
    final note = prayer.answeredNote;

    await ref.read(prayerRepositoryProvider).deletePrayer(prayer.id);
    if (!context.mounted) return;
    announceForAccessibility(context, 'Prayer deleted');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('Deleted “${prayer.name}”'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final id =
                await ref.read(prayerRepositoryProvider).createPrayer(snapshot);
            if (wasAnswered) {
              await ref.read(prayerRepositoryProvider).setAnswered(
                    id,
                    answered: true,
                    note: note,
                  );
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleAnswered(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(prayerRepositoryProvider);
    final next = !prayer.isAnswered;
    await repo.setAnswered(prayer.id, answered: next);
    if (!context.mounted) return;
    if (next) {
      announceForAccessibility(context, 'Marked answered');
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(next ? 'Marked answered' : 'Marked unanswered'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => repo.setAnswered(prayer.id, answered: !next),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('prayer-${prayer.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _toggleAnswered(context, ref);
          return false;
        }
        await _confirmDelete(context, ref);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.palette.answeredBadgeBg,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Icon(Icons.check, color: context.palette.answeredBadgeFg),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      child: PrayerCard(
        prayer: prayer,
        onTap: () => context.push('/prayers/${prayer.id}'),
        onMarkAnswered: () => _toggleAnswered(context, ref),
        onDelete: () => _confirmDelete(context, ref),
      ),
    );
  }
}
