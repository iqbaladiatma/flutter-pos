import '../../../../core/error/either.dart';
import '../../../../shared/models/staff_shift_model.dart';

/// Domain contract for cashier shift operations.
abstract class CashierShiftRepository {
  /// Opens a new cashier shift with [openingCash].
  Future<Result<CashierShiftModel>> openShift({
    required String outletId,
    required String staffId,
    required double openingCash,
  });

  /// Returns the currently active shift for [staffId] at [outletId], or null.
  Future<Result<CashierShiftModel?>> getActiveShift({
    required String outletId,
    required String staffId,
  });

  /// Closes the active shift with [closingCash] and computes [expectedCash].
  Future<Result<CashierShiftModel>> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
  });

  /// Returns all shifts for [outletId] on [date] (for Z-Report).
  Future<Result<List<CashierShiftModel>>> getShiftsByDate({
    required String outletId,
    required DateTime date,
  });

  /// Generates a Z-Report summary for a shift.
  Future<Result<ZReport>> generateZReport({required String shiftId});
}

/// Z-Report summary for a cashier shift.
class ZReport {
  final String shiftId;
  final String outletId;
  final String staffId;
  final String staffName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double closingCash;
  final double expectedCash;
  final double cashDifference;
  final int totalOrders;
  final double grossSales;
  final double totalDiscounts;
  final double totalTax;
  final double netSales;
  final Map<String, double> salesByPaymentMethod;

  const ZReport({
    required this.shiftId,
    required this.outletId,
    required this.staffId,
    required this.staffName,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.closingCash,
    required this.expectedCash,
    required this.cashDifference,
    required this.totalOrders,
    required this.grossSales,
    required this.totalDiscounts,
    required this.totalTax,
    required this.netSales,
    required this.salesByPaymentMethod,
  });
}
