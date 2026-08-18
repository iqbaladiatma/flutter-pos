import 'package:flutter/foundation.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../shared/models/staff_shift_model.dart';
import '../../domain/repositories/cashier_shift_repository.dart';
import '../datasources/cashier_shift_remote_data_source.dart';

/// Implementation of [CashierShiftRepository] with Supabase backend.
///
/// Cashier shifts require network connectivity (no offline support needed
/// for shift management — it's a staff operation done at the outlet).
class CashierShiftRepositoryImpl implements CashierShiftRepository {
  final CashierShiftRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivity;

  CashierShiftRepositoryImpl({
    CashierShiftRemoteDataSource? remoteDataSource,
    ConnectivityService? connectivity,
  })  : _remoteDataSource = remoteDataSource ?? CashierShiftRemoteDataSource(),
        _connectivity = connectivity ?? ConnectivityService.instance;

  @override
  Future<Result<CashierShiftModel>> openShift({
    required String outletId,
    required String staffId,
    required double openingCash,
  }) async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Buka shift butuh koneksi internet'));
    }
    try {
      final data = await _remoteDataSource.insertShift(
        outletId: outletId,
        staffId: staffId,
        openingCash: openingCash,
      );
      return Right(CashierShiftModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal membuka shift', original: e));
    }
  }

  @override
  Future<Result<CashierShiftModel?>> getActiveShift({
    required String outletId,
    required String staffId,
  }) async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Cek shift aktif butuh koneksi internet'));
    }
    try {
      final data = await _remoteDataSource.getActiveShift(
        outletId: outletId,
        staffId: staffId,
      );
      if (data == null) return const Right(null);
      return Right(CashierShiftModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal cek shift aktif', original: e));
    }
  }

  @override
  Future<Result<CashierShiftModel>> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
  }) async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Tutup shift butuh koneksi internet'));
    }
    try {
      final data = await _remoteDataSource.closeShift(
        shiftId: shiftId,
        closingCash: closingCash,
        expectedCash: expectedCash,
      );
      return Right(CashierShiftModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal tutup shift', original: e));
    }
  }

  @override
  Future<Result<List<CashierShiftModel>>> getShiftsByDate({
    required String outletId,
    required DateTime date,
  }) async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Riwayat shift butuh koneksi internet'));
    }
    try {
      final data = await _remoteDataSource.getShiftsByDate(
        outletId: outletId,
        date: date,
      );
      final shifts = data.map((e) => CashierShiftModel.fromJson(e)).toList();
      return Right(shifts);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal ambil riwayat shift', original: e));
    }
  }

  @override
  Future<Result<ZReport>> generateZReport({required String shiftId}) async {
    if (!await _connectivity.isOnline) {
      return const Left(NetworkFailure(
          message: 'Z-Report butuh koneksi internet'));
    }
    try {
      final summary = await _remoteDataSource.getShiftOrderSummary(
        shiftId: shiftId,
      );
      final shiftData =
          summary['shift'] as Map<String, dynamic>;
      final shift = CashierShiftModel.fromJson(shiftData);

      final staffName =
          await _remoteDataSource.getStaffName(shift.staffId);

      final openingCash = shift.openingCash;
      final closingCash = shift.closingCash ?? 0;
      final expectedCash = shift.expectedCash ?? 0;
      final salesByMethodRaw =
          summary['sales_by_method'] as Map<String, dynamic>;
      final salesByMethod = salesByMethodRaw.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );

      // Expected cash = opening + cash sales
      final cashSales = salesByMethod['cash'] ?? 0;
      final computedExpected = openingCash + cashSales;

      return Right(ZReport(
        shiftId: shift.id,
        outletId: shift.outletId,
        staffId: shift.staffId,
        staffName: staffName,
        openedAt: DateTime.parse(shift.openedAt),
        closedAt: shift.closedAt != null
            ? DateTime.tryParse(shift.closedAt!)
            : null,
        openingCash: openingCash,
        closingCash: closingCash,
        expectedCash: expectedCash > 0 ? expectedCash : computedExpected,
        cashDifference: closingCash - computedExpected,
        totalOrders: summary['total_orders'] as int,
        grossSales: (summary['gross_sales'] as num).toDouble(),
        totalDiscounts: (summary['total_discounts'] as num).toDouble(),
        totalTax: (summary['total_tax'] as num).toDouble(),
        netSales: (summary['net_sales'] as num).toDouble(),
        salesByPaymentMethod: salesByMethod,
      ));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Z-Report error: $e');
      }
      return Left(ServerFailure(message: 'Gagal buat Z-Report', original: e));
    }
  }
}
