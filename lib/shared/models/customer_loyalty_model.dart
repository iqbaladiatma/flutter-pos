import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? tierId;
  final int totalPoints;
  final int lifetimePoints;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.tierId,
    this.totalPoints = 0,
    this.lifetimePoints = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        tierId: json['tier_id'],
        totalPoints: json['total_points'] ?? 0,
        lifetimePoints: json['lifetime_points'] ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, name, phone, email, tierId, totalPoints, lifetimePoints];

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? tierId,
    int? totalPoints,
    int? lifetimePoints,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tierId: tierId ?? this.tierId,
      totalPoints: totalPoints ?? this.totalPoints,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'tier_id': tierId,
        'total_points': totalPoints,
        'lifetime_points': lifetimePoints,
      };
}

class LoyaltyTierModel extends Equatable {
  final String id;
  final String name;
  final int minLifetimePoints;
  final double earningRate;
  final String color;

  const LoyaltyTierModel({
    required this.id,
    required this.name,
    required this.minLifetimePoints,
    required this.earningRate,
    required this.color,
  });

  factory LoyaltyTierModel.fromJson(Map<String, dynamic> json) => LoyaltyTierModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        minLifetimePoints: json['min_lifetime_points'] ?? 0,
        earningRate: (json['earning_rate'] as num?)?.toDouble() ?? 1.0,
        color: json['color'] ?? '#6366F1',
      );

  @override
  List<Object?> get props =>
      [id, name, minLifetimePoints, earningRate, color];

  LoyaltyTierModel copyWith({
    String? id,
    String? name,
    int? minLifetimePoints,
    double? earningRate,
    String? color,
  }) {
    return LoyaltyTierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minLifetimePoints: minLifetimePoints ?? this.minLifetimePoints,
      earningRate: earningRate ?? this.earningRate,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'min_lifetime_points': minLifetimePoints,
        'earning_rate': earningRate,
        'color': color,
      };
}

class ChallengeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String type; // stamp_card, spending_goal
  final int targetCount;
  final double rewardValue;

  const ChallengeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.rewardValue,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) => ChallengeModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        type: json['type'] ?? 'stamp_card',
        targetCount: json['rules']?['target_count'] ?? 5,
        rewardValue: (json['reward']?['value'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, name, description, type, targetCount, rewardValue];

  ChallengeModel copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? targetCount,
    double? rewardValue,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      rewardValue: rewardValue ?? this.rewardValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
        'rules': {'target_count': targetCount},
        'reward': {'value': rewardValue},
      };
}
