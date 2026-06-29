class Client {
  String id;
  String companyName;
  String contactPerson;
  String phone;
  String email;
  String address;
  String gstin;

  Client({
    required this.id,
    this.companyName = '',
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gstin = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
      };

  factory Client.fromMap(Map<dynamic, dynamic> m) => Client(
        id: m['id'],
        companyName: m['companyName'] ?? '',
        contactPerson: m['contactPerson'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        address: m['address'] ?? '',
        gstin: m['gstin'] ?? '',
      );
}
