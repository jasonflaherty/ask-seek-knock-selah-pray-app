import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../domain/prayer.dart';

class PrayerCard extends ConsumerWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    required this.onPrayed,
    required this.onMarkAnswered,
    required this.onDelete,
  });

  final Prayer prayer;
  final VoidCallback onTap;
  final VoidCallback onPrayed;
  final VoidCallback onMarkAnswered;
  final VoidCallback onDelete;

  /// Person/focus first (PDF style); fall back to title.
  String get _focus => prayer.hasPerson ? prayer.person : prayer.name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final statusLabel = prayer.isAnswered
        ? 'ANSWERED PRAISE'
        : 'ACTIVE PETITION';
    final preview = prayer.request.length > 160
        ? '${prayer.request.substring(0, 160)}…'
        : prayer.request;

    final verseRefs = ref
        .watch(verseSuggesterProvider)
        .byIds(prayer.verseIds)
        .map((v) => v.ref)
        .toList();

    final visibilityLabel = prayer.shared ? 'Church' : 'Just me';
    final label =
        '$_focus. $statusLabel. $preview. ${verseRefs.join(', ')}. $visibilityLabel.';

    return Semantics(
      container: true,
      button: true,
      label: label,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Prayed for'): onPrayed,
        if (!prayer.isAnswered)
          const CustomSemanticsAction(label: 'Mark answered'): onMarkAnswered,
        const CustomSemanticsAction(label: 'Delete'): onDelete,
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_focus, style: theme.textTheme.titleMedium),
                if (prayer.hasPerson &&
                    prayer.name.trim().toLowerCase() !=
                        prayer.person.trim().toLowerCase()) ...[
                  const SizedBox(height: 2),
                  Text(prayer.name, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _VisibilityBadge(shared: prayer.shared),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _StatusBadge(
                        answered: prayer.isAnswered,
                        label: statusLabel,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Prayer actions',
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'answered') onMarkAnswered();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        if (!prayer.isAnswered)
                          const PopupMenuItem(
                            value: 'answered',
                            child: Text('Mark answered'),
                          ),
                        if (prayer.isAnswered)
                          const PopupMenuItem(
                            value: 'answered',
                            child: Text('Mark unanswered'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"$preview"',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: AppTheme.scriptureFont,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (verseRefs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final refText in verseRefs.take(3))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              refText,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      if (verseRefs.length > 3)
                        Text(
                          '+${verseRefs.length - 3} more',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
                if (prayer.isAnswered &&
                    prayer.answeredNote != null &&
                    prayer.answeredNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.answeredBadgeBg.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Praise Answer: ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.answeredBadgeFg,
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
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: prayer.tags.isEmpty
                          ? const SizedBox.shrink()
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final tag in prayer.tags)
                                  Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                    ),
                    PrayedButton(onPressed: onPrayed),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Heart control. Tap records that this petition was prayed for.
class PrayedButton extends StatefulWidget {
  const PrayedButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<PrayedButton> createState() => _PrayedButtonState();
}

class _PrayedButtonState extends State<PrayedButton> {
  bool _justPrayed = false;

  Future<void> _press() async {
    setState(() => _justPrayed = true);
    widget.onPressed();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justPrayed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _justPrayed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return IconButton(
      tooltip: 'Prayed for',
      onPressed: _press,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppTheme.minTapTarget,
        minHeight: AppTheme.minTapTarget,
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _justPrayed ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(_justPrayed),
          size: 22,
          color: color,
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.shared});

  final bool shared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final label = shared ? 'Church' : 'Just me';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.selectedItemBg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            shared ? Icons.groups_outlined : Icons.lock_outline,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 0.2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.answered, required this.label});

  final bool answered;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final bg = answered ? palette.answeredBadgeBg : palette.selectedItemBg;
    final fg = answered ? palette.answeredBadgeFg : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (answered) ...[
            Icon(Icons.check, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                letterSpacing: 0.4,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
