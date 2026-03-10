// test/widget/add_transaction_sheet_test.dart
// Widget test cho màn hình thêm giao dịch

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:thanh_taxi_xanh_sm/data/app_database.dart';
import 'package:thanh_taxi_xanh_sm/core/theme/app_theme.dart';
import 'package:thanh_taxi_xanh_sm/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:thanh_taxi_xanh_sm/features/transaction/presentation/screens/add_transaction_sheet.dart';

/// Tạo database in-memory cho test
AppDatabase _makeTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _makeTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  Widget _buildTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('AddTransactionSheet hiển thị đúng các thành phần', (tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => AddTransactionSheet.show(ctx),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    // Mở sheet
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Kiểm tra toggle Thu/Chi
    expect(find.text('📈 Thu Nhập'), findsOneWidget);
    expect(find.text('📉 Chi Tiêu'), findsOneWidget);

    // Kiểm tra hiển thị 0đ ban đầu
    expect(find.text('0đ'), findsOneWidget);

    // Kiểm tra bàn phím số
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('⌫'), findsOneWidget);
  });

  testWidgets('Nhập số tiền hiển thị đúng định dạng VND', (tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => AddTransactionSheet.show(ctx),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Nhấn số
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('000'));
    await tester.pump();

    // 32000đ phải hiển thị
    expect(find.text('32.000đ'), findsOneWidget);
  });

  testWidgets('Toggle Thu/Chi đổi màu nút đúng', (tester) async {
    await tester.pumpWidget(
      _buildTestWidget(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => AddTransactionSheet.show(ctx),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Mặc định là Thu Nhập
    expect(find.text('✅ Lưu Thu Nhập'), findsOneWidget);

    // Chuyển sang Chi Tiêu
    await tester.tap(find.text('📉 Chi Tiêu'));
    await tester.pump();

    expect(find.text('✅ Lưu Chi Tiêu'), findsOneWidget);
  });
}
