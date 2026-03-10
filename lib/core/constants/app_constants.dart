// lib/core/constants/app_constants.dart
// Hằng số toàn ứng dụng Thanh Taxi Xanh SM

/// Màu sắc chính - Xanh SM brand
class AppColors {
  AppColors._();

  static const int primaryGreen = 0xFF00C853;    // Xanh lá Xanh SM
  static const int accentYellow = 0xFFFFD600;    // Vàng accent
  static const int negativeRed = 0xFFFF5252;     // Đỏ chi tiêu
  static const int positiveGreen = 0xFF00C853;   // Xanh thu nhập
  static const int neutralGrey = 0xFF9E9E9E;     // Xám trung tính
  static const int backgroundLight = 0xFFF5F5F5;
  static const int backgroundDark = 0xFF121212;
  static const int cardLight = 0xFFFFFFFF;
  static const int cardDark = 0xFF1E1E1E;
  static const int surfaceDark = 0xFF2C2C2C;
}

/// Cấu hình phí nền tảng
class FeeConfig {
  FeeConfig._();

  /// Phí mặc định Xanh SM 2026 (18%)
  static const double defaultXanhSmFeeRate = 0.18;

  /// Giới hạn phí tối đa
  static const double maxFeeRate = 0.50;

  /// Giới hạn phí tối thiểu
  static const double minFeeRate = 0.01;
}

/// Giới hạn ứng dụng
class AppLimits {
  AppLimits._();

  static const int maxWallets = 10;
  static const int maxCategories = 50;
  static const int pinMinLength = 4;
  static const int pinMaxLength = 6;
  static const int maxNoteLength = 500;
}

/// Tên ví mặc định khi cài đặt lần đầu
class DefaultWallets {
  DefaultWallets._();

  static const String xanhSm = 'Xanh SM';
  static const String huongGiang = 'APP Hương Giang';
  static const String other = 'Khác';

  // Loại tiền mặc định
  static const List<String> xanhSmMoneyTypes = ['Tiền Mặt', 'Thẻ/Ví'];
  static const List<String> huongGiangMoneyTypes = ['Tiền Mặt', 'Chuyển Khoản'];
  static const List<String> otherMoneyTypes = ['Tiền Mặt'];
}

/// Danh mục mặc định
class DefaultCategories {
  DefaultCategories._();

  // Thu nhập
  static const List<Map<String, String>> incomeCategories = [
    {'name': 'Tiền cuốc', 'emoji': '🚕'},
    {'name': 'Thưởng', 'emoji': '🏆'},
    {'name': 'Khác', 'emoji': '💰'},
  ];

  // Chi tiêu
  static const List<Map<String, String>> expenseCategories = [
    {'name': 'Xăng xe', 'emoji': '⛽'},
    {'name': 'Ăn uống', 'emoji': '🍜'},
    {'name': 'Sửa xe', 'emoji': '🔧'},
    {'name': 'Phí app', 'emoji': '📱'},
    {'name': 'Khác', 'emoji': '💸'},
  ];
}

/// Key cho flutter_secure_storage
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String pinHash = 'pin_hash';
  static const String biometricsEnabled = 'biometrics_enabled';
  static const String geminiApiKey = 'gemini_api_key';
  static const String backupEncryptKey = 'backup_encrypt_key';
  static const String onboardingDone = 'onboarding_done';
}

/// Tên route
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String lock = '/lock';
  static const String home = '/home';
  static const String addTransaction = '/add-transaction';
  static const String transactionDetail = '/transaction-detail';
  static const String wallet = '/wallet';
  static const String walletDetail = '/wallet-detail';
  static const String stats = '/stats';
  static const String insights = '/insights';
  static const String settings = '/settings';
  static const String categories = '/categories';
  static const String feeCalculator = '/fee-calculator';
  static const String backup = '/backup';
  static const String pinSetup = '/pin-setup';
}

/// Thứ trong tuần tiếng Việt
const List<String> vietnameseDayNames = [
  '', // index 0 không dùng
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

/// Cấu hình thống kê
enum StatsPeriod {
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

extension StatsPeriodLabel on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.thisWeek: return 'Tuần này';
      case StatsPeriod.lastWeek: return 'Tuần trước';
      case StatsPeriod.thisMonth: return 'Tháng này';
      case StatsPeriod.lastMonth: return 'Tháng trước';
      case StatsPeriod.thisYear: return 'Năm nay';
      case StatsPeriod.custom: return 'Tùy chọn';
    }
  }
}
