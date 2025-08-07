import 'package:intl/intl.dart';

class Helpers {
  // Formats a DateTime object into a more readable string like "August 7, 2025".
  static String formatDate(DateTime date) {
    // You can change the format string to whatever you need, e.g., 'dd/MM/yyyy'.
    final formatter = DateFormat.yMMMMd(); 
    return formatter.format(date);
  }

  // Formats a number with commas for better readability, e.g., 15000 -> "15,000".
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  // Formats a price with a currency symbol.
  static String formatPrice(double price, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US', 
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  // Creates a simple "time ago" string, e.g., "5m ago", "2h ago", "3d ago".
  static String timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays > 7) {
      return formatDate(date); // If it's over a week old, just show the date.
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Gets the initials from a full name for use in a placeholder avatar.
  // e.g., "John Doe" -> "JD"
  static String getInitials(String fullName) {
    if (fullName.trim().isEmpty) {
      return '?';
    }
    final names = fullName.trim().split(' ');
    if (names.length > 1) {
      return names.first[0].toUpperCase() + names.last[0].toUpperCase();
    } else {
      return names.first[0].toUpperCase();
    }
  }
}
