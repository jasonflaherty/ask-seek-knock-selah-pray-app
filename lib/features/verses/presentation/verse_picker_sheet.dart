import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../application/verse_suggest_notifier.dart';
import '../domain/verse.dart';

Future<Set<String>?> showVersePickerSheet({
  required BuildContext context,
  required String requestText,
  required Set<String> selectedIds,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => VersePickerSheet(
      requestText: requestText,
      initialSelected: selectedIds,
    ),
  );
}

class VersePickerSheet extends ConsumerStatefulWidget {
  const VersePickerSheet({
    super.key,
    required this.requestText,
    required this.initialSelected,
  });

  final String requestText;
  final Set<String> initialSelected;

  @override
  ConsumerState<VersePickerSheet> createState() => _VersePickerSheetState();
}

class _VersePickerSheetState extends ConsumerState<VersePickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.initialSelected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verseSuggestProvider.notifier).refresh(widget.requestText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggest = ref.watch(verseSuggestProvider);
    final suggester = ref.watch(verseSuggesterProvider);
    final selectedVerses = suggester.byIds(_selected.toList());
    final suggestionIds = suggest.suggestions.map((v) => v.id).toSet();
    final extras = selectedVerses.where((v) => !suggestionIds.contains(v.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verses to pray',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(verseSuggestProvider.notifier).refresh(),
                    child: const Text('Refresh suggestions'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (suggest.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    for (final verse in [...extras, ...suggest.suggestions])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VerseSelectCard(
                          verse: verse,
                          selected: _selected.contains(verse.id),
                          onChanged: (value) {
                            setState(() {
                              if (value) {
                                _selected.add(verse.id);
                              } else {
                                _selected.remove(verse.id);
                              }
                            });
                          },
                        ),
                      ),
                    if (!suggest.isLoading &&
                        suggest.suggestions.isEmpty &&
                        extras.isEmpty)
                      Text(
                        'Keep writing your request (at least 8 characters) to see suggestions.',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Done (${_selected.length})'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VerseSelectCard extends StatelessWidget {
  const VerseSelectCard({
    super.key,
    required this.verse,
    required this.selected,
    required this.onChanged,
  });

  final Verse verse;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Semantics(
      checked: selected,
      label:
          '${verse.ref}. ${verse.text}. ${selected ? 'Selected' : 'Not selected'}',
      child: Material(
        color: selected ? palette.selectedItemBg : palette.verseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => onChanged(!selected),
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (v) => onChanged(v ?? false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              verse.ref,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              verse.promiseType.label,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.text,
                        style: AppTheme.scripture(theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(verse.note, style: theme.textTheme.bodyMedium),
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
