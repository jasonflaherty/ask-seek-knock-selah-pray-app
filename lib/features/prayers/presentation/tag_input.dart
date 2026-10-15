import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';

class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.suggestions,
    required this.onChanged,
  });

  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagInput> createState() => TagInputState();
}

class TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Commits any text still in the field (e.g. before Save).
  void commitPending() {
    final raw = _controller.text;
    if (raw.trim().isEmpty) return;
    _add(raw);
  }

  void _add(String raw) {
    final label = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (label.isEmpty) return;
    if (label.length > 40) return;
    final exists =
        widget.tags.any((t) => t.toLowerCase() == label.toLowerCase());
    if (exists) {
      _controller.clear();
      setState(() {});
      return;
    }
    widget.onChanged([...widget.tags, label]);
    _controller.clear();
    setState(() {});
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  List<String> get _availableSuggestions {
    final q = _controller.text.trim().toLowerCase();
    return widget.suggestions
        .where((s) {
          if (widget.tags.any((t) => t.toLowerCase() == s.toLowerCase())) {
            return false;
          }
          if (q.isEmpty) return true;
          return s.toLowerCase().contains(q);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _availableSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.tags.length; i++)
                InputChip(
                  label: Text(
                    i == 0 ? '${widget.tags[i]} (primary)' : widget.tags[i],
                  ),
                  onDeleted: () => _remove(widget.tags[i]),
                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(40),
                ],
                decoration: const InputDecoration(
                  labelText: 'Add a tag',
                  hintText: 'family, healing…',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filled(
                tooltip: 'Add tag',
                onPressed: () => _add(_controller.text),
                icon: const Icon(Symbols.add),
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppTheme.minTapTarget,
                    AppTheme.minTapTarget,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (available.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Tap to add',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in available)
                ActionChip(
                  label: Text(s),
                  onPressed: () => _add(s),
                  backgroundColor: context.palette.selectedItemBg,
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
