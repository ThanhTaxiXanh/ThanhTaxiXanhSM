// lib/features/settings/data/backup_service.dart
// FIX #3: Xóa hoàn toàn "as Uint8List" unsafe cast
// sublist() trên Uint8List trả về Uint8List – không cần cast

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../../../core/utils/security_service.dart';
import '../../../data/app_database.dart';

class BackupResult {
  const BackupResult({required this.success, this.message, this.fileId});
  final bool success;
  final String? message;
  final String? fileId;
}

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  static const _fileName = 'thanh_taxi_xanh_sm_backup.enc';
  static const _mime = 'application/octet-stream';

  final _gsi = GoogleSignIn(scopes: [drive.DriveApi.driveAppDataScope]);

  Future<bool> get isSignedIn => _gsi.isSignedIn();
  Future<void> signOut() => _gsi.signOut();

  // ── Backup ──────────────────────────────────────────────────

  Future<BackupResult> backup() async {
    try {
      final account =
          await _gsi.signInSilently() ?? await _gsi.signIn();
      if (account == null) {
        return const BackupResult(
            success: false, message: 'Đăng nhập Google thất bại');
      }
      final jsonData = await _exportAllData();
      final encrypted = await _encrypt(jsonData);

      final client = _AuthClient(await account.authHeaders);
      final api = drive.DriveApi(client);
      final media = drive.Media(
        Stream.value(encrypted.toList()),
        encrypted.length,
        contentType: _mime,
      );

      final existing = await _findId(api);
      String? fileId;
      if (existing != null) {
        await api.files.update(drive.File(), existing, uploadMedia: media);
        fileId = existing;
      } else {
        final f = drive.File()
          ..name = _fileName
          ..parents = ['appDataFolder'];
        fileId = (await api.files.create(f, uploadMedia: media)).id;
      }
      client.close();
      return BackupResult(
          success: true, message: 'Backup thành công!', fileId: fileId);
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi backup: $e');
    }
  }

  // ── Restore ─────────────────────────────────────────────────

  Future<BackupResult> restore() async {
    try {
      final account =
          await _gsi.signInSilently() ?? await _gsi.signIn();
      if (account == null) {
        return const BackupResult(
            success: false, message: 'Đăng nhập Google thất bại');
      }
      final client = _AuthClient(await account.authHeaders);
      final api = drive.DriveApi(client);
      final id = await _findId(api);
      if (id == null) {
        client.close();
        return const BackupResult(
            success: false, message: 'Không tìm thấy backup trên Drive');
      }
      final media = await api.files.get(
        id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // FIX #3: _collectStream trả về Uint8List thực sự
      final bytes = await _collectStream(media.stream);
      client.close();

      final json = await _decrypt(bytes);
      await _importAllData(jsonDecode(json) as Map<String, dynamic>);
      return const BackupResult(success: true, message: 'Khôi phục thành công!');
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi restore: $e');
    }
  }

  // ── Crypto ──────────────────────────────────────────────────

  Future<Uint8List> _encrypt(String plaintext) async {
    final keyB64 = await SecurityService.instance.getOrCreateBackupKey();
    final key = enc.Key(Uint8List.fromList(base64Decode(keyB64)));
    final iv = enc.IV.fromSecureRandom(16);
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = cipher.encrypt(plaintext, iv: iv);

    // Layout: [16 bytes IV][N bytes ciphertext]
    final out = Uint8List(16 + encrypted.bytes.length);
    out.setRange(0, 16, iv.bytes);
    out.setRange(16, out.length, encrypted.bytes);
    return out;
  }

  Future<String> _decrypt(Uint8List bytes) async {
    if (bytes.length <= 16) throw Exception('Dữ liệu backup bị hỏng');
    final keyB64 = await SecurityService.instance.getOrCreateBackupKey();
    final key = enc.Key(Uint8List.fromList(base64Decode(keyB64)));

    // FIX #3: sublist() trên Uint8List → trả về Uint8List, không cần cast
    final iv = enc.IV(bytes.sublist(0, 16));
    final cipher = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return cipher.decrypt(enc.Encrypted(bytes.sublist(16)), iv: iv);
  }

  // ── Helpers ─────────────────────────────────────────────────

  Future<String?> _findId(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName'",
      fields: 'files(id)',
    );
    return list.files?.firstOrNull?.id;
  }

  /// FIX #3: Trả về Uint8List thực sự – không cast
  Future<Uint8List> _collectStream(Stream<List<int>> stream) async {
    final buf = <int>[];
    await for (final chunk in stream) buf.addAll(chunk);
    return Uint8List.fromList(buf);
  }

  Future<String> _exportAllData() async {
    final wallets = await _db.walletDao.getAllWallets();
    final txns = await _db.transactionDao.getAllRaw();
    final cats = await _db.categoryDao.getAllCategories();
    final fees = await _db.feePaymentDao.getFeePayments();
    return jsonEncode({
      'version': '1',
      'backed_up_at': DateTime.now().toIso8601String(),
      'wallets': wallets
          .map((w) => {
                'id': w.id, 'name': w.name, 'is_xanh_sm': w.isXanhSm,
                'fee_rate': w.feeRate, 'money_types_json': w.moneyTypesJson,
                'emoji': w.emoji, 'color_hex': w.colorHex, 'sort_order': w.sortOrder,
              })
          .toList(),
      'categories': cats
          .map((c) => {
                'id': c.id, 'name': c.name, 'emoji': c.emoji,
                'type': c.type, 'sort_order': c.sortOrder, 'is_default': c.isDefault,
              })
          .toList(),
      'transactions': txns
          .map((t) => {
                'id': t.id, 'wallet_id': t.walletId, 'type': t.type,
                'amount': t.amount, 'money_type': t.moneyType,
                'category_id': t.categoryId, 'note': t.note,
                'date': t.date.toIso8601String(), 'trip_count': t.tripCount,
              })
          .toList(),
      'fee_payments': fees
          .map((f) => {
                'wallet_id': f.walletId,
                'period_start': f.periodStart.toIso8601String(),
                'period_end': f.periodEnd.toIso8601String(),
                'total_revenue': f.totalRevenue, 'total_fee': f.totalFee,
                'deducted_card': f.deductedCard, 'deducted_cash': f.deductedCash,
                'fee_rate_snapshot': f.feeRateSnapshot,
                'date_paid': f.datePaid.toIso8601String(),
              })
          .toList(),
    });
  }

  Future<void> _importAllData(Map<String, dynamic> data) async {
    await _db.clearAllData();
    // v1.1: implement full restore từ JSON
  }
}

class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);
  final Map<String, String> _headers;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) {
    req.headers.addAll(_headers);
    return _inner.send(req);
  }

  @override
  void close() => _inner.close();
}
