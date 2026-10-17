import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/theme.dart';
import '../../groups/application/group_session_notifier.dart';
import '../../groups/application/group_sync_service.dart';
import '../../groups/domain/group_models.dart';

final studyNotesProvider = FutureProvider.autoDispose<List<StudyNote>>((
  ref,
) async {
  final group = ref.watch(groupSessionProvider);
  final session = group.session;
  final membership = group.membership;
  if (session == null || membership == null) return const [];
  return ref
      .watch(selahApiProvider)
      .listNotes(session.token, groupId: membership.groupId);
});

class StudyNotesSection extends ConsumerStatefulWidget {
  const StudyNotesSection({super.key});

  @override
  ConsumerState<StudyNotesSection> createState() => _StudyNotesSectionState();
}

class _StudyNotesSectionState extends ConsumerState<StudyNotesSection> {
  static const _pageSize = 7;

  final _currentController = TextEditingController();
  final _otherController = TextEditingController();
  final _dateFormat = DateFormat.yMMMd();
  bool _busy = false;
  int _notesShown = _pageSize;

  @override
  void dispose() {
    _currentController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _saveReading() async {
    final body = _currentController.text;
    if (_busy || body.trim().isEmpty) return;
    final me = ref.read(groupSessionProvider).session?.user;
    if (me != null) {
      final List<StudyNote> list;
      try {
        list = await ref.read(studyNotesProvider.future);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
        return;
      }
      if (!mounted) return;
      final existing = list.where(
        (n) => n.isCurrentStudy && n.authorUserId == me.id,
      );
      final current = existing.isEmpty ? null : existing.first;
      if (current != null && current.body.trim() != body.trim()) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Replace what you\'re reading?'),
            content: const Text(
              'The group will see this instead of your current reading.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
      }
    }
    await _save(kind: 'current_study', body: body);
  }

  Future<void> _save({required String kind, required String body}) async {
    final group = ref.read(groupSessionProvider);
    final session = group.session;
    final membership = group.membership;
    if (session == null || membership == null || body.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(selahApiProvider)
          .upsertNote(
            session.token,
            kind: kind,
            body: body.trim(),
            groupId: membership.groupId,
          );
      ref.invalidate(studyNotesProvider);
      if (kind == 'other') _otherController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved for the group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(StudyNote note) async {
    final session = ref.read(groupSessionProvider).session;
    if (session == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(selahApiProvider).deleteNote(session.token, note.id);
      ref.invalidate(studyNotesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _addedLabel(StudyNote note) {
    final when = note.isCurrentStudy ? note.updatedAt : note.createdAt;
    return 'Added ${_dateFormat.format(when.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = ref.watch(studyNotesProvider);
    final me = ref.watch(groupSessionProvider).session?.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reading notes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Your group can read these. Only you can edit or remove your own.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What I\'m reading',
            hintText: 'Book or passage for today',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _saveReading,
          child: const Text('Save what I\'m reading'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otherController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Other note'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _save(kind: 'other', body: _otherController.text),
          child: const Text('Add note'),
        ),
        const SizedBox(height: 16),
        notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e', style: theme.textTheme.bodySmall),
          data: (list) {
            final reading = list.where((n) => n.isCurrentStudy).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final others = list.where((n) => !n.isCurrentStudy).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (reading.isEmpty && others.isEmpty) {
              return Text('No notes yet.', style: theme.textTheme.bodySmall);
            }
            final shown = others.take(_notesShown).toList();
            final hasMore = others.length > shown.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final note in reading) _noteCard(theme, note, me?.id),
                for (final note in shown) _noteCard(theme, note, me?.id),
                if (hasMore)
                  OutlinedButton(
                    onPressed: () => setState(() => _notesShown += _pageSize),
                    child: const Text('Show more'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _noteCard(ThemeData theme, StudyNote note, String? myId) {
    final title = note.isCurrentStudy
        ? 'Reading · ${note.authorDisplayName}'
        : note.authorDisplayName;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(_addedLabel(note), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(note.body),
                ],
              ),
            ),
            if (myId != null && note.authorUserId == myId)
              IconButton(
                tooltip: 'Remove note',
                onPressed: _busy ? null : () => _delete(note),
                icon: const Icon(Symbols.delete),
              ),
          ],
        ),
      ),
    );
  }
}
