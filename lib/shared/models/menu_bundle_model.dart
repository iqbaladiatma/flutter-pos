import 'package:equatable/equatable.dart';

/// Bundle / combo menu (e.g. "Paket Hemat: Burger + Fries + Drink").
class MenuBundleModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final String? imageUrl;
  final bool isActive;

  const MenuBundleModel({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    this.imageUrl,
    this.isActive = true,
  });

  factory MenuBundleModel.fromJson(Map<String, dynamic> json) =>
      MenuBundleModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
        imageUrl: json['image_url'],
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'base_price': basePrice,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  @override
  List<Object?> get props =>
      [id, name, description, basePrice, imageUrl, isActive];
}
