import '../../../../core/error/either.dart';
import '../../../../shared/models/delivery_assignment_model.dart';
import '../../../../shared/models/delivery_model.dart';

/// Domain contract for driver operations.
abstract class DriverRepository {
  /// Updates the driver's status (active, inactive, on_delivery).
  Future<Result<void>> updateDriverStatus({
    required String driverId,
    required String status,
  });

  /// Fetches pending delivery assignments for a driver.
  Future<Result<List<DeliveryAssignmentModel>>> getPendingAssignments({
    required String driverId,
  });

  /// Fetches active delivery for a driver (status: accepted, in_transit).
  Future<Result<List<DeliveryAssignmentModel>>> getActiveAssignments({
    required String driverId,
  });

  /// Accepts a delivery assignment.
  Future<Result<void>> acceptAssignment({
    required String assignmentId,
    required String driverId,
  });

  /// Rejects a delivery assignment.
  Future<Result<void>> rejectAssignment({
    required String assignmentId,
    required String driverId,
    String? reason,
  });

  /// Updates the delivery status (picked_up, in_transit, delivered).
  Future<Result<void>> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? notes,
  });

  /// Updates the driver's GPS coordinates.
  Future<Result<void>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  });

  /// Logs a delivery event (for audit trail).
  Future<Result<void>> logDeliveryEvent({
    required String deliveryId,
    required String status,
    double? latitude,
    double? longitude,
    String? notes,
  });

  /// Fetches delivery details (with address + coordinates).
  Future<Result<DeliveryModel>> getDeliveryDetails({
    required String deliveryId,
  });

  /// Uploads proof of delivery photo.
  ///
  /// Returns the photo URL.
  Future<Result<String>> uploadProofPhoto({
    required String deliveryId,
    required String filePath,
  });
}
