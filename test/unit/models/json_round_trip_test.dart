import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/shared/models/product_model.dart';
import 'package:pos_flutter/shared/models/table_model.dart';
import 'package:pos_flutter/shared/models/customer_loyalty_model.dart';
import 'package:pos_flutter/shared/models/customer_challenge_model.dart';
import 'package:pos_flutter/shared/models/point_transaction_model.dart';
import 'package:pos_flutter/shared/models/reward_model.dart';
import 'package:pos_flutter/shared/models/customer_redemption_model.dart';
import 'package:pos_flutter/shared/models/coupon_model.dart';
import 'package:pos_flutter/shared/models/delivery_model.dart';
import 'package:pos_flutter/shared/models/delivery_assignment_model.dart';
import 'package:pos_flutter/shared/models/delivery_log_model.dart';
import 'package:pos_flutter/shared/models/organization_model.dart';
import 'package:pos_flutter/shared/models/otp_code_model.dart';
import 'package:pos_flutter/shared/models/outlet_model.dart';
import 'package:pos_flutter/shared/models/staff_outlet_model.dart';
import 'package:pos_flutter/shared/models/staff_shift_model.dart';

void main() {
  group('JSON round-trip tests', () {
    test('CategoryModel round-trip', () {
      const original = CategoryModel(
        id: 'cat-1',
        name: 'Beverages',
        slug: 'beverages',
        isKitchen: false,
        isActive: true,
      );
      final json = original.toJson();
      final restored = CategoryModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.slug, equals(original.slug));
    });

    test('ProductModel round-trip', () {
      const original = ProductModel(
        id: 'prod-1',
        categoryId: 'cat-1',
        name: 'Espresso',
        slug: 'espresso',
        basePrice: 25000,
        isActive: true,
        description: 'Strong coffee',
      );
      final json = original.toJson();
      final restored = ProductModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.basePrice, equals(original.basePrice));
    });

    test('ProductVariantModel round-trip', () {
      const original = ProductVariantModel(
        id: 'var-1',
        name: 'Large',
        priceAdjustment: 5000,
        isDefault: false,
      );
      final json = original.toJson();
      final restored = ProductVariantModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.priceAdjustment, equals(original.priceAdjustment));
    });

    test('TableModel round-trip', () {
      final original = TableModel(
        id: 'tbl-1',
        outletId: 'outlet-1',
        name: 'Table 5',
        capacity: 4,
        status: TableStatus.available,
      );
      final json = original.toJson();
      final restored = TableModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.capacity, equals(original.capacity));
    });

    test('CustomerModel round-trip', () {
      const original = CustomerModel(
        id: 'cust-1',
        name: 'John Doe',
        phone: '08123456789',
        email: 'john@example.com',
        totalPoints: 500,
        lifetimePoints: 1500,
      );
      final json = original.toJson();
      final restored = CustomerModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.totalPoints, equals(original.totalPoints));
      expect(restored.lifetimePoints, equals(original.lifetimePoints));
    });

    test('LoyaltyTierModel round-trip', () {
      const original = LoyaltyTierModel(
        id: 'tier-1',
        name: 'Gold',
        minLifetimePoints: 1000,
        earningRate: 1.5,
        color: '#FFD700',
      );
      final json = original.toJson();
      final restored = LoyaltyTierModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.minLifetimePoints, equals(original.minLifetimePoints));
      expect(restored.earningRate, equals(original.earningRate));
    });

    test('ChallengeModel round-trip', () {
      const original = ChallengeModel(
        id: 'chal-1',
        name: 'Buy 5 Get Reward',
        description: 'Buy 5 coffees',
        type: 'stamp_card',
        targetCount: 5,
        rewardValue: 100,
      );
      final json = original.toJson();
      final restored = ChallengeModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.targetCount, equals(original.targetCount));
    });

    test('CustomerChallengeModel round-trip', () {
      const original = CustomerChallengeModel(
        id: 'cc-1',
        customerId: 'cust-1',
        challengeId: 'chal-1',
        progressCount: 3,
        isCompleted: false,
        createdAt: '2026-01-01T00:00:00Z',
      );
      final json = original.toJson();
      final restored = CustomerChallengeModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.progressCount, equals(original.progressCount));
      expect(restored.isCompleted, equals(original.isCompleted));
    });

    test('PointTransactionModel round-trip', () {
      const original = PointTransactionModel(
        id: 'pt-1',
        customerId: 'cust-1',
        points: 50,
        type: 'earn',
        description: 'Purchase order #123',
        orderId: 'order-123',
        createdAt: '2026-08-17T10:00:00Z',
      );
      final json = original.toJson();
      final restored = PointTransactionModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.points, equals(original.points));
      expect(restored.type, equals(original.type));
    });

    test('RewardModel round-trip', () {
      const original = RewardModel(
        id: 'rew-1',
        name: 'Free Coffee',
        type: 'free_product',
        pointsCost: 100,
        isActive: true,
      );
      final json = original.toJson();
      final restored = RewardModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.pointsCost, equals(original.pointsCost));
    });

    test('CustomerRedemptionModel round-trip', () {
      const original = CustomerRedemptionModel(
        id: 'red-1',
        customerId: 'cust-1',
        rewardId: 'rew-1',
        rewardName: 'Free Coffee',
        voucherCode: 'VC001',
        redeemedAt: '2026-08-17T10:00:00Z',
      );
      final json = original.toJson();
      final restored = CustomerRedemptionModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.customerId, equals(original.customerId));
      expect(restored.voucherCode, equals(original.voucherCode));
    });

    test('CouponModel round-trip', () {
      const original = CouponModel(
        id: 'cpn-1',
        code: 'DISC10',
        discountType: 'percentage',
        discountValue: 10,
      );
      final json = original.toJson();
      final restored = CouponModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.code, equals(original.code));
      expect(restored.discountValue, equals(original.discountValue));
    });

    test('DeliveryModel round-trip', () {
      const original = DeliveryModel(
        id: 'del-1',
        orderId: 'order-1',
        outletId: 'outlet-1',
        recipientName: 'John',
        recipientPhone: '08123456789',
        recipientAddress: 'Jl. Sudirman No. 1',
        shippingFee: 15000,
        status: 'pending',
      );
      final json = original.toJson();
      final restored = DeliveryModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.recipientName, equals(original.recipientName));
      expect(restored.shippingFee, equals(original.shippingFee));
    });

    test('DeliveryAssignmentModel round-trip', () {
      const original = DeliveryAssignmentModel(
        id: 'asg-1',
        deliveryId: 'del-1',
        driverId: 'drv-1',
        status: 'pending',
        assignedAt: '2026-08-17T10:00:00Z',
      );
      final json = original.toJson();
      final restored = DeliveryAssignmentModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.deliveryId, equals(original.deliveryId));
      expect(restored.status, equals(original.status));
    });

    test('DeliveryLogModel round-trip', () {
      const original = DeliveryLogModel(
        id: 'log-1',
        deliveryId: 'del-1',
        status: 'picked_up',
        notes: 'Package picked up',
        loggedAt: '2026-08-17T10:30:00Z',
      );
      final json = original.toJson();
      final restored = DeliveryLogModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.status, equals(original.status));
    });

    test('OutletModel round-trip', () {
      final original = OutletModel(
        id: 'outlet-1',
        organizationId: 'org-1',
        name: 'Outlet Jakarta',
        slug: 'outlet-jakarta',
        address: 'Jl. Sudirman',
        phone: '021123456',
        isActive: true,
      );
      final json = original.toJson();
      final restored = OutletModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
    });

    test('OrganizationModel round-trip', () {
      final original = OrganizationModel(
        id: 'org-1',
        name: 'PostSA Org',
        slug: 'postsa-org',
        settings: {'key': 'value'},
      );
      final json = original.toJson();
      final restored = OrganizationModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
    });

    test('OtpCodeModel round-trip', () {
      const original = OtpCodeModel(
        id: 'otp-1',
        phone: '08123456789',
        code: '123456',
        isUsed: false,
        createdAt: '2026-08-17T10:00:00Z',
      );
      final json = original.toJson();
      final restored = OtpCodeModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.code, equals(original.code));
      expect(restored.isUsed, equals(original.isUsed));
    });

    test('StaffOutletModel round-trip', () {
      const original = StaffOutletModel(
        id: 'so-1',
        staffId: 'staff-1',
        outletId: 'outlet-1',
        assignedAt: '2026-01-01T00:00:00Z',
      );
      final json = original.toJson();
      final restored = StaffOutletModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.staffId, equals(original.staffId));
    });

    test('StaffModel round-trip', () {
      const original = StaffModel(
        id: 'staff-1',
        name: 'John',
        email: 'john@pos.com',
        role: 'kasir',
        isActive: true,
      );
      final json = original.toJson();
      final restored = StaffModel.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.role, equals(original.role));
    });
  });
}
