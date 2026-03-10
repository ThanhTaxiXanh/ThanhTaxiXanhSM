// lib/data/daos/fee_payment_dao.dart
// DAO cho bảng FeePayments - lịch sử đóng phí nền tảng

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../schema/tables.dart';

part 'fee_payment_dao.g.dart';

@DriftAccessor(tables: [FeePayments])
class FeePaymentDao extends DatabaseAccessor<AppDatabase>
    with _$FeePaymentDaoMixin {
  FeePaymentDao(super.db);

  /// Stream lịch sử đóng phí (mới nhất trước)
  Stream<List<FeePaymentData>> watchFeePayments({int? walletId}) {
    return (select(feePayments)
          ..where((f) => walletId != null
              ? f.walletId.equals(walletId)
              : const Constant(true))
          ..orderBy([(f) => OrderingTerm.desc(f.datePaid)]))
        .watch();
  }

  /// Lấy lịch sử đóng phí
  Future<List<FeePaymentData>> getFeePayments({int? walletId}) {
    return (select(feePayments)
          ..where((f) => walletId != null
              ? f.walletId.equals(walletId)
              : const Constant(true))
          ..orderBy([(f) => OrderingTerm.desc(f.datePaid)]))
        .get();
  }

  /// Thêm bản ghi đóng phí
  Future<int> insertFeePayment(FeePaymentsCompanion payment) {
    return into(feePayments).insert(payment);
  }

  /// Tổng phí đã đóng trong năm
  Future<double> getTotalFeeByYear(int walletId, int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    final payments = await (select(feePayments)
          ..where((f) =>
              f.walletId.equals(walletId) &
              f.datePaid.isBetweenValues(start, end)))
        .get();
    return payments.fold(0, (sum, p) => sum + p.totalFee);
  }
}
