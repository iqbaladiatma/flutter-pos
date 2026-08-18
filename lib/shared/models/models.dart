// Barrel file for all Supabase data models.
// Import this single file instead of importing each model individually:
//   import 'package:pos_flutter/shared/models/models.dart';

// ── Tenant & Outlet ──────────────────────────────────────────────────
export 'organization_model.dart';
export 'outlet_model.dart';
export 'table_model.dart';

// ── Staff & Shift ────────────────────────────────────────────────────
export 'staff_shift_model.dart'; // StaffModel, CashierShiftModel, BannerModel, OutletPrinterModel
export 'staff_outlet_model.dart';

// ── Catalog & Menu ───────────────────────────────────────────────────
export 'product_model.dart'; // CategoryModel, ProductVariantModel, ModifierModel, ProductModel
export 'modifier_group_model.dart';
export 'product_modifier_group_model.dart';
export 'menu_bundle_model.dart';

// ── Orders & Payments ────────────────────────────────────────────────
export 'order_model.dart'; // OrderItemModel, OrderModel, OrderType, OrderStatus, PaymentMethod
export 'order_item_modifier_model.dart';
export 'order_payment_model.dart';
export 'order_status_log_model.dart';
export 'coupon_model.dart';

// ── Loyalty & Customer ───────────────────────────────────────────────
export 'customer_loyalty_model.dart'; // CustomerModel, LoyaltyTierModel, ChallengeModel
export 'point_transaction_model.dart';
export 'customer_challenge_model.dart';
export 'reward_model.dart';
export 'customer_redemption_model.dart';

// ── Delivery & Driver ────────────────────────────────────────────────
export 'delivery_model.dart'; // DeliveryZoneModel, DeliveryAddressModel, DeliveryModel, DriverModel
export 'delivery_assignment_model.dart';
export 'delivery_log_model.dart';

// ── Aux ──────────────────────────────────────────────────────────────
export 'otp_code_model.dart';
