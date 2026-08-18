import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_service.dart';
import '../../shared/models/product_model.dart';

class ProductRepository {
  // Lazy access: evaluated on each call, AFTER SupabaseService.init()
  // has completed in main(). Avoids LateInitializationError / race
  // condition when the repository is constructed before init finishes.
  SupabaseClient get _client => SupabaseService().client;

  Future<List<CategoryModel>> getCategories({String? organizationId}) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    try {
      var query = _client
          .from('products')
          .select('*, variants:product_variants(*)')
          .eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query;

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }
}
