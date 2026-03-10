// lib/data/app_database.dart
// FIX #11: Thêm composite index (isDeleted, date) và (wallet_id, isDeleted, date)

import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'schema/tables.dart';
import 'daos/wallet_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/category_dao.dart';
import 'daos/fee_payment_dao.dart';
import '../core/constants/app_constants.dart';

part 'app_database.g.dart';

const int _kDbVersion = 1;

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, FeePayments, AppSettings],
  daos: [WalletDao, TransactionDao, CategoryDao, FeePaymentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for in-memory testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => _kDbVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // FIX #11: Composite indexes thực sự giúp WHERE isDeleted=0 AND date BETWEEN
          await customStatement(
            'CREATE INDEX idx_txn_active_date '
            'ON transactions(is_deleted, date DESC)',
          );
          await customStatement(
            'CREATE INDEX idx_txn_wallet_active_date '
            'ON transactions(wallet_id, is_deleted, date DESC)',
          );
          await customStatement(
            'CREATE INDEX idx_txn_type_date '
            'ON transactions(type, is_deleted, date DESC)',
          );
        },
        onUpgrade: (m, from, to) async {
          // Migrations tương lai
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
          await customStatement('PRAGMA synchronous=NORMAL');
          await customStatement('PRAGMA cache_size=-4096'); // 4 MB page cache
          if (details.wasCreated) {
            await _seedDefaultData();
          }
        },
      );

  Future<void> _seedDefaultData() async {
    int order = 0;
    for (final cat in DefaultCategories.incomeCategories) {
      await into(categories).insert(CategoriesCompanion.insert(
        name: cat['name']!,
        emoji: Value(cat['emoji']!),
        type: 'income',
        sortOrder: Value(order++),
        isDefault: const Value(true),
      ));
    }
    order = 0;
    for (final cat in DefaultCategories.expenseCategories) {
      await into(categories).insert(CategoriesCompanion.insert(
        name: cat['name']!,
        emoji: Value(cat['emoji']!),
        type: 'expense',
        sortOrder: Value(order++),
        isDefault: const Value(true),
      ));
    }
    await into(wallets).insert(WalletsCompanion.insert(
      name: DefaultWallets.xanhSm,
      isXanhSm: const Value(true),
      feeRate: const Value(FeeConfig.defaultXanhSmFeeRate),
      moneyTypesJson: Value(jsonEncode(DefaultWallets.xanhSmMoneyTypes)),
      emoji: const Value('🚕'),
      colorHex: const Value('#00C853'),
      sortOrder: const Value(0),
    ));
    await into(wallets).insert(WalletsCompanion.insert(
      name: DefaultWallets.huongGiang,
      moneyTypesJson: Value(jsonEncode(DefaultWallets.huongGiangMoneyTypes)),
      emoji: const Value('📱'),
      colorHex: const Value('#2196F3'),
      sortOrder: const Value(1),
    ));
    await into(wallets).insert(WalletsCompanion.insert(
      name: DefaultWallets.other,
      moneyTypesJson: Value(jsonEncode(DefaultWallets.otherMoneyTypes)),
      emoji: const Value('💼'),
      colorHex: const Value('#9C27B0'),
      sortOrder: const Value(2),
    ));
  }

  /// Xóa toàn bộ data – dùng khi restore backup
  Future<void> clearAllData() => transaction(() async {
        await delete(feePayments).go();
        await delete(transactions).go();
        await delete(categories).go();
        await delete(wallets).go();
        await delete(appSettings).go();
      });

  @override
  Future<void> close() => super.close();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'thanh_taxi_xanh_sm.db'));
    return NativeDatabase.createInBackground(file);
  });
}
