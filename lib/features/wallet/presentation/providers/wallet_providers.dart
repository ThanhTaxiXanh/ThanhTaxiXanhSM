// lib/features/wallet/presentation/providers/wallet_providers.dart
// FIX #8: feeCalculatorProvider thêm autoDispose

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/app_database.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet_entity.dart';
import '../../domain/fee_calculator.dart';

// ── Singleton database – dispose khi app tắt ────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Repositories ─────────────────────────────────────────────

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(databaseProvider));
});

// ── Wallet list (global stream, không autoDispose) ───────────

final walletListProvider = StreamProvider<List<WalletEntity>>((ref) {
  return ref.watch(walletRepositoryProvider).watchWallets();
});

final walletDetailProvider =
    FutureProvider.autoDispose.family<WalletEntity?, int>((ref, id) {
  return ref.watch(walletRepositoryProvider).getWalletById(id);
});

// ── Fee Calculator ───────────────────────────────────────────

class FeeCalculatorState {
  const FeeCalculatorState({
    this.selectedWalletId,
    this.periodStart,
    this.periodEnd,
    this.result,
    this.isLoading = false,
    this.error,
  });

  final int? selectedWalletId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final FeeCalculationResult? result;
  final bool isLoading;
  final String? error;

  bool get canCalculate =>
      selectedWalletId != null && periodStart != null && periodEnd != null;

  FeeCalculatorState copyWith({
    int? selectedWalletId,
    DateTime? periodStart,
    DateTime? periodEnd,
    FeeCalculationResult? result,
    bool? isLoading,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      FeeCalculatorState(
        selectedWalletId: selectedWalletId ?? this.selectedWalletId,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        result: clearResult ? null : (result ?? this.result),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class FeeCalculatorNotifier
    extends StateNotifier<FeeCalculatorState> {
  FeeCalculatorNotifier(this._repo) : super(const FeeCalculatorState());

  final WalletRepository _repo;

  void setWallet(int id) =>
      state = state.copyWith(selectedWalletId: id, clearResult: true);

  void setPeriod(DateTime start, DateTime end) =>
      state = state.copyWith(
          periodStart: start, periodEnd: end, clearResult: true);

  Future<void> calculate() async {
    if (!state.canCalculate) {
      state =
          state.copyWith(error: 'Vui lòng chọn ví và khoảng thời gian');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallet = await _repo.getWalletById(state.selectedWalletId!);
      if (wallet == null) {
        state = state.copyWith(isLoading: false, error: 'Không tìm thấy ví');
        return;
      }
      final result = await _repo.calculateFee(
          wallet, state.periodStart!, state.periodEnd!);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Lỗi tính phí: $e');
    }
  }

  Future<bool> confirmPayment() async {
    if (state.result == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.confirmFeePayment(state.result!);
      state = const FeeCalculatorState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Lỗi đóng phí: $e');
      return false;
    }
  }

  void reset() => state = const FeeCalculatorState();
}

// FIX #8: autoDispose – không leak khi rời màn hình tính phí
final feeCalculatorProvider = StateNotifierProvider.autoDispose<
    FeeCalculatorNotifier, FeeCalculatorState>((ref) {
  return FeeCalculatorNotifier(ref.watch(walletRepositoryProvider));
});
