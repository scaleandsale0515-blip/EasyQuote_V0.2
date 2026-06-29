class LineItem {
  String description;
  String unit;
  double qty;
  double rate;

  LineItem({
    this.description = '',
    this.unit = '',
    this.qty = 0,
    this.rate = 0,
  });

  double get amount => qty * rate;

  Map<String, dynamic> toMap() => {
        'description': description,
        'unit': unit,
        'qty': qty,
        'rate': rate,
      };

  factory LineItem.fromMap(Map<dynamic, dynamic> m) => LineItem(
        description: m['description'] ?? '',
        unit: m['unit'] ?? '',
        qty: (m['qty'] ?? 0).toDouble(),
        rate: (m['rate'] ?? 0).toDouble(),
      );
}
