import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../domain/prayer.dart';
import '../domain/prayer_event.dart';
import 'tag_input.dart';

class AddEditPrayerScreen extends ConsumerStatefulWidget {
  const AddEditPrayerScreen({super.key, this.prayerId});

  final int? prayerId;

  bool get isEditing => prayerId != null;

  @override
  ConsumerState<AddEditPrayerScreen> createState() =>
      _AddEditPrayerScreenState();
}

class _AddEditPrayerScreenState extends ConsumerState<AddEditPrayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _requestController = TextEditingController();
  final _answerNoteController = TextEditingController();

  List<String> _tags = [];
  List<String> _verseIds = [];
  List<String> _suggestions = [];
  bool _isAnswered = false;
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  String? _nameError;
  String? _requestError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(prayerRepositoryProvider);
    _suggestions = await repo.allTagLabels();
    if (widget.prayerId != null) {
      final prayer = await repo.getPrayer(widget.prayerId!);
      if (prayer != null && mounted) {
        _nameController.text = prayer.name;
        _requestController.text = prayer.request;
        _tags = List.of(prayer.tags);
        _verseIds = List.of(prayer.verseIds);
        _isAnswered = prayer.isAnswered;
        _answerNoteController.text = prayer.answeredNote ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _requestController.dispose();
    _answerNoteController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final request = _requestController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _requestError = request.isEmpty ? 'Prayer request is required' : null;
    });
    return _nameError == null && _requestError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(prayerRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repo.updatePrayer(
          widget.prayerId!,
          PrayerUpdate(
            name: _nameController.text.trim(),
            request: _requestController.text.trim(),
            tags: _tags,
            verseIds: _verseIds,
            isAnswered: _isAnswered,
            answeredNote:
                _isAnswered ? _answerNoteController.text.trim() : null,
          ),
        );
        await repo.logEvent(widget.prayerId!, PrayerEventType.edited);
      } else {
        await repo.createPrayer(
          NewPrayer(
            name: _nameController.text.trim(),
            request: _requestController.text.trim(),
            tags: _tags,
            verseIds: _verseIds,
          ),
        );
      }
      if (!mounted) return;
      announceForAccessibility(context, 'Prayer saved');
      _dirty = false;
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit prayer' : 'Add prayer'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTheme.screenPadding),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Name', style: theme.textTheme.labelLarge),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  maxLength: 100,
                                  decoration: InputDecoration(
                                    labelText: 'Who or what is this for?',
                                    errorText: _nameError,
                                    errorStyle: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    _markDirty();
                                    if (_nameError != null) {
                                      setState(() => _nameError = null);
                                    }
                                  },
                                ),
                                if (_nameError != null)
                                  Semantics(
                                    liveRegion: true,
                                    child: const SizedBox.shrink(),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  'Prayer request',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _requestController,
                                  minLines: 4,
                                  maxLines: 10,
                                  decoration: InputDecoration(
                                    labelText: 'What are you praying for?',
                                    alignLabelWithHint: true,
                                    errorText: _requestError,
                                  ),
                                  onChanged: (_) {
                                    _markDirty();
                                    if (_requestError != null) {
                                      setState(() => _requestError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                                TagInput(
                                  tags: _tags,
                                  suggestions: _suggestions,
                                  onChanged: (tags) {
                                    setState(() => _tags = tags);
                                    _markDirty();
                                  },
                                ),
                                const SizedBox(height: 24),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Verses to pray',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Promises and answered prayers that speak to this need.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.palette.verseSurface,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.controlRadius,
                                    ),
                                  ),
                                  child: Text(
                                    _verseIds.isEmpty
                                        ? 'Verse suggestions will appear after you write your request (Phase 3).'
                                        : '${_verseIds.length} verse(s) selected.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                if (widget.isEditing) ...[
                                  const SizedBox(height: 24),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      'Answered',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    value: _isAnswered,
                                    onChanged: (v) {
                                      setState(() {
                                        _isAnswered = v;
                                        _dirty = true;
                                      });
                                    },
                                  ),
                                  if (_isAnswered) ...[
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _answerNoteController,
                                      minLines: 2,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        labelText: 'How did God answer?',
                                      ),
                                      onChanged: (_) => _markDirty(),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPadding,
                            12,
                            AppTheme.screenPadding,
                            12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () async {
                                          final discard = await _confirmDiscard();
                                          if (discard && context.mounted) {
                                            context.pop();
                                          }
                                        },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saving ? null : _save,
                                  child: Text(_saving ? 'Saving…' : 'Save'),
                                ),
                              ),
                            ],
                          ),
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
