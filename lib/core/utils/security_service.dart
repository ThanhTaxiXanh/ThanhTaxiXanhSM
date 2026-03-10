// lib/core/utils/security_service.dart
// Dịch vụ bảo mật: PIN (bcrypt-like hash) + Biometrics (local_auth)
// Lưu trữ an toàn với flutter_secure_storage (Android Keystore / iOS Keychain)

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';

/// Kết quả xác thực PIN
enum PinVerifyResult { success, wrongPin, notSet }

/// Kết quả xác thực biometrics
enum BiometricResult { success, failed, notAvailable, notEnrolled, cancelled }

class SecurityService {
  SecurityService._();
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final _localAuth = LocalAuthentication();

  // === PIN ===

  /// Hash PIN với salt (PBKDF2-style với SHA-256)
  String _hashPin(String pin, String salt) {
    // Lặp 10000 vòng để chống brute-force
    var data = utf8.encode('$salt$pin');
    for (int i = 0; i < 10000; i++) {
      data = sha256.convert(data).bytes;
    }
    return base64Encode(data);
  }

  /// Tạo salt ngẫu nhiên
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Lưu PIN mới (đã hash)
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(
      key: SecureStorageKeys.pinHash,
      value: '$salt:$hash',
    );
  }

  /// Xác minh PIN
  Future<PinVerifyResult> verifyPin(String pin) async {
    final stored = await _storage.read(key: SecureStorageKeys.pinHash);
    if (stored == null) return PinVerifyResult.notSet;

    final parts = stored.split(':');
    if (parts.length != 2) return PinVerifyResult.notSet;

    final salt = parts[0];
    final storedHash = parts[1];
    final inputHash = _hashPin(pin, salt);

    return inputHash == storedHash
        ? PinVerifyResult.success
        : PinVerifyResult.wrongPin;
  }

  /// Kiểm tra đã thiết lập PIN chưa
  Future<bool> hasPinSet() async {
    final stored = await _storage.read(key: SecureStorageKeys.pinHash);
    return stored != null && stored.isNotEmpty;
  }

  /// Xóa PIN
  Future<void> removePin() async {
    await _storage.delete(key: SecureStorageKeys.pinHash);
  }

  // === BIOMETRICS ===

  /// Kiểm tra thiết bị có hỗ trợ biometrics không
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Lấy danh sách biometrics được hỗ trợ
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Xác thực biometrics
  Future<BiometricResult> authenticateWithBiometrics({
    String reason = 'Xác thực để mở ứng dụng Thanh Taxi Xanh SM',
  }) async {
    final isAvailable = await isBiometricAvailable();
    if (!isAvailable) return BiometricResult.notAvailable;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // cho phép fallback PIN thiết bị
        ),
      );
      return authenticated
          ? BiometricResult.success
          : BiometricResult.cancelled;
    } catch (e) {
      return BiometricResult.failed;
    }
  }

  /// Bật/tắt biometrics
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: SecureStorageKeys.biometricsEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricsEnabled() async {
    final value =
        await _storage.read(key: SecureStorageKeys.biometricsEnabled);
    return value == 'true';
  }

  // === GEMINI API KEY ===

  Future<void> saveGeminiApiKey(String key) async {
    await _storage.write(key: SecureStorageKeys.geminiApiKey, value: key);
  }

  Future<String?> getGeminiApiKey() async {
    return _storage.read(key: SecureStorageKeys.geminiApiKey);
  }

  Future<void> removeGeminiApiKey() async {
    await _storage.delete(key: SecureStorageKeys.geminiApiKey);
  }

  // === BACKUP KEY ===

  /// Tạo hoặc lấy key mã hóa backup (AES-256)
  Future<String> getOrCreateBackupKey() async {
    var key = await _storage.read(key: SecureStorageKeys.backupEncryptKey);
    if (key == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(
          key: SecureStorageKeys.backupEncryptKey, value: key);
    }
    return key;
  }

  // === ONBOARDING ===

  Future<bool> isOnboardingDone() async {
    final value =
        await _storage.read(key: SecureStorageKeys.onboardingDone);
    return value == 'true';
  }

  Future<void> setOnboardingDone() async {
    await _storage.write(
        key: SecureStorageKeys.onboardingDone, value: 'true');
  }
}
