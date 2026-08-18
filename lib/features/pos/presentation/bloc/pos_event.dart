import 'package:equatable/equatable.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/product_model.dart';

/// Cart item representation used by the POS BLoC.
///
/// Supports variants, modifiers, notes, and bundle components.
class CartItem extends Equatable {
  final String id;
  final String productId;
  final String name;
  final double basePrice;
  final int qty;
  final String? variantId;
  final String? variantName;
  final double variantPriceAdjustment;
  final List<CartItemModifier> modifiers;
  final String? notes;
  final bool isBundle;
  final List<CartItem> bundleItems;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.basePrice,
    required this.qty,
    this.variantId,
    this.variantName,
    this.variantPriceAdjustment = 0,
    this.modifiers = const [],
    this.notes,
    this.isBundle = false,
    this.bundleItems = const [],
  });

  /// Unit price = base + variant adjustment + sum of modifiers.
  double get unitPrice =>
      basePrice +
      variantPriceAdjustment +
      modifiers.fold(0, (sum, m) => sum + m.priceAdjustment * m.quantity);

  /// Line total = unit price * qty.
  double get subtotal => unitPrice * qty;

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? basePrice,
    int? qty,
    String? variantId,
    String? variantName,
    double? variantPriceAdjustment,
    List<CartItemModifier>? modifiers,
    String? notes,
    bool? isBundle,
    List<CartItem>? bundleItems,
  }) =>
      CartItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        name: name ?? this.name,
        basePrice: basePrice ?? this.basePrice,
        qty: qty ?? this.qty,
        variantId: variantId ?? this.variantId,
        variantName: variantName ?? this.variantName,
        variantPriceAdjustment:
            variantPriceAdjustment ?? this.variantPriceAdjustment,
        modifiers: modifiers ?? this.modifiers,
        notes: notes ?? this.notes,
        isBundle: isBundle ?? this.isBundle,
        bundleItems: bundleItems ?? this.bundleItems,
      );

  /// Converts to a map for Supabase `order_items` insert.
  Map<String, dynamic> toMap() => {
        'product_id': productId,
        'product_name': name,
        'variant_id': variantId,
        'variant_name': variantName,
        'quantity': qty,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'notes': notes,
        'modifiers': modifiers.map((m) => m.toMap()).toList(),
      };

  @override
  List<Object?> get props =>
      [id, productId, name, basePrice, qty, variantId, variantName, variantPriceAdjustment, modifiers, notes, isBundle, bundleItems];
}

/// Modifier selected for a cart item.
class CartItemModifier extends Equatable {
  final String modifierId;
  final String name;
  final double priceAdjustment;
  final int quantity;

  const CartItemModifier({
    required this.modifierId,
    required this.name,
    this.priceAdjustment = 0,
    this.quantity = 1,
  });

  CartItemModifier copyWith({
    String? modifierId,
    String? name,
    double? priceAdjustment,
    int? quantity,
  }) =>
      CartItemModifier(
        modifierId: modifierId ?? this.modifierId,
        name: name ?? this.name,
        priceAdjustment: priceAdjustment ?? this.priceAdjustment,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap() => {
        'modifier_id': modifierId,
        'modifier_name': name,
        'price_adjustment': priceAdjustment,
        'quantity': quantity,
      };

  @override
  List<Object?> get props =>
      [modifierId, name, priceAdjustment, quantity];
}

/// Represents one payment in a split-bill scenario.
class PaymentEntry extends Equatable {
  final String method; // cash, qris, bank_transfer, ewallet, card
  final double amount;
  final double? paidAmount; // for cash: amount received
  final double? changeAmount;

  const PaymentEntry({
    required this.method,
    required this.amount,
    this.paidAmount,
    this.changeAmount,
  });

  PaymentEntry copyWith({
    String? method,
    double? amount,
    double? paidAmount,
    double? changeAmount,
  }) =>
      PaymentEntry(
        method: method ?? this.method,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        changeAmount: changeAmount ?? this.changeAmount,
      );

  @override
  List<Object?> get props => [method, amount, paidAmount, changeAmount];
}

/// All events that the POS BLoC can handle.
abstract class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

/// Load categories and all products on screen entry.
class PosLoadCatalog extends PosEvent {
  const PosLoadCatalog();
}

/// Filter products by category. Empty string = all categories.
class PosFilterByCategory extends PosEvent {
  final String categoryId;
  const PosFilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Set the order type (dine-in, takeaway, delivery).
class PosSetOrderType extends PosEvent {
  final OrderType orderType;
  const PosSetOrderType(this.orderType);

  @override
  List<Object?> get props => [orderType];
}

/// Set the table for dine-in orders.
class PosSetTable extends PosEvent {
  final String? tableId;
  final String? tableName;
  const PosSetTable({this.tableId, this.tableName});

  @override
  List<Object?> get props => [tableId, tableName];
}

/// Add a product to the cart (with optional variant + modifiers).
class PosAddToCart extends PosEvent {
  final ProductModel product;
  final String? variantId;
  final String? variantName;
  final double? variantPriceAdjustment;
  final List<CartItemModifier> modifiers;
  final String? notes;

  const PosAddToCart({
    required this.product,
    this.variantId,
    this.variantName,
    this.variantPriceAdjustment,
    this.modifiers = const [],
    this.notes,
  });

  @override
  List<Object?> get props =>
      [product, variantId, variantName, variantPriceAdjustment, modifiers, notes];
}

/// Update notes for a specific cart item.
class PosUpdateCartItemNotes extends PosEvent {
  final String cartItemId;
  final String notes;
  const PosUpdateCartItemNotes({required this.cartItemId, required this.notes});

  @override
  List<Object?> get props => [cartItemId, notes];
}

/// Change quantity of a cart item (removes if qty reaches 0).
class PosChangeCartQty extends PosEvent {
  final String cartItemId;
  final int delta; // +1 or -1
  const PosChangeCartQty({required this.cartItemId, required this.delta});

  @override
  List<Object?> get props => [cartItemId, delta];
}

/// Remove a cart item entirely.
class PosRemoveFromCart extends PosEvent {
  final String cartItemId;
  const PosRemoveFromCart(this.cartItemId);

  @override
  List<Object?> get props => [cartItemId];
}

/// Clear the entire cart.
class PosClearCart extends PosEvent {
  const PosClearCart();
}

/// Apply a discount (percentage or nominal).
class PosApplyDiscount extends PosEvent {
  final String type; // 'percentage' or 'nominal'
  final double value;
  const PosApplyDiscount({required this.type, required this.value});

  @override
  List<Object?> get props => [type, value];
}

/// Apply a coupon code.
class PosApplyCoupon extends PosEvent {
  final String couponCode;
  const PosApplyCoupon(this.couponCode);

  @override
  List<Object?> get props => [couponCode];
}

/// Clear any applied discount/coupon.
class PosClearDiscount extends PosEvent {
  const PosClearDiscount();
}

/// Add a payment entry (for split bill).
class PosAddPayment extends PosEvent {
  final PaymentEntry payment;
  const PosAddPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

/// Remove a payment entry (for split bill).
class PosRemovePayment extends PosEvent {
  final int index;
  const PosRemovePayment(this.index);

  @override
  List<Object?> get props => [index];
}

/// Process payment: create order in Supabase + print receipt.
/// If [payments] is empty, uses [singlePaymentMethod] for the full amount.
class PosProcessPayment extends PosEvent {
  final String outletId;
  final OrderType orderType;
  final String? tableId;
  final List<PaymentEntry> payments;
  final String singlePaymentMethod;
  final double? cashReceived; // for cash payment change calculation

  const PosProcessPayment({
    required this.outletId,
    this.orderType = OrderType.dineIn,
    this.tableId,
    this.payments = const [],
    this.singlePaymentMethod = 'cash',
    this.cashReceived,
  });

  @override
  List<Object?> get props =>
      [outletId, orderType, tableId, payments, singlePaymentMethod, cashReceived];
}

/// Dismiss the success dialog and reset `lastCompletedOrder`.
class PosDismissSuccess extends PosEvent {
  const PosDismissSuccess();
}
