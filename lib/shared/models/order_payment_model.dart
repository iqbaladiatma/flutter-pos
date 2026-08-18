import 'package:equatable/equatable.dart';

/// Payment record for an order (supports split bill — one order can have
/// multiple payments).
class OrderPaymentModel extends Equatable {
  final String id;
  final String orderId;
  final String method; // cash, qris, bank_transfer, ewallet, card
  final double amount;
  final double? changeAmount;
  final String? referenceNumber;
  final String? paidAt;

  const OrderPaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    this.changeAmount,
    this.referenceNumber,
    this.paidAt,
  });

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) =>
      OrderPaymentModel(
        id: json['id'] ?? '',
        orderId: json['order_id'] ?? '',
        method: json['method'] ?? 'cash',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        changeAmount: (json['change_amount'] as num?)?.toDouble(),
        referenceNumber: json['reference_number'],
        paidAt: json['paid_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'method': method,
        'amount': amount,
        'change_amount': changeAmount,
        'reference_number': referenceNumber,
        'paid_at': paidAt,
      };

  @override
  List<Object?> get props =>
      [id, orderId, method, amount, changeAmount, referenceNumber, paidAt];
}
