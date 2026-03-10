// lib/features/settings/presentation/screens/onboarding_screen.dart
// Màn hình Onboarding lần đầu: giới thiệu, tùy chọn thiết lập PIN

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/security_service.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final _pages = const [
    _OnboardingPage(
      emoji: '🚕',
      title: 'Chào Mừng!\nThanh Taxi Xanh SM',
      subtitle:
          'Ứng dụng quản lý thu chi miễn phí dành riêng cho tài xế công nghệ Việt Nam.',
      features: [
        '✅ Hoàn toàn miễn phí, không quảng cáo',
        '🔒 Offline-first, không lưu lên server',
        '⚡ Thêm giao dịch dưới 10 giây',
      ],
    ),
    _OnboardingPage(
      emoji: '💳',
      title: 'Quản Lý Ví\nDễ Dàng',
      subtitle:
          'Đã tạo sẵn 3 ví cho bạn: Xanh SM, APP Hương Giang và Khác. Bạn có thể thêm tối đa 10 ví.',
      features: [
        '🚕 Ví Xanh SM: tính phí nền tảng tự động',
        '📱 Hỗ trợ nhiều loại tiền: Tiền Mặt, Thẻ/Ví',
        '➕ Thêm ví Grab, Be hoặc bất kỳ nguồn nào',
      ],
    ),
    _OnboardingPage(
      emoji: '💸',
      title: 'Tính Phí\nXanh SM Tự Động',
      subtitle:
          'Chọn khoảng thời gian, ứng dụng sẽ tính phí nền tảng (mặc định 18%) và trừ tự động từ ví.',
      features: [
        '📊 Phí mặc định 18% theo chính sách 2026',
        '🎛️ Có thể tùy chỉnh tỷ lệ phí từng ví',
        '💡 Ưu tiên trừ Thẻ/Ví trước, rồi Tiền Mặt',
      ],
    ),
  ];

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    await SecurityService.instance.setOnboardingDone();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Bỏ qua', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppTheme.primaryGreen
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finish();
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentPage < _pages.length - 1
                              ? 'Tiếp Theo →'
                              : '🚀 Bắt Đầu Ngay!',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(f, style: const TextStyle(fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
