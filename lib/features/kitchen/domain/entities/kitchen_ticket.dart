import 'package:equatable/equatable.dart';

import '../../../../shared/models/order_model.dart';

/// A kitchen ticket representing one order with its items.
class KitchenTicket extends Equatable {
  final String id;
  final String orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final String? tableNumber;
  final String? customerName;
  final DateTime createdAt;
  final List<KitchenTicketItem> items;
  final int elapsedSeconds;

  const KitchenTicket({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    this.tableNumber,
    this.customerName,
    required this.createdAt,
    required this.items,
    this.elapsedSeconds = 0,
  });

  /// Returns `true` if the ticket is new (not yet started).
  bool get isNew => status == OrderStatus.pending;

  /// Returns `true` if the ticket is being prepared.
  bool get isPreparing => status == OrderStatus.preparing;

  /// Returns `true` if the ticket is ready for pickup.
  bool get isReady => status == OrderStatus.ready;

  /// Returns `true` if the ticket is completed.
  bool get isCompleted => status == OrderStatus.completed;

  /// Returns the total item count across all items.
  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  KitchenTicket copyWith({
    String? id,
    String? orderNumber,
    OrderType? orderType,
    OrderStatus? status,
    String? tableNumber,
    String? customerName,
    DateTime? createdAt,
    List<KitchenTicketItem>? items,
    int? elapsedSeconds,
  }) =>
      KitchenTicket(
        id: id ?? this.id,
        orderNumber: orderNumber ?? this.orderNumber,
        orderType: orderType ?? this.orderType,
        status: status ?? this.status,
        tableNumber: tableNumber ?? this.tableNumber,
        customerName: customerName ?? this.customerName,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );

  @override
  List<Object?> get props =>
      [id, orderNumber, orderType, status, tableNumber, customerName, createdAt, items, elapsedSeconds];
}

/// A single item in a kitchen ticket.
class KitchenTicketItem extends Equatable {
  final String id;
  final String productName;
  final int quantity;
  final String? variantName;
  final String? notes;
  final String? categoryName;
  final bool isKitchenItem;

  const KitchenTicketItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.variantName,
    this.notes,
    this.categoryName,
    this.isKitchenItem = true,
  });

  KitchenTicketItem copyWith({
    String? id,
    String? productName,
    int? quantity,
    String? variantName,
    String? notes,
    String? categoryName,
    bool? isKitchenItem,
  }) =>
      KitchenTicketItem(
        id: id ?? this.id,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        variantName: variantName ?? this.variantName,
        notes: notes ?? this.notes,
        categoryName: categoryName ?? this.categoryName,
        isKitchenItem: isKitchenItem ?? this.isKitchenItem,
      );

  @override
  List<Object?> get props =>
      [id, productName, quantity, variantName, notes, categoryName, isKitchenItem];
}
