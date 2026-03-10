// lib/features/wallet/data/wallet_repository.dart
// Repository lớp trung gian giữa DAO và Presentation

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/app_database.dart';
import '../../../data/schema/tables.dart';
import '../domain/wallet_entity.dart';
import '../domain/fee_calculator.dart';

class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // === WALLETS ===

  Stream<List<WalletEntity>> watchWallets() {
    return _db.walletDao.watchAllWallets().map(
          (list) => list.map(_mapToEntity).toList(),
        );
  }

  Future<List<WalletEntity>> getWallets() async {
    final list = await _db.walletDao.getAllWallets();
    return list.map(_mapToEntity).toList();
  }

  Future<WalletEntity?> getWalletById(int id) async {
    final data = await _db.walletDao.getWalletById(id);
    return data != null ? _mapToEntity(data) : null;
  }

  Future<int> addWallet({
    required String name,
    bool isXanhSm = false,
    double feeRate = 0.18,
    required List<String> moneyTypes,
    String emoji = '💳',
    String? colorHex,
  }) async {
    final count = await _db.walletDao.countActiveWallets();
    if (count >= 10) {
      throw Exception('Tối đa 10 ví. Xóa bớt ví cũ để thêm mới.');
    }

    return _db.walletDao.insertWallet(WalletsCompanion.insert(
      name: name,
      isXanhSm: Value(isXanhSm),
      feeRate: Value(feeRate),
      moneyTypesJson: Value(jsonEncode(moneyTypes)),
      emoji: Value(emoji),
      colorHex: Value(colorHex),
      sortOrder: Value(count),
    ));
  }

  Future<void> updateWallet(WalletEntity entity) async {
    await _db.walletDao.updateWallet(WalletsCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      isXanhSm: Value(entity.isXanhSm),
      feeRate: Value(entity.feeRate),
      moneyTypesJson: Value(jsonEncode(entity.moneyTypes)),
      emoji: Value(entity.emoji),
      colorHex: Value(entity.colorHex),
      sortOrder: Value(entity.sortOrder),
    ));
  }

  Future<void> deleteWallet(int id) async {
    await _db.walletDao.deleteWallet(id);
  }

  // === FEE CALCULATION ===

  /// Tính phí nền tảng cho ví Xanh SM
  Future<FeeCalculationResult> calculateFee(
    WalletEntity wallet,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final revenueByType = await _db.transactionDao.getSummaryByMoneyType(
      wallet.id,
      periodStart,
      periodEnd,
      'income',
    );

    return FeeCalculator.calculate(
      wallet: wallet,
      revenueByType: revenueByType,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  /// Xác nhận đóng phí: tạo transaction chi + lưu fee_payment
  Future<void> confirmFeePayment(FeeCalculationResult result) async {
    final now = DateTime.now();

    // Tạo transaction chi từ Thẻ/Ví
    if (result.deductFromCard > 0) {
      final cardBalance =
          result.revenueByType['Thẻ/Ví'] ?? 0;
      final actualDeduct =
          result.deductFromCard > cardBalance ? cardBalance : result.deductFromCard;

      if (actualDeduct > 0) {
        await _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
          id: _uuid.v4(),
          walletId: result.wallet.id,
          type: 'expense',
          amount: actualDeduct,
          moneyType: 'Thẻ/Ví',
          note: const Value('Phí nền tảng Xanh SM'),
          date: now,
        ));
      }
    }

    // Tạo transaction chi từ Tiền Mặt
    if (result.deductFromCash > 0) {
      await _db.transactionDao.insertTransaction(TransactionsCompanion.insert(
        id: _uuid.v4(),
        walletId: result.wallet.id,
        type: 'expense',
        amount: result.deductFromCash,
        moneyType: 'Tiền Mặt',
        note: const Value('Phí nền tảng Xanh SM (Tiền Mặt)'),
        date: now,
      ));
    }

    // Lưu lịch sử đóng phí
    await _db.feePaymentDao.insertFeePayment(FeePaymentsCompanion.insert(
      walletId: result.wallet.id,
      periodStart: result.periodStart,
      periodEnd: result.periodEnd,
      totalRevenue: result.totalRevenue,
      totalFee: result.totalFee,
      deductedCard: Value(result.deductFromCard),
      deductedCash: Value(result.deductFromCash),
      feeRateSnapshot: result.feeRate,
    ));
  }

  // === MAPPER ===

  WalletEntity _mapToEntity(WalletData data) {
    return WalletEntity(
      id: data.id,
      name: data.name,
      isXanhSm: data.isXanhSm,
      feeRate: data.feeRate,
      moneyTypes: WalletEntity.parseMoneyTypes(data.moneyTypesJson),
      emoji: data.emoji,
      colorHex: data.colorHex,
      sortOrder: data.sortOrder,
      isDeleted: data.isDeleted,
    );
  }
}
