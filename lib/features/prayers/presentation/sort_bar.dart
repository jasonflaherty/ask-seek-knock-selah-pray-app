import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../domain/sort_mode.dart';

class SortBar extends StatelessWidget {
  const SortBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SortMode selected;
  final ValueChanged<SortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mode in SortMode.values) ...[
            if (mode != SortMode.values.first) const SizedBox(width: 8),
            FilterChip(
              showCheckmark: false,
              selected: selected == mode,
              avatar: selected == mode
                  ? Icon(Symbols.check, size: 16, color: theme.colorScheme.primary)
                  : null,
              label: Text(mode.label),
              onSelected: (_) => onSelected(mode),
              selectedColor: palette.selectedItemBg,
              side: BorderSide(
                color: selected == mode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              labelStyle: theme.textTheme.labelMedium,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ],
        ],
      ),
    );
  }
}
