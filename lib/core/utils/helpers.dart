import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  /// Format price with commas: 15000 → "15,000"
  static String formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// Short price format: 15000 → "15k", 12500 → "12.5k"
  static String formatPriceShort(int price) {
    if (price >= 1000) {
      final k = price / 1000;
      return '${k == k.toInt() ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return price.toString();
  }

  /// Format date from DateTime
  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static DateTime parseDate(String value, {DateTime? fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback ?? DateTime.now();

    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) return isoDate;

    const patterns = [
      'MMM d, yyyy',
      'MMM dd, yyyy',
      'd MMM yyyy',
      'dd MMM yyyy',
    ];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern, 'en_US').parseStrict(trimmed);
      } catch (_) {}
    }

    return fallback ?? DateTime.now();
  }

  /// Get initials from full name: "Ali Khan" → "AK"
  static String getInitials(String name) {
    return name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase()).take(2).join();
  }

  /// Generate a random booking ID
  static String generateBookingId() {
    final n = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    return 'BK-$n';
  }
}
