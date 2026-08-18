import 'package:equatable/equatable.dart';

/// Pivot table: links products to modifier groups (many-to-many).
class ProductModifierGroupModel extends Equatable {
  final String id;
  final String productId;
  final String modifierGroupId;
  final int sortOrder;

  const ProductModifierGroupModel({
    required this.id,
    required this.productId,
    required this.modifierGroupId,
    this.sortOrder = 0,
  });

  factory ProductModifierGroupModel.fromJson(Map<String, dynamic> json) =>
      ProductModifierGroupModel(
        id: json['id'] ?? '',
        productId: json['product_id'] ?? '',
        modifierGroupId: json['modifier_group_id'] ?? '',
        sortOrder: json['sort_order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'modifier_group_id': modifierGroupId,
        'sort_order': sortOrder,
      };

  @override
  List<Object?> get props => [id, productId, modifierGroupId, sortOrder];
}
