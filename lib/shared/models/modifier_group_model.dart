import 'package:equatable/equatable.dart';

/// Group of modifier options (e.g. "Extra Topping", "Level Pedas").
class ModifierGroupModel extends Equatable {
  final String id;
  final String name;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final int sortOrder;
  final bool isActive;

  const ModifierGroupModel({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelection = 0,
    this.maxSelection = 1,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ModifierGroupModel.fromJson(Map<String, dynamic> json) =>
      ModifierGroupModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        isRequired: json['is_required'] ?? false,
        minSelection: json['min_selection'] ?? 0,
        maxSelection: json['max_selection'] ?? 1,
        sortOrder: json['sort_order'] ?? 0,
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_required': isRequired,
        'min_selection': minSelection,
        'max_selection': maxSelection,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  @override
  List<Object?> get props =>
      [id, name, isRequired, minSelection, maxSelection, sortOrder, isActive];
}
