import 'package:equatable/equatable.dart';

/// Audit trail for order status changes (pending → preparing → ready → …).
class OrderStatusLogModel extends Equatable {
  final String id;
  final String orderId;
  final String fromStatus;
  final String toStatus;
  final String? changedByStaffId;
  final String changedAt;
  final String? notes;

  const OrderStatusLogModel({
    required this.id,
    required this.orderId,
    required this.fromStatus,
    required this.toStatus,
    this.changedByStaffId,
    required this.changedAt,
    this.notes,
  });

  factory OrderStatusLogModel.fromJson(Map<String, dynamic> json) =>
      OrderStatusLogModel(
        id: json['id'] ?? '',
        orderId: json['order_id'] ?? '',
        fromStatus: json['from_status'] ?? '',
        toStatus: json['to_status'] ?? '',
        changedByStaffId: json['changed_by_staff_id'],
        changedAt: json['changed_at'] ?? DateTime.now().toIso8601String(),
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'from_status': fromStatus,
        'to_status': toStatus,
        'changed_by_staff_id': changedByStaffId,
        'changed_at': changedAt,
        'notes': notes,
      };

  @override
  List<Object?> get props =>
      [id, orderId, fromStatus, toStatus, changedByStaffId, changedAt, notes];
}
