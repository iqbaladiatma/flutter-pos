import 'package:equatable/equatable.dart';

abstract class CashierShiftEvent extends Equatable {
  const CashierShiftEvent();

  @override
  List<Object?> get props => [];
}

/// Checks if there's an active shift for the current staff member.
class CashierShiftCheckActive extends CashierShiftEvent {
  final String outletId;
  final String staffId;

  const CashierShiftCheckActive({
    required this.outletId,
    required this.staffId,
  });

  @override
  List<Object?> get props => [outletId, staffId];
}

/// Opens a new cashier shift with beginning cash.
class CashierShiftOpen extends CashierShiftEvent {
  final String outletId;
  final String staffId;
  final double openingCash;

  const CashierShiftOpen({
    required this.outletId,
    required this.staffId,
    required this.openingCash,
  });

  @override
  List<Object?> get props => [outletId, staffId, openingCash];
}

/// Closes the active shift with counted cash.
class CashierShiftClose extends CashierShiftEvent {
  final String shiftId;
  final double closingCash;
  final double expectedCash;

  const CashierShiftClose({
    required this.shiftId,
    required this.closingCash,
    required this.expectedCash,
  });

  @override
  List<Object?> get props => [shiftId, closingCash, expectedCash];
}

/// Generates a Z-Report for a shift.
class CashierShiftGenerateZReport extends CashierShiftEvent {
  final String shiftId;

  const CashierShiftGenerateZReport({required this.shiftId});

  @override
  List<Object?> get props => [shiftId];
}

/// Resets the BLoC to initial state (e.g. after navigating away).
class CashierShiftReset extends CashierShiftEvent {
  const CashierShiftReset();
}
