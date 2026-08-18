import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/sync_queue_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/product_model.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_local_data_source.dart';
import '../datasources/pos_remote_data_source.dart';
import '../seed_data.dart';

/// Concrete implementation of [PosRepository] with **cache-first** strategy.
///
/// Read operations:
/// 1. Try local Drift cache first → return immediately if data exists.
/// 2. If cache empty AND online → fetch from Supabase → cache → return.
/// 3. If cache empty AND offline → return [CacheFailure].
///
/// Write operations (createOrder):
/// 1. If online → insert to Supabase directly → return order.
/// 2. If offline → save to Drift `order_drafts` + enqueue sync → return
///    a temporary [OrderModel] with local ID.
class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remoteDataSource;
  final PosLocalDataSource _localDataSource;
  final ConnectivityService _connectivity;
  final SyncQueueService _syncQueueService;
  final Uuid _uuid;

  PosRepositoryImpl({
    required AppDatabase database,
    PosRemoteDataSource? remoteDataSource,
    PosLocalDataSource? localDataSource,
    ConnectivityService? connectivityService,
    SyncQueueService? syncQueueService,
    Uuid? uuid,
  })  : _remoteDataSource = remoteDataSource ?? PosRemoteDataSource(),
        _localDataSource = localDataSource ?? PosLocalDataSource(database),
        _connectivity = connectivityService ?? ConnectivityService.instance,
        _syncQueueService = syncQueueService ??
            SyncQueueService(database: database),
        _uuid = uuid ?? const Uuid();

  // ── Categories: cache-first with seed fallback ─────────────────────
  @override
  Future<Result<List<CategoryModel>>> getCategories() async {
    // 1. Try cache
    try {
      final cached = await _localDataSource.getCategories();
      if (cached.isNotEmpty) return Right(cached);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Cache read error (categories): $e');
      }
    }

    // 2. Cache empty — try remote if Supabase is initialized
    if (_isSupabaseReady() && await _connectivity.isOnline) {
      try {
        final data = await _remoteDataSource.fetchCategories();
        final categories =
            data.map((json) => CategoryModel.fromJson(json)).toList();
        if (categories.isNotEmpty) {
          // Cache for next time
          await _localDataSource.upsertCategories(categories);
          return Right(categories);
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Remote fetch error (categories): $e');
        }
      }
    }

    // 3. Fallback to seed data so app is always usable
    return const Right(SeedData.categories);
  }

  // ── Products: cache-first with seed fallback ───────────────────────
  @override
  Future<Result<List<ProductModel>>> getProducts({String? categoryId}) async {
    // 1. Try cache
    try {
      final cached =
          await _localDataSource.getProducts(categoryId: categoryId);
      if (cached.isNotEmpty) return Right(cached);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Cache read error (products): $e');
      }
    }

    // 2. Cache empty — try remote if Supabase is initialized
    if (_isSupabaseReady() && await _connectivity.isOnline) {
      try {
        final data =
            await _remoteDataSource.fetchProducts(categoryId: categoryId);
        final products =
            data.map((json) => ProductModel.fromJson(json)).toList();
        if (products.isNotEmpty) {
          // Cache all products (not just filtered) for offline use
          await _localDataSource.upsertProducts(products);
          return Right(products);
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Remote fetch error (products): $e');
        }
      }
    }

    // 3. Fallback to seed data (filtered by category if needed)
    final catId = categoryId;
    final seed = catId != null && catId.isNotEmpty
        ? SeedData.products.where((p) => p.categoryId == catId).toList()
        : SeedData.products;
    return Right(seed);
  }

  /// Check if Supabase is initialized and ready.
  bool _isSupabaseReady() {
    try {
      return getIt<SupabaseService>().isReady;
    } catch (_) {
      return false;
    }
  }

  // ── Create Order: online-direct / offline-queue ────────────────────
  @override
  Future<Result<OrderModel>> createOrder({
    required String outletId,
    String? tableId,
    required OrderType orderType,
    required double subtotal,
    required double total,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    final typeString = switch (orderType) {
      OrderType.dineIn => 'dine_in',
      OrderType.takeaway => 'takeaway',
      OrderType.delivery => 'delivery',
    };

    // Online → direct insert
    if (await _connectivity.isOnline) {
      try {
        final orderData = await _remoteDataSource.insertOrder(
          outletId: outletId,
          tableId: tableId,
          orderType: typeString,
          subtotal: subtotal,
          total: total,
          notes: notes,
          items: items,
        );
        return Right(OrderModel.fromJson(orderData));
      } catch (e) {
        return Left(ServerFailure(
            message: 'Gagal membuat pesanan', original: e));
      }
    }

    // Offline → save draft + enqueue sync
    try {
      final localId = _uuid.v4();
      final orderNumber =
          'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      await _localDataSource.saveOrderDraft(
        id: localId,
        outletId: outletId,
        tableId: tableId,
        orderNumber: orderNumber,
        orderType: typeString,
        subtotal: subtotal,
        total: total,
        notes: notes,
        items: items,
      );

      // Enqueue for sync when back online
      await _syncQueueService.enqueue(
        operation: SyncOperation.insertOrder,
        table: 'orders',
        payload: {
          'order': {
            'outlet_id': outletId,
            'table_id': tableId,
            'order_number': orderNumber,
            'order_type': typeString,
            'status': 'pending',
            'subtotal': subtotal,
            'total': total,
            'notes': notes,
          },
          'items': items,
        },
      );

      // Return a temporary OrderModel so UI can proceed
      return Right(OrderModel(
        id: localId,
        outletId: outletId,
        tableId: tableId,
        orderNumber: orderNumber,
        orderType: orderType,
        status: OrderStatus.pending,
        subtotal: subtotal,
        total: total,
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
      ));
    } catch (e) {
      return Left(CacheFailure(
          message: 'Gagal menyimpan pesanan offline', original: e));
    }
  }

  /// Forces a refresh of the catalog from Supabase (pull-to-refresh).
  Future<Result<void>> refreshCatalog() async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Tidak bisa refresh saat offline'));
    }

    try {
      final catData = await _remoteDataSource.fetchCategories();
      final categories =
          catData.map((json) => CategoryModel.fromJson(json)).toList();
      await _localDataSource.upsertCategories(categories);

      final prodData = await _remoteDataSource.fetchProducts();
      final products =
          prodData.map((json) => ProductModel.fromJson(json)).toList();
      await _localDataSource.upsertProducts(products);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal refresh katalog', original: e));
    }
  }

  /// Returns the count of pending sync operations (for UI badge).
  Future<int> getPendingSyncCount() => _syncQueueService
      .pendingCountStream
      .first;
}
