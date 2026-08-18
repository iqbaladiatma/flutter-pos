import 'package:equatable/equatable.dart';

/// Transaction log for loyalty points (earn or redeem).
class PointTransactionModel extends Equatable {
  final String id;
  final String customerId;
  final String type; // earn, redeem
  final int points;
  final String? orderId;
  final String? rewardId;
  final String description;
  final String createdAt;

  const PointTransactionModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.points,
    this.orderId,
    this.rewardId,
    this.description = '',
    required this.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) =>
      PointTransactionModel(
        id: json['id'] ?? '',
        customerId: json['customer_id'] ?? '',
        type: json['type'] ?? 'earn',
        points: json['points'] ?? 0,
        orderId: json['order_id'],
        rewardId: json['reward_id'],
        description: json['description'] ?? '',
        createdAt:
            json['created_at'] ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'type': type,
        'points': points,
        'order_id': orderId,
        'reward_id': rewardId,
        'description': description,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props =>
      [id, customerId, type, points, orderId, rewardId, description, createdAt];
}
