import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme.dart';
import '../domain/prayer.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    required this.onMarkAnswered,
    required this.onDelete,
  });

  final Prayer prayer;
  final VoidCallback onTap;
  final VoidCallback onMarkAnswered;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final preview = prayer.request.length > 80
        ? '${prayer.request.substring(0, 80)}…'
        : prayer.request;
    final tagText = prayer.tags.isEmpty ? '' : prayer.tags.join(', ');
    final status = prayer.isAnswered ? 'Answered' : 'Active';
    final label =
        '${prayer.name}. $preview. ${prayer.verseIds.length} verses. $tagText. $status.';

    return Semantics(
      container: true,
      button: true,
      label: label,
      customSemanticsActions: {
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        prayer.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Prayer actions',
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
                const SizedBox(height: 8),
                Text(
                  prayer.request,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (prayer.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in prayer.tags)
                        Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${prayer.verseIds.length} verses',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    if (prayer.isAnswered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.answeredBadgeBg,
                          borderRadius:
                              BorderRadius.circular(AppTheme.controlRadius),
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
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: palette.answeredBadgeFg,
                              ),
                            ),
                          ],
                        ),
                      ),
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
