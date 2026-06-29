/// Company profile — the data shown on every Quotation/Invoice header,
/// bank details block, and signature/stamp area.
/// Multiple profiles can exist (e.g. separate brands/companies); each is
/// stored in Hive box 'profiles' keyed by its own id.
class CompanyProfile {
  String id;
  String name;
  String tagline;
  String contactName;
  String phone1;
  String phone2;
  String email;
  String website;
  String address;
  List<String> capabilities;

  // Bank details
  String bankName;
  String acType;
  String acHolder;
  String acNumber;
  String ifsc;

  String gstin;
  String jurisdiction;
  double defaultGST;
  String prefix; // used for Ref. No. generation e.g. "WS"

  // Local file paths (images live in app documents directory, only the
  // path is stored here — see LocalFiles helper)
  String logoPath;
  String signaturePath;
  String stampPath;
  String stampSignatureText;

  CompanyProfile({
    this.id = '',
    this.name = '',
    this.tagline = '',
    this.contactName = '',
    this.phone1 = '',
    this.phone2 = '',
    this.email = '',
    this.website = '',
    this.address = '',
    List<String>? capabilities,
    this.bankName = '',
    this.acType = 'Current',
    this.acHolder = '',
    this.acNumber = '',
    this.ifsc = '',
    this.gstin = '',
    this.jurisdiction = '',
    this.defaultGST = 18,
    this.prefix = 'EQ',
    this.logoPath = '',
    this.signaturePath = '',
    this.stampPath = '',
    this.stampSignatureText = '',
  }) : capabilities = capabilities ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'contactName': contactName,
        'phone1': phone1,
        'phone2': phone2,
        'email': email,
        'website': website,
        'address': address,
        'capabilities': capabilities,
        'bankName': bankName,
        'acType': acType,
        'acHolder': acHolder,
        'acNumber': acNumber,
        'ifsc': ifsc,
        'gstin': gstin,
        'jurisdiction': jurisdiction,
        'defaultGST': defaultGST,
        'prefix': prefix,
        'logoPath': logoPath,
        'signaturePath': signaturePath,
        'stampPath': stampPath,
        'stampSignatureText': stampSignatureText,
      };

  factory CompanyProfile.fromMap(Map<dynamic, dynamic> m) => CompanyProfile(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        tagline: m['tagline'] ?? '',
        contactName: m['contactName'] ?? '',
        phone1: m['phone1'] ?? '',
        phone2: m['phone2'] ?? '',
        email: m['email'] ?? '',
        website: m['website'] ?? '',
        address: m['address'] ?? '',
        capabilities: List<String>.from(m['capabilities'] ?? []),
        bankName: m['bankName'] ?? '',
        acType: m['acType'] ?? 'Current',
        acHolder: m['acHolder'] ?? '',
        acNumber: m['acNumber'] ?? '',
        ifsc: m['ifsc'] ?? '',
        gstin: m['gstin'] ?? '',
        jurisdiction: m['jurisdiction'] ?? '',
        defaultGST: (m['defaultGST'] ?? 18).toDouble(),
        prefix: m['prefix'] ?? 'EQ',
        logoPath: m['logoPath'] ?? '',
        signaturePath: m['signaturePath'] ?? '',
        stampPath: m['stampPath'] ?? '',
        stampSignatureText: m['stampSignatureText'] ?? '',
      );
}
