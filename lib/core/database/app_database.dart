import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Main offline-first SQLite database for PostSA POS.
///
/// Uses Drift for type-safe queries and automatic schema migrations.
/// The generated companion file is `app_database.g.dart` (produced by
/// `dart run build_runner build`).
@DriftDatabase(tables: [
  Categories,
  Products,
  ProductVariants,
  RestaurantTables,
  OrderDrafts,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests — allows injecting an in-memory database.
  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'postsa_pos');
  }

  @override
  int get schemaVersion => 1;

  // ── Categories ─────────────────────────────────────────────────────
  /// Returns all active categories sorted by `sort_order`.
  Future<List<Category>> getCategories() =>
      (select(categories)..where((t) => t.isActive.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  /// Bulk upserts categories from Supabase (replaces all rows).
  Future<void> upsertCategories(List<CategoriesCompanion> rows) async {
    await batch((b) {
      b.deleteWhere(categories, (t) => const Constant(true));
      b.insertAll(categories, rows);
    });
  }

  // ── Products ───────────────────────────────────────────────────────
  /// Returns all active products, optionally filtered by category.
  Future<List<Product>> getProducts({String? categoryId}) {
    final query = select(products)..where((t) => t.isActive.equals(true));
    if (categoryId != null && categoryId.isNotEmpty) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    return query.get();
  }

  /// Bulk upserts products from Supabase (replaces all rows).
  Future<void> upsertProducts(List<ProductsCompanion> rows) async {
    await batch((b) {
      b.deleteWhere(products, (t) => const Constant(true));
      b.insertAll(products, rows);
    });
  }

  // ── Product Variants ───────────────────────────────────────────────
  /// Returns all variants for a given product.
  Future<List<ProductVariant>> getVariants(String productId) =>
      (select(productVariants)..where((t) => t.productId.equals(productId)))
          .get();

  Future<void> upsertVariants(List<ProductVariantsCompanion> rows) async {
    await batch((b) {
      b.insertAll(productVariants, rows, mode: InsertMode.insertOrReplace);
    });
  }

  // ── Tables (Floor Plan) ────────────────────────────────────────────
  Future<List<RestaurantTable>> getTables(String outletId) =>
      (select(restaurantTables)..where((t) => t.outletId.equals(outletId)))
          .get();

  Future<void> upsertTables(List<RestaurantTablesCompanion> rows) async {
    await batch((b) {
      b.insertAll(restaurantTables, rows, mode: InsertMode.insertOrReplace);
    });
  }

  // ── Order Drafts ───────────────────────────────────────────────────
  /// Returns all draft orders (not yet synced), oldest first.
  Future<List<OrderDraft>> getOrderDrafts() =>
      (select(orderDrafts)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Inserts a new draft order.
  Future<void> insertOrderDraft(OrderDraftsCompanion row) =>
      into(orderDrafts).insert(row);

  /// Deletes a draft order after successful sync.
  Future<void> deleteOrderDraft(String id) =>
      (delete(orderDrafts)..where((t) => t.id.equals(id))).go();

  // ── Sync Queue ─────────────────────────────────────────────────────
  /// Returns all pending sync operations, oldest first.
  Future<List<SyncQueueData>> getPendingSyncOperations() =>
      (select(syncQueue)
            ..where((t) => t.nextRetryAt.isNull() |
                t.nextRetryAt.isSmallerOrEqualValue(DateTime.now()))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Enqueues a new sync operation.
  Future<void> enqueueSync(SyncQueueCompanion row) =>
      into(syncQueue).insert(row);

  /// Marks a sync operation as failed with error + retry metadata.
  Future<void> markSyncFailed({
    required String id,
    required String error,
    required DateTime nextRetryAt,
  }) async {
    // Read current retry count, increment in Dart, then write.
    final current = await (select(syncQueue)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    final newRetryCount = (current?.retryCount ?? 0) + 1;
    await (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(newRetryCount),
        lastError: Value(error),
        nextRetryAt: Value(nextRetryAt),
      ),
    );
  }

  /// Removes a sync operation after successful completion.
  Future<void> dequeueSync(String id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  /// Returns the count of pending sync operations.
  Future<int> getPendingSyncCount() async {
    final count = countAll();
    final query = selectOnly(syncQueue)
      ..addColumns([count])
      ..where(syncQueue.nextRetryAt.isNull() |
          syncQueue.nextRetryAt.isSmallerOrEqualValue(DateTime.now()));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
