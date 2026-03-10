// lib/core/utils/formatters.dart
// Hàm format tiền VND, ngày tháng, thứ tiếng Việt

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Format tiền VND: 1.000.000đ
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat(
    '#,##0',
    'vi_VN',
  );

  /// Format số tiền thành chuỗi VND: 32.000đ
  static String format(double amount) {
    if (amount == 0) return '0đ';
    return '${_formatter.format(amount)}đ';
  }

  /// Format có dấu + / - : +32.000đ hoặc -32.000đ
  static String formatWithSign(double amount) {
    final abs = amount.abs();
    final sign = amount >= 0 ? '+' : '-';
    return '$sign${_formatter.format(abs)}đ';
  }

  /// Parse chuỗi VND về double: "32.000đ" → 32000.0
  static double parse(String value) {
    final cleaned = value.replaceAll('đ', '').replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format ngắn gọn: 1.500.000 → 1,5tr | 850.000 → 850k
  static String formatShort(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      if (millions == millions.truncate()) {
        return '${millions.truncate()}tr';
      }
      return '${millions.toStringAsFixed(1)}tr';
    } else if (amount >= 1000) {
      final thousands = (amount / 1000).truncate();
      return '${thousands}k';
    }
    return '${amount.truncate()}đ';
  }
}

/// Format ngày tháng tiếng Việt
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _yearFormat = DateFormat('yyyy');

  /// Format ngày: 09/03/2026
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format tháng/năm: 03/2026
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format giờ: 12:38
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Lấy thứ trong tuần tiếng Việt (1=Thứ Hai ... 7=Chủ Nhật)
  static String getDayOfWeek(DateTime date) {
    return vietnameseDayNames[date.weekday];
  }

  /// Format đầy đủ: Thứ Hai, 09/03/2026
  static String formatFullDate(DateTime date) {
    return '${getDayOfWeek(date)}, ${formatDate(date)}';
  }

  /// Label thông minh: Hôm nay / Hôm qua / Thứ Hai, 07/03
  static String formatSmartDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Hôm nay';
    if (target == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    if (target == today.subtract(const Duration(days: 2))) return 'Hôm kia';

    // Trong tuần này
    final diff = today.difference(target).inDays;
    if (diff <= 6) {
      return '${getDayOfWeek(date)}, ${DateFormat('dd/MM').format(date)}';
    }

    return formatDate(date);
  }

  /// Format khoảng thời gian: 01/03 - 09/03/2026
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('dd').format(start)} - ${formatDate(end)}';
    }
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  /// Kiểm tra hai ngày cùng ngày
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Lấy đầu ngày (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Lấy cuối ngày (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Lấy đầu tháng
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Lấy cuối tháng
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Lấy đầu tuần (Thứ Hai)
  static DateTime startOfWeek(DateTime date) {
    final diff = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: diff)));
  }

  /// Lấy cuối tuần (Chủ Nhật)
  static DateTime endOfWeek(DateTime date) {
    final diff = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: diff)));
  }
}
