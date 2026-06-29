import 'package:flutter/material.dart';
import '../models/client.dart';
import '../storage/local_db.dart';
import '../utils/ids.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? existing;
  const ClientFormScreen({super.key, this.existing});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _companyNameCtl = TextEditingController();
  final _contactPersonCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _gstinCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _companyNameCtl.text = e.companyName;
      _contactPersonCtl.text = e.contactPerson;
      _phoneCtl.text = e.phone;
      _emailCtl.text = e.email;
      _addressCtl.text = e.address;
      _gstinCtl.text = e.gstin;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _companyNameCtl,
      _contactPersonCtl,
      _phoneCtl,
      _emailCtl,
      _addressCtl,
      _gstinCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_companyNameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name is required')),
      );
      return;
    }
    final client = Client(
      id: widget.existing?.id ?? generateId(),
      companyName: _companyNameCtl.text.trim(),
      contactPerson: _contactPersonCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      email: _emailCtl.text.trim(),
      address: _addressCtl.text.trim(),
      gstin: _gstinCtl.text.trim(),
    );
    await LocalDB.instance.saveClient(client);
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
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Client' : 'Edit Client')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field('Company Name *', _companyNameCtl),
          _field('Contact Person', _contactPersonCtl),
          _field('Phone', _phoneCtl, keyboardType: TextInputType.phone),
          _field('Email', _emailCtl, keyboardType: TextInputType.emailAddress),
          _field('Address', _addressCtl, maxLines: 3),
          _field('GSTIN', _gstinCtl),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _save, child: const Text('Save Client')),
        ],
      ),
    );
  }
}
