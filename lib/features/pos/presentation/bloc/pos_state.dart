import 'package:equatable/equatable.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/product_model.dart';
import 'pos_event.dart';

/// All possible states the POS screen can be in.
sealed class PosState extends Equatable {
  const PosState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class PosInitial extends PosState {
  const PosInitial();
}

/// Loading categories / products.
class PosLoading extends PosState {
  const PosLoading();
}

/// Catalog loaded with categories, products, cart, and payment state.
///
/// [lastCompletedOrder] is set briefly after a successful payment so the
/// UI layer can show a success dialog; it is cleared via [PosDismissSuccess].
class PosLoaded extends PosState {
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<CartItem> cart;
  final String selectedCategoryId;
  final OrderType orderType;
  final String? tableId;
  final String? tableName;
  final String? discountType; // 'percentage' or 'nominal'
  final double discountValue;
  final String? appliedCouponCode;
  final double couponDiscountAmount;
  final List<PaymentEntry> payments;
  final bool isProcessingPayment;
  final OrderModel? lastCompletedOrder;
  final String? errorMessage;

  const PosLoaded({
    required this.categories,
    required this.products,
    required this.cart,
    this.selectedCategoryId = '',
    this.orderType = OrderType.dineIn,
    this.tableId,
    this.tableName,
    this.discountType,
    this.discountValue = 0,
    this.appliedCouponCode,
    this.couponDiscountAmount = 0,
    this.payments = const [],
    this.isProcessingPayment = false,
    this.lastCompletedOrder,
    this.errorMessage,
  });

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + item.subtotal);

  bool get isCartEmpty => cart.isEmpty;

  /// Discount amount calculated from type + value.
  double get discountAmount {
    if (discountType == null || discountValue <= 0) return 0;
    if (discountType == 'percentage') {
      return cartTotal * (discountValue / 100);
    }
    return discountValue; // nominal
  }

  /// Total discount = manual discount + coupon discount.
  double get totalDiscount => discountAmount + couponDiscountAmount;

  /// Tax (11% PPN after discount).
  double get taxAmount => (cartTotal - totalDiscount) * 0.11;

  /// Grand total = cartTotal - discount + tax.
  double get grandTotal => cartTotal - totalDiscount + taxAmount;

  /// Sum of payments already entered (for split bill).
  double get totalPaid =>
      payments.fold(0, (sum, p) => sum + p.amount);

  /// Remaining amount to pay (for split bill).
  double get remainingToPay => grandTotal - totalPaid;

  /// Whether the order is fully paid (split bill complete).
  bool get isFullyPaid => remainingToPay <= 0;

  /// Returns a copy with updated fields.
  PosLoaded copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<CartItem>? cart,
    String? selectedCategoryId,
    OrderType? orderType,
    String? tableId,
    String? tableName,
    String? discountType,
    double? discountValue,
    String? appliedCouponCode,
    double? couponDiscountAmount,
    List<PaymentEntry>? payments,
    bool? isProcessingPayment,
    OrderModel? lastCompletedOrder,
    String? errorMessage,
    bool clearLastOrder = false,
    bool clearError = false,
    bool clearTable = false,
    bool clearDiscount = false,
  }) =>
      PosLoaded(
        categories: categories ?? this.categories,
        products: products ?? this.products,
        cart: cart ?? this.cart,
        selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
        orderType: orderType ?? this.orderType,
        tableId: clearTable ? null : (tableId ?? this.tableId),
        tableName: clearTable ? null : (tableName ?? this.tableName),
        discountType:
            clearDiscount ? null : (discountType ?? this.discountType),
        discountValue: clearDiscount ? 0 : (discountValue ?? this.discountValue),
        appliedCouponCode:
            clearDiscount ? null : (appliedCouponCode ?? this.appliedCouponCode),
        couponDiscountAmount:
            clearDiscount ? 0 : (couponDiscountAmount ?? this.couponDiscountAmount),
        payments: payments ?? this.payments,
        isProcessingPayment:
            isProcessingPayment ?? this.isProcessingPayment,
        lastCompletedOrder:
            clearLastOrder ? null : (lastCompletedOrder ?? this.lastCompletedOrder),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        categories,
        products,
        cart,
        selectedCategoryId,
        orderType,
        tableId,
        tableName,
        discountType,
        discountValue,
        appliedCouponCode,
        couponDiscountAmount,
        payments,
        isProcessingPayment,
        lastCompletedOrder,
        errorMessage,
      ];
}

/// An error occurred.
class PosError extends PosState {
  final String message;

  const PosError(this.message);

  @override
  List<Object?> get props => [message];
}
