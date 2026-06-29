import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/quote_doc.dart';
import '../models/line_item.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/ids.dart';
import '../pdf/pdf_builder.dart';
import 'document_form_screen.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String docId;
  const DocumentPreviewScreen({super.key, required this.docId});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  QuoteDoc? _doc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final all = LocalDB.instance.getDocuments();
    final found = all.where((d) => d.id == widget.docId);
    setState(() => _doc = found.isEmpty ? null : found.first);
  }

  Future<void> _duplicate() async {
    final d = _doc;
    if (d == null) return;
    final profile = LocalDB.instance.getActiveProfile();
    final seq = LocalDB.instance.nextCounter(d.type.name);
    final tag = d.type == DocType.quotation ? 'Q' : 'INV';
    final refNo = '${profile.prefix.isEmpty ? 'EQ' : profile.prefix}/$tag/${seq.toString().padLeft(2, '0')}';

    final copy = QuoteDoc(
      id: generateId(),
      type: d.type,
      refNo: refNo,
      date: DateTime.now(),
      clientId: d.clientId,
      termsId: d.termsId,
      termsSnapshot: d.termsSnapshot,
      includeTerms: d.includeTerms,
      profileId: d.profileId,
      lineItems: d.lineItems.map((li) => LineItem(description: li.description, unit: li.unit, qty: li.qty, rate: li.rate)).toList(),
      headerNotes: List<String>.from(d.headerNotes),
      specNotes: List<String>.from(d.specNotes),
      introText: d.introText,
      siteLocation: d.siteLocation,
      gstPercent: d.gstPercent,
      includePO: d.includePO,
      poInName: d.poInName,
      poPercent: d.poPercent,
      status: DocStatus.draft,
    );
    await LocalDB.instance.saveDocument(copy);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DocumentPreviewScreen(docId: copy.id)),
    );
  }

  Future<void> _convertToInvoice() async {
    final d = _doc;
    if (d == null || d.type != DocType.quotation) return;
    final profile = LocalDB.instance.getActiveProfile();
    final seq = LocalDB.instance.nextCounter(DocType.invoice.name);
    final refNo = '${profile.prefix.isEmpty ? 'EQ' : profile.prefix}/INV/${seq.toString().padLeft(2, '0')}';

    final invoice = QuoteDoc(
      id: generateId(),
      type: DocType.invoice,
      refNo: refNo,
      date: DateTime.now(),
      clientId: d.clientId,
      termsId: d.termsId,
      termsSnapshot: d.termsSnapshot,
      includeTerms: d.includeTerms,
      profileId: d.profileId,
      lineItems: d.lineItems.map((li) => LineItem(description: li.description, unit: li.unit, qty: li.qty, rate: li.rate)).toList(),
      headerNotes: List<String>.from(d.headerNotes),
      specNotes: List<String>.from(d.specNotes),
      introText: d.introText,
      siteLocation: d.siteLocation,
      gstPercent: d.gstPercent,
      includePO: d.includePO,
      poInName: d.poInName,
      poPercent: d.poPercent,
      status: DocStatus.draft,
    );
    await LocalDB.instance.saveDocument(invoice);

    d.status = DocStatus.converted;
    await LocalDB.instance.saveDocument(d);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DocumentPreviewScreen(docId: invoice.id)),
    );
  }

  Future<Uint8List> _generate(PdfPageFormat format) async {
    final doc = _doc;
    if (doc == null) return Uint8List(0);
    final profile = LocalDB.instance.getProfileById(doc.profileId);
    final clients = LocalDB.instance.getClients();
    final client = clients.where((c) => c.id == doc.clientId);
    if (client.isEmpty) {
      _error = 'This document\'s client no longer exists.';
      return Uint8List(0);
    }
    try {
      return await DocumentPdfBuilder.build(profile: profile, client: client.first, doc: doc);
    } catch (e) {
      _error = 'PDF generation failed: $e';
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: Text('Document not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.refNo),
        actions: [
          if (doc.type == DocType.quotation)
            IconButton(
              icon: const Icon(Icons.sync_alt),
              tooltip: 'Convert to Invoice',
              onPressed: _convertToInvoice,
            ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Duplicate',
            onPressed: _duplicate,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DocumentFormScreen(docType: doc.type, existing: doc),
                ),
              );
              _load();
            },
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            )
          : PdfPreview(
              build: _generate,
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: '${doc.refNo.replaceAll('/', '-')}.pdf',
              initialPageFormat: PdfPageFormat.a4,
            ),
    );
  }
}
