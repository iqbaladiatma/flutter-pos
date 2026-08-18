import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

/// Load dashboard analytics for an outlet.
class AdminLoadDashboard extends AdminEvent {
  final String outletId;
  const AdminLoadDashboard({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Load hourly sales chart data.
class AdminLoadHourlyChart extends AdminEvent {
  final String outletId;
  final DateTime date;
  const AdminLoadHourlyChart({
    required this.outletId,
    required this.date,
  });

  @override
  List<Object?> get props => [outletId, date];
}

/// Load payment method breakdown.
class AdminLoadPaymentBreakdown extends AdminEvent {
  final String outletId;
  final DateTime startDate;
  final DateTime endDate;
  const AdminLoadPaymentBreakdown({
    required this.outletId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [outletId, startDate, endDate];
}

/// Load outlet comparison (multi-outlet).
class AdminLoadOutletComparison extends AdminEvent {
  final String organizationId;
  final DateTime startDate;
  final DateTime endDate;
  const AdminLoadOutletComparison({
    required this.organizationId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [organizationId, startDate, endDate];
}

/// Load products for management.
class AdminLoadProducts extends AdminEvent {
  final String outletId;
  const AdminLoadProducts({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Create a new product.
class AdminCreateProduct extends AdminEvent {
  final String outletId;
  final String name;
  final double basePrice;
  final String categoryId;
  final String? description;
  const AdminCreateProduct({
    required this.outletId,
    required this.name,
    required this.basePrice,
    required this.categoryId,
    this.description,
  });

  @override
  List<Object?> get props =>
      [outletId, name, basePrice, categoryId, description];
}

/// Update a product.
class AdminUpdateProduct extends AdminEvent {
  final String productId;
  final String? name;
  final double? basePrice;
  final String? categoryId;
  final String? description;
  final bool? isAvailable;
  const AdminUpdateProduct({
    required this.productId,
    this.name,
    this.basePrice,
    this.categoryId,
    this.description,
    this.isAvailable,
  });

  @override
  List<Object?> get props =>
      [productId, name, basePrice, categoryId, description, isAvailable];
}

/// Delete a product (soft delete).
class AdminDeleteProduct extends AdminEvent {
  final String productId;
  final String outletId;
  const AdminDeleteProduct({
    required this.productId,
    required this.outletId,
  });

  @override
  List<Object?> get props => [productId, outletId];
}

/// Load staff for management.
class AdminLoadStaff extends AdminEvent {
  final String outletId;
  const AdminLoadStaff({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Create a new staff member.
class AdminCreateStaff extends AdminEvent {
  final String outletId;
  final String name;
  final String phone;
  final String role;
  final String? pinHash;
  const AdminCreateStaff({
    required this.outletId,
    required this.name,
    required this.phone,
    required this.role,
    this.pinHash,
  });

  @override
  List<Object?> get props => [outletId, name, phone, role, pinHash];
}

/// Update a staff member.
class AdminUpdateStaff extends AdminEvent {
  final String staffId;
  final String? name;
  final String? phone;
  final String? role;
  final bool? isActive;
  const AdminUpdateStaff({
    required this.staffId,
    this.name,
    this.phone,
    this.role,
    this.isActive,
  });

  @override
  List<Object?> get props => [staffId, name, phone, role, isActive];
}

/// Refresh all dashboard data.
class AdminRefresh extends AdminEvent {
  final String outletId;
  const AdminRefresh({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}
