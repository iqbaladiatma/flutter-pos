import '../../../../core/error/either.dart';
import '../entities/kitchen_ticket.dart';

/// Domain contract for KDS (Kitchen Display System) operations.
abstract class KitchenRepository {
  /// Returns all active kitchen tickets (pending + preparing + ready).
  ///
  /// Filters out completed/cancelled orders. Only items from kitchen
  /// categories (`is_kitchen = true`) are included.
  Future<Result<List<KitchenTicket>>> getActiveTickets({
    required String outletId,
  });

  /// Updates the status of an order (e.g. pending → preparing → ready).
  ///
  /// Also writes an audit row to `order_status_logs`.
  Future<Result<void>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? staffId,
    String? notes,
  });

  /// Returns a stream of real-time ticket updates via Supabase Realtime.
  ///
  /// Emits the full list of active tickets whenever an order is inserted,
  /// updated, or deleted.
  Stream<List<KitchenTicket>> watchActiveTickets({
    required String outletId,
  });
}
