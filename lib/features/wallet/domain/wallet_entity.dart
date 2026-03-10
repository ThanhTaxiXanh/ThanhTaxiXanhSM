// lib/features/wallet/domain/wallet_entity.dart
// Domain entity cho Wallet - tách biệt khỏi Drift DataClass

import 'dart:convert';

/// Entity domain của Ví
class WalletEntity {
  final int id;
  final String name;
  final bool isXanhSm;
  final double feeRate;
  final List<String> moneyTypes;
  final String emoji;
  final String? colorHex;
  final int sortOrder;
  final bool isDeleted;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.isXanhSm,
    required this.feeRate,
    required this.moneyTypes,
    required this.emoji,
    this.colorHex,
    required this.sortOrder,
    this.isDeleted = false,
  });

  /// Parse moneyTypes từ JSON string
  static List<String> parseMoneyTypes(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return ['Tiền Mặt'];
    }
  }

  /// Encode moneyTypes thành JSON string
  static String encodeMoneyTypes(List<String> types) {
    return jsonEncode(types);
  }

  /// Tên hiển thị đầy đủ với emoji
  String get displayName => '$emoji $name';

  /// Phí theo % string: "18%"
  String get feeRatePercent => '${(feeRate * 100).toStringAsFixed(0)}%';

  WalletEntity copyWith({
    int? id,
    String? name,
    bool? isXanhSm,
    double? feeRate,
    List<String>? moneyTypes,
    String? emoji,
    String? colorHex,
    int? sortOrder,
    bool? isDeleted,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isXanhSm: isXanhSm ?? this.isXanhSm,
      feeRate: feeRate ?? this.feeRate,
      moneyTypes: moneyTypes ?? this.moneyTypes,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WalletEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WalletEntity(id: $id, name: $name, isXanhSm: $isXanhSm)';
}

/// Kết quả tính phí nền tảng
class FeeCalculationResult {
  final WalletEntity wallet;
  final DateTime periodStart;
  final DateTime periodEnd;

  /// Doanh thu theo loại tiền: {"Tiền Mặt": 500000, "Thẻ/Ví": 300000}
  final Map<String, double> revenueByType;

  /// Tổng doanh thu
  final double totalRevenue;

  /// Tỷ lệ phí
  final double feeRate;

  /// Tổng phí phải đóng
  final double totalFee;

  /// Phân bổ trừ tiền: ưu tiên Thẻ/Ví trước
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

  /// Số dư dự kiến sau khi đóng phí (theo loại tiền)
  Map<String, double> get balanceAfterFee {
    final balances = Map<String, double>.from(revenueByType);
    // Trừ Thẻ/Ví trước
    if (balances.containsKey('Thẻ/Ví')) {
      balances['Thẻ/Ví'] = (balances['Thẻ/Ví'] ?? 0) - deductFromCard;
    }
    // Trừ Tiền Mặt
    if (balances.containsKey('Tiền Mặt')) {
      balances['Tiền Mặt'] = (balances['Tiền Mặt'] ?? 0) - deductFromCash;
    }
    return balances;
  }
}
