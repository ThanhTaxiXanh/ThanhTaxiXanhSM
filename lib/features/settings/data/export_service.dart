// lib/features/settings/data/export_service.dart
// Dịch vụ xuất dữ liệu: CSV, Excel, JSON
// Chia sẻ qua share_plus (bất kỳ app nào: Gmail, Zalo, Drive, v.v.)

import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../transaction/domain/transaction_entity.dart';
import '../../../core/utils/formatters.dart';

class ExportService {
  ExportService._();
  static ExportService get instance => ExportService._();

  final _dateHeader = DateFormat('dd/MM/yyyy');

  // === HEADERS ===
  static const List<String> _headers = [
    'Ngày',
    'Giờ',
    'Loại',
    'Ví',
    'Loại tiền',
    'Danh mục',
    'Số tiền (đ)',
    'Số cuốc',
    'Ghi chú',
  ];

  List<List<dynamic>> _buildRows(List<TransactionEntity> transactions) {
    return transactions.map((t) {
      return [
        DateFormatter.formatDate(t.date),
        DateFormatter.formatTime(t.date),
        t.isIncome ? 'Thu nhập' : 'Chi tiêu',
        '${t.walletEmoji} ${t.walletName}',
        t.moneyType,
        t.categoryDisplay,
        t.amount.toStringAsFixed(0),
        t.tripCount.toString(),
        t.note,
      ];
    }).toList();
  }

  /// Xuất CSV và chia sẻ
  Future<void> exportCsv(
    List<TransactionEntity> transactions, {
    String? filename,
  }) async {
    final rows = [_headers, ..._buildRows(transactions)];
    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final name = filename ??
        'thanh_taxi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$name');
    // Thêm BOM UTF-8 để Excel VN đọc đúng tiếng Việt
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📊 Dữ liệu thu chi từ Thanh Taxi Xanh SM',
      subject: 'Xuất dữ liệu thu chi',
    );
  }

  /// Xuất Excel (.xlsx) và chia sẻ
  Future<void> exportExcel(
    List<TransactionEntity> transactions, {
    String? filename,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Thu Chi'];
    excel.setDefaultSheet('Thu Chi');

    // Header row (in đậm)
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#00C853'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    for (int i = 0; i < _headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(_headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    final rows = _buildRows(transactions);
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
        );
        final value = rows[r][c];
        // Cột số tiền là số
        if (c == 6) {
          cell.value = DoubleCellValue(double.tryParse(value.toString()) ?? 0);
        } else {
          cell.value = TextCellValue(value.toString());
        }
      }
    }

    // Auto-width (gần đúng)
    for (int i = 0; i < _headers.length; i++) {
      sheet.setColumnWidth(i, 18.0);
    }

    final dir = await getTemporaryDirectory();
    final name = filename ??
        'thanh_taxi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$name');
    final bytes = excel.encode()!;
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📊 Dữ liệu thu chi từ Thanh Taxi Xanh SM (Excel)',
      subject: 'Xuất dữ liệu thu chi',
    );
  }

  /// Xuất JSON và chia sẻ (dùng để backup thủ công)
  Future<void> exportJson(
    List<TransactionEntity> transactions, {
    String? filename,
  }) async {
    final data = {
      'app': 'Thanh Taxi Xanh SM',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': transactions.length,
      'transactions': transactions
          .map((t) => {
                'id': t.id,
                'wallet': t.walletName,
                'type': t.type,
                'amount': t.amount,
                'money_type': t.moneyType,
                'category': t.categoryName,
                'note': t.note,
                'date': t.date.toIso8601String(),
                'trip_count': t.tripCount,
              })
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final name = filename ??
        'thanh_taxi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(jsonStr, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📦 Dữ liệu JSON từ Thanh Taxi Xanh SM',
      subject: 'Xuất dữ liệu JSON',
    );
  }
}
