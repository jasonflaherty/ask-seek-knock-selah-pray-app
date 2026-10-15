import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../domain/prayer.dart';

extension AnswerFilterLabel on AnswerFilter {
  String get label => switch (this) {
        AnswerFilter.active => 'Active',
        AnswerFilter.answered => 'Answered',
        AnswerFilter.all => 'All',
      };
}

/// Compact filter control: one icon that opens a dropdown of filter options.
class FilterMenu extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AnswerFilter selected;
  final ValueChanged<AnswerFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return PopupMenuButton<AnswerFilter>(
      tooltip: 'Filter: ${selected.label}',
      offset: const Offset(0, 48),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final filter in AnswerFilter.values)
          CheckedPopupMenuItem<AnswerFilter>(
            value: filter,
            checked: filter == selected,
            child: Text(filter.label),
          ),
      ],
      child: Semantics(
        button: true,
        label: 'Filter prayers, currently ${selected.label}',
        child: Container(
          width: AppTheme.minTapTarget,
          height: AppTheme.minTapTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.selectedItemBg,
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            border: Border.all(color: theme.colorScheme.primary, width: 1),
          ),
          child: Icon(
            Symbols.filter_list,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
