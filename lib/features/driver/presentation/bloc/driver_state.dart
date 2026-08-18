import 'package:equatable/equatable.dart';
import '../../../../shared/models/delivery_assignment_model.dart';

sealed class DriverState extends Equatable {
  const DriverState();

  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoading extends DriverState {
  const DriverLoading();
}

class DriverLoaded extends DriverState {
  final String driverId;
  final String status; // active, inactive, on_delivery
  final List<DeliveryAssignmentModel> pendingAssignments;
  final List<DeliveryAssignmentModel> activeAssignments;
  final double? latitude;
  final double? longitude;
  final bool isUpdating;
  final String? errorMessage;

  const DriverLoaded({
    required this.driverId,
    required this.status,
    required this.pendingAssignments,
    required this.activeAssignments,
    this.latitude,
    this.longitude,
    this.isUpdating = false,
    this.errorMessage,
  });

  bool get isActive => status == 'active' || status == 'on_delivery';
  bool get isOnDelivery => status == 'on_delivery';
  bool get hasPendingAssignments => pendingAssignments.isNotEmpty;
  bool get hasActiveDeliveries => activeAssignments.isNotEmpty;

  DriverLoaded copyWith({
    String? driverId,
    String? status,
    List<DeliveryAssignmentModel>? pendingAssignments,
    List<DeliveryAssignmentModel>? activeAssignments,
    double? latitude,
    double? longitude,
    bool? isUpdating,
    String? errorMessage,
    bool clearError = false,
  }) =>
      DriverLoaded(
        driverId: driverId ?? this.driverId,
        status: status ?? this.status,
        pendingAssignments:
            pendingAssignments ?? this.pendingAssignments,
        activeAssignments:
            activeAssignments ?? this.activeAssignments,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isUpdating: isUpdating ?? this.isUpdating,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        driverId,
        status,
        pendingAssignments,
        activeAssignments,
        latitude,
        longitude,
        isUpdating,
        errorMessage,
      ];
}

class DriverError extends DriverState {
  final String message;
  const DriverError(this.message);

  @override
  List<Object?> get props => [message];
}
