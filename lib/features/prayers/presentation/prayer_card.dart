import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../groups/application/group_session_notifier.dart';
import '../domain/prayer.dart';
import '../domain/share_scope.dart';

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

    final groupState = ref.watch(groupSessionProvider);
    final groupLabel = _groupLabel(prayer, groupState);
    final visibilityLabel = groupLabel == null
        ? prayer.shareScope.label
        : '${prayer.shareScope.label} · $groupLabel';
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
                    _VisibilityBadge(
                      scope: prayer.shareScope,
                      extra: groupLabel,
                    ),
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
                              Symbols.menu_book,
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
          Symbols.favorite,
          key: ValueKey(_justPrayed),
          size: 22,
          color: color,
          fill: _justPrayed ? 1.0 : 0.0,
        ),
      ),
    );
  }
}

String? _groupLabel(Prayer prayer, GroupSessionState groupState) {
  if (!prayer.shareScope.isShared) return null;
  if ((groupState.session?.memberships.length ?? 0) <= 1) return null;
  final gid = prayer.groupId;
  if (gid != null && gid.isNotEmpty) {
    final m = groupState.session?.membershipFor(gid);
    if (m != null) return m.groupName;
  }
  final cid = prayer.churchId;
  if (cid != null && cid.isNotEmpty) {
    for (final m in groupState.session?.memberships ?? const []) {
      if (m.churchId == cid) return m.churchName;
    }
  }
  return null;
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.scope, this.extra});

  final ShareScope scope;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final label =
        extra == null || extra!.isEmpty ? scope.label : '${scope.label} · $extra';
    final icon = switch (scope) {
      ShareScope.justMe => Symbols.lock,
      ShareScope.group => Symbols.group,
      ShareScope.church => Symbols.groups,
    };
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
            icon,
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
            Icon(Symbols.check, size: 14, color: fg),
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
