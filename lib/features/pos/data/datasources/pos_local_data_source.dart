import 'dart:convert';

import 'package:drift/drift.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../core/database/app_database.dart';

/// Local data source backed by Drift (SQLite).
///
/// All reads/writes go through the offline cache. The repository layer
/// decides when to refresh from Supabase and when to serve from cache.
class PosLocalDataSource {
  final AppDatabase _db;

  PosLocalDataSource(this._db);

  // ── Categories ─────────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories() async {
    final rows = await _db.getCategories();
    return rows
        .map((r) => CategoryModel(
              id: r.id,
              name: r.name,
              slug: r.slug,
              isKitchen: r.isKitchen,
              isActive: r.isActive,
            ))
        .toList();
  }

  Future<void> upsertCategories(List<CategoryModel> categories) async {
    final companions = categories
        .map((c) => CategoriesCompanion.insert(
              id: c.id,
              name: c.name,
              slug: c.slug,
              isKitchen: Value(c.isKitchen),
              isActive: Value(c.isActive),
            ))
        .toList();
    await _db.upsertCategories(companions);
  }

  // ── Products ───────────────────────────────────────────────────────
  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    final rows = await _db.getProducts(categoryId: categoryId);
    return rows
        .map((r) => ProductModel(
              id: r.id,
              categoryId: r.categoryId ?? '',
              name: r.name,
              slug: r.slug,
              description: r.description,
              imageUrl: r.imageUrl,
              basePrice: r.basePrice,
              isActive: r.isActive,
            ))
        .toList();
  }

  Future<void> upsertProducts(List<ProductModel> products) async {
    final companions = products
        .map((p) => ProductsCompanion.insert(
              id: p.id,
              categoryId: Value(p.categoryId),
              name: p.name,
              slug: p.slug,
              description: Value(p.description),
              imageUrl: Value(p.imageUrl),
              basePrice: Value(p.basePrice),
              isActive: Value(p.isActive),
            ))
        .toList();
    await _db.upsertProducts(companions);
  }

  // ── Order Drafts ───────────────────────────────────────────────────
  Future<void> saveOrderDraft({
    required String id,
    required String outletId,
    String? tableId,
    required String orderNumber,
    required String orderType,
    required double subtotal,
    required double total,
    String? notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'cash',
  }) async {
    await _db.insertOrderDraft(OrderDraftsCompanion.insert(
      id: id,
      outletId: outletId,
      tableId: Value(tableId),
      orderNumber: orderNumber,
      orderType: Value(orderType),
      subtotal: Value(subtotal),
      total: Value(total),
      notes: Value(notes),
      itemsJson: jsonEncode(items),
      paymentMethod: Value(paymentMethod),
    ));
  }

  Future<List<OrderDraft>> getOrderDrafts() => _db.getOrderDrafts();

  Future<void> deleteOrderDraft(String id) => _db.deleteOrderDraft(id);
}
