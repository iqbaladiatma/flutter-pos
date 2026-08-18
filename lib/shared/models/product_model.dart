import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final bool isKitchen;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.isKitchen = false,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        isKitchen: json['is_kitchen'] ?? false,
        isActive: json['is_active'] ?? true,
      );

  @override
  List<Object?> get props => [id, name, slug, isKitchen, isActive];

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    bool? isKitchen,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isKitchen: isKitchen ?? this.isKitchen,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'is_kitchen': isKitchen,
        'is_active': isActive,
      };
}

class ProductVariantModel extends Equatable {
  final String id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  const ProductVariantModel({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    this.isDefault = false,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) =>
      ProductVariantModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
        isDefault: json['is_default'] ?? false,
      );

  @override
  List<Object?> get props => [id, name, priceAdjustment, isDefault];

  ProductVariantModel copyWith({
    String? id,
    String? name,
    double? priceAdjustment,
    bool? isDefault,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price_adjustment': priceAdjustment,
        'is_default': isDefault,
      };
}

class ModifierModel extends Equatable {
  final String id;
  final String name;
  final double price;

  const ModifierModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ModifierModel.fromJson(Map<String, dynamic> json) => ModifierModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [id, name, price];

  ModifierModel copyWith({
    String? id,
    String? name,
    double? price,
  }) {
    return ModifierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };
}

class ProductModel extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final double basePrice;
  final bool isActive;
  final List<ProductVariantModel> variants;
  final List<ModifierModel> modifiers;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    required this.basePrice,
    this.isActive = true,
    this.variants = const [],
    this.modifiers = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] ?? '',
        categoryId: json['category_id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        description: json['description'],
        imageUrl: json['image_url'],
        basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] ?? true,
        variants: (json['variants'] as List?)
                ?.map((e) => ProductVariantModel.fromJson(e))
                .toList() ??
            [],
        modifiers: (json['modifiers'] as List?)
                ?.map((e) => ModifierModel.fromJson(e))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props =>
      [id, categoryId, name, slug, description, imageUrl, basePrice, isActive, variants, modifiers];

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    double? basePrice,
    bool? isActive,
    List<ProductVariantModel>? variants,
    List<ModifierModel>? modifiers,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      isActive: isActive ?? this.isActive,
      variants: variants ?? this.variants,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'slug': slug,
        'description': description,
        'image_url': imageUrl,
        'base_price': basePrice,
        'is_active': isActive,
        'variants': variants.map((e) => e.toJson()).toList(),
        'modifiers': modifiers.map((e) => e.toJson()).toList(),
      };
}
