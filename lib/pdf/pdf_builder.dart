import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company_profile.dart';
import '../models/client.dart';
import '../models/quote_doc.dart';
import '../models/terms_preset.dart';
import '../utils/formatters.dart';

class PdfFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;
  PdfFonts({required this.regular, required this.bold, required this.italic});

  static Future<PdfFonts> load() async {
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final italicData = await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');
    return PdfFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
      italic: pw.Font.ttf(italicData),
    );
  }
}

/// Colors matched to the original web template's CSS variables.
class _Pal {
  static const ink = PdfColor.fromInt(0xFF232220);
  static const inkSoft = PdfColor.fromInt(0xFF5B5750);
  static const blueprintDk = PdfColor.fromInt(0xFF1F4757);
  static const paperDim = PdfColor.fromInt(0xFFE3DFD4);
  static const line = PdfColor.fromInt(0xFFD8D3C8);
  static const white = PdfColor.fromInt(0xFFFFFFFF);
  static const black = PdfColor.fromInt(0xFF000000);
  static const poBg = PdfColor.fromInt(0xFFFAF3E9);
  static const poBorder = PdfColor.fromInt(0xFFECD9BD);
}

class DocumentPdfBuilder {
  static Future<Uint8List> build({
    required CompanyProfile profile,
    required Client client,
    required QuoteDoc doc,
  }) async {
    final fonts = await PdfFonts.load();
    final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold, italic: fonts.italic);

    final pdf = pw.Document(theme: theme);

    pw.MemoryImage? logoImg = _tryLoadImage(profile.logoPath);
    pw.MemoryImage? sigImg = _tryLoadImage(profile.signaturePath);
    pw.MemoryImage? stampImg = _tryLoadImage(profile.stampPath);

    final isQuotation = doc.type == DocType.quotation;
    final docLabel = isQuotation ? 'QUOTATION / CONTRACT' : 'TAX INVOICE';
    final ts = doc.termsSnapshot ?? TermsPreset(id: '');

    final intro = doc.introText.isNotEmpty
        ? doc.introText
        : 'We are pleased to submit detailed ${isQuotation ? 'Quotation' : 'Invoice'} for '
            '${client.companyName.isEmpty ? 'your company' : client.companyName}'
            '${doc.siteLocation.isNotEmpty ? ' for your site located at ${doc.siteLocation}' : ''}.';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          // Proper breathing space from every edge of the paper.
          margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
          theme: theme,
        ),
        header: (context) => context.pageNumber == 1
            ? _buildLetterhead(profile, logoImg, docLabel, fonts)
            : pw.SizedBox(),
        build: (context) => [
          _buildMetaRow(client, doc, fonts),
          pw.SizedBox(height: 10),
          _buildIntro(intro, doc.headerNotes, fonts),
          pw.SizedBox(height: 8),
          _buildItemsTable(doc, fonts),
          pw.SizedBox(height: 6),
          _buildTotals(doc, fonts),
          pw.SizedBox(
            height: 2,
            child: pw.Text(
              '(exclusive of taxes and duties)',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _Pal.inkSoft),
            ),
          ),
          pw.SizedBox(height: 10),
          if (doc.includePO) _buildPoNote(doc, fonts),

          // ---- Terms & Conditions: only when the toggle is on, and only
          // when the preset actually has clauses. Always starts on its own
          // fresh page when shown. ----
          if (doc.includeTerms && ts.clauses.isNotEmpty) ...[
            pw.NewPage(),
            _buildTermsHeading(fonts),
            _buildTermsList(ts, fonts),
            pw.SizedBox(height: 16),
          ] else
            pw.SizedBox(height: 16),
          _buildBottomBlock(profile, sigImg, stampImg, fonts),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.MemoryImage? _tryLoadImage(String path) {
    if (path.isEmpty) return null;
    final f = File(path);
    if (!f.existsSync()) return null;
    try {
      return pw.MemoryImage(f.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _buildLetterhead(
      CompanyProfile c, pw.MemoryImage? logo, String docLabel, PdfFonts fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: c.capabilities.isEmpty
                  ? pw.SizedBox()
                  : pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Our Capabilities',
                            style: pw.TextStyle(font: fonts.bold, fontSize: 9, color: _Pal.ink)),
                        pw.SizedBox(height: 2),
                        ...c.capabilities.map((cap) => pw.Text(cap,
                            style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _Pal.blueprintDk))),
                      ],
                    ),
            ),
            if (logo != null) pw.Container(width: 110, height: 56, child: pw.Image(logo, fit: pw.BoxFit.contain)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(c.name.isEmpty ? 'Your Company' : c.name,
                  style: pw.TextStyle(font: fonts.bold, fontSize: 17)),
              if (c.tagline.isNotEmpty)
                pw.Text('"${c.tagline}"',
                    style: pw.TextStyle(font: fonts.italic, fontSize: 8.5, color: _Pal.inkSoft)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        if (c.address.isNotEmpty || c.website.isNotEmpty || c.email.isNotEmpty)
          pw.Center(
            child: pw.Text(
              [
                if (c.address.isNotEmpty) c.address,
                [if (c.website.isNotEmpty) c.website, if (c.email.isNotEmpty) 'Email: ${c.email}'].join('   '),
              ].where((s) => s.isNotEmpty).join('\n'),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: fonts.regular, fontSize: 8.5, color: _Pal.inkSoft),
            ),
          ),
        if (c.contactName.isNotEmpty || c.phone1.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Center(
              child: pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(text: c.contactName, style: pw.TextStyle(font: fonts.bold, fontSize: 9)),
                  if (c.phone1.isNotEmpty)
                    pw.TextSpan(
                      text: '   Mo: ${c.phone1}${c.phone2.isNotEmpty ? ' / ${c.phone2}' : ''}',
                      style: pw.TextStyle(font: fonts.regular, fontSize: 9),
                    ),
                ]),
              ),
            ),
          ),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 8, bottom: 10),
          width: double.infinity,
          color: _Pal.ink,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Center(
            child: pw.Text(docLabel,
                style: pw.TextStyle(font: fonts.bold, fontSize: 12, color: _Pal.white, letterSpacing: 1.2)),
          ),
        ),
      ],
    );
  }

  /// Date/Ref. No. box made narrower and fixed-width; the To/Kind Attn/Mo/Email
  /// block gets the remaining (larger) share of the row's width.
  static pw.Widget _buildMetaRow(Client client, QuoteDoc doc, PdfFonts fonts) {
    final rows = <List<String>>[
      ['Date', formatDate(doc.date)],
      ['Ref. No.', doc.refNo],
    ];
    if (doc.type == DocType.invoice && doc.dueDate != null) {
      rows.add(['Due Date', formatDate(doc.dueDate!)]);
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(text: 'To: ', style: pw.TextStyle(font: fonts.bold, fontSize: 9.5)),
                  pw.TextSpan(
                      text: client.companyName.isEmpty ? '—' : client.companyName,
                      style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
                ]),
              ),
              if (client.contactPerson.isNotEmpty)
                pw.Text('Kind Attn.: ${client.contactPerson}', style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
              if (client.phone.isNotEmpty)
                pw.Text('Mo: ${client.phone}', style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
              if (client.email.isNotEmpty)
                pw.Text('Email: ${client.email}', style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        // Fixed, narrow width — does not expand to eat the row's space.
        pw.Container(
          width: 140,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _Pal.line, width: 0.6)),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _Pal.line, width: 0.6),
            ),
            columnWidths: const {0: pw.FlexColumnWidth(1.1), 1: pw.FlexColumnWidth(1.4)},
            children: rows
                .map((r) => pw.TableRow(children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Text(r[0], style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _Pal.inkSoft)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Text(r[1], style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
                      ),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildIntro(String intro, List<String> headerNotes, PdfFonts fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Dear Sir,', style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
        pw.SizedBox(height: 2),
        pw.Text(intro, style: pw.TextStyle(font: fonts.regular, fontSize: 9.5)),
        if (headerNotes.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          ...headerNotes.map((n) => pw.Text('# $n',
              style: pw.TextStyle(font: fonts.regular, fontSize: 8, color: _Pal.blueprintDk))),
        ],
      ],
    );
  }

  static pw.Widget _buildItemsTable(QuoteDoc doc, PdfFonts fonts) {
    final headerStyle = pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: _Pal.ink);
    final cellStyle = pw.TextStyle(font: fonts.regular, fontSize: 8.5);

    pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.left, bool header = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(text, style: header ? headerStyle : cellStyle, textAlign: align),
        );

    final table = pw.Table(
      border: pw.TableBorder.all(color: _Pal.line, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.2),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _Pal.paperDim),
          children: [
            cell('DESCRIPTION', header: true),
            cell('UNIT', header: true),
            cell('QTY', header: true),
            cell('RATE', header: true),
            cell('AMOUNT (₹)', header: true),
          ],
        ),
        ...doc.lineItems.map((li) => pw.TableRow(children: [
              cell(li.description),
              cell(li.unit, align: pw.TextAlign.center),
              cell(li.qty == li.qty.roundToDouble() ? li.qty.toStringAsFixed(0) : li.qty.toString(),
                  align: pw.TextAlign.right),
              cell(formatRupees(li.rate), align: pw.TextAlign.right),
              cell(formatRupees(li.amount), align: pw.TextAlign.right),
            ])),
      ],
    );

    if (doc.specNotes.isEmpty) return table;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        table,
        ...doc.specNotes.map((n) => pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: _Pal.line, width: 0.6),
                  right: pw.BorderSide(color: _Pal.line, width: 0.6),
                  bottom: pw.BorderSide(color: _Pal.line, width: 0.6),
                ),
                color: const PdfColor.fromInt(0xFFFAF8F3),
              ),
              child: pw.Text(n, style: pw.TextStyle(font: fonts.italic, fontSize: 8, color: _Pal.inkSoft)),
            )),
      ],
    );
  }

  /// Totals block — right-aligned (not centered), matching a normal invoice layout.
  static pw.Widget _buildTotals(QuoteDoc doc, PdfFonts fonts) {
    final rows = <pw.TableRow>[
      _totalRow('Subtotal', formatRupees(doc.subtotal), fonts, bold: false),
      _totalRow('GST @ ${_trimZero(doc.gstPercent)}% (Extra)', formatRupees(doc.gstAmount), fonts, bold: false),
      _totalRow('Total', formatRupees(doc.total), fonts, bold: true, topBorder: true),
    ];
    if (doc.type == DocType.invoice && doc.amountPaid > 0) {
      rows.add(_totalRow('Amount Paid', formatRupees(doc.amountPaid), fonts, bold: false));
      rows.add(_totalRow('Balance Due', formatRupees(doc.balanceDue), fonts, bold: true));
    }

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 230,
        child: pw.Table(
          columnWidths: const {0: pw.FlexColumnWidth(1.4), 1: pw.FlexColumnWidth(1)},
          children: rows,
        ),
      ),
    );
  }

  static pw.TableRow _totalRow(String label, String value, PdfFonts fonts,
      {bool bold = false, bool topBorder = false}) {
    final style = pw.TextStyle(font: bold ? fonts.bold : fonts.regular, fontSize: bold ? 11 : 9);
    final border = topBorder
        ? const pw.Border(top: pw.BorderSide(color: _Pal.black, width: 1.1))
        : null;
    return pw.TableRow(
      decoration: border != null ? pw.BoxDecoration(border: border) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static String _trimZero(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  static pw.Widget _buildPoNote(QuoteDoc doc, PdfFonts fonts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _Pal.poBg,
        border: pw.Border.all(color: _Pal.poBorder, width: 0.7),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(font: fonts.regular, fontSize: 8.5),
          children: [
            const pw.TextSpan(text: 'Material Purchase Order to be issued in the name of '),
            pw.TextSpan(text: doc.poInName, style: pw.TextStyle(font: fonts.bold)),
            pw.TextSpan(text: ' @ ${_trimZero(doc.poPercent)}% of above value.'),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTermsHeading(PdfFonts fonts) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        'Terms & Conditions',
        style: pw.TextStyle(font: fonts.bold, fontSize: 12, decoration: pw.TextDecoration.underline),
      ),
    );
  }

  static pw.Widget _buildTermsList(TermsPreset ts, PdfFonts fonts) {
    final mainStyle = pw.TextStyle(font: fonts.regular, fontSize: 9);
    final numStyle = pw.TextStyle(font: fonts.bold, fontSize: 9);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: ts.clauses.asMap().entries.map((entry) {
        final n = entry.key + 1;
        final text = entry.value;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 18, child: pw.Text('$n.', style: numStyle)),
              pw.Expanded(child: pw.Text(text, style: mainStyle)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildBottomBlock(
      CompanyProfile profile, pw.MemoryImage? sigImg, pw.MemoryImage? stampImg, PdfFonts fonts) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BANK DETAILS', style: pw.TextStyle(font: fonts.bold, fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Text('Bank Name: ${profile.bankName}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
              pw.Text('A/C Type: ${profile.acType}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
              pw.Text('A/C Holder: ${profile.acHolder}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
              pw.Text('A/C No.: ${profile.acNumber}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
              pw.Text('IFSC: ${profile.ifsc}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
            ],
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('For, ${profile.name}', style: pw.TextStyle(font: fonts.regular, fontSize: 8.5)),
              pw.SizedBox(height: 8),
              if (sigImg != null) pw.Container(height: 36, child: pw.Image(sigImg, fit: pw.BoxFit.contain)),
              if (stampImg != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Container(height: 44, child: pw.Image(stampImg, fit: pw.BoxFit.contain)),
                ),
              if (sigImg == null && stampImg == null)
                pw.Text(
                  profile.stampSignatureText.isEmpty ? profile.name : profile.stampSignatureText,
                  style: pw.TextStyle(font: fonts.bold, fontSize: 9),
                ),
              pw.SizedBox(height: 6),
              pw.Text('(Authorised Signatory & Stamp)',
                  style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: _Pal.inkSoft)),
            ],
          ),
        ),
      ],
    );
  }
}
