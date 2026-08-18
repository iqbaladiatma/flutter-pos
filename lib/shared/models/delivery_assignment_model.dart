import 'package:equatable/equatable.dart';

/// Assignment of a delivery to a driver (with accept/reject status).
class DeliveryAssignmentModel extends Equatable {
  final String id;
  final String deliveryId;
  final String driverId;
  final String status; // pending, accepted, rejected, cancelled
  final String assignedAt;
  final String? respondedAt;

  const DeliveryAssignmentModel({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    this.status = 'pending',
    required this.assignedAt,
    this.respondedAt,
  });

  factory DeliveryAssignmentModel.fromJson(Map<String, dynamic> json) =>
      DeliveryAssignmentModel(
        id: json['id'] ?? '',
        deliveryId: json['delivery_id'] ?? '',
        driverId: json['driver_id'] ?? '',
        status: json['status'] ?? 'pending',
        assignedAt:
            json['assigned_at'] ?? DateTime.now().toIso8601String(),
        respondedAt: json['responded_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'driver_id': driverId,
        'status': status,
        'assigned_at': assignedAt,
        'responded_at': respondedAt,
      };

  @override
  List<Object?> get props =>
      [id, deliveryId, driverId, status, assignedAt, respondedAt];
}
