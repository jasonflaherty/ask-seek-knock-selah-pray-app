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

  Future<void> _showOwnerPanel(String groupId) async {
    final notifier = ref.read(groupSessionProvider.notifier);
    await notifier.syncNow();
    if (!mounted) return;
    final members = await notifier.listMembers(groupId);
    if (!mounted) return;
    final group = ref.read(groupSessionProvider);
    final incoming = group.incomingJoinRequests
        .where((r) => r.groupId == groupId)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('People', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const Text('No members yet.')
                else
                  for (final m in members)
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
                              onPressed: () async {
                                await notifier.removeMember(
                                  groupId: groupId,
                                  userId: m.userId,
                                );
                                if (context.mounted) Navigator.pop(context);
                                await _showOwnerPanel(groupId);
                              },
                            ),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Requests',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (incoming.isEmpty)
                  const Text('No one is waiting.')
                else
                  for (final r in incoming)
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
                            onPressed: () async {
                              await notifier.denyJoinRequest(r.id);
                              if (context.mounted) Navigator.pop(context);
                              await _showOwnerPanel(groupId);
                            },
                            child: const Text('Do not allow'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await notifier.allowJoinRequest(r.id);
                              if (context.mounted) Navigator.pop(context);
                              await _showOwnerPanel(groupId);
                            },
                            child: const Text('Allow'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
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

  Future<void> _applyReminder({bool announceDenied = false}) async {
    final prefs = ref.read(reminderPrefsProvider);
    final reminder = ref.read(morningReminderProvider);
    if (prefs.enabled) {
      final allowed = await reminder.requestPermission();
      if (!allowed) {
        if (announceDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Allow notifications for Selah so the morning reminder can appear.',
              ),
            ),
          );
        }
        // Still call apply so a denied grant clears any stale schedule.
      }
    }
    await reminder.apply(prefs);
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
                    await _applyReminder(announceDenied: v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    '${reminder.hour.toString().padLeft(2, '0')}:'
                    '${reminder.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Symbols.schedule),
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
                    await _applyReminder(announceDenied: true);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/read-pray'),
                  icon: const Icon(Symbols.menu_book),
                  label: const Text('Open read and pray'),
                ),
                const SizedBox(height: 32),
                Text('Account and groups', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in with email to create or ask to join groups. '
                  'You may belong to more than one. Group and church '
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
                  Text('Your groups', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (session.memberships.isEmpty)
                    Text(
                      'You are not in a group yet.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final m in session.memberships)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${m.churchName} · ${m.groupName}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (group.activeMembership?.groupId ==
                                      m.groupId)
                                    Text(
                                      'Active',
                                      style: theme.textTheme.labelSmall,
                                    )
                                  else
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => ref
                                              .read(
                                                groupSessionProvider.notifier,
                                              )
                                              .setActiveGroup(m.groupId),
                                      child: const Text('Use'),
                                    ),
                                ],
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
                                                  groupSessionProvider
                                                      .notifier,
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
                                              title:
                                                  const Text('Delete group?'),
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
                      ),
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
                  const SizedBox(height: 16),
                  Text('Create or ask to join', style: theme.textTheme.titleSmall),
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
                              await ref
                                  .read(groupSessionProvider.notifier)
                                  .requestJoin(_inviteController.text);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Waiting for the group owner.',
                                  ),
                                ),
                              );
                            }),
                    child: const Text('Ask to join'),
                  ),
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
