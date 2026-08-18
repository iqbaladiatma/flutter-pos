import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/features/pos/presentation/bloc/pos_event.dart';
import 'package:pos_flutter/features/pos/presentation/bloc/pos_state.dart';

void main() {
  group('CartItem calculations', () {
    test('unitPrice = basePrice with no modifiers or variant', () {
      const item = CartItem(
        id: '1',
        productId: 'p1',
        name: 'Coffee',
        basePrice: 25000,
        qty: 2,
      );
      expect(item.unitPrice, equals(25000));
      expect(item.subtotal, equals(50000));
    });

    test('unitPrice includes variant price adjustment', () {
      const item = CartItem(
        id: '1',
        productId: 'p1',
        name: 'Coffee',
        basePrice: 25000,
        qty: 1,
        variantPriceAdjustment: 5000,
      );
      expect(item.unitPrice, equals(30000));
      expect(item.subtotal, equals(30000));
    });

    test('unitPrice includes modifier price adjustments', () {
      const item = CartItem(
        id: '1',
        productId: 'p1',
        name: 'Coffee',
        basePrice: 25000,
        qty: 1,
        modifiers: [
          CartItemModifier(
              modifierId: 'm1', name: 'Extra Shot', priceAdjustment: 5000),
          CartItemModifier(
              modifierId: 'm2', name: 'Whipped Cream', priceAdjustment: 3000),
        ],
      );
      expect(item.unitPrice, equals(33000));
      expect(item.subtotal, equals(33000));
    });

    test('unitPrice includes modifier quantity', () {
      const item = CartItem(
        id: '1',
        productId: 'p1',
        name: 'Coffee',
        basePrice: 25000,
        qty: 1,
        modifiers: [
          CartItemModifier(
              modifierId: 'm1',
              name: 'Extra Shot',
              priceAdjustment: 5000,
              quantity: 2),
        ],
      );
      // 25000 + (5000 * 2) = 35000
      expect(item.unitPrice, equals(35000));
    });

    test('unitPrice includes both variant and modifiers', () {
      const item = CartItem(
        id: '1',
        productId: 'p1',
        name: 'Coffee',
        basePrice: 25000,
        qty: 3,
        variantPriceAdjustment: 5000,
        modifiers: [
          CartItemModifier(
              modifierId: 'm1', name: 'Extra Shot', priceAdjustment: 5000),
        ],
      );
      // unitPrice = 25000 + 5000 + 5000 = 35000
      // subtotal = 35000 * 3 = 105000
      expect(item.unitPrice, equals(35000));
      expect(item.subtotal, equals(105000));
    });
  });

  group('PosLoaded calculations', () {
    PosLoaded makeLoaded({
      List<CartItem> cart = const [],
      String? discountType,
      double discountValue = 0,
      double couponDiscountAmount = 0,
    }) =>
        PosLoaded(
          categories: const [],
          products: const [],
          cart: cart,
          discountType: discountType,
          discountValue: discountValue,
          couponDiscountAmount: couponDiscountAmount,
        );

    CartItem item(double price, int qty) => CartItem(
          id: '${price}_$qty',
          productId: 'p',
          name: 'Item',
          basePrice: price,
          qty: qty,
        );

    test('cartTotal sums all item subtotals', () {
      final loaded = makeLoaded(cart: [
        item(25000, 2), // 50000
        item(15000, 1), // 15000
      ]);
      expect(loaded.cartTotal, equals(65000));
    });

    test('cartTotal is 0 for empty cart', () {
      final loaded = makeLoaded();
      expect(loaded.cartTotal, equals(0));
    });

    test('discountAmount with percentage type', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'percentage',
        discountValue: 10,
      );
      expect(loaded.discountAmount, equals(10000));
    });

    test('discountAmount with nominal type', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'nominal',
        discountValue: 15000,
      );
      expect(loaded.discountAmount, equals(15000));
    });

    test('discountAmount is 0 when no discount', () {
      final loaded = makeLoaded(cart: [item(100000, 1)]);
      expect(loaded.discountAmount, equals(0));
    });

    test('discountAmount is 0 when value is 0', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'percentage',
        discountValue: 0,
      );
      expect(loaded.discountAmount, equals(0));
    });

    test('totalDiscount = manual + coupon', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'percentage',
        discountValue: 10,
        couponDiscountAmount: 5000,
      );
      // 10% of 100000 = 10000 + 5000 = 15000
      expect(loaded.totalDiscount, equals(15000));
    });

    test('taxAmount = 11% of (cartTotal - totalDiscount)', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'nominal',
        discountValue: 10000,
      );
      // (100000 - 10000) * 0.11 = 9900
      expect(loaded.taxAmount, closeTo(9900, 0.01));
    });

    test('grandTotal = cartTotal - totalDiscount + tax', () {
      final loaded = makeLoaded(
        cart: [item(100000, 1)],
        discountType: 'nominal',
        discountValue: 10000,
      );
      // 100000 - 10000 + 9900 = 99900
      expect(loaded.grandTotal, closeTo(99900, 0.01));
    });

    test('grandTotal with no discount', () {
      final loaded = makeLoaded(cart: [item(100000, 1)]);
      // 100000 + 11000 = 111000
      expect(loaded.grandTotal, closeTo(111000, 0.01));
    });

    test('remainingToPay with split payments', () {
      final loaded = PosLoaded(
        categories: const [],
        products: const [],
        cart: [item(100000, 1)],
        payments: const [
          PaymentEntry(method: 'cash', amount: 50000),
          PaymentEntry(method: 'qris', amount: 30000),
        ],
      );
      // grandTotal = 111000, paid = 80000, remaining = 31000
      expect(loaded.totalPaid, equals(80000));
      expect(loaded.remainingToPay, closeTo(31000, 0.01));
      expect(loaded.isFullyPaid, isFalse);
    });

    test('isFullyPaid when payments cover grandTotal', () {
      final loaded = PosLoaded(
        categories: const [],
        products: const [],
        cart: [item(100000, 1)],
        payments: const [
          PaymentEntry(method: 'cash', amount: 111000),
        ],
      );
      expect(loaded.isFullyPaid, isTrue);
    });
  });
}
