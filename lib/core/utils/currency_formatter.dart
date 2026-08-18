import 'package:intl/intl.dart';

/// Currency formatting utilities for Indonesian Rupiah (Rp).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Formats a number as `Rp 25.000` (no decimals).
  static String format(double amount) => _rupiahFormat.format(amount);

  /// Formats a number as `25.000` (no symbol, no decimals).
  static String formatPlain(double amount) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(amount);
  }

  /// Parses a formatted string like `Rp 25.000` back to double.
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
