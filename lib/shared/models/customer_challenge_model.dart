import 'package:equatable/equatable.dart';

/// Progress of a customer on a specific challenge (stamp card, spending goal).
class CustomerChallengeModel extends Equatable {
  final String id;
  final String customerId;
  final String challengeId;
  final int progressCount;
  final double progressAmount;
  final bool isCompleted;
  final bool isClaimed;
  final String? claimedAt;
  final String createdAt;

  const CustomerChallengeModel({
    required this.id,
    required this.customerId,
    required this.challengeId,
    this.progressCount = 0,
    this.progressAmount = 0,
    this.isCompleted = false,
    this.isClaimed = false,
    this.claimedAt,
    required this.createdAt,
  });

  factory CustomerChallengeModel.fromJson(Map<String, dynamic> json) =>
      CustomerChallengeModel(
        id: json['id'] ?? '',
        customerId: json['customer_id'] ?? '',
        challengeId: json['challenge_id'] ?? '',
        progressCount: json['progress_count'] ?? 0,
        progressAmount:
            (json['progress_amount'] as num?)?.toDouble() ?? 0,
        isCompleted: json['is_completed'] ?? false,
        isClaimed: json['is_claimed'] ?? false,
        claimedAt: json['claimed_at'],
        createdAt:
            json['created_at'] ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'challenge_id': challengeId,
        'progress_count': progressCount,
        'progress_amount': progressAmount,
        'is_completed': isCompleted,
        'is_claimed': isClaimed,
        'claimed_at': claimedAt,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [
        id,
        customerId,
        challengeId,
        progressCount,
        progressAmount,
        isCompleted,
        isClaimed,
        claimedAt,
        createdAt,
      ];
}
