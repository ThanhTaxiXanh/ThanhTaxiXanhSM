// lib/features/transaction/domain/transaction_entity.dart
// Domain entity – mapped từ JOIN result, không cần query DB thêm

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/daos/transaction_dao.dart';

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.walletId,
    required this.walletName,
    required this.walletEmoji,
    required this.type,
    required this.amount,
    required this.moneyType,
    this.categoryId,
    this.categoryName,
    this.categoryEmoji,
    required this.note,
    required this.date,
    required this.tripCount,
    required this.createdAt,
  });

  final String id;
  final int walletId;
  final String walletName;
  final String walletEmoji;
  final String type;
  final double amount;
  final String moneyType;
  final int? categoryId;
  final String? categoryName;
  final String? categoryEmoji;
  final String note;
  final DateTime date;
  final int tripCount;
  final DateTime createdAt;

  bool get isIncome => type == 'income';
  bool get isExpense => !isIncome;
  String get sign => isIncome ? '+' : '-';
  String get typeLabel => isIncome ? 'Thu nhập' : 'Chi tiêu';
  Color get amountColor =>
      isIncome ? AppTheme.primaryGreen : AppTheme.negativeRed;

  String get categoryDisplay =>
      (categoryEmoji != null && categoryName != null)
          ? '$categoryEmoji $categoryName'
          : (categoryName ?? (isIncome ? '💰 Thu nhập' : '💸 Chi tiêu'));

  /// FIX #2: Factory từ JOIN row – 0 extra DB queries
  factory TransactionEntity.fromJoin(TransactionJoinRow row) =>
      TransactionEntity(
        id: row.txn.id,
        walletId: row.txn.walletId,
        walletName: row.wallet.name,
        walletEmoji: row.wallet.emoji,
        type: row.txn.type,
        amount: row.txn.amount,
        moneyType: row.txn.moneyType,
        categoryId: row.txn.categoryId,
        categoryName: row.category?.name,
        categoryEmoji: row.category?.emoji,
        note: row.txn.note,
        date: row.txn.date,
        tripCount: row.txn.tripCount,
        createdAt: row.txn.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TransactionEntity && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
