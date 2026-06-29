import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/company_profile.dart';
import '../storage/local_db.dart';
import '../storage/local_files.dart';
import '../theme/app_theme.dart';

class CompanyProfileFormScreen extends StatefulWidget {
  final CompanyProfile? existing;
  const CompanyProfileFormScreen({super.key, this.existing});

  @override
  State<CompanyProfileFormScreen> createState() => _CompanyProfileFormScreenState();
}

class _CompanyProfileFormScreenState extends State<CompanyProfileFormScreen> {
  late CompanyProfile _profile;

  final _nameCtl = TextEditingController();
  final _taglineCtl = TextEditingController();
  final _contactNameCtl = TextEditingController();
  final _phone1Ctl = TextEditingController();
  final _phone2Ctl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _websiteCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _capabilitiesCtl = TextEditingController(); // one per line

  final _bankNameCtl = TextEditingController();
  final _acHolderCtl = TextEditingController();
  final _acNumberCtl = TextEditingController();
  final _ifscCtl = TextEditingController();

  final _gstinCtl = TextEditingController();
  final _jurisdictionCtl = TextEditingController();
  final _prefixCtl = TextEditingController();
  final _gstPercentCtl = TextEditingController();
  final _stampTextCtl = TextEditingController();

  String _acType = 'Current';
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profile = widget.existing ?? CompanyProfile();
    _nameCtl.text = _profile.name;
    _taglineCtl.text = _profile.tagline;
    _contactNameCtl.text = _profile.contactName;
    _phone1Ctl.text = _profile.phone1;
    _phone2Ctl.text = _profile.phone2;
    _emailCtl.text = _profile.email;
    _websiteCtl.text = _profile.website;
    _addressCtl.text = _profile.address;
    _capabilitiesCtl.text = _profile.capabilities.join('\n');
    _bankNameCtl.text = _profile.bankName;
    _acHolderCtl.text = _profile.acHolder;
    _acNumberCtl.text = _profile.acNumber;
    _ifscCtl.text = _profile.ifsc;
    _gstinCtl.text = _profile.gstin;
    _jurisdictionCtl.text = _profile.jurisdiction;
    _prefixCtl.text = _profile.prefix;
    _gstPercentCtl.text = _profile.defaultGST.toString();
    _stampTextCtl.text = _profile.stampSignatureText;
    _acType = _profile.acType.isEmpty ? 'Current' : _profile.acType;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtl,
      _taglineCtl,
      _contactNameCtl,
      _phone1Ctl,
      _phone2Ctl,
      _emailCtl,
      _websiteCtl,
      _addressCtl,
      _capabilitiesCtl,
      _bankNameCtl,
      _acHolderCtl,
      _acNumberCtl,
      _ifscCtl,
      _gstinCtl,
      _jurisdictionCtl,
      _prefixCtl,
      _gstPercentCtl,
      _stampTextCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    _profile.name = _nameCtl.text.trim();
    _profile.tagline = _taglineCtl.text.trim();
    _profile.contactName = _contactNameCtl.text.trim();
    _profile.phone1 = _phone1Ctl.text.trim();
    _profile.phone2 = _phone2Ctl.text.trim();
    _profile.email = _emailCtl.text.trim();
    _profile.website = _websiteCtl.text.trim();
    _profile.address = _addressCtl.text.trim();
    _profile.capabilities = _capabilitiesCtl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _profile.bankName = _bankNameCtl.text.trim();
    _profile.acType = _acType;
    _profile.acHolder = _acHolderCtl.text.trim();
    _profile.acNumber = _acNumberCtl.text.trim();
    _profile.ifsc = _ifscCtl.text.trim();
    _profile.gstin = _gstinCtl.text.trim();
    _profile.jurisdiction = _jurisdictionCtl.text.trim();
    _profile.prefix = _prefixCtl.text.trim().isEmpty ? 'EQ' : _prefixCtl.text.trim();
    _profile.defaultGST = double.tryParse(_gstPercentCtl.text.trim()) ?? 18;
    _profile.stampSignatureText = _stampTextCtl.text.trim();

    await LocalDB.instance.saveProfile(_profile);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  Future<void> _pickImage(String which) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final savedPath = await LocalFiles.saveImage(File(picked.path), which);
    setState(() {
      if (which == 'logo') _profile.logoPath = savedPath;
      if (which == 'signature') _profile.signaturePath = savedPath;
      if (which == 'stamp') _profile.stampPath = savedPath;
    });
    await LocalDB.instance.saveProfile(_profile);
  }

  void _clearImage(String which) {
    setState(() {
      if (which == 'logo') _profile.logoPath = '';
      if (which == 'signature') _profile.signaturePath = '';
      if (which == 'stamp') _profile.stampPath = '';
    });
    LocalDB.instance.saveProfile(_profile);
  }

  Widget _imagePicker(String label, String which, String currentPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 90,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
              ),
              child: currentPath.isEmpty
                  ? const Icon(Icons.image_outlined, color: AppColors.line)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.file(File(currentPath), fit: BoxFit.contain),
                    ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _pickImage(which),
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(currentPath.isEmpty ? 'Upload' : 'Replace'),
            ),
            if (currentPath.isNotEmpty)
              TextButton(
                onPressed: () => _clearImage(which),
                child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
              ),
          ],
        ),
      ],
    );
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.blueprintDk,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            letterSpacing: 0.6,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Company Profile' : 'Edit Company Profile')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _sectionTitle('Company Details'),
          _field('Company Name', _nameCtl),
          _field('Tagline', _taglineCtl),
          _field('Address', _addressCtl, maxLines: 3),
          _field('Capabilities (one per line)', _capabilitiesCtl, maxLines: 4),

          _sectionTitle('Contact'),
          _field('Contact Person', _contactNameCtl),
          _field('Phone 1', _phone1Ctl, keyboardType: TextInputType.phone),
          _field('Phone 2 (optional)', _phone2Ctl, keyboardType: TextInputType.phone),
          _field('Email', _emailCtl, keyboardType: TextInputType.emailAddress),
          _field('Website', _websiteCtl),

          _sectionTitle('Branding'),
          _imagePicker('Company Logo', 'logo', _profile.logoPath),
          const SizedBox(height: 16),
          _imagePicker('Authorised Signature', 'signature', _profile.signaturePath),
          const SizedBox(height: 16),
          _imagePicker('Company Stamp', 'stamp', _profile.stampPath),
          const SizedBox(height: 14),
          _field('Fallback Signature Text (used if no signature/stamp image)', _stampTextCtl),

          _sectionTitle('Tax & Legal'),
          _field('GSTIN', _gstinCtl),
          _field('Jurisdiction (for disputes clause)', _jurisdictionCtl),
          _field('Default GST %', _gstPercentCtl, keyboardType: TextInputType.number),
          _field('Ref. No. Prefix', _prefixCtl),

          _sectionTitle('Bank Details'),
          _field('Bank Name', _bankNameCtl),
          DropdownButtonFormField<String>(
            initialValue: _acType,
            decoration: const InputDecoration(labelText: 'Account Type'),
            items: const ['Current', 'Savings']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _acType = v ?? 'Current'),
          ),
          const SizedBox(height: 14),
          _field('Account Holder', _acHolderCtl),
          _field('Account Number', _acNumberCtl),
          _field('IFSC', _ifscCtl),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Profile'),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is saved only on this device. Logo/signature/stamp images are copied into this app\'s private storage folder.',
            style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
