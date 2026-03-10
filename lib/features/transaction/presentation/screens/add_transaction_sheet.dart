// lib/features/transaction/presentation/screens/add_transaction_sheet.dart
// FIX #5: Guard wallets.isEmpty – không còn crash .first trên list rỗng
// Amount state nằm hoàn toàn trong Notifier (amountRaw string)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../settings/presentation/providers/category_providers.dart';
import '../providers/transaction_providers.dart';

class AddTransactionSheet extends ConsumerWidget {
  const AddTransactionSheet({super.key});

  static Future<bool?> show(BuildContext context) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransactionSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletListProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.6,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _Handle(),
          Expanded(
            child: wallets.isEmpty
                // FIX #5: Hiển thị hướng dẫn thay vì crash
                ? const _NoWalletPlaceholder()
                : _SheetBody(
                    scrollCtrl: sc, wallets: wallets),
          ),
        ]),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2)),
      );
}

// ── FIX #5: Fallback khi chưa có ví ─────────────────────────

class _NoWalletPlaceholder extends StatelessWidget {
  const _NoWalletPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💳', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Chưa có ví nào',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Vào tab Cài Đặt → Ví để tạo ví trước khi thêm giao dịch.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
    );
  }
}

// ── Sheet body ───────────────────────────────────────────────

class _SheetBody extends ConsumerStatefulWidget {
  const _SheetBody({required this.scrollCtrl, required this.wallets});
  final ScrollController scrollCtrl;
  final List wallets;

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final notifier = ref.read(addTransactionProvider.notifier);
    notifier.setNote(_noteCtrl.text.trim());
    final ok = await notifier.save();
    if (!mounted) return;
    if (ok) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Đã lưu giao dịch!'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      notifier.resetAfterSave();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addTransactionProvider);
    final notifier = ref.read(addTransactionProvider.notifier);
    final categories =
        ref.watch(categoriesByTypeProvider(state.type)).valueOrNull ?? [];
    final themeColor =
        state.isIncome ? AppTheme.primaryGreen : AppTheme.negativeRed;

    return SingleChildScrollView(
      controller: widget.scrollCtrl,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeToggle(
              isIncome: state.isIncome, onToggle: notifier.setType),
          const SizedBox(height: 14),
          _AmountDisplay(raw: state.amountRaw, color: themeColor),
          const SizedBox(height: 12),
          _Label('Ví'),
          const SizedBox(height: 8),
          _WalletChips(
              wallets: widget.wallets,
              selectedId: state.selectedWalletId,
              onSelect: notifier.setWallet),
          const SizedBox(height: 12),
          if (state.selectedWalletId != null) ...[
            _Label('Loại tiền'),
            const SizedBox(height: 8),
            _MoneyTypeChips(
                wallets: widget.wallets,
                selectedId: state.selectedWalletId,
                selected: state.selectedMoneyType,
                onSelect: notifier.setMoneyType),
            const SizedBox(height: 12),
          ],
          _Label('Danh mục'),
          const SizedBox(height: 8),
          _CategoryChips(
              categories: categories,
              selected: state.selectedCategoryId,
              onSelect: notifier.setCategory),
          const SizedBox(height: 12),
          _Label('Ghi chú (tuỳ chọn)'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLength: 200,
            maxLines: 2,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Cuốc sân bay, thưởng chuyến dài…',
              hintStyle:
                  TextStyle(fontSize: 14, color: Colors.grey[400]),
              counterText: '',
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.negativeRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Text('⚠️'),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(state.errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.negativeRed, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          _Keyboard(notifier: notifier),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: state.isLoading || !state.isValid ? null : _onSave,
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor),
              child: state.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      state.isIncome
                          ? '✅ Lưu Thu Nhập'
                          : '✅ Lưu Chi Tiêu',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.isIncome, required this.onToggle});
  final bool isIncome;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _Tab(
            label: '📈 Thu Nhập',
            active: isIncome,
            color: AppTheme.primaryGreen,
            onTap: () => onToggle('income')),
        _Tab(
            label: '📉 Chi Tiêu',
            active: !isIncome,
            color: AppTheme.negativeRed,
            onTap: () => onToggle('expense')),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.grey)),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.raw, required this.color});
  final String raw;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(raw) ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        amount > 0 ? CurrencyFormatter.format(amount) : '0đ',
        style: TextStyle(
            fontSize: 30, fontWeight: FontWeight.bold, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey[600], fontWeight: FontWeight.w600));
  }
}

class _WalletChips extends StatelessWidget {
  const _WalletChips(
      {required this.wallets,
      required this.selectedId,
      required this.onSelect});
  final List wallets;
  final int? selectedId;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wallets.map<Widget>((w) {
        final sel = w.id == selectedId;
        return FilterChip(
          label:
              Text('${w.emoji} ${w.name}', style: const TextStyle(fontSize: 13)),
          selected: sel,
          onSelected: (_) => onSelect(w.id),
          selectedColor: AppTheme.primaryGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
              color: sel ? Colors.white : null,
              fontWeight: sel ? FontWeight.bold : null),
        );
      }).toList(),
    );
  }
}

class _MoneyTypeChips extends StatelessWidget {
  const _MoneyTypeChips(
      {required this.wallets,
      required this.selectedId,
      required this.selected,
      required this.onSelect});
  final List wallets;
  final int? selectedId;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    // FIX #5: firstOrNull – không crash
    final wallet =
        wallets.where((w) => w.id == selectedId).firstOrNull;
    if (wallet == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      children: wallet.moneyTypes.map<Widget>((type) {
        final sel = type == selected;
        return FilterChip(
          label: Text(type, style: const TextStyle(fontSize: 13)),
          selected: sel,
          onSelected: (_) => onSelect(type),
          selectedColor: AppTheme.primaryGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(color: sel ? Colors.white : null),
        );
      }).toList(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips(
      {required this.categories,
      required this.selected,
      required this.onSelect});
  final List categories;
  final int? selected;
  final void Function(int?) onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Tất cả', style: TextStyle(fontSize: 12)),
          selected: selected == null,
          onSelected: (_) => onSelect(null),
          selectedColor: Colors.grey[700],
          labelStyle: TextStyle(
              color: selected == null ? Colors.white : null),
        ),
        ...categories.map<Widget>((c) {
          final sel = c.id == selected;
          return FilterChip(
            label: Text('${c.emoji} ${c.name}',
                style: const TextStyle(fontSize: 12)),
            selected: sel,
            onSelected: (_) => onSelect(c.id),
            selectedColor: AppTheme.primaryGreen,
            checkmarkColor: Colors.white,
            labelStyle:
                TextStyle(color: sel ? Colors.white : null),
          );
        }),
      ],
    );
  }
}

class _Keyboard extends ConsumerWidget {
  const _Keyboard({required this.notifier});
  final AddTransactionNotifier notifier;

  static const _rows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['000', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: _rows.map((row) => Row(
        children: row.map((k) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (k == '⌫') notifier.backspace();
                  else if (k == '000') notifier.appendZeros();
                  else notifier.appendDigit(k);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceVariant,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(k,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        )).toList(),
      )).toList(),
    );
  }
}
