import 'package:intl/intl.dart';

/// Date / time formatting utilities.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateTimeFormat =
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dayFormat = DateFormat('EEEE', 'id_ID');

  /// `16 Agu 2026, 14:30`
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// `16 Agu 2026`
  static String formatDate(DateTime dt) => _dateFormat.format(dt);

  /// `14:30`
  static String formatTime(DateTime dt) => _timeFormat.format(dt);

  /// `Minggu`
  static String formatDay(DateTime dt) => _dayFormat.format(dt);

  /// Parses an ISO-8601 string, returns `DateTime.now()` on failure.
  static DateTime parse(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Returns a human-readable relative time, e.g. `5 menit lalu`.
  static String timeAgo(DateTime dt, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(dt);
  }
}
