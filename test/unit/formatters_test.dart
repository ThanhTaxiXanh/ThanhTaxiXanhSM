import 'package:flutter_test/flutter_test.dart';
import 'package:thanh_taxi_xanh_sm/core/utils/formatters.dart';

void main() {
  group('CurrencyFormatter', () {
    test('format chuẩn VND', () {
      expect(CurrencyFormatter.format(32000), '32.000đ');
      expect(CurrencyFormatter.format(1000000), '1.000.000đ');
      expect(CurrencyFormatter.format(0), '0đ');
    });

    test('formatShort: triệu/nghìn/đồng', () {
      expect(CurrencyFormatter.formatShort(2000000), '2tr');
      expect(CurrencyFormatter.formatShort(1500000), '1,5tr');
      expect(CurrencyFormatter.formatShort(850000), '850k');
      expect(CurrencyFormatter.formatShort(500), '500đ');
    });

    test('formatWithSign thêm dấu +/-', () {
      expect(CurrencyFormatter.formatWithSign(32000), '+32.000đ');
      expect(CurrencyFormatter.formatWithSign(-32000), '-32.000đ');
    });

    test('parse string về double', () {
      expect(CurrencyFormatter.parse('32.000đ'), 32000.0);
      expect(CurrencyFormatter.parse('1.000.000đ'), 1000000.0);
    });
  });

  group('DateFormatter', () {
    final monday = DateTime(2026, 3, 9, 12, 38); // Thứ Hai

    test('formatDate dd/MM/yyyy', () {
      expect(DateFormatter.formatDate(monday), '09/03/2026');
    });

    test('formatTime HH:mm', () {
      expect(DateFormatter.formatTime(monday), '12:38');
    });

    test('getDayOfWeek tiếng Việt đúng', () {
      expect(DateFormatter.getDayOfWeek(monday), 'Thứ Hai');
      expect(DateFormatter.getDayOfWeek(DateTime(2026, 3, 7)), 'Thứ Bảy');
      expect(DateFormatter.getDayOfWeek(DateTime(2026, 3, 8)), 'Chủ Nhật');
    });

    test('formatFullDate đầy đủ', () {
      expect(DateFormatter.formatFullDate(monday), 'Thứ Hai, 09/03/2026');
    });

    test('isSameDay đúng', () {
      expect(DateFormatter.isSameDay(
          DateTime(2026, 3, 9, 8), DateTime(2026, 3, 9, 23)), true);
      expect(DateFormatter.isSameDay(
          DateTime(2026, 3, 9), DateTime(2026, 3, 10)), false);
    });

    test('startOfDay / endOfDay boundaries', () {
      final start = DateFormatter.startOfDay(monday);
      final end = DateFormatter.endOfDay(monday);
      expect(start, DateTime(2026, 3, 9, 0, 0, 0));
      expect(end, DateTime(2026, 3, 9, 23, 59, 59, 999));
    });

    test('startOfWeek luôn là Thứ Hai', () {
      expect(DateFormatter.startOfWeek(monday).weekday, DateTime.monday);
      // Chủ Nhật vẫn trả về Thứ Hai của tuần đó
      final sunday = DateTime(2026, 3, 8);
      expect(DateFormatter.startOfWeek(sunday).weekday, DateTime.monday);
    });
  });
}
