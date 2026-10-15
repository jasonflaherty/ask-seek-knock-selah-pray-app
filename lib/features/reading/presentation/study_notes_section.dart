import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../groups/application/group_session_notifier.dart';
import '../../groups/application/group_sync_service.dart';
import '../../groups/domain/group_models.dart';

final studyNotesProvider = FutureProvider.autoDispose<List<StudyNote>>((
  ref,
) async {
  final session = ref.watch(groupSessionProvider).session;
  if (session?.membership == null) return const [];
  return ref.watch(selahApiProvider).listNotes(session!.token);
});

class StudyNotesSection extends ConsumerStatefulWidget {
  const StudyNotesSection({super.key});

  @override
  ConsumerState<StudyNotesSection> createState() => _StudyNotesSectionState();
}

class _StudyNotesSectionState extends ConsumerState<StudyNotesSection> {
  final _currentController = TextEditingController();
  final _otherController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _currentController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _save({required String kind, required String body}) async {
    final session = ref.read(groupSessionProvider).session;
    if (session == null || body.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(selahApiProvider).upsertNote(
            session.token,
            kind: kind,
            body: body.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = ref.watch(studyNotesProvider);
    final me = ref.watch(groupSessionProvider).session?.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Study notes', style: theme.textTheme.titleMedium),
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
            labelText: 'Current study',
            hintText: 'What you are reading now',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _save(
                    kind: 'current_study',
                    body: _currentController.text,
                  ),
          child: const Text('Save current study'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otherController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Other note',
          ),
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
            if (list.isEmpty) {
              return Text(
                'No notes yet.',
                style: theme.textTheme.bodySmall,
              );
            }
            return Column(
              children: [
                for (final note in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppTheme.cardPadding),
                      title: Text(
                        note.isCurrentStudy
                            ? 'Current study · ${note.authorDisplayName}'
                            : note.authorDisplayName,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(note.body),
                      ),
                      trailing: me != null && note.authorUserId == me.id
                          ? IconButton(
                              tooltip: 'Remove note',
                              onPressed: _busy ? null : () => _delete(note),
                              icon: const Icon(Icons.delete_outline),
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
