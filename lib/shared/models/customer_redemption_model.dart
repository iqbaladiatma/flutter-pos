import 'package:equatable/equatable.dart';

/// Voucher / coupon generated when a customer redeems a reward.
class CustomerRedemptionModel extends Equatable {
  final String id;
  final String customerId;
  final String rewardId;
  final String rewardName;
  final String voucherCode;
  final String status; // active, used, expired
  final String? usedWithOrderId;
  final String redeemedAt;
  final String? usedAt;
  final String? expiresAt;

  const CustomerRedemptionModel({
    required this.id,
    required this.customerId,
    required this.rewardId,
    required this.rewardName,
    required this.voucherCode,
    this.status = 'active',
    this.usedWithOrderId,
    required this.redeemedAt,
    this.usedAt,
    this.expiresAt,
  });

  factory CustomerRedemptionModel.fromJson(Map<String, dynamic> json) =>
      CustomerRedemptionModel(
        id: json['id'] ?? '',
        customerId: json['customer_id'] ?? '',
        rewardId: json['reward_id'] ?? '',
        rewardName: json['reward_name'] ?? '',
        voucherCode: json['voucher_code'] ?? '',
        status: json['status'] ?? 'active',
        usedWithOrderId: json['used_with_order_id'],
        redeemedAt:
            json['redeemed_at'] ?? DateTime.now().toIso8601String(),
        usedAt: json['used_at'],
        expiresAt: json['expires_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'reward_id': rewardId,
        'reward_name': rewardName,
        'voucher_code': voucherCode,
        'status': status,
        'used_with_order_id': usedWithOrderId,
        'redeemed_at': redeemedAt,
        'used_at': usedAt,
        'expires_at': expiresAt,
      };

  @override
  List<Object?> get props => [
        id,
        customerId,
        rewardId,
        rewardName,
        voucherCode,
        status,
        usedWithOrderId,
        redeemedAt,
        usedAt,
        expiresAt,
      ];
}
