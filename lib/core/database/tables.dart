import 'package:drift/drift.dart';

/// Local cache of `categories` table from Supabase.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  BoolColumn get isKitchen => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cache of `products` table from Supabase.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get basePrice => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cache of `product_variants` table.
class ProductVariants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  RealColumn get priceAdjustment => real().withDefault(const Constant(0.0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cache of `tables` (dine-in floor plan).
class RestaurantTables extends Table {
  TextColumn get id => text()();
  TextColumn get outletId => text()();
  TextColumn get name => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  RealColumn get positionX => real().withDefault(const Constant(0.0))();
  RealColumn get positionY => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('available'))();
  TextColumn get currentOrderId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Draft orders created offline — synced to Supabase `orders` when online.
class OrderDrafts extends Table {
  TextColumn get id => text()(); // local UUID
  TextColumn get outletId => text()();
  TextColumn get tableId => text().nullable()();
  TextColumn get orderNumber => text()();
  TextColumn get orderType => text().withDefault(const Constant('dine_in'))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  TextColumn get itemsJson => text()(); // JSON-encoded list of cart items
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Queue of operations pending sync to Supabase.
///
/// Each row represents one API call that needs to be replayed when
/// connectivity is restored. Processed in FIFO order by [createdAt].
class SyncQueue extends Table {
  TextColumn get id => text()(); // local UUID
  TextColumn get operation => text()(); // insert_order, update_status, etc.
  TextColumn get table_ => text()(); // target Supabase table
  TextColumn get payloadJson => text()(); // JSON-encoded request body
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
