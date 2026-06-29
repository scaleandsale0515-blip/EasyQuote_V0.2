import 'package:intl/intl.dart';

/// Formats a number the way the original template shows money, e.g.
/// 11554961.20 -> "1,15,54,961.20" (Indian digit grouping).
final NumberFormat _indianNumber = NumberFormat('#,##,##0.00', 'en_US');

String formatRupees(double value) => '₹ ${_indianNumber.format(value)}';

String formatNumber(double value) => _indianNumber.format(value);

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
