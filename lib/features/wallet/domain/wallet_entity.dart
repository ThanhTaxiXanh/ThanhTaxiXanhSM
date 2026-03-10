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

  /// Wallet giả dùng cho preview / test / CI
  factory WalletEntity.preview() {
    return const WalletEntity(
      id: -1,
      name: 'Preview',
      isXanhSm: true,
      feeRate: 0,
      moneyTypes: [],
      emoji: '🧮',
      sortOrder: -1,
    );
  }

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

  /// Phần % tài xế nhận
  double get driverPercent => 1 - feeRate;

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

  /// So sánh entity theo id
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WalletEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WalletEntity(id: $id, name: $name, isXanhSm: $isXanhSm)';
}