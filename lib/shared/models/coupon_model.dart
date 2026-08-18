import 'package:equatable/equatable.dart';

/// Discount coupon that can be applied to an order.
class CouponModel extends Equatable {
  final String id;
  final String code;
  final String description;
  final String discountType; // percentage, nominal
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int usageLimit;
  final int usageCount;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.validFrom,
    this.validUntil,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.isActive = true,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        description: json['description'] ?? '',
        discountType: json['discount_type'] ?? 'percentage',
        discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
        minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
        maxDiscountAmount:
            (json['max_discount_amount'] as num?)?.toDouble(),
        validFrom: json['valid_from'] != null
            ? DateTime.tryParse(json['valid_from'])
            : null,
        validUntil: json['valid_until'] != null
            ? DateTime.tryParse(json['valid_until'])
            : null,
        usageLimit: json['usage_limit'] ?? 0,
        usageCount: json['usage_count'] ?? 0,
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount_amount': maxDiscountAmount,
        'valid_from': validFrom?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'is_active': isActive,
      };

  /// Calculates the discount amount for a given order subtotal.
  double calculateDiscount(double subtotal) {
    if (!isActive) return 0;
    if (minOrderAmount != null && subtotal < minOrderAmount!) return 0;

    double discount;
    if (discountType == 'percentage') {
      discount = subtotal * (discountValue / 100);
      if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
        discount = maxDiscountAmount!;
      }
    } else {
      discount = discountValue;
    }
    return discount;
  }

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        discountType,
        discountValue,
        minOrderAmount,
        maxDiscountAmount,
        validFrom,
        validUntil,
        usageLimit,
        usageCount,
        isActive,
      ];
}
