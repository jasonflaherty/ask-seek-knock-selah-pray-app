import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../domain/liturgical_prayer.dart';

class LiturgyScreen extends ConsumerWidget {
  const LiturgyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncPrayers = ref.watch(liturgyPrayersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liturgical prayers',
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
            child: asyncPrayers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Text(
                    'Could not load prayers.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              data: (prayers) => _LiturgyBody(prayers: prayers),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiturgyBody extends ConsumerStatefulWidget {
  const _LiturgyBody({required this.prayers});

  final List<LiturgicalPrayer> prayers;

  @override
  ConsumerState<_LiturgyBody> createState() => _LiturgyBodyState();
}

class _LiturgyBodyState extends ConsumerState<_LiturgyBody> {
  static const _sectionOrder = [
    'Morning',
    'Evening',
    'After the Collects',
    'Christian Year',
  ];

  final _favoritesKey = GlobalKey();
  final Map<String, GlobalKey> _prayerKeys = {};
  final Map<String, GlobalKey> _sectionKeys = {};

  GlobalKey _prayerKey(String id) =>
      _prayerKeys.putIfAbsent(id, GlobalKey.new);

  GlobalKey _sectionKey(String section) =>
      _sectionKeys.putIfAbsent(section, GlobalKey.new);

  Future<void> _scrollTo(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: motion(context, const Duration(milliseconds: 280)),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(liturgyTodayProvider);
    final favorites = ref.watch(liturgyFavoritesProvider);
    final byId = {for (final p in widget.prayers) p.id: p};

    final todayPrayers = today.prayerIds
        .map((id) => byId[id])
        .whereType<LiturgicalPrayer>()
        .toList();

    final favoritePrayers = widget.prayers
        .where((p) => favorites.contains(p.id))
        .toList();

    final sections = <String, List<LiturgicalPrayer>>{};
    for (final prayer in widget.prayers) {
      sections.putIfAbsent(prayer.section, () => []).add(prayer);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            16,
            AppTheme.screenPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Today',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  today.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final prayer in todayPrayers) ...[
                  _CollectCard(
                    prayer: prayer,
                    favorited: favorites.contains(prayer.id),
                    favoriteKey: ValueKey('favorite-today-${prayer.id}'),
                    onToggleFavorite: () => ref
                        .read(liturgyFavoritesProvider.notifier)
                        .toggle(prayer.id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        if (favoritePrayers.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              8,
              AppTheme.screenPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _favoritesKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Favorites',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final prayer in favoritePrayers) ...[
                      _CollectCard(
                        prayer: prayer,
                        favorited: true,
                        favoriteKey: ValueKey('favorite-saved-${prayer.id}'),
                        onToggleFavorite: () => ref
                            .read(liturgyFavoritesProvider.notifier)
                            .toggle(prayer.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            16,
            AppTheme.screenPadding,
            8,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Contents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (favoritePrayers.isNotEmpty)
                  _TocLink(
                    key: const ValueKey('toc-favorites'),
                    label: 'Favorites',
                    onTap: () => _scrollTo(_favoritesKey),
                  ),
                for (final section in _sectionOrder)
                  if (sections.containsKey(section)) ...[
                    _TocLink(
                      key: ValueKey('toc-section-$section'),
                      label: section,
                      isSection: true,
                      onTap: () => _scrollTo(_sectionKey(section)),
                    ),
                    for (final prayer in sections[section]!)
                      _TocLink(
                        key: ValueKey('toc-${prayer.id}'),
                        label: prayer.title,
                        indent: true,
                        onTap: () => _scrollTo(_prayerKey(prayer.id)),
                      ),
                  ],
              ],
            ),
          ),
        ),
        for (final section in _sectionOrder)
          if (sections.containsKey(section)) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPadding,
                20,
                AppTheme.screenPadding,
                8,
              ),
              sliver: SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: _sectionKey(section),
                  child: Text(
                    section,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Eager list so TOC GlobalKeys exist before first scroll.
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < sections[section]!.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      KeyedSubtree(
                        key: _prayerKey(sections[section]![i].id),
                        child: _CollectCard(
                          prayer: sections[section]![i],
                          favorited: favorites.contains(
                            sections[section]![i].id,
                          ),
                          favoriteKey: ValueKey(
                            'favorite-catalog-${sections[section]![i].id}',
                          ),
                          onToggleFavorite: () => ref
                              .read(liturgyFavoritesProvider.notifier)
                              .toggle(sections[section]![i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _TocLink extends StatelessWidget {
  const _TocLink({
    super.key,
    required this.label,
    required this.onTap,
    this.indent = false,
    this.isSection = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool indent;
  final bool isSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent ? 16 : 0, 8, 0, 8),
            child: Text(
              label,
              style: (isSection
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(
                fontWeight: isSection ? FontWeight.w600 : FontWeight.w400,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectCard extends StatelessWidget {
  const _CollectCard({
    required this.prayer,
    required this.favorited,
    required this.onToggleFavorite,
    this.favoriteKey,
  });

  final LiturgicalPrayer prayer;
  final bool favorited;
  final VoidCallback onToggleFavorite;
  final Key? favoriteKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Card(
      color: palette.verseSurface.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      prayer.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: favoriteKey,
                  tooltip: favorited ? 'Remove favorite' : 'Favorite',
                  icon: Icon(
                    favorited ? Icons.star : Icons.star_border,
                    color: favorited
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                prayer.text,
                style: AppTheme.scripture(theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
