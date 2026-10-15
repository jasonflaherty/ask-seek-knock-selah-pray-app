import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_config.dart';
import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
import '../../groups/application/group_session_notifier.dart';
import '../../reading/application/reminder_prefs.dart';
import '../../reading/data/morning_reminder.dart';
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

  Future<void> _applyReminder() async {
    final prefs = ref.read(reminderPrefsProvider);
    await ref.read(morningReminderProvider).apply(prefs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final showHomeVerse = ref.watch(homeVerseVisibleProvider);
    final group = ref.watch(groupSessionProvider);
    final reminder = ref.watch(reminderPrefsProvider);
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
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
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
                Text('Read and pray', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'A morning reminder on this phone. Private prayers stay here.',
                  style: theme.textTheme.bodyMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Morning reminder'),
                  subtitle: Text(
                    'Read for 10 minutes, then pray for 10 minutes.',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: reminder.enabled,
                  onChanged: (v) async {
                    await ref.read(reminderPrefsProvider.notifier).setEnabled(v);
                    await _applyReminder();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    '${reminder.hour.toString().padLeft(2, '0')}:'
                    '${reminder.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: reminder.hour,
                        minute: reminder.minute,
                      ),
                    );
                    if (picked == null) return;
                    await ref
                        .read(reminderPrefsProvider.notifier)
                        .setTime(picked.hour, picked.minute);
                    await _applyReminder();
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/read-pray'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Open read and pray'),
                ),
                const SizedBox(height: 32),
                Text('Account and group', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in with email to join one group. Group and church '
                  'prayers sync. Just me prayers never leave this phone.',
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
                  if (session.membership == null) ...[
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
                                await ref
                                    .read(groupSessionProvider.notifier)
                                    .joinGroup(_inviteController.text);
                              }),
                      child: const Text('Join group'),
                    ),
                  ] else ...[
                    Text(
                      '${session.membership!.churchName} · '
                      '${session.membership!.groupName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'Invite code: ${session.membership!.inviteCode}',
                      style: theme.textTheme.bodySmall,
                    ),
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
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync now'),
                    ),
                    const SizedBox(height: 8),
                    if (session.membership!.isOwner)
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete group?'),
                                    content: const Text(
                                      'This removes the group and its shared '
                                      'prayers from the server.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                await _run(() async {
                                  await ref
                                      .read(groupSessionProvider.notifier)
                                      .deleteGroup();
                                });
                              },
                        child: const Text('Delete group'),
                      )
                    else
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                  await ref
                                      .read(groupSessionProvider.notifier)
                                      .leaveGroup();
                                }),
                        child: const Text('Leave group'),
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
                                            .read(
                                              groupSessionProvider.notifier,
                                            )
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
                    icon: const Icon(Icons.logout),
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
                  icon: const Icon(Icons.insights_outlined),
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
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Export JSON'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _export('csv'),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Export CSV'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _importBackup,
                  icon: const Icon(Icons.download_outlined),
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
                      : const Icon(Icons.science_outlined),
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
                      : const Icon(Icons.delete_outline),
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
                  icon: const Icon(Icons.favorite_outline),
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
