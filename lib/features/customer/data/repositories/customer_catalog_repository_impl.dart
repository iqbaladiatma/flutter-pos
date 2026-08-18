import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/table_model.dart';
import '../../domain/repositories/customer_catalog_repository.dart';

/// Implementation of [CustomerCatalogRepository] using Supabase.
class CustomerCatalogRepositoryImpl
    implements CustomerCatalogRepository {
  final SupabaseService _supabaseService;

  CustomerCatalogRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<List<ProductModel>>> getOutletProducts({
    required String outletId,
    String? categoryId,
  }) async {
    try {
      final baseQuery = _client
          .from('products')
          .select()
          .eq('outlet_id', outletId)
          .eq('is_available', true);

      final filteredQuery = categoryId != null
          ? baseQuery.eq('category_id', categoryId)
          : baseQuery;

      final data = await filteredQuery.order('name', ascending: true);
      final products = data
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat menu', original: e));
    }
  }

  @override
  Future<Result<List<CategoryModel>>> getOutletCategories({
    required String outletId,
  }) async {
    try {
      final data = await _client
          .from('categories')
          .select('id, name, sort_order')
          .eq('outlet_id', outletId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final categories = data
          .map<CategoryModel>((e) => CategoryModel.fromJson(e))
          .toList();
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat kategori', original: e));
    }
  }

  @override
  Future<Result<List<Banner>>> getBanners({required String outletId}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = await _client
          .from('banners')
          .select()
          .eq('outlet_id', outletId)
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('sort_order', ascending: true);

      final banners =
          data.map<Banner>((e) => Banner.fromJson(e)).toList();
      return Right(banners);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat banner', original: e));
    }
  }

  @override
  Future<Result<TableModel>> getTableByQrCode({
    required String outletId,
    required String qrCode,
  }) async {
    try {
      final data = await _client
          .from('restaurant_tables')
          .select()
          .eq('outlet_id', outletId)
          .eq('qr_code', qrCode)
          .maybeSingle();

      if (data == null) {
        return const Left(ValidationFailure(
            message: 'Meja tidak ditemukan. QR code tidak valid.'));
      }
      return Right(TableModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal scan QR meja', original: e));
    }
  }
}
