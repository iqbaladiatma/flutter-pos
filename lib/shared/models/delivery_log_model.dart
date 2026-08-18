import 'package:equatable/equatable.dart';

/// Tracking log for a delivery (per-journey status updates + GPS pings).
class DeliveryLogModel extends Equatable {
  final String id;
  final String deliveryId;
  final String status; // pending, allocated, picked_up, in_transit, delivered, cancelled
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String loggedAt;

  const DeliveryLogModel({
    required this.id,
    required this.deliveryId,
    required this.status,
    this.latitude,
    this.longitude,
    this.notes,
    required this.loggedAt,
  });

  factory DeliveryLogModel.fromJson(Map<String, dynamic> json) =>
      DeliveryLogModel(
        id: json['id'] ?? '',
        deliveryId: json['delivery_id'] ?? '',
        status: json['status'] ?? 'pending',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        notes: json['notes'],
        loggedAt: json['logged_at'] ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'logged_at': loggedAt,
      };

  @override
  List<Object?> get props =>
      [id, deliveryId, status, latitude, longitude, notes, loggedAt];
}
