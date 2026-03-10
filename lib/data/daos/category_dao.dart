// lib/data/daos/category_dao.dart
// DAO cho bảng Categories

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../schema/tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Stream tất cả danh mục active
  Stream<List<CategoryData>> watchAllCategories() {
    return (select(categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Stream danh mục theo loại (income/expense)
  Stream<List<CategoryData>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type) & c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// Lấy danh mục theo loại (one-time)
  Future<List<CategoryData>> getCategoriesByType(String type) {
    return (select(categories)
          ..where((c) => c.type.equals(type) & c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Lấy tất cả danh mục
  Future<List<CategoryData>> getAllCategories() {
    return (select(categories)
          ..where((c) => c.isDeleted.equals(false))
          ..orderBy([(c) => OrderingTerm.asc(c.type), (c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// Lấy danh mục theo ID
  Future<CategoryData?> getCategoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Thêm danh mục
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Cập nhật danh mục
  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  /// Xóa mềm danh mục
  Future<void> deleteCategory(int id) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(isDeleted: Value(true)),
    );
  }
}
