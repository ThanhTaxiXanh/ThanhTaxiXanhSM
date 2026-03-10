// lib/features/transaction/presentation/screens/home_screen.dart
// FIX #7: InsightsEngine nhận data thật từ providers
// FIX #6/#7: Tách mỗi section thành widget riêng – chỉ rebuild phần liên quan

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../insights/domain/insights_engine.dart';
import '../providers/transaction_providers.dart';
import '../../data/transaction_repository.dart';

// ── Scoped providers chỉ dùng trên HomeScreen ───────────────

final _todaySummaryProvider =
    FutureProvider.autoDispose<DailySummary>((ref) async {
  final now = DateTime.now();
  return ref
      .watch(transactionRepositoryProvider)
      .getDailySummary(now); // FIX #4: now fresh mỗi lần
});

final _yesterdaySummaryProvider =
    FutureProvider.autoDispose<DailySummary>((ref) async {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return ref.watch(transactionRepositoryProvider).getDailySummary(yesterday);
});

final _weeklyAvgProvider = FutureProvider.autoDispose<double>((ref) async {
  final now = DateTime.now();
  final start = DateFormatter.startOfWeek(now);
  final end = DateFormatter.endOfWeek(now);
  final s = await ref
      .watch(transactionRepositoryProvider)
      .getSummary(start, end);
  return s.tripCount > 0 ? s.totalIncome / s.tripCount : 0;
});

// ── HomeScreen ───────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _AppBar(),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                // FIX #7: mỗi widget tự watch provider riêng
                _TodayCard(),
                SizedBox(height: 12),
                _FeeShortcut(),
                SizedBox(height: 12),
                _InsightsCarousel(),
                SizedBox(height: 12),
                _RecentList(),
                SizedBox(height: 90),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App bar ──────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚕 Thanh Taxi Xanh SM',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormatter.formatFullDate(now),
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00C853), Color(0xFF00897B)],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Today card ───────────────────────────────────────────────

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_todaySummaryProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: async.when(
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('📊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Hôm nay',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                _Pill(
                    label: '${s.tripCount} cuốc',
                    color: AppTheme.primaryGreen),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _StatCol(
                        label: 'Thu nhập',
                        value: CurrencyFormatter.format(s.totalIncome),
                        color: AppTheme.primaryGreen)),
                Expanded(
                    child: _StatCol(
                        label: 'Chi tiêu',
                        value: CurrencyFormatter.format(s.totalExpense),
                        color: AppTheme.negativeRed)),
                Expanded(
                    child: _StatCol(
                        label: 'Số dư',
                        value: CurrencyFormatter.format(s.balance),
                        color: s.balance >= 0
                            ? AppTheme.primaryGreen
                            : AppTheme.negativeRed)),
              ]),
            ],
          ),
          loading: () => const _Skeleton(),
          error: (e, _) => Text('Lỗi: $e'),
        ),
      ),
    );
  }
}

// ── Fee shortcut ─────────────────────────────────────────────

class _FeeShortcut extends ConsumerWidget {
  const _FeeShortcut();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasXanhSm = (ref.watch(walletListProvider).valueOrNull ?? [])
        .any((w) => w.isXanhSm);
    if (!hasXanhSm) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pushNamed('/fee-calculator'),
        icon: const Text('💸', style: TextStyle(fontSize: 18)),
        label: const Text('Tính & Đóng Phí Xanh SM',
            style: TextStyle(fontSize: 15)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}

// ── Insights carousel ────────────────────────────────────────

/// FIX #7: Widget riêng với providers riêng – HomeScreen không rebuild khi data thay đổi
class _InsightsCarousel extends ConsumerWidget {
  const _InsightsCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(_todaySummaryProvider).valueOrNull;
    final yesterday = ref.watch(_yesterdaySummaryProvider).valueOrNull;
    final avg = ref.watch(_weeklyAvgProvider).valueOrNull ?? 0;

    if (today == null) return const SizedBox.shrink();

    // FIX #7: Truyền data thật vào InsightsEngine
    final insights = InsightsEngine.analyze(
      today: today,
      yesterday: yesterday ??
          DailySummary(
            date: DateTime.now().subtract(const Duration(days: 1)),
            totalIncome: 0,
            totalExpense: 0,
            tripCount: 0,
          ),
      thisWeek: [],
      avgPerTrip: avg,
    );

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'Nhận xét hôm nay', emoji: '🤖'),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _InsightTile(card: insights[i]),
          ),
        ),
      ],
    );
  }
}

// ── Recent transactions list ─────────────────────────────────

/// FIX #7: Widget riêng – không kéo HomeScreen rebuild
class _RecentList extends ConsumerWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentTransactionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'Giao dịch gần đây', emoji: '🕐'),
        const SizedBox(height: 8),
        async.when(
          data: (list) => list.isEmpty
              ? const _EmptyState()
              : Column(
                  children: list
                      .take(8)
                      .map((t) => _TxnTile(txn: t))
                      .toList()),
          loading: () => const _Skeleton(),
          error: (e, _) =>
              Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.emoji});
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 6),
      Text(label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.grey[700])),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 3),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.card});
  final InsightCard card;

  Color get _bg {
    switch (card.type) {
      case InsightType.positive:
      case InsightType.achievement:
        return AppTheme.primaryGreen.withOpacity(0.08);
      case InsightType.warning:
        return AppTheme.negativeRed.withOpacity(0.08);
      case InsightType.info:
        return Colors.blue.withOpacity(0.08);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 215,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(card.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(card.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 5),
          Text(card.message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});
  final txn;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: txn.amountColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
              txn.categoryEmoji ?? (txn.isIncome ? '💰' : '💸'),
              style: const TextStyle(fontSize: 20)),
        ),
        title: Text(txn.categoryDisplay,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
            '${txn.walletEmoji} ${txn.walletName} · ${txn.moneyType}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(children: [
        const Text('🌅', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 8),
        Text('Chưa có giao dịch nào',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text('Nhấn + để thêm giao dịch đầu tiên!',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}
