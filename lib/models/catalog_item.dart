class CatalogItem {
  String id;
  String description;
  String unit;
  double rate;
  String grade; // material grade, e.g. M30 — optional

  CatalogItem({
    required this.id,
    this.description = '',
    this.unit = '',
    this.rate = 0,
    this.grade = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'unit': unit,
        'rate': rate,
        'grade': grade,
      };

  factory CatalogItem.fromMap(Map<dynamic, dynamic> m) => CatalogItem(
        id: m['id'],
        description: m['description'] ?? '',
        unit: m['unit'] ?? '',
        rate: (m['rate'] ?? 0).toDouble(),
        grade: m['grade'] ?? '',
      );
}
