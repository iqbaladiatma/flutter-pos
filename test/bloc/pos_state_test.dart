import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/features/pos/presentation/bloc/pos_event.dart';
import 'package:pos_flutter/features/pos/presentation/bloc/pos_state.dart';
import 'package:pos_flutter/shared/models/order_model.dart';
import 'package:pos_flutter/shared/models/product_model.dart';

void main() {
  group('PosState transitions (unit-level)', () {
    test('PosInitial has empty props', () {
      const state = PosInitial();
      expect(state.props, isEmpty);
    });

    test('PosLoading has empty props', () {
      const state = PosLoading();
      expect(state.props, isEmpty);
    });

    test('PosLoaded copyWith preserves values', () {
      const state = PosLoaded(
        categories: [],
        products: [],
        cart: [],
      );
      final updated = state.copyWith(
        selectedCategoryId: 'cat-1',
      );
      expect(updated.selectedCategoryId, equals('cat-1'));
      expect(updated.categories, equals(state.categories));
    });

    test('PosLoaded copyWith clearDiscount resets discount', () {
      const state = PosLoaded(
        categories: [],
        products: [],
        cart: [],
        discountType: 'percentage',
        discountValue: 10,
      );
      final updated = state.copyWith(clearDiscount: true);
      expect(updated.discountType, isNull);
      expect(updated.discountValue, equals(0));
    });

    test('PosError stores message', () {
      const state = PosError('Test error');
      expect(state.message, equals('Test error'));
      expect(state.props, equals(['Test error']));
    });
  });

  group('PosEvent props', () {
    test('PosLoadCatalog has empty props', () {
      const event = PosLoadCatalog();
      expect(event.props, isEmpty);
    });

    test('PosAddToCart stores product', () {
      const product = ProductModel(
        id: 'p1',
        categoryId: 'c1',
        name: 'Test',
        slug: 'test',
        basePrice: 10000,
      );
      const event = PosAddToCart(product: product);
      expect(event.product.id, equals('p1'));
    });

    test('PosApplyDiscount stores type and value', () {
      const event = PosApplyDiscount(type: 'percentage', value: 15);
      expect(event.type, equals('percentage'));
      expect(event.value, equals(15));
    });

    test('PosSetOrderType stores order type', () {
      const event = PosSetOrderType(OrderType.delivery);
      expect(event.orderType, equals(OrderType.delivery));
    });
  });
}
