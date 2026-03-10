// lib/data/schema/tables.dart
// FIX #11: Thêm index isDeleted để tăng tốc filtered queries

import 'package:drift/drift.dart';

@DataClassName('WalletData')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get isXanhSm => boolean().withDefault(const Constant(false))();
  RealColumn get feeRate => real().withDefault(const Constant(0.18))();
  TextColumn get moneyTypesJson =>
      text().withDefault(const Constant('["Tiền Mặt"]'))();
  TextColumn get emoji => text().withDefault(const Constant('💳'))();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#00C853')).nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CategoryData')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get emoji => text().withDefault(const Constant('📌'))();
  TextColumn get type => text()(); // 'income' | 'expense'
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()(); // UUID – PK
  IntColumn get walletId => integer().references(Wallets, #id)();
  TextColumn get type => text()(); // 'income' | 'expense'
  RealColumn get amount => real()();
  TextColumn get moneyType => text()();
  IntColumn get categoryId =>
      integer().references(Categories, #id).nullable()();
  TextColumn get note =>
      text().withDefault(const Constant('')).withLength(max: 500)();
  DateTimeColumn get date => dateTime()();
  IntColumn get tripCount => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FeePaymentData')
class FeePayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  RealColumn get totalRevenue => real()();
  RealColumn get totalFee => real()();
  RealColumn get deductedCard => real().withDefault(const Constant(0))();
  RealColumn get deductedCash => real().withDefault(const Constant(0))();
  RealColumn get feeRateSnapshot => real()();
  DateTimeColumn get datePaid =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('AppSettingData')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
