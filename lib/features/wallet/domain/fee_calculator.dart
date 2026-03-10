// lib/features/wallet/domain/fee_calculator.dart
// Logic tính phí nền tảng Xanh SM - Pure Dart (dễ test, không phụ thuộc Flutter)
// Phí nền tảng 2026: mặc định 18%, tài xế nhận ~82% doanh thu

import 'wallet_entity.dart';
import '../../../core/constants/app_constants.dart';

/// Service tính phí nền tảng - Pure Dart
class FeeCalculator {
  FeeCalculator._();

  /// Tính phí nền tảng cho ví Xanh SM
  ///
  /// [wallet] - ví cần tính phí
  /// [revenueByType] - doanh thu theo loại tiền: {"Tiền Mặt": 500000, "Thẻ/Ví": 300000}
  /// [periodStart] / [periodEnd] - khoảng thời gian tính
  ///
  /// Ưu tiên trừ Thẻ/Ví trước, thiếu mới trừ Tiền Mặt
  static FeeCalculationResult calculate({
    required WalletEntity wallet,
    required Map<String, double> revenueByType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    assert(wallet.isXanhSm, 'Chỉ ví Xanh SM mới tính được phí nền tảng');

    // Tổng doanh thu
    final totalRevenue = revenueByType.values.fold(0.0, (a, b) => a + b);

    // Tổng phí = tổng doanh thu × tỷ lệ phí (làm tròn đến 1000đ)
    final rawFee = totalRevenue * wallet.feeRate;
    final totalFee = _roundToThousand(rawFee);

    // Phân bổ trừ tiền: ưu tiên Thẻ/Ví trước
    double remaining = totalFee;
    double deductFromCard = 0;
    double deductFromCash = 0;

    // 1. Trừ từ Thẻ/Ví
    final cardBalance = revenueByType['Thẻ/Ví'] ?? 0;
    if (cardBalance > 0) {
      deductFromCard = remaining <= cardBalance ? remaining : cardBalance;
      remaining -= deductFromCard;
    }

    // 2. Trừ phần còn lại từ Tiền Mặt
    if (remaining > 0) {
      final cashBalance = revenueByType['Tiền Mặt'] ?? 0;
      deductFromCash = remaining <= cashBalance ? remaining : cashBalance;
      // Nếu tiền mặt không đủ, ghi lại toàn bộ để báo user
      if (deductFromCash < remaining) {
        deductFromCash = remaining; // báo hiệu thiếu tiền
      }
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

  /// Tính phí nhanh (preview)
  static double quickCalc(double totalRevenue, double feeRate) {
    return _roundToThousand(totalRevenue * feeRate);
  }

  /// Tính phần tài xế nhận được sau phí
  static double driverReceives(double totalRevenue, double feeRate) {
    return totalRevenue - quickCalc(totalRevenue, feeRate);
  }

  /// Làm tròn đến 1000đ (tránh số lẻ khó hiểu)
  static double _roundToThousand(double value) {
    return (value / 1000).round() * 1000.0;
  }

  /// Validate tỷ lệ phí
  static bool isValidFeeRate(double rate) {
    return rate >= FeeConfig.minFeeRate && rate <= FeeConfig.maxFeeRate;
  }

  /// Phần trăm tài xế nhận
  static double driverPercent(double feeRate) => 1.0 - feeRate;
}
