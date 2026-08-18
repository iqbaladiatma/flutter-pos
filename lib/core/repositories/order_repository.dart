import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_service.dart';
import '../../shared/models/order_model.dart';

class OrderRepository {
  // Lazy access: evaluated on each call, AFTER SupabaseService.init()
  // has completed in main(). Avoids LateInitializationError / race
  // condition when the repository is constructed before init finishes.
  SupabaseClient get _client => SupabaseService().client;

  // Create new Order in Supabase
  Future<OrderModel?> createOrder({
    required String outletId,
    String? tableId,
    required OrderType orderType,
    required double subtotal,
    required double total,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final orderNumber =
          'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      final String typeString = orderType == OrderType.dineIn
          ? 'dine_in'
          : (orderType == OrderType.takeaway ? 'takeaway' : 'delivery');

      // 1. Insert order header
      final orderData = await _client.from('orders').insert({
        'outlet_id': outletId,
        'table_id': tableId,
        'order_number': orderNumber,
        'order_type': typeString,
        'status': 'pending',
        'subtotal': subtotal,
        'total': total,
        'notes': notes,
      }).select().single();

      final orderId = orderData['id'];

      // 2. Insert order items
      final List<Map<String, dynamic>> itemInserts = items.map((item) {
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

      return OrderModel.fromJson(orderData);
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Fetch pending / active orders for Kitchen & Kasir
  Future<List<OrderModel>> getActiveOrders({String? outletId}) async {
    try {
      var query = _client.from('orders').select('*, items:order_items(*)');

      if (outletId != null && outletId.isNotEmpty) {
        query = query.eq('outlet_id', outletId);
      }

      final response =
          await query.order('created_at', ascending: false).limit(50);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching active orders: $e');
      return [];
    }
  }

  // Update order status (pending -> preparing -> ready -> completed)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Realtime WebSocket Channel for Kitchen Display System (KDS)
  RealtimeChannel subscribeToKitchenOrders({
    required Function(Map<String, dynamic> payload) onOrderUpdate,
  }) {
    final channel = _client
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            onOrderUpdate(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }
}
