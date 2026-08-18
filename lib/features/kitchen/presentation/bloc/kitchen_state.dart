import 'package:equatable/equatable.dart';
import '../../domain/entities/kitchen_ticket.dart';

sealed class KitchenState extends Equatable {
  const KitchenState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class KitchenInitial extends KitchenState {
  const KitchenInitial();
}

/// Loading tickets.
class KitchenLoading extends KitchenState {
  const KitchenLoading();
}

/// Tickets loaded successfully.
class KitchenLoaded extends KitchenState {
  final List<KitchenTicket> tickets;
  final String? selectedCategoryId;
  final bool isUpdating;

  const KitchenLoaded({
    required this.tickets,
    this.selectedCategoryId,
    this.isUpdating = false,
  });

  /// Returns tickets filtered by selected category.
  List<KitchenTicket> get filteredTickets {
    if (selectedCategoryId == null) return tickets;
    return tickets
        .where((t) =>
            t.items.any((i) => i.categoryName == selectedCategoryId))
        .toList();
  }

  /// Tickets grouped by status for kanban columns.
  List<KitchenTicket> get pendingTickets =>
      filteredTickets.where((t) => t.isNew).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<KitchenTicket> get preparingTickets =>
      filteredTickets.where((t) => t.isPreparing).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<KitchenTicket> get readyTickets =>
      filteredTickets.where((t) => t.isReady).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Returns `true` if there are new tickets (for audio alert).
  bool get hasNewTickets => tickets.any((t) => t.isNew);

  KitchenLoaded copyWith({
    List<KitchenTicket>? tickets,
    String? selectedCategoryId,
    bool? isUpdating,
    bool clearFilter = false,
  }) =>
      KitchenLoaded(
        tickets: tickets ?? this.tickets,
        selectedCategoryId:
            clearFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
        isUpdating: isUpdating ?? this.isUpdating,
      );

  @override
  List<Object?> get props => [tickets, selectedCategoryId, isUpdating];
}

/// Error state.
class KitchenError extends KitchenState {
  final String message;
  const KitchenError(this.message);

  @override
  List<Object?> get props => [message];
}
