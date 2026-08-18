import '../../../../core/error/either.dart';

/// Domain contract for admin analytics and management operations.
abstract class AdminRepository {
  /// Fetches today's sales summary for an outlet.
  Future<Result<SalesSummary>> getTodaySalesSummary({
    required String outletId,
  });

  /// Fetches hourly sales data for a date range.
  Future<Result<List<HourlySales>>> getHourlySales({
    required String outletId,
    required DateTime date,
  });

  /// Fetches daily sales data for a date range.
  Future<Result<List<DailySales>>> getDailySales({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches sales breakdown by payment method.
  Future<Result<List<PaymentMethodSummary>>> getSalesByPaymentMethod({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches sales breakdown by outlet (for multi-outlet view).
  Future<Result<List<OutletSalesSummary>>> getSalesByOutlet({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // ── Menu Management (CRUD) ──────────────────────────────────────

  /// Creates a new product.
  Future<Result<Map<String, dynamic>>> createProduct({
    required String outletId,
    required String name,
    required double basePrice,
    required String categoryId,
    String? description,
    String? imageUrl,
    bool isAvailable = true,
  });

  /// Updates a product.
  Future<Result<void>> updateProduct({
    required String productId,
    String? name,
    double? basePrice,
    String? categoryId,
    String? description,
    String? imageUrl,
    bool? isAvailable,
  });

  /// Deletes a product (soft delete — sets is_available = false).
  Future<Result<void>> deleteProduct({required String productId});

  /// Creates a new category.
  Future<Result<Map<String, dynamic>>> createCategory({
    required String outletId,
    required String name,
    int sortOrder = 0,
  });

  /// Updates a category.
  Future<Result<void>> updateCategory({
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? isActive,
  });

  // ── Staff Management ────────────────────────────────────────────

  /// Fetches all staff for an outlet.
  Future<Result<List<Map<String, dynamic>>>> getStaff({
    required String outletId,
  });

  /// Creates a new staff member.
  Future<Result<Map<String, dynamic>>> createStaff({
    required String outletId,
    required String name,
    required String phone,
    required String role,
    String? pinHash,
  });

  /// Updates a staff member.
  Future<Result<void>> updateStaff({
    required String staffId,
    String? name,
    String? phone,
    String? role,
    String? pinHash,
    bool? isActive,
  });
}

/// Today's sales summary for an outlet.
class SalesSummary {
  final double totalSales;
  final int totalOrders;
  final double avgOrderValue;
  final double totalDiscounts;
  final double totalTax;
  final int totalCustomers;

  const SalesSummary({
    required this.totalSales,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.totalDiscounts,
    required this.totalTax,
    required this.totalCustomers,
  });
}

/// Hourly sales data point.
class HourlySales {
  final int hour;
  final double sales;
  final int orders;

  const HourlySales({
    required this.hour,
    required this.sales,
    required this.orders,
  });
}

/// Daily sales data point.
class DailySales {
  final DateTime date;
  final double sales;
  final int orders;

  const DailySales({
    required this.date,
    required this.sales,
    required this.orders,
  });
}

/// Sales breakdown by payment method.
class PaymentMethodSummary {
  final String method;
  final double total;
  final int count;

  const PaymentMethodSummary({
    required this.method,
    required this.total,
    required this.count,
  });
}

/// Sales breakdown by outlet.
class OutletSalesSummary {
  final String outletId;
  final String outletName;
  final double totalSales;
  final int totalOrders;

  const OutletSalesSummary({
    required this.outletId,
    required this.outletName,
    required this.totalSales,
    required this.totalOrders,
  });
}
