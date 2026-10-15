import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../domain/prayer.dart';

/// Compact weekly intercession log (PDF page 2), using last-prayed day this week.
class IntercessionChecklist extends StatelessWidget {
  const IntercessionChecklist({
    super.key,
    required this.prayers,
  });

  final List<Prayer> prayers;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Monday-based weekday index 0–6 for [date] in the current local week.
  static int? weekdayIndexThisWeek(DateTime? date, DateTime now) {
    if (date == null) return null;
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(start) || !d.isBefore(end)) return null;
    return d.weekday - 1; // Mon=0
  }

  static DateTime _startOfWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekLabel = DateFormat.MMMd().format(_startOfWeek(now));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'DAILY PRAYER & INTERCESSION',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Week of $weekLabel · checkmarks from “I prayed”',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Person / Focus',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    for (final d in _days)
                      SizedBox(
                        width: 28,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              for (final prayer in prayers.take(12))
                _ChecklistRow(
                  prayer: prayer,
                  checkedDay: weekdayIndexThisWeek(prayer.lastPrayedAt, now),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.prayer,
    required this.checkedDay,
  });

  final Prayer prayer;
  final int? checkedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = prayer.hasPerson ? prayer.person : prayer.name;
    final category = prayer.tags.isNotEmpty ? prayer.tags.first : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  focus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
                ),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (var i = 0; i < 7; i++)
            SizedBox(
              width: 28,
              child: Icon(
                checkedDay == i ? Symbols.check : Symbols.remove,
                size: 14,
                color: checkedDay == i
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
