import 'package:equatable/equatable.dart';
import '../../../../shared/models/staff_shift_model.dart';
import '../../domain/repositories/cashier_shift_repository.dart';

sealed class CashierShiftState extends Equatable {
  const CashierShiftState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no shift check has been performed yet.
class CashierShiftInitial extends CashierShiftState {
  const CashierShiftInitial();
}

/// Checking for active shift.
class CashierShiftLoading extends CashierShiftState {
  const CashierShiftLoading();
}

/// An active shift exists — cashier can proceed with POS operations.
class CashierShiftActive extends CashierShiftState {
  final CashierShiftModel shift;

  const CashierShiftActive({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// No active shift — cashier needs to open a shift first.
class CashierShiftNone extends CashierShiftState {
  const CashierShiftNone();
}

/// Shift opened successfully.
class CashierShiftOpened extends CashierShiftState {
  final CashierShiftModel shift;

  const CashierShiftOpened({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// Shift closed successfully.
class CashierShiftClosed extends CashierShiftState {
  final CashierShiftModel shift;

  const CashierShiftClosed({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// Z-Report generated successfully.
class CashierShiftZReportReady extends CashierShiftState {
  final ZReport report;

  const CashierShiftZReportReady({required this.report});

  @override
  List<Object?> get props => [report];
}

/// Error state.
class CashierShiftError extends CashierShiftState {
  final String message;

  const CashierShiftError({required this.message});

  @override
  List<Object?> get props => [message];
}
