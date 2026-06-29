import 'package:flutter/material.dart';
import '../models/quote_doc.dart';
import '../models/client.dart';
import '../models/catalog_item.dart';
import '../models/terms_preset.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/ids.dart';
import '../utils/formatters.dart';
import 'client_form_screen.dart';
import 'document_preview_screen.dart';

class DocumentFormScreen extends StatefulWidget {
  final DocType docType;
  final QuoteDoc? existing;
  const DocumentFormScreen({super.key, required this.docType, this.existing});

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  late QuoteDoc _doc;
  List<Client> _clients = [];
  List<CatalogItem> _catalog = [];
  List<TermsPreset> _termsPresets = [];
  List<CompanyProfile> _profiles = [];

  final _siteLocationCtl = TextEditingController();
  final _introCtl = TextEditingController();
  final _gstCtl = TextEditingController();
  final _poInNameCtl = TextEditingController();
  final _poPercentCtl = TextEditingController();
  final _amountPaidCtl = TextEditingController();

  final List<TextEditingController> _headerNoteCtls = [];
  final List<TextEditingController> _specNoteCtls = [];

  @override
  void initState() {
    super.initState();
    _clients = LocalDB.instance.getClients();
    _catalog = LocalDB.instance.getCatalogItems();
    _termsPresets = LocalDB.instance.getTermsPresets();
    _profiles = LocalDB.instance.getProfiles();

    if (widget.existing != null) {
      _doc = widget.existing!;
    } else {
      final profile = LocalDB.instance.getActiveProfile();
      final seq = LocalDB.instance.nextCounter(widget.docType.name);
      final tag = widget.docType == DocType.quotation ? 'Q' : 'INV';
      final refNo = '${profile.prefix.isEmpty ? 'EQ' : profile.prefix}/$tag/${seq.toString().padLeft(2, '0')}';
      _doc = QuoteDoc(
        id: generateId(),
        type: widget.docType,
        refNo: refNo,
        date: DateTime.now(),
        gstPercent: profile.defaultGST,
        profileId: profile.id,
        termsId: _termsPresets.isNotEmpty ? _termsPresets.first.id : '',
        termsSnapshot: _termsPresets.isNotEmpty ? _termsPresets.first : null,
      );
    }

    _siteLocationCtl.text = _doc.siteLocation;
    _introCtl.text = _doc.introText;
    _gstCtl.text = _doc.gstPercent.toString();
    _poInNameCtl.text = _doc.poInName;
    _poPercentCtl.text = _doc.poPercent.toString();
    _amountPaidCtl.text = _doc.amountPaid.toString();

    for (final n in _doc.headerNotes) {
      _headerNoteCtls.add(TextEditingController(text: n));
    }
    for (final n in _doc.specNotes) {
      _specNoteCtls.add(TextEditingController(text: n));
    }
  }

  @override
  void dispose() {
    _siteLocationCtl.dispose();
    _introCtl.dispose();
    _gstCtl.dispose();
    _poInNameCtl.dispose();
    _poPercentCtl.dispose();
    _amountPaidCtl.dispose();
    for (final c in _headerNoteCtls) c.dispose();
    for (final c in _specNoteCtls) c.dispose();
    super.dispose();
  }

  double get _subtotal => _doc.lineItems.fold(0.0, (s, li) => s + li.amount);
  double get _gstAmount => _subtotal * ((double.tryParse(_gstCtl.text) ?? 0) / 100);
  double get _total => _subtotal + _gstAmount;

  void _addLineItem({CatalogItem? fromCatalog}) {
    setState(() {
      _doc.lineItems.add(
        fromCatalog != null
            ? LineItem(description: fromCatalog.description, unit: fromCatalog.unit, qty: 1, rate: fromCatalog.rate)
            : LineItem(qty: 1),
      );
    });
  }

  void _removeLineItem(int i) {
    setState(() => _doc.lineItems.removeAt(i));
  }

  void _addHeaderNote() => setState(() => _headerNoteCtls.add(TextEditingController()));
  void _removeHeaderNote(int i) => setState(() => _headerNoteCtls.removeAt(i));
  void _addSpecNote() => setState(() => _specNoteCtls.add(TextEditingController()));
  void _removeSpecNote(int i) => setState(() => _specNoteCtls.removeAt(i));

  /// Keeps "Amount Paid" and "Status" in sync for invoices, so the
  /// Dashboard's paid/outstanding totals stay correct no matter which one
  /// you actually update.
  void _onStatusChanged(DocStatus newStatus) {
    setState(() {
      _doc.status = newStatus;
      if (widget.docType == DocType.invoice) {
        if (newStatus == DocStatus.paid) {
          _amountPaidCtl.text = _total.toStringAsFixed(2);
        } else if (newStatus != DocStatus.partiallyPaid && (double.tryParse(_amountPaidCtl.text) ?? 0) >= _total) {
          // Switching away from Paid/Partially-Paid to something like Draft
          // or Sent with a full amount still set would be confusing — reset it.
          _amountPaidCtl.text = '0';
        }
      }
    });
  }

  void _onAmountPaidChanged(String value) {
    setState(() {
      if (widget.docType != DocType.invoice) return;
      final paid = double.tryParse(value) ?? 0;
      if (_total <= 0) return;
      if (paid >= _total - 0.01) {
        _doc.status = DocStatus.paid;
      } else if (paid > 0) {
        _doc.status = DocStatus.partiallyPaid;
      }
    });
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final initial = isDueDate ? (_doc.dueDate ?? DateTime.now()) : _doc.date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _doc.dueDate = picked;
        } else {
          _doc.date = picked;
        }
      });
    }
  }

  Future<void> _addClientInline() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClientFormScreen()));
    setState(() => _clients = LocalDB.instance.getClients());
  }

  Future<void> _save({bool openPreview = false}) async {
    if (_doc.clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a client')));
      return;
    }
    if (_doc.lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one line item')));
      return;
    }

    _doc.siteLocation = _siteLocationCtl.text.trim();
    _doc.introText = _introCtl.text.trim();
    _doc.gstPercent = double.tryParse(_gstCtl.text.trim()) ?? 18;
    _doc.poInName = _poInNameCtl.text.trim();
    _doc.poPercent = double.tryParse(_poPercentCtl.text.trim()) ?? 0;
    _doc.amountPaid = double.tryParse(_amountPaidCtl.text.trim()) ?? 0;
    _doc.headerNotes = _headerNoteCtls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    _doc.specNotes = _specNoteCtls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    await LocalDB.instance.saveDocument(_doc);

    if (!mounted) return;
    if (openPreview) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DocumentPreviewScreen(docId: _doc.id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.docType == DocType.quotation ? 'Quotation' : 'Invoice'} saved')),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
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
    final isQuotation = widget.docType == DocType.quotation;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isQuotation ? 'Quotation' : 'Invoice'}  •  ${_doc.refNo}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- Client + dates ----------------
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _doc.clientId.isEmpty ? null : _doc.clientId,
                  decoration: const InputDecoration(labelText: 'Client *'),
                  items: _clients
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.companyName)))
                      .toList(),
                  onChanged: (v) => setState(() => _doc.clientId = v ?? ''),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_outlined),
                tooltip: 'Add new client',
                onPressed: _addClientInline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isDueDate: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(formatDate(_doc.date)),
                  ),
                ),
              ),
              if (!isQuotation) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isDueDate: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date'),
                      child: Text(_doc.dueDate != null ? formatDate(_doc.dueDate!) : '—'),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _siteLocationCtl,
            decoration: const InputDecoration(labelText: 'Site location (optional, used in intro line)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _introCtl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Intro line (optional — leave blank to auto-generate)',
            ),
          ),

          // ---------------- Header notes ----------------
          _sectionTitle('Header Notes'),
          ..._headerNoteCtls.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(labelText: 'Note ${e.key + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeHeaderNote(e.key),
                    ),
                  ],
                ),
              )),
          TextButton.icon(
            onPressed: _addHeaderNote,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add header note'),
          ),

          // ---------------- Line items ----------------
          _sectionTitle('Line Items'),
          ..._doc.lineItems.asMap().entries.map((entry) {
            final i = entry.key;
            final li = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: li.description,
                      decoration: const InputDecoration(labelText: 'Description'),
                      onChanged: (v) => li.description = v,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: li.unit,
                            decoration: const InputDecoration(labelText: 'Unit'),
                            onChanged: (v) => li.unit = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: li.qty == 0 ? '' : li.qty.toString(),
                            decoration: const InputDecoration(labelText: 'Qty'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() => li.qty = double.tryParse(v) ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: li.rate == 0 ? '' : li.rate.toString(),
                            decoration: const InputDecoration(labelText: 'Rate'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) => setState(() => li.rate = double.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _removeLineItem(i),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(formatRupees(li.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _addLineItem(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add line item'),
              ),
              const SizedBox(width: 8),
              if (_catalog.isNotEmpty)
                PopupMenuButton<CatalogItem>(
                  tooltip: 'Add from catalog',
                  onSelected: (item) => _addLineItem(fromCatalog: item),
                  itemBuilder: (ctx) => _catalog
                      .map((it) => PopupMenuItem(value: it, child: Text(it.description)))
                      .toList(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.blueprint),
                        SizedBox(width: 6),
                        Text('From catalog', style: TextStyle(color: AppColors.blueprint, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ---------------- Spec notes ----------------
          _sectionTitle('Spec / Italic Notes (shown as extra rows under the table)'),
          ..._specNoteCtls.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(labelText: 'Spec note ${e.key + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeSpecNote(e.key),
                    ),
                  ],
                ),
              )),
          TextButton.icon(
            onPressed: _addSpecNote,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add spec note'),
          ),

          // ---------------- Totals / GST ----------------
          _sectionTitle('GST & Totals'),
          TextField(
            controller: _gstCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'GST %'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Card(
            color: AppColors.paperDim,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _totalRow('Subtotal', _subtotal),
                  _totalRow('GST @ ${_gstCtl.text.isEmpty ? 0 : _gstCtl.text}% (Extra)', _gstAmount),
                  const Divider(),
                  _totalRow('Total', _total, bold: true),
                  if (!isQuotation) ...[
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountPaidCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount Paid'),
                      onChanged: _onAmountPaidChanged,
                    ),
                    const SizedBox(height: 6),
                    _totalRow('Balance Due', _total - (double.tryParse(_amountPaidCtl.text) ?? 0), bold: true),
                  ],
                ],
              ),
            ),
          ),

          // ---------------- PO clause ----------------
          _sectionTitle('Purchase Order Clause (optional)'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include PO clause on document'),
            value: _doc.includePO,
            onChanged: (v) => setState(() => _doc.includePO = v),
          ),
          if (_doc.includePO) ...[
            TextField(
              controller: _poInNameCtl,
              decoration: const InputDecoration(labelText: 'PO to be issued in the name of'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _poPercentCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'PO % of above value'),
            ),
          ],

          // ---------------- Terms preset ----------------
          _sectionTitle('Terms & Conditions'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include Terms & Conditions page'),
            subtitle: const Text('Turn off if this document doesn\'t need one.', style: TextStyle(fontSize: 11.5)),
            value: _doc.includeTerms,
            onChanged: (v) => setState(() => _doc.includeTerms = v),
          ),
          if (_doc.includeTerms) ...[
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _doc.termsId.isEmpty ? null : _doc.termsId,
              decoration: const InputDecoration(labelText: 'Preset'),
              items: _termsPresets.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (v) {
                setState(() {
                  _doc.termsId = v ?? '';
                  _doc.termsSnapshot = _termsPresets.firstWhere((t) => t.id == v, orElse: () => _termsPresets.first);
                });
              },
            ),
            const SizedBox(height: 4),
            const Text(
              'A snapshot of this preset\'s wording is saved with the document, so editing the '
              'preset later won\'t change wording on documents already issued.',
              style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
          ],

          // ---------------- Company profile (only shown if you have more than one) ----------------
          if (_profiles.length > 1) ...[
            _sectionTitle('Issued From'),
            DropdownButtonFormField<String>(
              initialValue: _doc.profileId.isEmpty ? null : _doc.profileId,
              decoration: const InputDecoration(labelText: 'Company Profile'),
              items: _profiles
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name.isEmpty ? '(unnamed)' : p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _doc.profileId = v ?? _doc.profileId),
            ),
          ],

          // ---------------- Status ----------------
          _sectionTitle('Status'),
          DropdownButtonFormField<DocStatus>(
            initialValue: _doc.status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: DocStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => _onStatusChanged(v ?? DocStatus.draft),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(openPreview: false),
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _save(openPreview: true),
                  child: const Text('Save & Preview'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 13.5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: style),
          const SizedBox(width: 20),
          Text(formatRupees(value), style: style),
        ],
      ),
    );
  }
}
