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
              data: (prayers) => _LiturgyList(prayers: prayers),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiturgyList extends StatelessWidget {
  const _LiturgyList({required this.prayers});

  final List<LiturgicalPrayer> prayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = <String, List<LiturgicalPrayer>>{};
    for (final prayer in prayers) {
      sections.putIfAbsent(prayer.section, () => []).add(prayer);
    }
    final sectionOrder = [
      'Morning',
      'Evening',
      'After the Collects',
      'Christian Year',
    ];

    return CustomScrollView(
      slivers: [
        for (final section in sectionOrder)
          if (sections.containsKey(section)) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPadding,
                20,
                AppTheme.screenPadding,
                8,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  section,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenPadding,
              ),
              sliver: SliverList.separated(
                itemCount: sections[section]!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prayer = sections[section]![index];
                  return _CollectCard(prayer: prayer);
                },
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _CollectCard extends StatelessWidget {
  const _CollectCard({required this.prayer});

  final LiturgicalPrayer prayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Card(
      color: palette.verseSurface.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prayer.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              prayer.text,
              style: AppTheme.scripture(theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
