// lib/features/wallet/domain/fee_calculator.dart
// Logic tính phí nền tảng Xanh SM - Pure Dart

import 'wallet_entity.dart';
import '../../../core/constants/app_constants.dart';

class FeeCalculator {
  FeeCalculator._();

  /// Tính phí nền tảng
  static FeeCalculationResult calculate({
    required WalletEntity wallet,
    required Map<String, double> revenueByType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    assert(wallet.isXanhSm, 'Chỉ ví Xanh SM mới tính được phí nền tảng');

    // Tổng doanh thu
    final totalRevenue =
        revenueByType.values.fold<double>(0, (a, b) => a + b);

    // Phí nền tảng
    final rawFee = totalRevenue * wallet.feeRate;
    final totalFee = _roundToThousand(rawFee);

    double remaining = totalFee;
    double deductFromCard = 0;
    double deductFromCash = 0;

    // Ưu tiên trừ Thẻ/Ví
    final cardBalance = revenueByType['Thẻ/Ví'] ?? 0;

    if (cardBalance > 0) {
      deductFromCard =
          remaining <= cardBalance ? remaining : cardBalance;

      remaining -= deductFromCard;
    }

    // Sau đó trừ Tiền Mặt
    if (remaining > 0) {
      final cashBalance = revenueByType['Tiền Mặt'] ?? 0;

      deductFromCash =
          remaining <= cashBalance ? remaining : cashBalance;

      remaining -= deductFromCash;
    }

    return FeeCalculationResult(
      wallet: wallet,
      periodStart: periodStart,
      periodEnd: periodEnd,
      revenueByType: revenueByType,
      totalRevenue: totalRevenue,
      feeRate: wallet.feeRate,
      totalFee: totalFee,
      deductFromCard: deductFromCard,
      deductFromCash: deductFromCash,
    );
  }

  /// Tính nhanh preview
  static FeeCalculationResult quickCalc(double totalRevenue, double feeRate) {
    final totalFee = _roundToThousand(totalRevenue * feeRate);

    return FeeCalculationResult(
      wallet: WalletEntity.preview(),
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
      revenueByType: {},
      totalRevenue: totalRevenue,
      feeRate: feeRate,
      totalFee: totalFee,
      deductFromCard: totalFee,
      deductFromCash: 0,
    );
  }

  /// Làm tròn đến 1000đ
  static double _roundToThousand(double value) {
    return (value / 1000).round() * 1000.0;
  }

  /// Validate tỷ lệ phí
  static bool isValidFeeRate(double rate) {
    return rate >= FeeConfig.minFeeRate && rate <= FeeConfig.maxFeeRate;
  }

  /// % tài xế nhận
  static double driverPercent(double feeRate) => 1.0 - feeRate;
}

/// Kết quả tính phí
class FeeCalculationResult {
  final WalletEntity wallet;

  final DateTime periodStart;
  final DateTime periodEnd;

  final Map<String, double> revenueByType;

  final double totalRevenue;
  final double feeRate;
  final double totalFee;

  final double deductFromCard;
  final double deductFromCash;

  const FeeCalculationResult({
    required this.wallet,
    required this.periodStart,
    required this.periodEnd,
    required this.revenueByType,
    required this.totalRevenue,
    required this.feeRate,
    required this.totalFee,
    required this.deductFromCard,
    required this.deductFromCash,
  });

  /// Phần tài xế nhận
  double get driverReceives => totalRevenue - totalFee;
}