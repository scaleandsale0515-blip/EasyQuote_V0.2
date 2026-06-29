import 'package:flutter/material.dart';
import '../models/terms_preset.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/ids.dart';
import 'terms_form_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  List<TermsPreset> _terms = [];

  @override
  void initState() {
    super.initState();
    _ensureSeed();
  }

  Future<void> _ensureSeed() async {
    var list = LocalDB.instance.getTermsPresets();
    if (list.isEmpty) {
      // Seed with one ready-made starting point so there's always at least
      // one preset to pick from — this never affects presets you create
      // yourself, which always start blank.
      final seed = TermsPreset.standardSeed(generateId());
      await LocalDB.instance.saveTermsPreset(seed);
      list = LocalDB.instance.getTermsPresets();
    }
    setState(() => _terms = list);
  }

  void _reload() {
    setState(() => _terms = LocalDB.instance.getTermsPresets());
  }

  Future<void> _openForm({TermsPreset? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TermsFormScreen(existing: existing)),
    );
    _reload();
  }

  Future<void> _confirmDelete(TermsPreset t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('Remove "${t.name}" from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await LocalDB.instance.deleteTermsPreset(t.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms Templates')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _terms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          final t = _terms[idx];
          return Card(
            child: ListTile(
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${t.clauses.length} clause${t.clauses.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => _openForm(existing: t),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _confirmDelete(t),
              ),
            ),
          );
        },
      ),
    );
  }
}
