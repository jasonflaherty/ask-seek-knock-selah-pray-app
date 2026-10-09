import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../domain/bible_reference.dart';
import '../domain/verse.dart';

Future<Verse?> showAddCustomVerseSheet(BuildContext context) {
  return showModalBottomSheet<Verse>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const AddCustomVerseSheet(),
  );
}

class AddCustomVerseSheet extends ConsumerStatefulWidget {
  const AddCustomVerseSheet({super.key});

  @override
  ConsumerState<AddCustomVerseSheet> createState() =>
      _AddCustomVerseSheetState();
}

class _AddCustomVerseSheetState extends ConsumerState<AddCustomVerseSheet> {
  final _refController = TextEditingController();
  final _textController = TextEditingController();
  final _noteController = TextEditingController();
  bool _affirmed = false;
  bool _saving = false;
  String? _refError;
  String? _textError;
  String? _affirmError;

  @override
  void dispose() {
    _refController.dispose();
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _validate() {
    final parsed = parseBibleReference(_refController.text);
    final text = _textController.text.trim();
    setState(() {
      _refError = parsed == null
          ? 'Use a Bible reference like John 14:13–14 or Psalm 50:15'
          : null;
      _textError = text.length < 12
          ? 'Paste the exact words of Scripture (a promise or answered prayer)'
          : null;
      _affirmError = !_affirmed
          ? 'Confirm this is God’s Word and a promise you will pray'
          : null;
    });
    return _refError == null && _textError == null && _affirmError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final verse = await ref.read(verseCatalogProvider).addCustom(
            ref: _refController.text,
            text: _textController.text,
            note: _noteController.text,
          );
      if (mounted) Navigator.pop(context, verse);
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not save verse')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Add a Scripture promise',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We pray with arguments from God’s revealed will—His own words. '
              'Add a Bible verse where God makes a promise or answers prayer. '
              'Copy the wording from Scripture; do not paraphrase.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text('Bible reference', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _refController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Reference',
                hintText: 'e.g. Philippians 4:19',
                errorText: _refError,
              ),
              onChanged: (_) {
                if (_refError != null) setState(() => _refError = null);
              },
            ),
            const SizedBox(height: 16),
            Text('Scripture text', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              minLines: 4,
              maxLines: 10,
              style: AppTheme.scripture(theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Exact wording from the Bible',
                alignLabelWithHint: true,
                errorText: _textError,
              ),
              onChanged: (_) {
                if (_textError != null) setState(() => _textError = null);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Why this promise (optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'How this speaks to the need',
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _affirmed,
              onChanged: (v) {
                setState(() {
                  _affirmed = v ?? false;
                  _affirmError = null;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'This is the exact wording of Scripture, and it is a promise '
                'or answered prayer I will pray back to God.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (_affirmError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  _affirmError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Add verse'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
