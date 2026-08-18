import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/order_model.dart';
import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_repository.dart';

/// Implementation of [KitchenRepository] using Supabase.
///
/// Reads orders with their items (filtered by kitchen categories),
/// and subscribes to real-time changes via Supabase Realtime.
class KitchenRepositoryImpl implements KitchenRepository {
  final SupabaseService _supabaseService;

  KitchenRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<List<KitchenTicket>>> getActiveTickets({
    required String outletId,
  }) async {
    try {
      // Fetch active orders (pending, confirmed, preparing, ready)
      final ordersData = await _client
          .from('orders')
          .select('''
            id,
            order_number,
            order_type,
            status,
            table_id,
            created_at,
            order_items (
              id,
              product_name,
              quantity,
              variant_name,
              notes,
              products (
                category_id,
                categories (
                  name,
                  is_kitchen
                )
              )
            )
          ''')
          .eq('outlet_id', outletId)
          .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready'])
          .order('created_at', ascending: true);

      final tickets = <KitchenTicket>[];
      for (final orderData in ordersData) {
        final ticket = _parseTicket(orderData);
        if (ticket.items.isNotEmpty) {
          tickets.add(ticket);
        }
      }

      return Right(tickets);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('KDS getActiveTickets error: $e');
      }
      return Left(ServerFailure(message: 'Gagal memuat tiket dapur', original: e));
    }
  }

  @override
  Future<Result<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? staffId,
    String? notes,
  }) async {
    try {
      // Fetch current status for audit log
      final current = await _client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      final fromStatus = current['status'] as String? ?? 'pending';

      // Update order status
      await _client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);

      // Write audit log
      await _client.from('order_status_logs').insert({
        'order_id': orderId,
        'from_status': fromStatus,
        'to_status': newStatus,
        'changed_by_staff_id': staffId,
        'changed_at': DateTime.now().toUtc().toIso8601String(),
        'notes': notes,
      });

      return const Right(null);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('KDS updateOrderStatus error: $e');
      }
      return Left(ServerFailure(
          message: 'Gagal update status pesanan', original: e));
    }
  }

  @override
  Stream<List<KitchenTicket>> watchActiveTickets({
    required String outletId,
  }) {
    // Create a controller that we'll feed from realtime events.
    final controller = StreamController<List<KitchenTicket>>();

    // Initial load.
    getActiveTickets(outletId: outletId).then((result) {
      result.fold(
        ifLeft: (_) => controller.add([]),
        ifRight: (tickets) => controller.add(tickets),
      );
    });

    // Subscribe to realtime changes on orders table.
    try {
      final channel = _client
          .channel('kitchen_orders_$outletId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'outlet_id',
              value: outletId,
            ),
            callback: (payload) {
              // Reload all tickets on any change.
              getActiveTickets(outletId: outletId).then((result) {
                result.fold(
                  ifLeft: (_) {},
                  ifRight: (tickets) => controller.add(tickets),
                );
              });
            },
          )
          .subscribe();

      // Cleanup when stream is cancelled.
      controller.onCancel = () {
        _client.removeChannel(channel);
        controller.close();
      };
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('KDS realtime subscribe error: $e');
      }
    }

    return controller.stream;
  }

  /// Parses a Supabase order row (with nested order_items) into a [KitchenTicket].
  KitchenTicket _parseTicket(Map<String, dynamic> data) {
    final itemsData = data['order_items'] as List? ?? [];
    final items = <KitchenTicketItem>[];

    for (final itemData in itemsData) {
      final product = itemData['products'] as Map<String, dynamic>?;
      final category = product?['categories'] as Map<String, dynamic>?;
      final isKitchen = category?['is_kitchen'] as bool? ?? true;

      // Only include kitchen items
      if (!isKitchen) continue;

      items.add(KitchenTicketItem(
        id: itemData['id'] as String? ?? '',
        productName: itemData['product_name'] as String? ?? '',
        quantity: itemData['quantity'] as int? ?? 1,
        variantName: itemData['variant_name'] as String?,
        notes: itemData['notes'] as String?,
        categoryName: category?['name'] as String?,
        isKitchenItem: isKitchen,
      ));
    }

    final orderTypeStr = data['order_type'] as String? ?? 'dine_in';
    final statusStr = data['status'] as String? ?? 'pending';
    final createdAtStr = data['created_at'] as String? ??
        DateTime.now().toIso8601String();

    return KitchenTicket(
      id: data['id'] as String? ?? '',
      orderNumber: data['order_number'] as String? ?? '',
      orderType: _parseOrderType(orderTypeStr),
      status: _parseOrderStatus(statusStr),
      createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
      items: items,
    );
  }

  OrderType _parseOrderType(String value) {
    return switch (value) {
      'takeaway' => OrderType.takeaway,
      'delivery' => OrderType.delivery,
      _ => OrderType.dineIn,
    };
  }

  OrderStatus _parseOrderStatus(String value) {
    return switch (value) {
      'confirmed' => OrderStatus.confirmed,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }
}
