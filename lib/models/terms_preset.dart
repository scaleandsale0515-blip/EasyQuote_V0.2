/// A saved Terms & Conditions preset.
///
/// Free-form by design: `clauses` is just an ordered list of plain-text
/// blocks, numbered automatically (1, 2, 3...) when shown on a document.
/// There's no fixed count or fixed structure — write 3 clauses or 9,
/// whatever a given factory/client needs. A brand-new preset starts with
/// an empty `clauses` list (genuinely blank, not pre-filled).
class TermsPreset {
  String id;
  String name; // preset label, e.g. "Standard Precast Terms"
  List<String> clauses;

  TermsPreset({
    required this.id,
    this.name = '',
    List<String>? clauses,
  }) : clauses = clauses ?? [];

  /// A ready-made starting point mirroring the original 5-clause wording —
  /// only used as a named seed preset you can pick and edit, never silently
  /// applied to a preset you create yourself.
  factory TermsPreset.standardSeed(String id) => TermsPreset(
        id: id,
        name: 'Standard Precast Terms',
        clauses: [
          'Payment: 100% advance along with PO. Unloading and laying will be in the scope of Client.',
          'Quoted rates are not inclusive of transport. Our responsibility shall cease immediately after '
              'unloading of the material and no claim shall be entertained thereafter. In the event of '
              'detention beyond 4 hours, charges as paid to the transporter will be debited to you.',
          'Delivery Period: After getting PO & advance, supply lot will start within 21 days. Buyer shall '
              'inspect material on receipt. Any claim regarding shortage, damage, defect or non-conformity '
              'must be submitted in writing within 1 working day(s) of receipt; claims after this period '
              'stand waived.',
          'Validity: This quotation is valid for 7 days from the issue date.',
          'All disputes are subject to Ahmedabad jurisdiction. Any test report of product required by '
              'buyer will be charged extra as actual.',
        ],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'clauses': clauses,
      };

  factory TermsPreset.fromMap(Map<dynamic, dynamic> m) {
    if (m['clauses'] != null) {
      return TermsPreset(
        id: m['id'],
        name: m['name'] ?? '',
        clauses: List<String>.from(m['clauses']),
      );
    }
    // Backward compatibility: presets saved before this rework used a fixed
    // 5-field schema. Fold those old fields into an equivalent clause list
    // once, so existing saved data isn't lost.
    final legacyClauses = <String>[];
    if ((m['paymentTerms'] ?? '').toString().isNotEmpty || (m['unloadingScope'] ?? '').toString().isNotEmpty) {
      legacyClauses.add(
        ['Payment: ${m['paymentTerms'] ?? ''}', if ((m['unloadingScope'] ?? '').toString().isNotEmpty) 'Unloading and laying will be in the scope of ${m['unloadingScope']}.']
            .join(' '),
      );
    }
    if ((m['transportNote'] ?? '').toString().isNotEmpty || (m['liabilityNote'] ?? '').toString().isNotEmpty) {
      legacyClauses.add([m['transportNote'] ?? '', m['liabilityNote'] ?? ''].where((s) => s.toString().isNotEmpty).join(' '));
    }
    if ((m['deliveryDays'] ?? '').toString().isNotEmpty) {
      legacyClauses.add('Delivery Period: After getting PO & advance, supply lot will start within ${m['deliveryDays'] ?? 21} days.');
    }
    if ((m['validityDays'] ?? '').toString().isNotEmpty) {
      legacyClauses.add('Validity: This quotation/invoice is valid for ${m['validityDays'] ?? 7} days from the issue date.');
    }
    if ((m['jurisdiction'] ?? '').toString().isNotEmpty || (m['testReportNote'] ?? '').toString().isNotEmpty) {
      legacyClauses.add(
        ['All disputes are subject to ${m['jurisdiction'] ?? ''} jurisdiction.', m['testReportNote'] ?? '']
            .where((s) => s.toString().isNotEmpty)
            .join(' '),
      );
    }
    return TermsPreset(id: m['id'], name: m['name'] ?? 'Standard', clauses: legacyClauses);
  }
}
