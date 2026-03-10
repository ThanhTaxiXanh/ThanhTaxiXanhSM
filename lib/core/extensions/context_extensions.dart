// lib/core/extensions/context_extensions.dart
// Extension methods tiện ích cho BuildContext

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Hiển thị snackbar thành công (xanh)
  void showSuccessSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Hiển thị snackbar lỗi (đỏ)
  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.negativeRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hiển thị dialog xác nhận
  Future<bool> showConfirmDialog({
    required String title,
    required String content,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDanger
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.negativeRed,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

extension StringX on String {
  /// Viết hoa chữ cái đầu
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Kiểm tra chuỗi chỉ gồm chữ số
  bool get isDigitsOnly => RegExp(r'^\d+$').hasMatch(this);
}

extension DoubleX on double {
  /// Làm tròn đến N chữ số thập phân
  double roundTo(int decimals) {
    final factor = 10 * decimals;
    return (this * factor).round() / factor;
  }

  /// Kiểm tra dương
  bool get isPositive => this > 0;
}

extension DateTimeX on DateTime {
  /// Kiểm tra cùng ngày
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Đầu ngày
  DateTime get startOfDay => DateTime(year, month, day);

  /// Cuối ngày
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Đầu tháng
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Cuối tháng
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}
