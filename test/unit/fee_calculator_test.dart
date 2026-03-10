import 'package:flutter_test/flutter_test.dart';
import 'package:thanh_taxi_xanh_sm/features/wallet/domain/fee_calculator.dart';
import 'package:thanh_taxi_xanh_sm/features/wallet/domain/wallet_entity.dart';

void main() {
  final xanhSmWallet = WalletEntity(
    id: 1,
    name: 'Xanh SM',
    isXanhSm: true,
    feeRate: 0.18,
    moneyTypes: ['Tiền Mặt', 'Thẻ/Ví'],
    emoji: '🚕',
    sortOrder: 0,
  );

  final now = DateTime(2026, 3, 9);

  group('FeeCalculator.calculate()', () {
    test('Tính 18% trên tổng doanh thu hỗn hợp', () {
      final result = FeeCalculator.calculate(
        wallet: xanhSmWallet,
        revenueByType: {'Tiền Mặt': 200000, 'Thẻ/Ví': 100000},
        periodStart: now,
        periodEnd: now,
      );
      expect(result.totalRevenue, 300000);
      expect(result.totalFee, closeTo(54000, 1000)); // 18% of 300k
    });

    test('Ưu tiên trừ Thẻ/Ví trước Tiền Mặt', () {
      final result = FeeCalculator.calculate(
        wallet: xanhSmWallet,
        revenueByType: {'Tiền Mặt': 200000, 'Thẻ/Ví': 100000},
        periodStart: now,
        periodEnd: now,
      );
      expect(result.deductFromCard, greaterThan(0));
      if (result.totalFee > result.deductFromCard) {
        expect(result.deductFromCash, greaterThan(0));
      }
    });

    test('Dùng Tiền Mặt khi không có Thẻ/Ví', () {
      final result = FeeCalculator.calculate(
        wallet: xanhSmWallet,
        revenueByType: {'Tiền Mặt': 300000},
        periodStart: now,
        periodEnd: now,
      );
      expect(result.deductFromCard, 0);
      expect(result.deductFromCash, greaterThan(0));
    });

    test('Doanh thu 0 → phí 0', () {
      final result = FeeCalculator.calculate(
        wallet: xanhSmWallet,
        revenueByType: {},
        periodStart: now,
        periodEnd: now,
      );
      expect(result.totalFee, 0);
      expect(result.driverReceives, 0);
    });

    test('quickCalc trả về đúng phần tài xế nhận', () {
      final res = FeeCalculator.quickCalc(320000, 0.18);
      expect(res.driverReceives, lessThan(320000));
      expect(res.totalFee, greaterThan(0));
    });

    test('isValidFeeRate từ chối ngoài [0, 0.5]', () {
      expect(FeeCalculator.isValidFeeRate(-0.01), false);
      expect(FeeCalculator.isValidFeeRate(0.51), false);
      expect(FeeCalculator.isValidFeeRate(0.18), true);
    });

    test('Phí được làm tròn đến 1000đ', () {
      final result = FeeCalculator.calculate(
        wallet: xanhSmWallet,
        revenueByType: {'Tiền Mặt': 55555},
        periodStart: now,
        periodEnd: now,
      );
      expect(result.totalFee % 1000, 0);
    });
  });
}
