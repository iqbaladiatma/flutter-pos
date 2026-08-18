import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/repositories/admin_repository.dart';

/// Implementation of [AdminRepository] using Supabase.
class AdminRepositoryImpl implements AdminRepository {
  final SupabaseService _supabaseService;

  AdminRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<SalesSummary>> getTodaySalesSummary({
    required String outletId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _client
          .from('orders')
          .select('total, discount_amount, tax_amount, customer_id')
          .eq('outlet_id', outletId)
          .neq('status', 'cancelled')
          .gte('created_at', startOfDay.toUtc().toIso8601String())
          .lt('created_at', endOfDay.toUtc().toIso8601String());

      double totalSales = 0;
      double totalDiscounts = 0;
      double totalTax = 0;
      final customers = <String>{};

      for (final order in data) {
        totalSales += (order['total'] as num?)?.toDouble() ?? 0;
        totalDiscounts +=
            (order['discount_amount'] as num?)?.toDouble() ?? 0;
        totalTax += (order['tax_amount'] as num?)?.toDouble() ?? 0;
        final customerId = order['customer_id'] as String?;
        if (customerId != null) customers.add(customerId);
      }

      final totalOrders = data.length;
      final avgOrderValue =
          totalOrders > 0 ? totalSales / totalOrders : 0.0;

      return Right(SalesSummary(
        totalSales: totalSales,
        totalOrders: totalOrders,
        avgOrderValue: avgOrderValue,
        totalDiscounts: totalDiscounts,
        totalTax: totalTax,
        totalCustomers: customers.length,
      ));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat ringkasan penjualan', original: e));
    }
  }

  @override
  Future<Result<List<HourlySales>>> getHourlySales({
    required String outletId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _client
          .from('orders')
          .select('total, created_at')
          .eq('outlet_id', outletId)
          .neq('status', 'cancelled')
          .gte('created_at', startOfDay.toUtc().toIso8601String())
          .lt('created_at', endOfDay.toUtc().toIso8601String());

      // Group by hour
      final hourlyMap = <int, _HourAccumulator>{};
      for (final order in data) {
        final createdAt =
            DateTime.tryParse(order['created_at'] as String? ?? '');
        if (createdAt == null) continue;
        final hour = createdAt.toLocal().hour;
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final acc =
            hourlyMap.putIfAbsent(hour, () => _HourAccumulator());
        acc.sales += total;
        acc.orders += 1;
      }

      // Fill all 24 hours
      final result = <HourlySales>[];
      for (var h = 0; h < 24; h++) {
        final acc = hourlyMap[h];
        result.add(HourlySales(
          hour: h,
          sales: acc?.sales ?? 0,
          orders: acc?.orders ?? 0,
        ));
      }

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat grafik penjualan', original: e));
    }
  }

  @override
  Future<Result<List<DailySales>>> getDailySales({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await _client
          .from('orders')
          .select('total, created_at')
          .eq('outlet_id', outletId)
          .neq('status', 'cancelled')
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', endDate.toUtc().toIso8601String());

      // Group by date
      final dailyMap = <String, _DayAccumulator>{};
      for (final order in data) {
        final createdAt =
            DateTime.tryParse(order['created_at'] as String? ?? '');
        if (createdAt == null) continue;
        final dateKey =
            '${createdAt.toLocal().year}-${createdAt.toLocal().month.toString().padLeft(2, '0')}-${createdAt.toLocal().day.toString().padLeft(2, '0')}';
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final acc = dailyMap.putIfAbsent(dateKey, () => _DayAccumulator());
        acc.sales += total;
        acc.orders += 1;
      }

      final result = dailyMap.entries.map((e) {
        final parts = e.key.split('-');
        return DailySales(
          date: DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          sales: e.value.sales,
          orders: e.value.orders,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat penjualan harian', original: e));
    }
  }

  @override
  Future<Result<List<PaymentMethodSummary>>> getSalesByPaymentMethod({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await _client
          .from('orders')
          .select('total, payment_method')
          .eq('outlet_id', outletId)
          .neq('status', 'cancelled')
          .gte('created_at', startDate.toUtc().toIso8601String())
          .lte('created_at', endDate.toUtc().toIso8601String());

      final methodMap = <String, _MethodAccumulator>{};
      for (final order in data) {
        final method = order['payment_method'] as String? ?? 'cash';
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final acc =
            methodMap.putIfAbsent(method, () => _MethodAccumulator());
        acc.total += total;
        acc.count += 1;
      }

      final result = methodMap.entries.map((e) {
        return PaymentMethodSummary(
          method: e.key,
          total: e.value.total,
          count: e.value.count,
        );
      }).toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat ringkasan pembayaran', original: e));
    }
  }

  @override
  Future<Result<List<OutletSalesSummary>>> getSalesByOutlet({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch outlets
      final outlets = await _client
          .from('outlets')
          .select('id, name')
          .eq('organization_id', organizationId);

      final result = <OutletSalesSummary>[];
      for (final outlet in outlets) {
        final outletId = outlet['id'] as String;
        final outletName = outlet['name'] as String;

        final orders = await _client
            .from('orders')
            .select('total')
            .eq('outlet_id', outletId)
            .neq('status', 'cancelled')
            .gte('created_at', startDate.toUtc().toIso8601String())
            .lte('created_at', endDate.toUtc().toIso8601String());

        double totalSales = 0;
        for (final order in orders) {
          totalSales += (order['total'] as num?)?.toDouble() ?? 0;
        }

        result.add(OutletSalesSummary(
          outletId: outletId,
          outletName: outletName,
          totalSales: totalSales,
          totalOrders: orders.length,
        ));
      }

      result.sort((a, b) => b.totalSales.compareTo(a.totalSales));
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat ringkasan per outlet', original: e));
    }
  }

  // ── Menu Management ─────────────────────────────────────────────

  @override
  Future<Result<Map<String, dynamic>>> createProduct({
    required String outletId,
    required String name,
    required double basePrice,
    required String categoryId,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    try {
      final data = await _client.from('products').insert({
        'outlet_id': outletId,
        'name': name,
        'base_price': basePrice,
        'category_id': categoryId,
        'description': description,
        'image_url': imageUrl,
        'is_available': isAvailable,
      }).select().single();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal membuat produk', original: e));
    }
  }

  @override
  Future<Result<void>> updateProduct({
    required String productId,
    String? name,
    double? basePrice,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (basePrice != null) updates['base_price'] = basePrice;
      if (categoryId != null) updates['category_id'] = categoryId;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      if (updates.isEmpty) return const Right(null);

      await _client
          .from('products')
          .update(updates)
          .eq('id', productId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal update produk', original: e));
    }
  }

  @override
  Future<Result<void>> deleteProduct({required String productId}) async {
    try {
      await _client
          .from('products')
          .update({'is_available': false}).eq('id', productId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal hapus produk', original: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createCategory({
    required String outletId,
    required String name,
    int sortOrder = 0,
  }) async {
    try {
      final data = await _client.from('categories').insert({
        'outlet_id': outletId,
        'name': name,
        'sort_order': sortOrder,
        'is_active': true,
      }).select().single();
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal membuat kategori', original: e));
    }
  }

  @override
  Future<Result<void>> updateCategory({
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) return const Right(null);

      await _client
          .from('categories')
          .update(updates)
          .eq('id', categoryId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal update kategori', original: e));
    }
  }

  // ── Staff Management ────────────────────────────────────────────

  @override
  Future<Result<List<Map<String, dynamic>>>> getStaff({
    required String outletId,
  }) async {
    try {
      final data = await _client
          .from('staff_outlets')
          .select('''
            *,
            staff (*)
          ''')
          .eq('outlet_id', outletId)
          .order('created_at', ascending: true);
      return Right(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat staf', original: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> createStaff({
    required String outletId,
    required String name,
    required String phone,
    required String role,
    String? pinHash,
  }) async {
    try {
      // Create staff record
      final staff = await _client.from('staff').insert({
        'name': name,
        'phone': phone,
        'pin_hash': pinHash,
        'is_active': true,
      }).select().single();

      // Link to outlet
      await _client.from('staff_outlets').insert({
        'staff_id': staff['id'],
        'outlet_id': outletId,
        'role': role,
      });

      return Right(staff);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal membuat staf', original: e));
    }
  }

  @override
  Future<Result<void>> updateStaff({
    required String staffId,
    String? name,
    String? phone,
    String? role,
    String? pinHash,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (pinHash != null) updates['pin_hash'] = pinHash;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isNotEmpty) {
        await _client.from('staff').update(updates).eq('id', staffId);
      }

      if (role != null) {
        await _client
            .from('staff_outlets')
            .update({'role': role}).eq('staff_id', staffId);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal update staf', original: e));
    }
  }
}

class _HourAccumulator {
  double sales = 0;
  int orders = 0;
}

class _DayAccumulator {
  double sales = 0;
  int orders = 0;
}

class _MethodAccumulator {
  double total = 0;
  int count = 0;
}
