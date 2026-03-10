// lib/features/transaction/data/transaction_repository.dart
// FIX #1: asyncMap + Future.wait stream đã xóa – stream trả về JOIN entity
// FIX #2: _enrichEntity N+1 hoàn toàn bị loại bỏ

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/app_database.dart';
import '../../../data/schema/tables.dart';
import '../../../data/daos/transaction_dao.dart';
import '../domain/transaction_entity.dart';

// ──────────────────────────────────────────────────────────────
// Model
// ──────────────────────────────────────────────────────────────

class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
    required this.tripCount,
  });
  final DateTime date;
  final double totalIncome;
  final double totalExpense;
  final int tripCount;
  double get balance => totalIncome - totalExpense;
  bool get hasData => totalIncome > 0 || totalExpense > 0;
  double get avgPerTrip => tripCount > 0 ? totalIncome / tripCount : 0;
}

// ──────────────────────────────────────────────────────────────
// Repository
// ──────────────────────────────────────────────────────────────

class TransactionRepository {
  const TransactionRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── Streams (JOIN, 1 round-trip) ────────────────────────────

  /// FIX #1: Stream dùng JOIN từ DAO – không còn asyncMap wrapping
  Stream<List<TransactionEntity>> watchByDateRange(
    DateTime start,
    DateTime end, {
    int? walletId,
  }) =>
      _db.transactionDao
          .watchByDateRange(start, end, walletId: walletId)
          .map((rows) => rows.map(TransactionEntity.fromJoin).toList());

  Stream<List<TransactionEntity>> watchRecent({int limit = 50}) =>
      _db.transactionDao
          .watchRecent(limit: limit)
          .map((rows) => rows.map(TransactionEntity.fromJoin).toList());

  // ── One-time fetch ──────────────────────────────────────────

  Future<List<TransactionEntity>> getByDateRange(
    DateTime start,
    DateTime end, {
    int? walletId,
    String? type,
  }) async {
    final rows = await _db.transactionDao
        .getByDateRange(start, end, walletId: walletId, type: type);
    return rows.map(TransactionEntity.fromJoin).toList();
  }

  Future<List<TransactionEntity>> getByDay(DateTime day) => getByDateRange(
        DateTime(day.year, day.month, day.day),
        DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
      );

  Future<TransactionEntity?> getById(String id) async {
    final row = await _db.transactionDao.getById(id);
    return row == null ? null : TransactionEntity.fromJoin(row);
  }

  Future<List<TransactionEntity>> getAllForExport() async {
    final rows = await _db.transactionDao.getByDateRange(
      DateTime(2000),
      DateTime(2100),
    );
    return rows.map(TransactionEntity.fromJoin).toList();
  }

  // ── Aggregation (SQL-level, FIX #10) ────────────────────────

  Future<TransactionSummary> getSummary(
    DateTime start,
    DateTime end, {
    int? walletId,
    String? moneyType,
  }) =>
      _db.transactionDao
          .getSummarySQL(start, end, walletId: walletId, moneyType: moneyType);

  Future<DailySummary> getDailySummary(DateTime day) async {
    final s = await getSummary(
      DateTime(day.year, day.month, day.day),
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
    );
    return DailySummary(
      date: day,
      totalIncome: s.totalIncome,
      totalExpense: s.totalExpense,
      tripCount: s.tripCount,
    );
  }

  Future<Map<int, double>> getSummaryByCategory(
    DateTime start,
    DateTime end,
    String type, {
    int? walletId,
  }) =>
      _db.transactionDao
          .getSummaryByCategorySQL(start, end, type, walletId: walletId);

  Future<Map<String, double>> getSummaryByMoneyType(
    int walletId,
    DateTime start,
    DateTime end,
    String type,
  ) =>
      _db.transactionDao.getSummaryByMoneyType(walletId, start, end, type);

  Future<Map<DateTime, DailySummary>> getMonthlyCalendar(
      int year, int month) async {
    final aggs = await _db.transactionDao.getDayAggregates(year, month);
    return aggs.map(
      (day, a) => MapEntry(
        day,
        DailySummary(
          date: day,
          totalIncome: a.income,
          totalExpense: a.expense,
          tripCount: a.trips,
        ),
      ),
    );
  }

  // ── Mutations ───────────────────────────────────────────────

  Future<void> add({
    required int walletId,
    required String type,
    required double amount,
    required String moneyType,
    int? categoryId,
    String note = '',
    required DateTime date,
    int tripCount = 1,
  }) =>
      _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          id: _uuid.v4(),
          walletId: walletId,
          type: type,
          amount: amount,
          moneyType: moneyType,
          categoryId: Value(categoryId),
          note: Value(note),
          date: date,
          tripCount: Value(tripCount),
        ),
      );

  Future<void> update(TransactionEntity e) =>
      _db.transactionDao.updateTransaction(
        TransactionsCompanion(
          id: Value(e.id),
          walletId: Value(e.walletId),
          type: Value(e.type),
          amount: Value(e.amount),
          moneyType: Value(e.moneyType),
          categoryId: Value(e.categoryId),
          note: Value(e.note),
          date: Value(e.date),
          tripCount: Value(e.tripCount),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> delete(String id) => _db.transactionDao.softDelete(id);
}
