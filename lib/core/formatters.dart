import 'package:intl/intl.dart';

/// Small formatting helpers shared across screens.
class Formatters {
  Formatters._();

  static String date(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('yyyy-MM-dd hh:mm a').format(d);

  static String timeRange(DateTime start, DateTime end) =>
      '${DateFormat('hh:mm a').format(start)}-${DateFormat('hh:mm a').format(end)}';

  static String price(num v, [String symbol = 'Rs ']) => '$symbol${_num(v)}';

  static String _num(num v) {
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return s;
  }

  static String money(num v, [String symbol = 'Rs ']) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$symbol$buf.${parts[1]}';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
