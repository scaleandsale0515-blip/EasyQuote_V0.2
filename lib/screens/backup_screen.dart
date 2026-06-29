import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/local_db.dart';
import '../storage/local_files.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = LocalDB.instance.exportAll();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await LocalFiles.exportsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/easyquote_backup_$stamp.json');
      await file.writeAsString(jsonStr);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'EasyQuote backup — $stamp',
      ));
      await LocalDB.instance.setLastBackupAtNow();
      setState(() => _message = 'Backup created and ready to share/save.');
    } catch (e) {
      setState(() => _message = 'Export failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) {
        setState(() => _busy = false);
        return;
      }
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore this backup?'),
          content: const Text(
            'This will REPLACE clients, catalog items, terms presets and all '
            'quotations/invoices currently on this device with the contents '
            'of the backup file. This can\'t be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await LocalDB.instance.importAll(data);
        setState(() => _message = 'Backup restored on this device.');
      }
    } catch (e) {
      setState(() => _message = 'Import failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastBackup = LocalDB.instance.getLastBackupAt();
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'EasyQuote never syncs to the cloud — every device keeps its own '
            'independent data. Use this screen to move data between devices '
            'on purpose: export a backup file from one device, then import '
            'it on another.',
            style: TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            lastBackup == null ? 'Last backup: never' : 'Last backup: ${formatDate(lastBackup)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blueprintDk),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: AppColors.blueprint),
              title: const Text('Export backup'),
              subtitle: const Text('Save/share a JSON file of everything on this device.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : _export,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined, color: AppColors.rebar),
              title: const Text('Restore from backup'),
              subtitle: const Text('Choose a previously exported JSON file.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy ? null : _import,
            ),
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 20), child: LinearProgressIndicator()),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(_message!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
