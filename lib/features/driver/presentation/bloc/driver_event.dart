import 'package:equatable/equatable.dart';

abstract class DriverEvent extends Equatable {
  const DriverEvent();

  @override
  List<Object?> get props => [];
}

/// Load driver dashboard (status + assignments).
class DriverLoad extends DriverEvent {
  final String driverId;
  const DriverLoad({required this.driverId});

  @override
  List<Object?> get props => [driverId];
}

/// Toggle driver status (active ↔ inactive).
class DriverToggleStatus extends DriverEvent {
  final String driverId;
  final String newStatus; // active, inactive
  const DriverToggleStatus({
    required this.driverId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [driverId, newStatus];
}

/// Accept a delivery assignment.
class DriverAcceptAssignment extends DriverEvent {
  final String assignmentId;
  final String driverId;
  const DriverAcceptAssignment({
    required this.assignmentId,
    required this.driverId,
  });

  @override
  List<Object?> get props => [assignmentId, driverId];
}

/// Reject a delivery assignment.
class DriverRejectAssignment extends DriverEvent {
  final String assignmentId;
  final String driverId;
  final String? reason;
  const DriverRejectAssignment({
    required this.assignmentId,
    required this.driverId,
    this.reason,
  });

  @override
  List<Object?> get props => [assignmentId, driverId, reason];
}

/// Update delivery status (picked_up, in_transit, delivered).
class DriverUpdateDeliveryStatus extends DriverEvent {
  final String deliveryId;
  final String status;
  final String? notes;
  const DriverUpdateDeliveryStatus({
    required this.deliveryId,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [deliveryId, status, notes];
}

/// Update driver location (from GPS).
class DriverUpdateLocation extends DriverEvent {
  final String driverId;
  final double latitude;
  final double longitude;
  const DriverUpdateLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [driverId, latitude, longitude];
}

/// Upload proof of delivery photo.
class DriverUploadProof extends DriverEvent {
  final String deliveryId;
  final String filePath;
  const DriverUploadProof({
    required this.deliveryId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [deliveryId, filePath];
}

/// Refresh assignments.
class DriverRefresh extends DriverEvent {
  const DriverRefresh();
}
