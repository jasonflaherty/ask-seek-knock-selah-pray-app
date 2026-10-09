import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/announce.dart';
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

  Future<void> _refreshStatus() async {
    final loaded = await _importer.isLoaded();
    if (!mounted) return;
    setState(() {
      _loaded = loaded;
      _statusReady = true;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count sample prayers')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(String format) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final content =
          format == 'csv' ? await _backup.exportCsv() : await _backup.exportJson();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read that file: $e')),
      );
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    final isCsv = ext == 'csv' || file.name.toLowerCase().endsWith('.csv');

    setState(() => _busy = true);
    try {
      final count =
          isCsv ? await _backup.importCsv(raw) : await _backup.importJson(raw);
      if (!mounted) return;
      announceForAccessibility(context, 'Imported $count prayers');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count prayers')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final showHomeVerse = ref.watch(homeVerseVisibleProvider);
    final canImport = _statusReady && !_loaded && !_busy;
    final canDelete = _statusReady && _loaded && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
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
                Text('Backup', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Export your prayers as JSON or CSV (Sheets-friendly). '
                  'Import restores them as new entries. Everything stays on '
                  'this device until you share a file.',
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
                  'Scripture promises attached. Useful for trying filters, '
                  'sort, and the verse picker.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
