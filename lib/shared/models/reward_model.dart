import 'package:equatable/equatable.dart';

/// Catalog of rewards that customers can redeem with loyalty points.
class RewardModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String type; // discount, free_product, free_shipping
  final int pointsCost;
  final double rewardValue;
  final String? productId;
  final bool isActive;

  const RewardModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.pointsCost,
    this.rewardValue = 0,
    this.productId,
    this.isActive = true,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) => RewardModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        type: json['type'] ?? 'discount',
        pointsCost: json['points_cost'] ?? 0,
        rewardValue: (json['reward_value'] as num?)?.toDouble() ?? 0,
        productId: json['product_id'],
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
        'points_cost': pointsCost,
        'reward_value': rewardValue,
        'product_id': productId,
        'is_active': isActive,
      };

  @override
  List<Object?> get props =>
      [id, name, description, type, pointsCost, rewardValue, productId, isActive];
}
