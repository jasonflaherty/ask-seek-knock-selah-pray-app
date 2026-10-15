import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../domain/prayer.dart';

class PersonFilterMenu extends StatelessWidget {
  const PersonFilterMenu({
    super.key,
    required this.selected,
    required this.knownPersons,
    required this.onSelected,
  });

  final PersonFilter selected;
  final List<String> knownPersons;
  final ValueChanged<PersonFilter> onSelected;

  String get _label {
    if (selected.isAll) return 'Anyone';
    if (selected.isUnassigned) return 'Unassigned';
    return selected.value!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final isFiltered = !selected.isAll;

    return PopupMenuButton<PersonFilter>(
      tooltip: 'Person: $_label',
      offset: const Offset(0, 48),
      onSelected: onSelected,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: PersonFilter.all,
          checked: selected.isAll,
          child: const Text('Anyone'),
        ),
        CheckedPopupMenuItem(
          value: PersonFilter.unassigned,
          checked: selected.isUnassigned,
          child: const Text('Unassigned'),
        ),
        if (knownPersons.isNotEmpty) const PopupMenuDivider(),
        for (final name in knownPersons)
          CheckedPopupMenuItem(
            value: PersonFilter.named(name),
            checked: selected.value == name,
            child: Text(name),
          ),
      ],
      child: Semantics(
        button: true,
        label: 'Filter by person, currently $_label',
        child: Container(
          constraints: const BoxConstraints(
            minWidth: AppTheme.minTapTarget,
            minHeight: AppTheme.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFiltered ? palette.selectedItemBg : null,
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            border: Border.all(
              color: isFiltered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Symbols.person,
                size: 20,
                color: isFiltered
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isFiltered ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
