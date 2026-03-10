// lib/features/stats/presentation/screens/stats_screen.dart
// Màn hình Thống Kê: Segmented control + Cards + Pie Chart fl_chart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../transaction/data/transaction_repository.dart';
import '../../../transaction/presentation/providers/transaction_providers.dart';
import '../../../settings/presentation/providers/category_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  int? _selectedWalletId;
  int _touchedPieIndex = -1;

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_period) {
      case StatsPeriod.thisWeek:
        return DateTimeRange(
          start: DateFormatter.startOfWeek(now),
          end: DateFormatter.endOfWeek(now),
        );
      case StatsPeriod.lastWeek:
        final lastWeek = now.subtract(const Duration(days: 7));
        return DateTimeRange(
          start: DateFormatter.startOfWeek(lastWeek),
          end: DateFormatter.endOfWeek(lastWeek),
        );
      case StatsPeriod.thisMonth:
        return DateTimeRange(
          start: DateFormatter.startOfMonth(now),
          end: DateFormatter.endOfMonth(now),
        );
      case StatsPeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        return DateTimeRange(
          start: DateFormatter.startOfMonth(lastMonth),
          end: DateFormatter.endOfMonth(lastMonth),
        );
      case StatsPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case StatsPeriod.custom:
        return DateTimeRange(
          start: _customStart ?? DateFormatter.startOfMonth(now),
          end: _customEnd ?? DateFormatter.endOfMonth(now),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _getDateRange();
    final txnsAsync = ref.watch(transactionsByDateRangeProvider(
      DateRangeFilter(
        start: range.start,
        end: range.end,
        walletId: _selectedWalletId,
      ),
    ));
    final wallets = ref.watch(walletListProvider).valueOrNull ?? [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Thống Kê'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // === PERIOD SELECTOR ===
          _buildPeriodSelector(),

          // === WALLET FILTER ===
          _buildWalletFilter(wallets),

          // === CONTENT ===
          Expanded(
            child: txnsAsync.when(
              data: (txns) => _buildContent(context, txns, categories, range),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: StatsPeriod.values.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(p.label),
              selected: selected,
              onSelected: (_) async {
                if (p == StatsPeriod.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('vi', 'VN'),
                  );
                  if (picked != null) {
                    setState(() {
                      _period = p;
                      _customStart = picked.start;
                      _customEnd = picked.end;
                    });
                  }
                } else {
                  setState(() => _period = p);
                }
              },
              selectedColor: AppTheme.primaryGreen,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWalletFilter(wallets) {
    if (wallets.isEmpty) return const SizedBox();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _selectedWalletId == null,
            onSelected: (_) => setState(() => _selectedWalletId = null),
            selectedColor: Colors.grey[700],
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: _selectedWalletId == null ? Colors.white : null,
            ),
          ),
          const SizedBox(width: 8),
          ...wallets.map<Widget>((w) {
            final selected = w.id == _selectedWalletId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${w.emoji} ${w.name}'),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedWalletId = selected ? null : w.id),
                selectedColor: AppTheme.primaryGreen,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, txns, categories, DateTimeRange range) {
    double totalIncome = 0;
    double totalExpense = 0;
    int tripCount = 0;
    final Map<int, double> expenseByCategory = {};
    final Map<int, double> incomeByCategory = {};

    for (final t in txns) {
      if (t.isIncome) {
        totalIncome += t.amount;
        tripCount += t.tripCount;
        if (t.categoryId != null) {
          incomeByCategory[t.categoryId!] =
              (incomeByCategory[t.categoryId!] ?? 0) + t.amount;
        }
      } else {
        totalExpense += t.amount;
        if (t.categoryId != null) {
          expenseByCategory[t.categoryId!] =
              (expenseByCategory[t.categoryId!] ?? 0) + t.amount;
        }
      }
    }

    final balance = totalIncome - totalExpense;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // === CARDS TỔNG QUAN ===
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '📈',
                label: 'Thu nhập',
                value: CurrencyFormatter.format(totalIncome),
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '📉',
                label: 'Chi tiêu',
                value: CurrencyFormatter.format(totalExpense),
                color: AppTheme.negativeRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                emoji: '💰',
                label: 'Số dư',
                value: CurrencyFormatter.format(balance),
                color:
                    balance >= 0 ? AppTheme.primaryGreen : AppTheme.negativeRed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                emoji: '🚕',
                label: 'Số cuốc',
                value: '$tripCount cuốc',
                color: Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // === PIE CHART CHI TIÊU ===
        if (expenseByCategory.isNotEmpty)
          _buildPieCard(
            context,
            title: '📉 Chi tiêu theo danh mục',
            dataMap: expenseByCategory,
            categories: categories,
            total: totalExpense,
          ),

        const SizedBox(height: 12),

        // === PIE CHART THU NHẬP ===
        if (incomeByCategory.isNotEmpty)
          _buildPieCard(
            context,
            title: '📈 Thu nhập theo danh mục',
            dataMap: incomeByCategory,
            categories: categories,
            total: totalIncome,
          ),

        if (txns.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Text('📊', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có dữ liệu trong khoảng này',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPieCard(
    BuildContext context, {
    required String title,
    required Map<int, double> dataMap,
    required categories,
    required double total,
  }) {
    if (dataMap.isEmpty) return const SizedBox();

    // Chuẩn bị data cho pie chart
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.negativeRed,
      const Color(0xFFFFD600),
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    final entries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      final pct = total > 0 ? (entry.value / total * 100) : 0;
      final touched = index == _touchedPieIndex;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: touched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: touched ? 60 : 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions &&
                          response?.touchedSection != null) {
                        setState(() {
                          _touchedPieIndex = response!
                              .touchedSection!.touchedSectionIndex;
                        });
                      } else {
                        setState(() => _touchedPieIndex = -1);
                      }
                    },
                  ),
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            ...entries.asMap().entries.map((e) {
              final catData = categories.where(
                  (c) => c.id == e.value.key).toList();
              final catName = catData.isNotEmpty
                  ? '${catData.first.emoji} ${catData.first.name}'
                  : 'Khác';
              final pct = total > 0
                  ? (e.value.value / total * 100).toStringAsFixed(1)
                  : '0';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(e.value.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
