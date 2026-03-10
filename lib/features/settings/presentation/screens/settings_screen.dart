// lib/features/settings/presentation/screens/settings_screen.dart
// Màn hình Cài Đặt: ví, PIN, backup, danh mục, xuất dữ liệu

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/security_service.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../../core/utils/formatters.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletListProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Ví & Cài Đặt'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // === DANH SÁCH VÍ ===
          _SectionHeader(title: '💳 Ví của tôi'),
          ...wallets.map((w) => _WalletTile(wallet: w)),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: AppTheme.primaryGreen),
            ),
            title: const Text('Thêm ví mới',
                style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${wallets.length}/10 ví',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            onTap: wallets.length < 10
                ? () => _showAddWalletDialog(context, ref)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đạt tối đa 10 ví')),
                    ),
          ),

          const Divider(height: 24),

          // === BẢO MẬT ===
          _SectionHeader(title: '🔐 Bảo Mật'),
          ListTile(
            leading: const Text('🔢', style: TextStyle(fontSize: 24)),
            title: const Text('Thiết lập PIN', style: TextStyle(fontSize: 16)),
            subtitle:
                const Text('PIN 4-6 số bảo vệ ứng dụng', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/pin-setup'),
          ),
          ListTile(
            leading: const Text('👆', style: TextStyle(fontSize: 24)),
            title: const Text('Vân tay / Face ID', style: TextStyle(fontSize: 16)),
            subtitle: const Text('Mở khóa bằng sinh trắc học', style: TextStyle(fontSize: 13)),
            trailing: _BiometricsSwitch(),
          ),

          const Divider(height: 24),

          // === DANH MỤC ===
          _SectionHeader(title: '🏷️ Danh Mục'),
          ListTile(
            leading: const Text('📝', style: TextStyle(fontSize: 24)),
            title: const Text('Quản lý danh mục', style: TextStyle(fontSize: 16)),
            subtitle: const Text('Thêm, sửa, xóa danh mục thu/chi', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/categories'),
          ),

          const Divider(height: 24),

          // === BACKUP ===
          _SectionHeader(title: '☁️ Sao Lưu & Khôi Phục'),
          ListTile(
            leading: const Text('☁️', style: TextStyle(fontSize: 24)),
            title: const Text('Backup Google Drive', style: TextStyle(fontSize: 16)),
            subtitle:
                const Text('Mã hóa AES-256, chỉ bạn mới đọc được', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/backup'),
          ),

          // === EXPORT ===
          _SectionHeader(title: '📤 Xuất Dữ Liệu'),
          ListTile(
            leading: const Text('📊', style: TextStyle(fontSize: 24)),
            title: const Text('Xuất Excel/CSV', style: TextStyle(fontSize: 16)),
            subtitle: const Text('Chia sẻ qua bất kỳ ứng dụng nào', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển...')),
              );
            },
          ),

          // === GEMINI AI ===
          const Divider(height: 24),
          _SectionHeader(title: '🤖 AI Nâng Cao (Tùy Chọn)'),
          ListTile(
            leading: const Text('🔑', style: TextStyle(fontSize: 24)),
            title: const Text('Gemini API Key', style: TextStyle(fontSize: 16)),
            subtitle: const Text(
                'Nhập key để phân tích AI chuyên sâu hơn',
                style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGeminiKeyDialog(context),
          ),

          const Divider(height: 24),

          // === THÔNG TIN ===
          _SectionHeader(title: 'ℹ️ Về Ứng Dụng'),
          const ListTile(
            leading: Text('🚕', style: TextStyle(fontSize: 24)),
            title: Text('Thanh Taxi Xanh SM v1.0.0', style: TextStyle(fontSize: 16)),
            subtitle: Text(
              'Miễn phí · Offline · Không quảng cáo\nMade with 💚 for Vietnamese Drivers',
              style: TextStyle(fontSize: 13),
            ),
            isThreeLine: true,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    bool isXanhSm = false;
    double feeRate = 0.18;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('➕ Thêm Ví Mới'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên ví',
                  hintText: 'VD: Grab, Be, Khác...',
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Ví nền tảng (có phí)'),
                subtitle:
                    const Text('Bật để tính phí nền tảng tự động'),
                value: isXanhSm,
                onChanged: (v) => setState(() => isXanhSm = v),
                activeColor: AppTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
              ),
              if (isXanhSm) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Phí nền tảng: '),
                    Text(
                      '${(feeRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
                Slider(
                  value: feeRate,
                  min: 0.05,
                  max: 0.40,
                  divisions: 35,
                  activeColor: AppTheme.primaryGreen,
                  label: '${(feeRate * 100).toStringAsFixed(0)}%',
                  onChanged: (v) => setState(() => feeRate = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(walletRepositoryProvider).addWallet(
                      name: name,
                      isXanhSm: isXanhSm,
                      feeRate: feeRate,
                      moneyTypes: isXanhSm
                          ? ['Tiền Mặt', 'Thẻ/Ví']
                          : ['Tiền Mặt'],
                      emoji: isXanhSm ? '🚕' : '💳',
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showGeminiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔑 Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập Gemini API key để phân tích tài chính AI chuyên sâu. Key được lưu an toàn trên thiết bị, không gửi lên server.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIza...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await SecurityService.instance.saveGeminiApiKey(key);
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('✅ Đã lưu API Key')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet});
  final wallet;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(wallet.emoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(wallet.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: wallet.isXanhSm
          ? Text(
              '🏷️ Phí nền tảng: ${wallet.feeRatePercent} · ${wallet.moneyTypes.join(", ")}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          : Text(
              wallet.moneyTypes.join(', '),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // TODO: Navigate to wallet detail/edit
      },
    );
  }
}

class _BiometricsSwitch extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BiometricsSwitch> createState() => _BiometricsSwitchState();
}

class _BiometricsSwitchState extends ConsumerState<_BiometricsSwitch> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    SecurityService.instance.isBiometricsEnabled().then(
          (v) => setState(() => _enabled = v),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      activeColor: AppTheme.primaryGreen,
      onChanged: (v) async {
        final available =
            await SecurityService.instance.isBiometricAvailable();
        if (!available && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Thiết bị không hỗ trợ sinh trắc học')),
          );
          return;
        }
        await SecurityService.instance.setBiometricsEnabled(v);
        setState(() => _enabled = v);
      },
    );
  }
}
