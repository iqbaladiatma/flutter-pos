import 'package:equatable/equatable.dart';

/// Records which modifiers were selected for a specific order item.
class OrderItemModifierModel extends Equatable {
  final String id;
  final String orderItemId;
  final String modifierId;
  final String modifierName;
  final double priceAdjustment;
  final int quantity;

  const OrderItemModifierModel({
    required this.id,
    required this.orderItemId,
    required this.modifierId,
    required this.modifierName,
    this.priceAdjustment = 0,
    this.quantity = 1,
  });

  factory OrderItemModifierModel.fromJson(Map<String, dynamic> json) =>
      OrderItemModifierModel(
        id: json['id'] ?? '',
        orderItemId: json['order_item_id'] ?? '',
        modifierId: json['modifier_id'] ?? '',
        modifierName: json['modifier_name'] ?? '',
        priceAdjustment:
            (json['price_adjustment'] as num?)?.toDouble() ?? 0,
        quantity: json['quantity'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_item_id': orderItemId,
        'modifier_id': modifierId,
        'modifier_name': modifierName,
        'price_adjustment': priceAdjustment,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [
        id,
        orderItemId,
        modifierId,
        modifierName,
        priceAdjustment,
        quantity,
      ];
}
