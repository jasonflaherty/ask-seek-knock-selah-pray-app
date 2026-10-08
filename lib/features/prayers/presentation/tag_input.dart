import 'package:flutter/material.dart';

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
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final label = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (label.isEmpty) return;
    final exists = widget.tags.any((t) => t.toLowerCase() == label.toLowerCase());
    if (exists) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.tags, label]);
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.suggestions
        .where((s) {
          final q = _controller.text.trim().toLowerCase();
          if (q.isEmpty) return false;
          if (widget.tags.any((t) => t.toLowerCase() == s.toLowerCase())) {
            return false;
          }
          return s.toLowerCase().contains(q);
        })
        .take(6)
        .toList();

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
        TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Add a tag',
            hintText: 'family, healing…',
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: _add,
        ),
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in filtered)
                ActionChip(
                  label: Text(s),
                  onPressed: () => _add(s),
                  backgroundColor: context.palette.selectedItemBg,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
