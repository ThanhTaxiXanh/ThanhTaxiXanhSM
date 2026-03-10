// lib/features/transaction/presentation/providers/transaction_providers.dart
// FIX #4: Xóa static final _kNow – DateTime.now() được gọi fresh mỗi lần
// FIX #8: Thêm autoDispose cho providers có vòng đời ngắn

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/app_database.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_entity.dart';

// ── Repository ───────────────────────────────────────────────

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

// ── DateRangeFilter (value object) ──────────────────────────

class DateRangeFilter {
  const DateRangeFilter({required this.start, required this.end, this.walletId});
  final DateTime start;
  final DateTime end;
  final int? walletId;

  @override
  bool operator ==(Object o) =>
      o is DateRangeFilter &&
      start == o.start &&
      end == o.end &&
      walletId == o.walletId;

  @override
  int get hashCode => Object.hash(start, end, walletId);
}

// ── Stream providers ─────────────────────────────────────────

final transactionsByDateRangeProvider = StreamProvider.autoDispose
    .family<List<TransactionEntity>, DateRangeFilter>((ref, filter) {
  return ref.watch(transactionRepositoryProvider).watchByDateRange(
        filter.start,
        filter.end,
        walletId: filter.walletId,
      );
});

final recentTransactionsProvider =
    StreamProvider.autoDispose<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchRecent(limit: 50);
});

// ── Calendar ─────────────────────────────────────────────────

final monthlyCalendarProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DailySummary>, ({int year, int month})>(
        (ref, p) async {
  return ref
      .watch(transactionRepositoryProvider)
      .getMonthlyCalendar(p.year, p.month);
});

// ── Selected date ────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>(
  // FIX #4: DateTime.now() là getter, fresh mỗi lần provider khởi tạo
  (ref) => DateTime.now(),
);

// ── Add Transaction State ────────────────────────────────────

class AddTransactionState {
  const AddTransactionState({
    this.amountRaw = '',
    this.type = 'income',
    this.selectedWalletId,
    this.selectedMoneyType,
    this.selectedCategoryId,
    this.note = '',
    this.date,
    this.tripCount = 1,
    this.isLoading = false,
    this.errorMessage,
    this.savedId,
  });

  final String amountRaw; // Raw digits string, không bị frozen
  final String type;
  final int? selectedWalletId;
  final String? selectedMoneyType;
  final int? selectedCategoryId;
  final String note;
  final DateTime? date; // null → DateTime.now() khi save, luôn fresh
  final int tripCount;
  final bool isLoading;
  final String? errorMessage;
  final String? savedId;

  bool get isIncome => type == 'income';
  double get amount => double.tryParse(amountRaw) ?? 0;
  bool get isValid =>
      amount > 0 && selectedWalletId != null && selectedMoneyType != null;

  // FIX #4: date luôn fresh – không dùng static DateTime
  DateTime get effectiveDate => date ?? DateTime.now();

  AddTransactionState copyWith({
    String? amountRaw,
    String? type,
    int? selectedWalletId,
    String? selectedMoneyType,
    int? selectedCategoryId,
    String? note,
    DateTime? date,
    int? tripCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? savedId,
    bool clearSaved = false,
  }) =>
      AddTransactionState(
        amountRaw: amountRaw ?? this.amountRaw,
        type: type ?? this.type,
        selectedWalletId: selectedWalletId ?? this.selectedWalletId,
        selectedMoneyType: selectedMoneyType ?? this.selectedMoneyType,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        note: note ?? this.note,
        date: date ?? this.date,
        tripCount: tripCount ?? this.tripCount,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        savedId: clearSaved ? null : (savedId ?? this.savedId),
      );
}

// ── Notifier ─────────────────────────────────────────────────

class AddTransactionNotifier
    extends StateNotifier<AddTransactionState> {
  AddTransactionNotifier(this._repo, this._ref)
      : super(const AddTransactionState());

  final TransactionRepository _repo;
  final Ref _ref;

  // Keyboard
  void appendDigit(String d) {
    final cur = state.amountRaw;
    if (cur.isEmpty || cur == '0') {
      state = state.copyWith(amountRaw: d, clearError: true);
    } else if (cur.length < 12) {
      state = state.copyWith(amountRaw: '$cur$d', clearError: true);
    }
  }

  void appendZeros() {
    if (state.amountRaw.isEmpty) return;
    if (state.amountRaw.length < 10) {
      state = state.copyWith(
          amountRaw: '${state.amountRaw}000', clearError: true);
    }
  }

  void backspace() {
    final t = state.amountRaw;
    state = state.copyWith(
      amountRaw: t.length <= 1 ? '' : t.substring(0, t.length - 1),
      clearError: true,
    );
  }

  // Form fields
  void setType(String type) =>
      state = state.copyWith(type: type, selectedCategoryId: null, clearError: true);

  /// FIX #5: Guard wallets.first crash
  void setWallet(int walletId) {
    final wallets = _ref.read(walletListProvider).valueOrNull ?? [];
    if (wallets.isEmpty) return;
    final wallet = wallets.where((w) => w.id == walletId).firstOrNull;
    if (wallet == null) return;
    state = state.copyWith(
      selectedWalletId: walletId,
      selectedMoneyType:
          wallet.moneyTypes.isNotEmpty ? wallet.moneyTypes.first : null,
      clearError: true,
    );
  }

  void setMoneyType(String t) =>
      state = state.copyWith(selectedMoneyType: t, clearError: true);
  void setCategory(int? id) =>
      state = state.copyWith(selectedCategoryId: id, clearError: true);
  void setNote(String n) => state = state.copyWith(note: n);
  void setDate(DateTime d) => state = state.copyWith(date: d);
  void setTripCount(int c) =>
      state = state.copyWith(tripCount: c.clamp(1, 999));

  Future<bool> save() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập số tiền và chọn ví');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final id = const Uuid().v4();
      await _repo.add(
        walletId: state.selectedWalletId!,
        type: state.type,
        amount: state.amount,
        moneyType: state.selectedMoneyType!,
        categoryId: state.selectedCategoryId,
        note: state.note.trim(),
        date: state.effectiveDate, // FIX #4: always fresh
        tripCount: state.tripCount,
      );
      state = state.copyWith(isLoading: false, savedId: id);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi lưu: ${e.toString()}',
      );
      return false;
    }
  }

  void resetAfterSave() {
    final wallets = _ref.read(walletListProvider).valueOrNull ?? [];
    if (wallets.isEmpty) {
      state = const AddTransactionState();
      return;
    }
    final w = wallets.first;
    state = AddTransactionState(
      selectedWalletId: w.id,
      selectedMoneyType: w.moneyTypes.isNotEmpty ? w.moneyTypes.first : null,
    );
  }
}

// FIX #8: autoDispose – giải phóng khi đóng bottom sheet
final addTransactionProvider = StateNotifierProvider.autoDispose<
    AddTransactionNotifier, AddTransactionState>((ref) {
  final wallets = ref.read(walletListProvider).valueOrNull ?? [];
  final notifier =
      AddTransactionNotifier(ref.watch(transactionRepositoryProvider), ref);
  // FIX #5: Guard empty wallets
  if (wallets.isNotEmpty) notifier.setWallet(wallets.first.id);
  return notifier;
});
