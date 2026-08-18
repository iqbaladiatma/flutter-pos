import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/printer/thermal_printer_service.dart';
import '../../../../shared/models/order_model.dart';
import '../../domain/repositories/pos_repository.dart';
import 'pos_event.dart';
import 'pos_state.dart';

/// BLoC that manages all POS screen state: catalog loading, cart
/// management, discounts, split payments, and order processing.
class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository _repository;
  final ThermalPrinterService _printerService;
  final Uuid _uuid;

  PosBloc({
    required PosRepository repository,
    ThermalPrinterService? printerService,
    Uuid? uuid,
  })  : _repository = repository,
        _printerService = printerService ?? ThermalPrinterService(),
        _uuid = uuid ?? const Uuid(),
        super(const PosInitial()) {
    on<PosLoadCatalog>(_onLoadCatalog);
    on<PosFilterByCategory>(_onFilterByCategory);
    on<PosSetOrderType>(_onSetOrderType);
    on<PosSetTable>(_onSetTable);
    on<PosAddToCart>(_onAddToCart);
    on<PosUpdateCartItemNotes>(_onUpdateCartItemNotes);
    on<PosChangeCartQty>(_onChangeCartQty);
    on<PosRemoveFromCart>(_onRemoveFromCart);
    on<PosClearCart>(_onClearCart);
    on<PosApplyDiscount>(_onApplyDiscount);
    on<PosApplyCoupon>(_onApplyCoupon);
    on<PosClearDiscount>(_onClearDiscount);
    on<PosAddPayment>(_onAddPayment);
    on<PosRemovePayment>(_onRemovePayment);
    on<PosProcessPayment>(_onProcessPayment);
    on<PosDismissSuccess>(_onDismissSuccess);
  }

  Future<void> _onLoadCatalog(
    PosLoadCatalog event,
    Emitter<PosState> emit,
  ) async {
    emit(const PosLoading());

    final catResult = await _repository.getCategories();
    final prodResult = await _repository.getProducts();

    catResult.fold(
      ifLeft: (failure) => emit(PosError(failure.message)),
      ifRight: (categories) {
        prodResult.fold(
          ifLeft: (failure) => emit(PosError(failure.message)),
          ifRight: (products) => emit(PosLoaded(
            categories: categories,
            products: products,
            cart: const [],
          )),
        );
      },
    );
  }

  Future<void> _onFilterByCategory(
    PosFilterByCategory event,
    Emitter<PosState> emit,
  ) async {
    final current = state;
    if (current is! PosLoaded) return;

    final result = await _repository.getProducts(categoryId: event.categoryId);

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        errorMessage: failure.message,
        clearError: false,
      )),
      ifRight: (products) => emit(current.copyWith(
        products: products,
        selectedCategoryId: event.categoryId,
        clearError: true,
      )),
    );
  }

  void _onSetOrderType(PosSetOrderType event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(
      orderType: event.orderType,
      clearTable: event.orderType != OrderType.dineIn,
    ));
  }

  void _onSetTable(PosSetTable event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(tableId: event.tableId, tableName: event.tableName));
  }

  void _onAddToCart(PosAddToCart event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;

    final product = event.product;
    final cart = List<CartItem>.from(current.cart);

    // Generate a unique cart item ID (allows same product with different variants)
    final cartItemId = _uuid.v4();

    cart.add(CartItem(
      id: cartItemId,
      productId: product.id,
      name: product.name,
      basePrice: product.basePrice,
      qty: 1,
      variantId: event.variantId,
      variantName: event.variantName,
      variantPriceAdjustment: event.variantPriceAdjustment ?? 0,
      modifiers: event.modifiers,
      notes: event.notes,
    ));

    emit(current.copyWith(cart: cart));
  }

  void _onUpdateCartItemNotes(
    PosUpdateCartItemNotes event,
    Emitter<PosState> emit,
  ) {
    final current = state;
    if (current is! PosLoaded) return;

    final cart = List<CartItem>.from(current.cart);
    final index = cart.indexWhere((item) => item.id == event.cartItemId);
    if (index < 0) return;

    cart[index] = cart[index].copyWith(notes: event.notes);
    emit(current.copyWith(cart: cart));
  }

  void _onChangeCartQty(PosChangeCartQty event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;

    final cart = List<CartItem>.from(current.cart);
    final index = cart.indexWhere((item) => item.id == event.cartItemId);
    if (index < 0) return;

    final newQty = cart[index].qty + event.delta;
    if (newQty <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(qty: newQty);
    }

    emit(current.copyWith(cart: cart));
  }

  void _onRemoveFromCart(PosRemoveFromCart event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;

    final cart = List<CartItem>.from(current.cart);
    cart.removeWhere((item) => item.id == event.cartItemId);
    emit(current.copyWith(cart: cart));
  }

  void _onClearCart(PosClearCart event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(
      cart: [],
      payments: [],
      clearDiscount: true,
    ));
  }

  void _onApplyDiscount(PosApplyDiscount event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(
      discountType: event.type,
      discountValue: event.value,
    ));
  }

  Future<void> _onApplyCoupon(
    PosApplyCoupon event,
    Emitter<PosState> emit,
  ) async {
    final current = state;
    if (current is! PosLoaded || current.isCartEmpty) return;

    // TODO: Validate coupon via repository when coupon API is available.
    // For now, just store the code and compute a placeholder discount.
    // In production, this would call _repository.validateCoupon(code).
    emit(current.copyWith(
      appliedCouponCode: event.couponCode,
      couponDiscountAmount: 0, // Will be computed when coupon API exists
    ));
  }

  void _onClearDiscount(PosClearDiscount event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(clearDiscount: true));
  }

  void _onAddPayment(PosAddPayment event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;

    final payments = List<PaymentEntry>.from(current.payments);
    payments.add(event.payment);
    emit(current.copyWith(payments: payments));
  }

  void _onRemovePayment(PosRemovePayment event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;

    final payments = List<PaymentEntry>.from(current.payments);
    if (event.index >= 0 && event.index < payments.length) {
      payments.removeAt(event.index);
    }
    emit(current.copyWith(payments: payments));
  }

  Future<void> _onProcessPayment(
    PosProcessPayment event,
    Emitter<PosState> emit,
  ) async {
    final current = state;
    if (current is! PosLoaded || current.isCartEmpty) return;

    emit(current.copyWith(isProcessingPayment: true));

    final cartItems = current.cart.map((item) => item.toMap()).toList();

    // Determine payment method for receipt
    String paymentMethod;
    if (event.payments.isNotEmpty) {
      paymentMethod =
          event.payments.length > 1 ? 'split' : event.payments.first.method;
    } else {
      paymentMethod = event.singlePaymentMethod;
    }

    // Calculate change for cash payment
    double changeAmount = 0;
    if (paymentMethod == 'cash' && event.cashReceived != null) {
      changeAmount = (event.cashReceived! - current.grandTotal).clamp(0, double.infinity);
    }

    final result = await _repository.createOrder(
      outletId: event.outletId,
      tableId: event.tableId,
      orderType: event.orderType,
      subtotal: current.cartTotal,
      total: current.grandTotal,
      items: cartItems,
    );

    await result.fold(
      ifLeft: (failure) async {
        emit(current.copyWith(
          isProcessingPayment: false,
          errorMessage: failure.message,
        ));
      },
      ifRight: (order) async {
        // Print receipt
        try {
          await _printerService.printReceipt(
            orderNumber: order.orderNumber,
            outletName: 'PostSA Outlet',
            items: cartItems,
            subtotal: current.cartTotal,
            discount: current.totalDiscount,
            tax: current.taxAmount,
            total: current.grandTotal,
            paymentMethod: paymentMethod,
            paidAmount: event.cashReceived ?? current.grandTotal,
            changeAmount: changeAmount,
          );
        } catch (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('Print error (non-fatal): $e');
          }
        }

        // Print kitchen ticket
        try {
          final kitchenItems = cartItems.map((item) => {
                'qty': item['quantity'],
                'name': item['product_name'],
                'note': item['notes'],
              }).toList();
          await _printerService.printKitchenLabel(
            orderNumber: order.orderNumber,
            orderType: event.orderType.name,
            kitchenItems: kitchenItems,
            tableNumber: current.tableName,
          );
        } catch (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('Kitchen print error (non-fatal): $e');
          }
        }

        emit(current.copyWith(
          cart: [],
          payments: [],
          isProcessingPayment: false,
          lastCompletedOrder: order,
          clearDiscount: true,
          clearTable: true,
        ));
      },
    );
  }

  void _onDismissSuccess(PosDismissSuccess event, Emitter<PosState> emit) {
    final current = state;
    if (current is! PosLoaded) return;
    emit(current.copyWith(clearLastOrder: true));
  }
}
