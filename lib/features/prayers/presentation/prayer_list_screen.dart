import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../application/prayer_counts_provider.dart';
import '../application/prayer_list_notifier.dart';
import '../application/prayer_list_state.dart';
import '../domain/prayer.dart';
import '../domain/sort_mode.dart';
import 'filter_menu.dart';
import 'intercession_checklist.dart';
import 'journal_header.dart';
import 'person_filter_menu.dart';
import 'prayer_card.dart';
import 'sort_bar.dart';

class PrayerListScreen extends ConsumerWidget {
  const PrayerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listState = ref.watch(prayerListProvider);
    final notifier = ref.read(prayerListProvider.notifier);
    final counts =
        ref.watch(prayerCountsProvider).valueOrNull ??
        const PrayerCounts(active: 0, answered: 0);
    final showHomeVerse = ref.watch(homeVerseVisibleProvider);
    final items = notifier.displayItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ask, Seek, Knock...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/prayers/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add petition'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenPadding,
                      8,
                      AppTheme.screenPadding,
                      0,
                    ),
                    child: JournalHeader(
                      activeCount: counts.active,
                      answeredCount: counts.answered,
                      showMeditationVerse: false,
                    ),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (showHomeVerse)
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppTheme.screenPadding,
                            16,
                            AppTheme.screenPadding,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: JournalMeditationVerse(),
                          ),
                        ),
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: theme.colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.screenPadding,
                              16,
                              AppTheme.screenPadding,
                              8,
                            ),
                            child: Row(
                              children: [
                                FilterMenu(
                                  selected: listState.filter,
                                  onSelected: notifier.setFilter,
                                ),
                                const SizedBox(width: 8),
                                PersonFilterMenu(
                                  selected: listState.personFilter,
                                  knownPersons: listState.knownPersons,
                                  onSelected: notifier.setPersonFilter,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SortBar(
                                    selected: listState.sortMode,
                                    onSelected: (mode) async {
                                      await notifier.setSortMode(mode);
                                      if (mode == SortMode.shuffle &&
                                          context.mounted) {
                                        announceForAccessibility(
                                          context,
                                          'List shuffled',
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (listState.isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (listState.prayers.isEmpty)
                        SliverToBoxAdapter(
                          child: _EmptyState(
                            onAdd: () => context.push('/prayers/new'),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPadding,
                            8,
                            AppTheme.screenPadding,
                            100,
                          ),
                          sliver: SliverList(
                            key: ValueKey(
                              '${listState.sortMode}-${listState.reshuffleCount}-${listState.filter}-${listState.personFilter.value}',
                            ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index == items.length) {
                                return IntercessionChecklist(
                                  prayers: listState.prayers,
                                );
                              }
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
                                      title.toUpperCase(),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            letterSpacing: 1.0,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                                PrayerListEntry(:final prayer) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.cardGap,
                                  ),
                                  child: _SwipeablePrayerCard(prayer: prayer),
                                ),
                              };
                            }, childCount: items.length + 1),
                          ),
                        ),
                    ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        32,
        AppTheme.screenPadding,
        100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Begin with a petition', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add who you are praying for. Selah will suggest promises '
            'from Scripture to pray with them.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'SELAH · Pause, Reflect, Meditate',
            style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onAdd,
            child: const Text('Add your first petition'),
          ),
        ],
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
      person: prayer.person,
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
            final id = await ref
                .read(prayerRepositoryProvider)
                .createPrayer(snapshot);
            if (wasAnswered) {
              await ref
                  .read(prayerRepositoryProvider)
                  .setAnswered(id, answered: true, note: note);
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
      child: VisibilityDetector(
        key: Key('visibility-prayer-${prayer.id}'),
        onVisibilityChanged: (info) {
          if (!context.mounted) return;
          ref
              .read(eventLoggerProvider)
              .onVisibilityChanged(prayer.id, info.visibleFraction);
        },
        child: PrayerCard(
          prayer: prayer,
          onTap: () => context.push('/prayers/${prayer.id}'),
          onPrayed: () async {
            HapticFeedback.lightImpact();
            await ref.read(eventLoggerProvider).prayed(prayer.id);
            if (!context.mounted) return;
            announceForAccessibility(context, 'Prayed');
          },
          onMarkAnswered: () => _toggleAnswered(context, ref),
          onDelete: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }
}
