import 'package:flutter_test/flutter_test.dart';
import 'package:thanh_taxi_xanh_sm/features/insights/domain/insights_engine.dart';
import 'package:thanh_taxi_xanh_sm/features/transaction/data/transaction_repository.dart';

void main() {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  DailySummary makeSummary({
    double income = 0,
    double expense = 0,
    int trips = 0,
  }) =>
      DailySummary(
        date: today,
        totalIncome: income,
        totalExpense: expense,
        tripCount: trips,
      );

  group('InsightsEngine.analyze()', () {
    test('Luôn trả về ít nhất 1 insight', () {
      final result = InsightsEngine.analyze(
        today: makeSummary(),
        yesterday: makeSummary(),
        thisWeek: [],
        avgPerTrip: 0,
      );
      expect(result, isNotEmpty);
    });

    test('Cảnh báo khi chi > 50% thu', () {
      final result = InsightsEngine.analyze(
        today: makeSummary(income: 200000, expense: 120000),
        yesterday: makeSummary(),
        thisWeek: [],
        avgPerTrip: 0,
      );
      expect(result.any((i) => i.type == InsightType.warning), true);
    });

    test('Không cảnh báo khi chi < 50% thu', () {
      final result = InsightsEngine.analyze(
        today: makeSummary(income: 500000, expense: 100000),
        yesterday: makeSummary(),
        thisWeek: [],
        avgPerTrip: 50000,
      );
      expect(result.any((i) => i.type == InsightType.warning), false);
    });

    test('Positive/achievement khi hôm nay tốt hơn hôm qua', () {
      final result = InsightsEngine.analyze(
        today: makeSummary(income: 500000, trips: 15),
        yesterday: makeSummary(income: 300000, trips: 10),
        thisWeek: [],
        avgPerTrip: 33333,
      );
      expect(
        result.any((i) =>
            i.type == InsightType.positive ||
            i.type == InsightType.achievement),
        true,
      );
    });

    test('Info khi avg/cuốc thấp dưới 25k', () {
      final result = InsightsEngine.analyze(
        today: makeSummary(income: 180000, trips: 10),
        yesterday: makeSummary(),
        thisWeek: [],
        avgPerTrip: 18000,
      );
      expect(result.any((i) => i.type == InsightType.info), true);
    });
  });
}
