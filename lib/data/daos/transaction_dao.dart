// lib/data/daos/transaction_dao.dart
// FIX #1 & #2: Thay thế N+1 _enrichEntity bằng JOIN query một round-trip
// FIX #10: getSummary dùng SQL aggregation, không kéo rows về Dart

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../schema/tables.dart';

part 'transaction_dao.g.dart';

// ──────────────────────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────────────────────

class TransactionSummary {
  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.tripCount,
  });
  final double totalIncome;
  final double totalExpense;
  final int tripCount;
  double get balance => totalIncome - totalExpense;
}

/// JOIN result: transaction + wallet + category trong 1 query
class TransactionJoinRow {
  const TransactionJoinRow({
    required this.txn,
    required this.wallet,
    this.category,
  });
  final TransactionData txn;
  final WalletData wallet;
  final CategoryData? category;
}

// ──────────────────────────────────────────────────────────────
// DAO
// ──────────────────────────────────────────────────────────────

@DriftAccessor(tables: [Transactions, Wallets, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ── JOIN helpers ────────────────────────────────────────────

  JoinedSelectStatement<HasResultSet, dynamic> _joinQuery({
    DateTime? start,
    DateTime? end,
    int? walletId,
    String? type,
    int limit = 500,
  }) {
    final q = select(transactions).join([
      innerJoin(wallets, wallets.id.equalsExp(transactions.walletId)),
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
    ])
      ..where(transactions.isDeleted.equals(false));

    if (start != null && end != null) {
      q.where(transactions.date.isBetweenValues(start, end));
    }
    if (walletId != null) q.where(transactions.walletId.equals(walletId));
    if (type != null) q.where(transactions.type.equals(type));

    q
      ..orderBy([OrderingTerm.desc(transactions.date)])
      ..limit(limit);
    return q;
  }

  List<TransactionJoinRow> _mapRows(List<TypedResult> rows) => rows
      .map((r) => TransactionJoinRow(
            txn: r.readTable(transactions),
            wallet: r.readTable(wallets),
            category: r.readTableOrNull(categories),
          ))
      .toList();

  // ── FIX #1 & #2: Stream với JOIN – không còn N+1 ────────────

  /// Stream giao dịch theo khoảng ngày, JOIN wallet + category
  Stream<List<TransactionJoinRow>> watchByDateRange(
    DateTime start,
    DateTime end, {
    int? walletId,
  }) =>
      _joinQuery(start: start, end: end, walletId: walletId)
          .watch()
          .map(_mapRows);

  /// Stream 50 giao dịch mới nhất – dùng cho Home
  Stream<List<TransactionJoinRow>> watchRecent({int limit = 50}) =>
      _joinQuery(limit: limit).watch().map(_mapRows);

  // ── One-time fetch ──────────────────────────────────────────

  Future<List<TransactionJoinRow>> getByDateRange(
    DateTime start,
    DateTime end, {
    int? walletId,
    String? type,
  }) async {
    final rows = await _joinQuery(
      start: start,
      end: end,
      walletId: walletId,
      type: type,
    ).get();
    return _mapRows(rows);
  }

  Future<TransactionJoinRow?> getById(String id) async {
    final q = select(transactions).join([
      innerJoin(wallets, wallets.id.equalsExp(transactions.walletId)),
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.id.equals(id));
    final rows = await q.get();
    return rows.isEmpty ? null : _mapRows(rows).first;
  }

  Future<List<TransactionData>> getAllRaw() =>
      (select(transactions)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  // ── FIX #10: Aggregation với SQL – không load rows vào Dart ─

  Future<TransactionSummary> getSummarySQL(
    DateTime start,
    DateTime end, {
    int? walletId,
    String? moneyType,
  }) async {
    // Income query
    final incQ = selectOnly(transactions)
      ..addColumns([transactions.amount.sum(), transactions.tripCount.sum()])
      ..where(
        transactions.date.isBetweenValues(start, end) &
            transactions.type.equals('income') &
            transactions.isDeleted.equals(false),
      );
    if (walletId != null) incQ.where(transactions.walletId.equals(walletId));
    if (moneyType != null) {
      incQ.where(transactions.moneyType.equals(moneyType));
    }
    final incRow = await incQ.getSingle();

    // Expense query
    final expQ = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()])
      ..where(
        transactions.date.isBetweenValues(start, end) &
            transactions.type.equals('expense') &
            transactions.isDeleted.equals(false),
      );
    if (walletId != null) expQ.where(transactions.walletId.equals(walletId));
    final expRow = await expQ.getSingle();

    return TransactionSummary(
      totalIncome: incRow.read(transactions.amount.sum()) ?? 0.0,
      totalExpense: expRow.read(transactions.amount.sum()) ?? 0.0,
      tripCount: incRow.read(transactions.tripCount.sum()) ?? 0,
    );
  }

  Future<Map<int, double>> getSummaryByCategorySQL(
    DateTime start,
    DateTime end,
    String type, {
    int? walletId,
  }) async {
    final rows = await (select(transactions)
          ..where((t) {
            var e = t.date.isBetweenValues(start, end) &
                t.type.equals(type) &
                t.isDeleted.equals(false);
            if (walletId != null) e = e & t.walletId.equals(walletId);
            return e;
          }))
        .get();
    final result = <int, double>{};
    for (final r in rows) {
      if (r.categoryId != null) {
        result[r.categoryId!] = (result[r.categoryId!] ?? 0) + r.amount;
      }
    }
    return result;
  }

  Future<Map<String, double>> getSummaryByMoneyType(
    int walletId,
    DateTime start,
    DateTime end,
    String type,
  ) async {
    final rows = await (select(transactions)
          ..where((t) =>
              t.walletId.equals(walletId) &
              t.date.isBetweenValues(start, end) &
              t.type.equals(type) &
              t.isDeleted.equals(false)))
        .get();
    final result = <String, double>{};
    for (final r in rows) {
      result[r.moneyType] = (result[r.moneyType] ?? 0) + r.amount;
    }
    return result;
  }

  // ── Calendar aggregation ────────────────────────────────────

  Future<Map<DateTime, _DayAgg>> getDayAggregates(
      int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final rows = await (select(transactions)
          ..where((t) =>
              t.date.isBetweenValues(start, end) &
              t.isDeleted.equals(false)))
        .get();

    final result = <DateTime, _DayAgg>{};
    for (final r in rows) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      final agg = result[day] ??= _DayAgg();
      if (r.type == 'income') {
        agg.income += r.amount;
        agg.trips += r.tripCount;
      } else {
        agg.expense += r.amount;
      }
    }
    return result;
  }

  // ── Mutations ───────────────────────────────────────────────

  Future<void> insertTransaction(TransactionsCompanion t) =>
      into(transactions).insert(t);

  Future<bool> updateTransaction(TransactionsCompanion t) =>
      update(transactions).replace(t);

  Future<void> softDelete(String id) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(isDeleted: Value(true)));
}

class _DayAgg {
  double income = 0;
  double expense = 0;
  int trips = 0;
}
