// lib/features/transaction/presentation/screens/history_screen.dart
// FIX #6: Xóa setState cho _selectedDay – dùng StateProvider.autoDispose
// Mỗi widget section là ConsumerWidget riêng – tránh rebuild cả màn hình

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/transaction_providers.dart';
import '../../data/transaction_repository.dart';

// ── Scoped providers ─────────────────────────────────────────

/// FIX #6: viewMonth dùng StateProvider – không setState cả màn hình
final _viewMonthProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final _selectedDayProvider =
    StateProvider.autoDispose<DateTime?>((ref) => null);

// ── HistoryScreen ────────────────────────────────────────────

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Lịch Sử'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      // FIX #6: Mỗi child là widget riêng, chỉ rebuild phần liên quan
      body: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _CalendarCard()),
          SliverToBoxAdapter(child: _MonthSummaryBar()),
          SliverToBoxAdapter(child: _DayTransactions()),
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ── Calendar card ────────────────────────────────────────────

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(_viewMonthProvider);
    final calAsync = ref.watch(
        monthlyCalendarProvider((year: month.year, month: month.month)));

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _MonthNav(month: month),
            const SizedBox(height: 6),
            _WeekdayRow(),
            const SizedBox(height: 4),
            calAsync.when(
              data: (data) => _Grid(month: month, data: data),
              loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SizedBox(
                  height: 60, child: Center(child: Text('Lỗi: $e'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthNav extends ConsumerWidget {
  const _MonthNav({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => ref.read(_viewMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        Expanded(
          child: Text(
            'Tháng ${month.month}/${month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => ref.read(_viewMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: d == 'CN'
                            ? AppTheme.negativeRed
                            : Colors.grey[600])),
              ))
          .toList(),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.month, required this.data});
  final DateTime month;
  final Map<DateTime, DailySummary> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedDayProvider);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final offset = (firstDay.weekday - 1) % 7;
    final cellCount = (((offset + lastDay.day) / 7).ceil()) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 0.72,
          mainAxisSpacing: 2,
          crossAxisSpacing: 1),
      itemCount: cellCount,
      itemBuilder: (_, i) {
        final dayNum = i - offset + 1;
        if (dayNum < 1 || dayNum > lastDay.day) return const SizedBox();
        final date = DateTime(month.year, month.month, dayNum);
        final summary = data[date];
        final isToday =
            DateFormatter.isSameDay(date, DateTime.now());
        final isSel =
            selected != null && DateFormatter.isSameDay(date, selected);

        return GestureDetector(
          onTap: () {
            final cur = ref.read(_selectedDayProvider);
            ref.read(_selectedDayProvider.notifier).state =
                (cur != null && DateFormatter.isSameDay(cur, date))
                    ? null
                    : date;
          },
          child: _DayCell(
            dayNum: dayNum,
            summary: summary,
            isToday: isToday,
            isSelected: isSel,
            isSunday: date.weekday == 7,
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNum,
    required this.summary,
    required this.isToday,
    required this.isSelected,
    required this.isSunday,
  });
  final int dayNum;
  final DailySummary? summary;
  final bool isToday, isSelected, isSunday;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryGreen.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppTheme.primaryGreen, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (summary != null && summary!.totalIncome > 0)
            Text(CurrencyFormatter.formatShort(summary!.totalIncome),
                style: const TextStyle(
                    fontSize: 8,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis)
          else
            const SizedBox(height: 10),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text('$dayNum',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isSunday
                            ? AppTheme.negativeRed
                            : null)),
          ),
          if (summary != null && summary!.totalExpense > 0)
            Text(CurrencyFormatter.formatShort(summary!.totalExpense),
                style: const TextStyle(
                    fontSize: 8,
                    color: AppTheme.negativeRed,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis)
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Month summary bar ────────────────────────────────────────

class _MonthSummaryBar extends ConsumerWidget {
  const _MonthSummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(_viewMonthProvider);
    final calAsync = ref.watch(
        monthlyCalendarProvider((year: month.year, month: month.month)));

    return calAsync.when(
      data: (data) {
        double inc = 0, exp = 0;
        int trips = 0;
        for (final s in data.values) {
          inc += s.totalIncome;
          exp += s.totalExpense;
          trips += s.tripCount;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            color: AppTheme.primaryGreen.withOpacity(0.07),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: _SumCol(
                          label: 'Thu tháng',
                          value: CurrencyFormatter.format(inc),
                          color: AppTheme.primaryGreen)),
                  Expanded(
                      child: _SumCol(
                          label: 'Chi tháng',
                          value: CurrencyFormatter.format(exp),
                          color: AppTheme.negativeRed)),
                  Expanded(
                      child: _SumCol(
                          label: 'Tổng cuốc',
                          value: '$trips',
                          color: Colors.blue)),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Selected day transactions ────────────────────────────────

/// FIX #6: Widget riêng – chỉ rebuild khi selectedDay thay đổi
class _DayTransactions extends ConsumerWidget {
  const _DayTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(_selectedDayProvider);
    if (day == null) return const SizedBox.shrink();

    final txnsAsync = ref.watch(transactionsByDateRangeProvider(DateRangeFilter(
      start: DateFormatter.startOfDay(day),
      end: DateFormatter.endOfDay(day),
    )));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              DateFormatter.formatSmartDate(day),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          txnsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('Không có giao dịch',
                            style: TextStyle(color: Colors.grey))))
                : Column(
                    children: list.map((t) => _TxnCard(txn: t)).toList()),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
          ),
        ],
      ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txn});
  final txn;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(txn.categoryEmoji ?? (txn.isIncome ? '💰' : '💸'),
            style: const TextStyle(fontSize: 22)),
        title: Text(txn.categoryDisplay,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            '${txn.walletEmoji} ${txn.walletName} · ${txn.moneyType}',
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${txn.sign}${CurrencyFormatter.format(txn.amount)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: txn.amountColor)),
            Text(DateFormatter.formatTime(txn.date),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _SumCol extends StatelessWidget {
  const _SumCol(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color),
          overflow: TextOverflow.ellipsis),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}
