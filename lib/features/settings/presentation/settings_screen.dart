import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/app_config.dart';
import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../../groups/application/group_session_notifier.dart';
import '../../groups/domain/group_models.dart';
import '../data/prayer_backup.dart';
import '../data/test_data_importer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  bool _loaded = false;
  bool _statusReady = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _churchNameController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _inviteController = TextEditingController();
  bool _codeSent = false;

  TestDataImporter get _importer => TestDataImporter(
    ref.read(prayerRepositoryProvider),
    ref.read(sharedPreferencesProvider),
  );

  PrayerBackupService get _backup =>
      PrayerBackupService(ref.read(prayerRepositoryProvider));

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _displayNameController.dispose();
    _churchNameController.dispose();
    _groupNameController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final loaded = await _importer.isLoaded();
    if (!mounted) return;
    setState(() {
      _loaded = loaded;
      _statusReady = true;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveGroupNames(
    String groupId,
    String churchName,
    String groupName,
  ) {
    return _run(() async {
      await ref
          .read(groupSessionProvider.notifier)
          .updateGroupNames(
            groupId: groupId,
            churchName: churchName,
            groupName: groupName,
          );
      if (!mounted) return;
      announceForAccessibility(context, 'Church and group name saved');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Church and group name saved')),
      );
    });
  }

  Future<void> _showOwnerPanel(String groupId) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OwnerPanelSheet(groupId: groupId),
    );
  }

  Future<void> _importTestData() async {
    if (_busy || _loaded) return;
    setState(() => _busy = true);
    try {
      final count = await _importer.importSamples();
      if (!mounted) return;
      await _refreshStatus();
      if (!mounted) return;
      if (count == 0) {
        announceForAccessibility(context, 'Test data already loaded');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test data is already loaded')),
        );
      } else {
        announceForAccessibility(context, 'Imported $count sample prayers');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count sample prayers')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTestData() async {
    if (_busy || !_loaded) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete test data?'),
        content: const Text(
          'This removes the sample prayers only. Your own prayers stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final count = await _importer.deleteSamples();
      if (!mounted) return;
      await _refreshStatus();
      if (!mounted) return;
      announceForAccessibility(context, 'Deleted $count sample prayers');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted $count sample prayers')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(String format) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final content = format == 'csv'
          ? await _backup.exportCsv()
          : await _backup.exportJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final name = 'selah-backup-$stamp.$format';
      final file = File(p.join(dir.path, name));
      await file.writeAsString(content, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: format == 'csv' ? 'text/csv' : 'application/json',
            ),
          ],
          subject: 'Selah prayer backup',
        ),
      );
      if (!mounted) return;
      announceForAccessibility(context, 'Backup ready to share');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    if (_busy) return;
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'csv'],
    );
    if (picked.isEmpty) return;

    final file = picked.first;
    final String raw;
    try {
      final bytes = await file.readAsBytes();
      raw = String.fromCharCodes(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not read that file: $e')));
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    final isCsv = ext == 'csv' || file.name.toLowerCase().endsWith('.csv');

    setState(() => _busy = true);
    try {
      final count = isCsv
          ? await _backup.importCsv(raw)
          : await _backup.importJson(raw);
      if (!mounted) return;
      announceForAccessibility(context, 'Imported $count prayers');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Imported $count prayers')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _supportDeveloper() async {
    final uri = AppConfig.venmoSupportUri;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open Venmo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final showHomeVerse = ref.watch(homeVerseVisibleProvider);
    final group = ref.watch(groupSessionProvider);
    final canImport = _statusReady && !_loaded && !_busy;
    final canDelete = _statusReady && _loaded && !_busy;
    final session = group.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              children: [
                Text('Appearance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Theme', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Symbols.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Symbols.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Symbols.dark_mode),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).setMode(s.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Home screen verse',
                    style: theme.textTheme.labelLarge,
                  ),
                  subtitle: Text(
                    'Show the meditation Scripture banner on the journal home.',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: showHomeVerse,
                  onChanged: (value) => ref
                      .read(homeVerseVisibleProvider.notifier)
                      .setVisible(value),
                ),
                const SizedBox(height: 32),
                Text('Account and groups', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in with email to create or ask to join one group. '
                  'Group and church prayers sync. Just me prayers never '
                  'leave this phone.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (session == null) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await ref
                                .read(groupSessionProvider.notifier)
                                .requestCode(_emailController.text);
                            setState(() => _codeSent = true);
                            if (!mounted) return;
                            announceForAccessibility(
                              context,
                              'Sign-in code sent',
                            );
                          }),
                    child: const Text('Send sign-in code'),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Code from email',
                      ),
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await ref
                                  .read(groupSessionProvider.notifier)
                                  .verifyCode(
                                    _emailController.text,
                                    _codeController.text,
                                  );
                              if (!mounted) return;
                              announceForAccessibility(context, 'Signed in');
                            }),
                      child: const Text('Sign in'),
                    ),
                  ],
                ] else ...[
                  Text(
                    session.user.displayName.isEmpty
                        ? session.user.email
                        : '${session.user.displayName} · ${session.user.email}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      hintText: session.user.displayName.isEmpty
                          ? 'Short name for the group'
                          : session.user.displayName,
                    ),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await ref
                                .read(groupSessionProvider.notifier)
                                .setDisplayName(_displayNameController.text);
                          }),
                    child: const Text('Save display name'),
                  ),
                  const SizedBox(height: 16),
                  Text('Your group', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (!session.hasGroup)
                    Text(
                      'You are not in a group yet.',
                      style: theme.textTheme.bodySmall,
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final m = session.membership!;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${m.churchName} · ${m.groupName}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  m.isOwner ? 'Owner' : 'Member',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (m.isOwner && m.inviteCode.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    'Invite code: ${m.inviteCode}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                                if (m.isOwner) ...[
                                  const SizedBox(height: 12),
                                  _RenameGroupForm(
                                    groupId: m.groupId,
                                    churchName: m.churchName,
                                    groupName: m.groupName,
                                    busy: _busy,
                                    onSave: (church, group) => _saveGroupNames(
                                      m.groupId,
                                      church,
                                      group,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (m.isOwner)
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _showOwnerPanel(m.groupId),
                                    child: const Text('People and requests'),
                                  )
                                else
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(() async {
                                            await ref
                                                .read(
                                                  groupSessionProvider.notifier,
                                                )
                                                .leaveGroup(m.groupId);
                                          }),
                                    child: const Text('Leave group'),
                                  ),
                                if (m.isOwner)
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete group?',
                                                ),
                                                content: const Text(
                                                  'This removes the group and '
                                                  'its shared prayers from the '
                                                  'server.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok != true) return;
                                            await _run(() async {
                                              await ref
                                                  .read(
                                                    groupSessionProvider
                                                        .notifier,
                                                  )
                                                  .deleteGroup(m.groupId);
                                            });
                                          },
                                    child: Text(
                                      'Delete group',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  if (group.myJoinRequests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for the group owner',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    for (final r in group.myJoinRequests)
                      Text(
                        '${r.churchName.isEmpty ? '' : '${r.churchName} · '}'
                        '${r.groupName}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                  if (!session.hasGroup) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Create or ask to join',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _churchNameController,
                      decoration: const InputDecoration(
                        labelText: 'Church name',
                      ),
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                      ),
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await ref
                                  .read(groupSessionProvider.notifier)
                                  .createGroup(
                                    churchName: _churchNameController.text,
                                    groupName: _groupNameController.text,
                                  );
                            }),
                      child: const Text('Create group'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inviteController,
                      decoration: const InputDecoration(
                        labelText: 'Invite code',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final result = await ref
                                  .read(groupSessionProvider.notifier)
                                  .requestJoin(_inviteController.text);
                              if (!mounted) return;
                              final joined =
                                  result?.status == 'joined' ||
                                  ref.read(groupSessionProvider).hasGroup;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    joined
                                        ? 'You joined the group.'
                                        : 'Waiting for the group owner.',
                                  ),
                                ),
                              );
                            }),
                      child: const Text('Ask to join'),
                    ),
                  ],
                  if (session.hasGroup) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await ref
                                  .read(groupSessionProvider.notifier)
                                  .syncNow();
                              if (!mounted) return;
                              announceForAccessibility(context, 'Synced');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Synced')),
                              );
                            }),
                      icon: const Icon(Symbols.sync),
                      label: const Text('Sync now'),
                    ),
                  ],
                  if (group.pendingChurchUploadConfirm) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Share my church prayers with this church?',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Prayers already marked Church on this phone '
                              'will upload only if you confirm.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                      await ref
                                          .read(groupSessionProvider.notifier)
                                          .confirmChurchUpload();
                                    }),
                              child: const Text('Share them'),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => ref
                                        .read(groupSessionProvider.notifier)
                                        .declineChurchUpload(),
                              child: const Text('Keep them on this phone'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await ref
                                .read(groupSessionProvider.notifier)
                                .signOut();
                            setState(() => _codeSent = false);
                          }),
                    icon: const Icon(Symbols.logout),
                    label: const Text('Sign out'),
                  ),
                ],
                const SizedBox(height: 32),
                Text('Metrics', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Graphs of active and answered petitions, tags, '
                  'and time the app is open.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/metrics'),
                  icon: const Icon(Symbols.insights),
                  label: const Text('Open metrics'),
                ),
                const SizedBox(height: 32),
                Text('Backup', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Export a copy of the journal on this phone. '
                  'This is not how church prayers are shared.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _export('json'),
                  icon: const Icon(Symbols.upload),
                  label: const Text('Export JSON'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _export('csv'),
                  icon: const Icon(Symbols.table_chart),
                  label: const Text('Export CSV'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _importBackup,
                  icon: const Icon(Symbols.download),
                  label: const Text('Import JSON or CSV'),
                ),
                const SizedBox(height: 32),
                Text('Testing', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Import sample prayer requests (active and answered) with '
                  'Scripture promises attached.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (_statusReady)
                  Text(
                    _loaded
                        ? 'Test data is loaded. Delete it before importing again.'
                        : 'No test data loaded.',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: canImport ? _importTestData : null,
                  icon: _busy && !_loaded
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.science),
                  label: Text(
                    _busy && !_loaded
                        ? 'Importing…'
                        : _loaded
                        ? 'Test data already loaded'
                        : 'Import test data',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: canDelete ? _deleteTestData : null,
                  icon: _busy && _loaded
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.delete),
                  label: Text(
                    _busy && _loaded ? 'Deleting…' : 'Delete test data',
                  ),
                ),
                const SizedBox(height: 40),
                Text('Support', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'If Selah helps you pray, you can support ongoing development.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _supportDeveloper,
                  icon: const Icon(Symbols.favorite),
                  label: const Text('Support the developer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Church and group names belong to the owner. Controllers live here so
/// they are not disposed with the create-group fields.
class _RenameGroupForm extends StatefulWidget {
  const _RenameGroupForm({
    required this.groupId,
    required this.churchName,
    required this.groupName,
    required this.busy,
    required this.onSave,
  });

  final String groupId;
  final String churchName;
  final String groupName;
  final bool busy;
  final Future<void> Function(String churchName, String groupName) onSave;

  @override
  State<_RenameGroupForm> createState() => _RenameGroupFormState();
}

class _RenameGroupFormState extends State<_RenameGroupForm> {
  late final TextEditingController _church = TextEditingController(
    text: widget.churchName,
  );
  late final TextEditingController _group = TextEditingController(
    text: widget.groupName,
  );

  @override
  void didUpdateWidget(_RenameGroupForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _church.text = widget.churchName;
      _group.text = widget.groupName;
      return;
    }
    if (_church.text == oldWidget.churchName) {
      _church.text = widget.churchName;
    }
    if (_group.text == oldWidget.groupName) {
      _group.text = widget.groupName;
    }
  }

  @override
  void dispose() {
    _church.dispose();
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _church,
          enabled: !widget.busy,
          decoration: const InputDecoration(labelText: 'Church name'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _group,
          enabled: !widget.busy,
          decoration: const InputDecoration(labelText: 'Group name'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: widget.busy
              ? null
              : () => widget.onSave(_church.text, _group.text),
          child: const Text('Save names'),
        ),
      ],
    );
  }
}

/// Owns the invite field so it is disposed with the sheet, not during pop.
class _OwnerPanelSheet extends ConsumerStatefulWidget {
  const _OwnerPanelSheet({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_OwnerPanelSheet> createState() => _OwnerPanelSheetState();
}

class _OwnerPanelSheetState extends ConsumerState<_OwnerPanelSheet> {
  final _inviteEmailController = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  List<GroupMember> _members = const [];
  List<EmailInviteSummary> _emailInvites = const [];
  List<JoinRequestSummary> _incoming = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPanel();
    });
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadPanel() async {
    try {
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _reload() async {
    final notifier = ref.read(groupSessionProvider.notifier);
    await notifier.refreshRequests();
    if (!mounted) return;
    final members = await notifier.listMembers(widget.groupId);
    if (!mounted) return;
    final emailInvites = await notifier.listEmailInvites(widget.groupId);
    if (!mounted) return;
    final incoming = ref
        .read(groupSessionProvider)
        .incomingJoinRequests
        .where((r) => r.groupId == widget.groupId)
        .toList();
    if (!mounted) return;
    setState(() {
      _members = members;
      _emailInvites = emailInvites;
      _incoming = incoming;
      _loading = false;
      _busy = false;
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _reload();
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(groupSessionProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.screenPadding,
          right: AppTheme.screenPadding,
          top: AppTheme.screenPadding,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AppTheme.screenPadding,
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('People', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_members.isEmpty)
                      const Text('No members yet.')
                    else
                      for (final m in _members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            m.displayName.isEmpty ? m.email : m.displayName,
                          ),
                          subtitle: Text(
                            '${m.email}${m.isOwner ? ' · Owner' : ''}',
                          ),
                          trailing: m.isOwner
                              ? null
                              : IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Symbols.person_remove),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => notifier.removeMember(
                                            groupId: widget.groupId,
                                            userId: m.userId,
                                          ),
                                        ),
                                ),
                        ),
                    const SizedBox(height: 16),
                    Text('Invite by email', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'They sign in with that email (web link or app) and join '
                      'automatically. No extra approval step.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inviteEmailController,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email to invite',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final sent = await _run(() async {
                                await notifier.sendEmailInvite(
                                  groupId: widget.groupId,
                                  email: _inviteEmailController.text,
                                );
                                _inviteEmailController.clear();
                              });
                              if (!sent || !context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invitation email sent'),
                                ),
                              );
                            },
                      child: Text(_busy ? 'Working…' : 'Send invitation'),
                    ),
                    if (_emailInvites.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pending email invites',
                        style: theme.textTheme.titleSmall,
                      ),
                      for (final inv in _emailInvites)
                        Text(inv.email, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 16),
                    Text('Requests', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_incoming.isEmpty)
                      const Text('No one is waiting.')
                    else
                      for (final r in _incoming)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            r.displayName.isEmpty ? r.email : r.displayName,
                          ),
                          subtitle: Text(r.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                        () => notifier.denyJoinRequest(r.id),
                                      ),
                                child: const Text('Do not allow'),
                              ),
                              FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                        () => notifier.allowJoinRequest(r.id),
                                      ),
                                child: const Text('Allow'),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}
