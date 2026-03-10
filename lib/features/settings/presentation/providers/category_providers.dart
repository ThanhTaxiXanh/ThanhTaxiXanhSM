// lib/features/settings/presentation/providers/category_providers.dart
// Riverpod providers cho Categories

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/app_database.dart';
import '../../../../data/schema/tables.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';

// === CATEGORY REPOSITORY ===
final categoryRepositoryProvider = Provider((ref) {
  return ref.watch(databaseProvider).categoryDao;
});

// === STREAMS ===
final allCategoriesProvider = StreamProvider<List<CategoryData>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAllCategories();
});

final categoriesByTypeProvider =
    StreamProvider.family<List<CategoryData>, String>((ref, type) {
  return ref.watch(categoryRepositoryProvider).watchCategoriesByType(type);
});

// === MUTATIONS ===
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  CategoryNotifier(this._db) : super(const AsyncValue.data(null));

  final AppDatabase _db;

  Future<void> addCategory({
    required String name,
    required String emoji,
    required String type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existing = await _db.categoryDao.getCategoriesByType(type);
      await _db.categoryDao.insertCategory(CategoriesCompanion.insert(
        name: name,
        emoji: Value(emoji),
        type: type,
        sortOrder: Value(existing.length),
      ));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      await _db.categoryDao.deleteCategory(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoryMutationProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref.watch(databaseProvider));
});
