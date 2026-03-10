// lib/main.dart
// Entry point chính - khởi tạo app, kiểm tra onboarding/PIN, setup navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/security_service.dart';
import 'features/transaction/presentation/screens/home_screen.dart';
import 'features/transaction/presentation/screens/history_screen.dart';
import 'features/transaction/presentation/screens/add_transaction_sheet.dart';
import 'features/stats/presentation/screens/stats_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/screens/onboarding_screen.dart';

/// Notification plugin (khởi tạo một lần)
final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cố định portrait orientation cho trải nghiệm nhất quán
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo notifications
  await _initNotifications();

  // Kiểm tra onboarding/PIN
  final onboardingDone = await SecurityService.instance.isOnboardingDone();
  final hasPin = await SecurityService.instance.hasPinSet();

  runApp(
    ProviderScope(
      child: ThanhTaxiXanhSmApp(
        showOnboarding: !onboardingDone,
        requirePin: hasPin,
      ),
    ),
  );
}

Future<void> _initNotifications() async {
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await notificationsPlugin.initialize(
    const InitializationSettings(
        android: androidSettings, iOS: iosSettings),
  );
}

class ThanhTaxiXanhSmApp extends StatelessWidget {
  const ThanhTaxiXanhSmApp({
    super.key,
    required this.showOnboarding,
    required this.requirePin,
  });

  final bool showOnboarding;
  final bool requirePin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thanh Taxi Xanh SM',
      debugShowCheckedModeBanner: false,

      // Light/Dark theme theo system
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Route đầu tiên
      initialRoute: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,

      // Named routes
      routes: {
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.pinSetup: (_) => const _PinSetupScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.feeCalculator: (_) => const _FeeCalculatorScreen(),
      },

      // Locale VN cho DatePicker
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
    );
  }
}

/// Shell chính với BottomNavigationBar 5 tabs
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    SizedBox.shrink(), // FAB placeholder
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex, // FAB không có màn hình riêng
        children: [
          const HomeScreen(),
          const HistoryScreen(),
          const SizedBox.shrink(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),

      // === BOTTOM NAVIGATION BAR ===
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // FAB: mở bottom sheet thêm giao dịch
            AddTransactionSheet.show(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 22)),
            activeIcon: Text('🏠', style: TextStyle(fontSize: 26)),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Text('📅', style: TextStyle(fontSize: 22)),
            activeIcon: Text('📅', style: TextStyle(fontSize: 26)),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 24,
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Text('📊', style: TextStyle(fontSize: 22)),
            activeIcon: Text('📊', style: TextStyle(fontSize: 26)),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Text('💳', style: TextStyle(fontSize: 22)),
            activeIcon: Text('💳', style: TextStyle(fontSize: 26)),
            label: 'Ví & CĐ',
          ),
        ],
      ),
    );
  }
}

// === PLACEHOLDER: PIN SETUP SCREEN ===
class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen();

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  Future<void> _save() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'PIN phải từ 4-6 chữ số');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PIN xác nhận không khớp');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'PIN chỉ được dùng chữ số (0-9)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    await SecurityService.instance.savePin(pin);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã thiết lập PIN thành công!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔢 Thiết Lập PIN'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '🔐 Tạo mã PIN để bảo vệ\nứng dụng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Nhập PIN (4-6 số)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Xác nhận PIN',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.negativeRed, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('✅ Lưu PIN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Bỏ qua (không thiết lập PIN)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === PLACEHOLDER: FEE CALCULATOR SCREEN ===
class _FeeCalculatorScreen extends ConsumerWidget {
  const _FeeCalculatorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💸 Tính Phí Xanh SM'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💸', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                'Tính Phí Nền Tảng',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Tính năng đang được hoàn thiện.\nSẽ sớm ra mắt trong phiên bản tiếp theo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
