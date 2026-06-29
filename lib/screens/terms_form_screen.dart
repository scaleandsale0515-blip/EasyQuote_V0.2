import 'package:flutter/material.dart';
import '../models/terms_preset.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/ids.dart';

class TermsFormScreen extends StatefulWidget {
  final TermsPreset? existing;
  const TermsFormScreen({super.key, this.existing});

  @override
  State<TermsFormScreen> createState() => _TermsFormScreenState();
}

class _TermsFormScreenState extends State<TermsFormScreen> {
  final _nameCtl = TextEditingController();
  final List<TextEditingController> _clauseCtls = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    // A brand new preset starts completely blank — name empty, zero clauses.
    // It never gets pre-filled with another preset's wording.
    _nameCtl.text = e?.name ?? '';
    if (e != null) {
      for (final c in e.clauses) {
        _clauseCtls.add(TextEditingController(text: c));
      }
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    for (final c in _clauseCtls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addClause() => setState(() => _clauseCtls.add(TextEditingController()));
  void _removeClause(int i) => setState(() => _clauseCtls.removeAt(i));
  void _moveClause(int from, int to) {
    setState(() {
      final item = _clauseCtls.removeAt(from);
      _clauseCtls.insert(to, item);
    });
  }

  Future<void> _save() async {
    if (_nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preset name is required')),
      );
      return;
    }
    final clauses = _clauseCtls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final preset = TermsPreset(
      id: widget.existing?.id ?? generateId(),
      name: _nameCtl.text.trim(),
      clauses: clauses,
    );
    await LocalDB.instance.saveTermsPreset(preset);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Terms Preset' : 'Edit Terms Preset')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addClause,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(labelText: 'Preset Name *'),
          ),
          const SizedBox(height: 18),
          Text(
            'CLAUSES (${_clauseCtls.length})',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.blueprintDk,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add as many or as few as you need — each becomes a numbered '
            'clause on the document. Plain text only.',
            style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          if (_clauseCtls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.playlist_add_outlined, size: 40, color: AppColors.line),
                    const SizedBox(height: 10),
                    const Text('No clauses yet', style: TextStyle(color: AppColors.inkSoft)),
                    const SizedBox(height: 4),
                    TextButton(onPressed: _addClause, child: const Text('Add the first clause')),
                  ],
                ),
              ),
            ),
          ..._clauseCtls.asMap().entries.map((entry) {
            final i = entry.key;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        maxLines: null,
                        minLines: 2,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Clause text…',
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        if (i > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            tooltip: 'Move up',
                            onPressed: () => _moveClause(i, i - 1),
                          ),
                        if (i < _clauseCtls.length - 1)
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            tooltip: 'Move down',
                            onPressed: () => _moveClause(i, i + 1),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _removeClause(i),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addClause,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add clause'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Save Preset')),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
