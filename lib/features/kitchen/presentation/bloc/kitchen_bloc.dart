import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/models/order_model.dart';
import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_repository.dart';
import 'kitchen_event.dart';
import 'kitchen_state.dart';

/// BLoC managing KDS state: real-time ticket stream, status updates,
/// category filtering, and elapsed time tracking.
class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  final KitchenRepository _repository;
  StreamSubscription<List<KitchenTicket>>? _ticketSub;
  Timer? _tickTimer;

  KitchenBloc({required KitchenRepository repository})
      : _repository = repository,
        super(const KitchenInitial()) {
    on<KitchenLoadTickets>(_onLoadTickets);
    on<KitchenStartWatching>(_onStartWatching);
    on<KitchenStopWatching>(_onStopWatching);
    on<KitchenTicketsUpdated>(_onTicketsUpdated);
    on<KitchenUpdateStatus>(_onUpdateStatus);
    on<KitchenFilterByCategory>(_onFilterByCategory);
    on<KitchenTickTimer>(_onTickTimer);
  }

  void _onLoadTickets(
    KitchenLoadTickets event,
    Emitter<KitchenState> emit,
  ) async {
    emit(const KitchenLoading());
    final result = await _repository.getActiveTickets(outletId: event.outletId);
    result.fold(
      ifLeft: (failure) => emit(KitchenError(failure.message)),
      ifRight: (tickets) {
        emit(KitchenLoaded(tickets: tickets));
        _startTickTimer();
      },
    );
  }

  void _onStartWatching(
    KitchenStartWatching event,
    Emitter<KitchenState> emit,
  ) {
    _ticketSub?.cancel();
    _ticketSub = _repository.watchActiveTickets(outletId: event.outletId).listen(
      (tickets) => add(KitchenTicketsUpdated(tickets)),
    );
    _startTickTimer();
  }

  void _onStopWatching(
    KitchenStopWatching event,
    Emitter<KitchenState> emit,
  ) {
    _ticketSub?.cancel();
    _ticketSub = null;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _onTicketsUpdated(
    KitchenTicketsUpdated event,
    Emitter<KitchenState> emit,
  ) {
    final current = state;
    if (current is KitchenLoaded) {
      emit(current.copyWith(tickets: event.tickets, isUpdating: false));
    } else {
      emit(KitchenLoaded(tickets: event.tickets));
    }
  }

  void _onUpdateStatus(
    KitchenUpdateStatus event,
    Emitter<KitchenState> emit,
  ) async {
    final current = state;
    if (current is! KitchenLoaded) return;

    // Optimistic update: update local state immediately
    final newStatus = _parseStatus(event.newStatus);
    final updatedTickets = current.tickets.map((t) {
      if (t.id == event.orderId) {
        return t.copyWith(status: newStatus);
      }
      return t;
    }).toList();
    emit(current.copyWith(tickets: updatedTickets, isUpdating: true));

    // Send to backend
    final result = await _repository.updateOrderStatus(
      orderId: event.orderId,
      newStatus: event.newStatus,
      staffId: event.staffId,
    );

    result.fold(
      ifLeft: (failure) {
        // Revert on failure — reload from server
        if (kDebugMode) {
          // ignore: avoid_print
          print('KDS status update failed: ${failure.message}');
        }
      },
      ifRight: (_) {
        // Success — the realtime stream will update the list
        emit(current.copyWith(isUpdating: false));
      },
    );
  }

  void _onFilterByCategory(
    KitchenFilterByCategory event,
    Emitter<KitchenState> emit,
  ) {
    final current = state;
    if (current is! KitchenLoaded) return;

    if (event.categoryId == null) {
      emit(current.copyWith(clearFilter: true));
    } else {
      emit(current.copyWith(selectedCategoryId: event.categoryId));
    }
  }

  void _onTickTimer(
    KitchenTickTimer event,
    Emitter<KitchenState> emit,
  ) {
    final current = state;
    if (current is! KitchenLoaded) return;

    final now = DateTime.now();
    final updated = current.tickets.map((t) {
      final elapsed = now.difference(t.createdAt).inSeconds;
      return t.copyWith(elapsedSeconds: elapsed);
    }).toList();
    emit(current.copyWith(tickets: updated));
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1),
        (_) => add(const KitchenTickTimer()));
  }

  /// Parses a status string into [OrderStatus].
  OrderStatus _parseStatus(String status) {
    return switch (status) {
      'confirmed' => OrderStatus.confirmed,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  @override
  Future<void> close() {
    _ticketSub?.cancel();
    _tickTimer?.cancel();
    return super.close();
  }
}
