// lib/data/daos/wallet_dao.dart
// DAO cho bảng Wallets - CRUD và queries

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../schema/tables.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase>
    with _$WalletDaoMixin {
  WalletDao(super.db);

  /// Lấy tất cả ví active (reactive stream)
  Stream<List<WalletData>> watchAllWallets() {
    return (select(wallets)
          ..where((w) => w.isDeleted.equals(false))
          ..orderBy([(w) => OrderingTerm.asc(w.sortOrder)]))
        .watch();
  }

  /// Lấy tất cả ví active (one-time)
  Future<List<WalletData>> getAllWallets() {
    return (select(wallets)
          ..where((w) => w.isDeleted.equals(false))
          ..orderBy([(w) => OrderingTerm.asc(w.sortOrder)]))
        .get();
  }

  /// Lấy ví theo ID
  Future<WalletData?> getWalletById(int id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  /// Lấy danh sách ví Xanh SM
  Future<List<WalletData>> getXanhSmWallets() {
    return (select(wallets)
          ..where((w) => w.isXanhSm.equals(true) & w.isDeleted.equals(false)))
        .get();
  }

  /// Thêm ví mới
  Future<int> insertWallet(WalletsCompanion wallet) {
    return into(wallets).insert(wallet);
  }

  /// Cập nhật ví
  Future<bool> updateWallet(WalletsCompanion wallet) {
    return update(wallets).replace(wallet);
  }

  /// Xóa mềm ví
  Future<void> deleteWallet(int id) async {
    await (update(wallets)..where((w) => w.id.equals(id))).write(
      const WalletsCompanion(isDeleted: Value(true)),
    );
  }

  /// Đếm số ví active
  Future<int> countActiveWallets() async {
    final count = wallets.id.count();
    final query = selectOnly(wallets)
      ..addColumns([count])
      ..where(wallets.isDeleted.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
