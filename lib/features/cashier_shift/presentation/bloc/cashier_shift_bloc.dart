import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/cashier_shift_repository.dart';
import 'cashier_shift_event.dart';
import 'cashier_shift_state.dart';

/// BLoC managing cashier shift lifecycle (open → active → close → Z-Report).
class CashierShiftBloc
    extends Bloc<CashierShiftEvent, CashierShiftState> {
  final CashierShiftRepository _repository;

  CashierShiftBloc({
    required CashierShiftRepository repository,
  })  : _repository = repository,
        super(const CashierShiftInitial()) {
    on<CashierShiftCheckActive>(_onCheckActive);
    on<CashierShiftOpen>(_onOpen);
    on<CashierShiftClose>(_onClose);
    on<CashierShiftGenerateZReport>(_onGenerateZReport);
    on<CashierShiftReset>(_onReset);
  }

  void _onCheckActive(
    CashierShiftCheckActive event,
    Emitter<CashierShiftState> emit,
  ) async {
    emit(const CashierShiftLoading());
    final result = await _repository.getActiveShift(
      outletId: event.outletId,
      staffId: event.staffId,
    );
    result.fold(
      ifLeft: (failure) => emit(CashierShiftError(message: failure.message)),
      ifRight: (shift) => shift != null
          ? emit(CashierShiftActive(shift: shift))
          : emit(const CashierShiftNone()),
    );
  }

  void _onOpen(
    CashierShiftOpen event,
    Emitter<CashierShiftState> emit,
  ) async {
    emit(const CashierShiftLoading());
    final result = await _repository.openShift(
      outletId: event.outletId,
      staffId: event.staffId,
      openingCash: event.openingCash,
    );
    result.fold(
      ifLeft: (failure) => emit(CashierShiftError(message: failure.message)),
      ifRight: (shift) => emit(CashierShiftOpened(shift: shift)),
    );
  }

  void _onClose(
    CashierShiftClose event,
    Emitter<CashierShiftState> emit,
  ) async {
    emit(const CashierShiftLoading());
    final result = await _repository.closeShift(
      shiftId: event.shiftId,
      closingCash: event.closingCash,
      expectedCash: event.expectedCash,
    );
    result.fold(
      ifLeft: (failure) => emit(CashierShiftError(message: failure.message)),
      ifRight: (shift) => emit(CashierShiftClosed(shift: shift)),
    );
  }

  void _onGenerateZReport(
    CashierShiftGenerateZReport event,
    Emitter<CashierShiftState> emit,
  ) async {
    emit(const CashierShiftLoading());
    final result = await _repository.generateZReport(shiftId: event.shiftId);
    result.fold(
      ifLeft: (failure) => emit(CashierShiftError(message: failure.message)),
      ifRight: (report) => emit(CashierShiftZReportReady(report: report)),
    );
  }

  void _onReset(
    CashierShiftReset event,
    Emitter<CashierShiftState> emit,
  ) {
    emit(const CashierShiftInitial());
  }
}
