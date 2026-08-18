import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/delivery_assignment_model.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../services/driver_location_service.dart';
import 'driver_event.dart';
import 'driver_state.dart';

/// BLoC managing driver state: status, assignments, GPS, delivery updates.
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final DriverRepository _repository;
  final DriverLocationService _locationService;

  DriverBloc({
    required DriverRepository repository,
    DriverLocationService? locationService,
  })  : _repository = repository,
        _locationService = locationService ?? DriverLocationService.instance,
        super(const DriverInitial()) {
    on<DriverLoad>(_onLoad);
    on<DriverToggleStatus>(_onToggleStatus);
    on<DriverAcceptAssignment>(_onAcceptAssignment);
    on<DriverRejectAssignment>(_onRejectAssignment);
    on<DriverUpdateDeliveryStatus>(_onUpdateDeliveryStatus);
    on<DriverUpdateLocation>(_onUpdateLocation);
    on<DriverUploadProof>(_onUploadProof);
    on<DriverRefresh>(_onRefresh);
  }

  void _onLoad(
    DriverLoad event,
    Emitter<DriverState> emit,
  ) async {
    emit(const DriverLoading());

    // Set up location callback
    _locationService.onLocationUpdate = (lat, lng) {
      add(DriverUpdateLocation(
        driverId: event.driverId,
        latitude: lat,
        longitude: lng,
      ));
    };

    // Load assignments
    final pendingResult =
        await _repository.getPendingAssignments(driverId: event.driverId);
    final activeResult =
        await _repository.getActiveAssignments(driverId: event.driverId);

    final pending = pendingResult.fold(
      ifLeft: (_) => <dynamic>[],
      ifRight: (a) => a,
    );
    final active = activeResult.fold(
      ifLeft: (_) => <dynamic>[],
      ifRight: (a) => a,
    );

    // Determine status from active assignments
    final status = active.isNotEmpty ? 'on_delivery' : 'active';

    emit(DriverLoaded(
      driverId: event.driverId,
      status: status,
      pendingAssignments: pending as List<DeliveryAssignmentModel>,
      activeAssignments: active as List<DeliveryAssignmentModel>,
    ));
  }

  void _onToggleStatus(
    DriverToggleStatus event,
    Emitter<DriverState> emit,
  ) async {
    final current = state;
    if (current is! DriverLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _repository.updateDriverStatus(
      driverId: event.driverId,
      status: event.newStatus,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        emit(current.copyWith(
          status: event.newStatus,
          isUpdating: false,
          clearError: true,
        ));

        // Start/stop GPS tracking based on status
        if (event.newStatus == 'active') {
          _locationService.startTracking();
        } else {
          _locationService.stopTracking();
        }
      },
    );
  }

  void _onAcceptAssignment(
    DriverAcceptAssignment event,
    Emitter<DriverState> emit,
  ) async {
    final current = state;
    if (current is! DriverLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _repository.acceptAssignment(
      assignmentId: event.assignmentId,
      driverId: event.driverId,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        // Reload assignments
        add(DriverLoad(driverId: event.driverId));
      },
    );
  }

  void _onRejectAssignment(
    DriverRejectAssignment event,
    Emitter<DriverState> emit,
  ) async {
    final current = state;
    if (current is! DriverLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _repository.rejectAssignment(
      assignmentId: event.assignmentId,
      driverId: event.driverId,
      reason: event.reason,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        // Remove from pending list
        final updated = current.pendingAssignments
            .where((a) => a.id != event.assignmentId)
            .toList();
        emit(current.copyWith(
          pendingAssignments: updated,
          isUpdating: false,
          clearError: true,
        ));
      },
    );
  }

  void _onUpdateDeliveryStatus(
    DriverUpdateDeliveryStatus event,
    Emitter<DriverState> emit,
  ) async {
    final current = state;
    if (current is! DriverLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _repository.updateDeliveryStatus(
      deliveryId: event.deliveryId,
      status: event.status,
      notes: event.notes,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        // Reload assignments
        add(DriverLoad(driverId: current.driverId));
      },
    );
  }

  void _onUpdateLocation(
    DriverUpdateLocation event,
    Emitter<DriverState> emit,
  ) {
    final current = state;
    if (current is! DriverLoaded) return;

    // Update local state with new coordinates
    emit(current.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
    ));

    // Upload to server (fire and forget)
    _repository.updateDriverLocation(
      driverId: event.driverId,
      latitude: event.latitude,
      longitude: event.longitude,
    );
  }

  void _onUploadProof(
    DriverUploadProof event,
    Emitter<DriverState> emit,
  ) async {
    final current = state;
    if (current is! DriverLoaded) return;

    emit(current.copyWith(isUpdating: true));

    final result = await _repository.uploadProofPhoto(
      deliveryId: event.deliveryId,
      filePath: event.filePath,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isUpdating: false,
        errorMessage: failure.message,
      )),
      ifRight: (photoUrl) {
        // Update delivery status to delivered
        add(DriverUpdateDeliveryStatus(
          deliveryId: event.deliveryId,
          status: 'delivered',
          notes: 'Proof photo: $photoUrl',
        ));
      },
    );
  }

  void _onRefresh(
    DriverRefresh event,
    Emitter<DriverState> emit,
  ) {
    final current = state;
    if (current is! DriverLoaded) return;
    add(DriverLoad(driverId: current.driverId));
  }

  @override
  Future<void> close() {
    _locationService.stopTracking();
    return super.close();
  }
}
