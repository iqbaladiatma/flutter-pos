import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';

/// Remote data source for POS — encapsulates all raw Supabase calls.
///
/// The repository implementation delegates to this class so that
/// Supabase-specific code is isolated in the data layer.
class PosRemoteDataSource {
  SupabaseClient get _client => SupabaseService().client;

  /// Fetches active categories ordered by name.
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Fetches active products with their variants, optionally filtered
  /// by [categoryId].
  Future<List<Map<String, dynamic>>> fetchProducts({String? categoryId}) async {
    var query = _client
        .from('products')
        .select('*, variants:product_variants(*)')
        .eq('is_active', true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('name', ascending: true);
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Inserts an order header and its items in a two-step transaction.
  Future<Map<String, dynamic>> insertOrder({
    required String outletId,
    String? tableId,
    required String orderType,
    required double subtotal,
    required double total,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final orderNumber =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    // 1. Insert order header
    final orderData = await _client.from('orders').insert({
      'outlet_id': outletId,
      'table_id': tableId,
      'order_number': orderNumber,
      'order_type': orderType,
      'status': 'pending',
      'subtotal': subtotal,
      'total': total,
      'notes': notes,
    }).select().single();

    final orderId = orderData['id'];

    // 2. Insert order items
    final itemInserts = items.map((item) {
      return {
        'order_id': orderId,
        'product_id': item['id'],
        'product_name': item['name'],
        'quantity': item['qty'],
        'unit_price': item['price'],
        'subtotal': (item['price'] * item['qty']),
      };
    }).toList();

    await _client.from('order_items').insert(itemInserts);

    return orderData;
  }
}
