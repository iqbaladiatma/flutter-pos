import 'package:equatable/equatable.dart';
import '../../domain/entities/kitchen_ticket.dart';

abstract class KitchenEvent extends Equatable {
  const KitchenEvent();

  @override
  List<Object?> get props => [];
}

/// Load all active kitchen tickets.
class KitchenLoadTickets extends KitchenEvent {
  final String outletId;
  const KitchenLoadTickets({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Start watching real-time ticket updates.
class KitchenStartWatching extends KitchenEvent {
  final String outletId;
  const KitchenStartWatching({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Stop watching real-time updates.
class KitchenStopWatching extends KitchenEvent {
  const KitchenStopWatching();
}

/// Internal event: tickets updated from realtime stream.
class KitchenTicketsUpdated extends KitchenEvent {
  final List<KitchenTicket> tickets;
  const KitchenTicketsUpdated(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

/// Update the status of an order.
class KitchenUpdateStatus extends KitchenEvent {
  final String orderId;
  final String newStatus;
  final String? staffId;

  const KitchenUpdateStatus({
    required this.orderId,
    required this.newStatus,
    this.staffId,
  });

  @override
  List<Object?> get props => [orderId, newStatus, staffId];
}

/// Filter tickets by category.
class KitchenFilterByCategory extends KitchenEvent {
  final String? categoryId;
  const KitchenFilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Recalculate elapsed time for all tickets (called by timer).
class KitchenTickTimer extends KitchenEvent {
  const KitchenTickTimer();
}
