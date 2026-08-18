import 'package:equatable/equatable.dart';

enum OrderType { dineIn, takeaway, delivery }
enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }
enum PaymentMethod { cash, qris, bankTransfer, ewallet, card }

class OrderItemModel extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] ?? '',
        productId: json['product_id'] ?? '',
        productName: json['product_name'] ?? '',
        variantName: json['variant_name'],
        quantity: json['quantity'] ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        notes: json['notes'],
      );

  @override
  List<Object?> get props =>
      [id, productId, productName, variantName, quantity, unitPrice, subtotal, notes];

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? variantName,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    String? notes,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'variant_name': variantName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'notes': notes,
      };
}

class OrderModel extends Equatable {
  final String id;
  final String outletId;
  final String? tableId;
  final String orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double deliveryFee;
  final double total;
  final String? notes;
  final List<OrderItemModel> items;
  final String createdAt;

  const OrderModel({
    required this.id,
    required this.outletId,
    this.tableId,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.deliveryFee = 0,
    required this.total,
    this.notes,
    this.items = const [],
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderType oType = OrderType.dineIn;
    if (json['order_type'] == 'takeaway') oType = OrderType.takeaway;
    if (json['order_type'] == 'delivery') oType = OrderType.delivery;

    OrderStatus oStatus = OrderStatus.pending;
    switch (json['status']) {
      case 'confirmed':
        oStatus = OrderStatus.confirmed;
        break;
      case 'preparing':
        oStatus = OrderStatus.preparing;
        break;
      case 'ready':
        oStatus = OrderStatus.ready;
        break;
      case 'completed':
        oStatus = OrderStatus.completed;
        break;
      case 'cancelled':
        oStatus = OrderStatus.cancelled;
        break;
    }

    return OrderModel(
      id: json['id'] ?? '',
      outletId: json['outlet_id'] ?? '',
      tableId: json['table_id'],
      orderNumber: json['order_number'] ?? '',
      orderType: oType,
      status: oStatus,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      items: (json['items'] as List?)
              ?.map((e) => OrderItemModel.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        outletId,
        tableId,
        orderNumber,
        orderType,
        status,
        subtotal,
        discountAmount,
        taxAmount,
        deliveryFee,
        total,
        notes,
        items,
        createdAt,
      ];

  OrderModel copyWith({
    String? id,
    String? outletId,
    String? tableId,
    String? orderNumber,
    OrderType? orderType,
    OrderStatus? status,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? deliveryFee,
    double? total,
    String? notes,
    List<OrderItemModel>? items,
    String? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      tableId: tableId ?? this.tableId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'table_id': tableId,
        'order_number': orderNumber,
        'order_type': switch (orderType) {
          OrderType.dineIn => 'dine_in',
          OrderType.takeaway => 'takeaway',
          OrderType.delivery => 'delivery',
        },
        'status': status.name,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'delivery_fee': deliveryFee,
        'total': total,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
        'created_at': createdAt,
      };
}
