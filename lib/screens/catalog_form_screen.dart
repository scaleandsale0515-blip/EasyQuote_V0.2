import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../storage/local_db.dart';
import '../utils/ids.dart';

class CatalogFormScreen extends StatefulWidget {
  final CatalogItem? existing;
  const CatalogFormScreen({super.key, this.existing});

  @override
  State<CatalogFormScreen> createState() => _CatalogFormScreenState();
}

class _CatalogFormScreenState extends State<CatalogFormScreen> {
  final _descCtl = TextEditingController();
  final _unitCtl = TextEditingController();
  final _rateCtl = TextEditingController();
  final _gradeCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _descCtl.text = e.description;
      _unitCtl.text = e.unit;
      _rateCtl.text = e.rate.toString();
      _gradeCtl.text = e.grade;
    }
  }

  @override
  void dispose() {
    for (final c in [_descCtl, _unitCtl, _rateCtl, _gradeCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_descCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description is required')),
      );
      return;
    }
    final item = CatalogItem(
      id: widget.existing?.id ?? generateId(),
      description: _descCtl.text.trim(),
      unit: _unitCtl.text.trim(),
      rate: double.tryParse(_rateCtl.text.trim()) ?? 0,
      grade: _gradeCtl.text.trim(),
    );
    await LocalDB.instance.saveCatalogItem(item);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _field(String label, TextEditingController ctl, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Item' : 'Edit Item')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field('Description *', _descCtl, maxLines: 2),
          _field('Unit (e.g. Sqm, Nos, Rmt)', _unitCtl),
          _field('Rate', _rateCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          _field('Grade / Spec (optional, e.g. M30)', _gradeCtl),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _save, child: const Text('Save Item')),
        ],
      ),
    );
  }
}
