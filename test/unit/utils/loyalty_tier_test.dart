import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/shared/models/customer_loyalty_model.dart';

void main() {
  group('Loyalty tier logic', () {
    final tiers = [
      const LoyaltyTierModel(
          id: 'bronze',
          name: 'Bronze',
          minLifetimePoints: 0,
          earningRate: 1.0,
          color: '#CD7F32'),
      const LoyaltyTierModel(
          id: 'silver',
          name: 'Silver',
          minLifetimePoints: 500,
          earningRate: 1.2,
          color: '#C0C0C0'),
      const LoyaltyTierModel(
          id: 'gold',
          name: 'Gold',
          minLifetimePoints: 1000,
          earningRate: 1.5,
          color: '#FFD700'),
      const LoyaltyTierModel(
          id: 'platinum',
          name: 'Platinum',
          minLifetimePoints: 5000,
          earningRate: 2.0,
          color: '#E5E4E2'),
    ];

    LoyaltyTierModel getTierForPoints(int lifetimePoints) {
      LoyaltyTierModel result = tiers.first;
      for (final tier in tiers) {
        if (lifetimePoints >= tier.minLifetimePoints) {
          result = tier;
        }
      }
      return result;
    }

    test('0 points → Bronze', () {
      final tier = getTierForPoints(0);
      expect(tier.name, equals('Bronze'));
    });

    test('499 points → Bronze', () {
      final tier = getTierForPoints(499);
      expect(tier.name, equals('Bronze'));
    });

    test('500 points → Silver', () {
      final tier = getTierForPoints(500);
      expect(tier.name, equals('Silver'));
    });

    test('999 points → Silver', () {
      final tier = getTierForPoints(999);
      expect(tier.name, equals('Silver'));
    });

    test('1000 points → Gold', () {
      final tier = getTierForPoints(1000);
      expect(tier.name, equals('Gold'));
    });

    test('4999 points → Gold', () {
      final tier = getTierForPoints(4999);
      expect(tier.name, equals('Gold'));
    });

    test('5000 points → Platinum', () {
      final tier = getTierForPoints(5000);
      expect(tier.name, equals('Platinum'));
    });

    test('10000 points → Platinum', () {
      final tier = getTierForPoints(10000);
      expect(tier.name, equals('Platinum'));
    });

    test('earning rate increases with tier', () {
      for (var i = 0; i < tiers.length - 1; i++) {
        expect(tiers[i].earningRate, lessThan(tiers[i + 1].earningRate));
      }
    });

    test('minLifetimePoints increases with tier', () {
      for (var i = 0; i < tiers.length - 1; i++) {
        expect(tiers[i].minLifetimePoints,
            lessThan(tiers[i + 1].minLifetimePoints));
      }
    });
  });

  group('CustomerModel points', () {
    test('totalPoints and lifetimePoints are independent', () {
      const customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '08123',
        totalPoints: 100,
        lifetimePoints: 500,
      );
      expect(customer.totalPoints, equals(100));
      expect(customer.lifetimePoints, equals(500));
    });

    test('totalPoints can be 0 while lifetimePoints > 0 (all redeemed)', () {
      const customer = CustomerModel(
        id: 'c1',
        name: 'Test',
        phone: '08123',
        totalPoints: 0,
        lifetimePoints: 1000,
      );
      expect(customer.totalPoints, equals(0));
      expect(customer.lifetimePoints, equals(1000));
    });
  });
}
