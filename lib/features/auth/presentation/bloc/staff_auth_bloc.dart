import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/staff_auth_repository.dart';
import 'staff_auth_event.dart';
import 'staff_auth_state.dart';

/// BLoC managing staff authentication state.
class StaffAuthBloc extends Bloc<StaffAuthEvent, StaffAuthState> {
  final StaffAuthRepository _repository;

  StaffAuthBloc({required StaffAuthRepository repository})
      : _repository = repository,
        super(const StaffAuthInitial()) {
    on<StaffAuthCheckSession>(_onCheckSession);
    on<StaffAuthLogin>(_onLogin);
    on<StaffAuthLogout>(_onLogout);
    on<StaffAuthSetPin>(_onSetPin);
    on<StaffAuthReset>(_onReset);
  }

  void _onCheckSession(
    StaffAuthCheckSession event,
    Emitter<StaffAuthState> emit,
  ) async {
    emit(const StaffAuthCheckingSession());

    final result = await _repository.getCurrentSession();

    result.fold(
      ifLeft: (failure) => emit(StaffAuthError(failure.message)),
      ifRight: (session) {
        if (session != null) {
          emit(StaffAuthAuthenticated(session: session));
        } else {
          emit(const StaffAuthUnauthenticated());
        }
      },
    );
  }

  void _onLogin(
    StaffAuthLogin event,
    Emitter<StaffAuthState> emit,
  ) async {
    emit(const StaffAuthAuthenticating());

    final result = await _repository.loginWithPin(
      phone: event.phone,
      pin: event.pin,
    );

    result.fold(
      ifLeft: (failure) => emit(StaffAuthError(failure.message)),
      ifRight: (session) => emit(StaffAuthAuthenticated(session: session)),
    );
  }

  void _onLogout(
    StaffAuthLogout event,
    Emitter<StaffAuthState> emit,
  ) async {
    final result = await _repository.logout();

    result.fold(
      ifLeft: (failure) => emit(StaffAuthError(failure.message)),
      ifRight: (_) => emit(const StaffAuthUnauthenticated()),
    );
  }

  void _onSetPin(
    StaffAuthSetPin event,
    Emitter<StaffAuthState> emit,
  ) async {
    final result = await _repository.setPin(
      staffId: event.staffId,
      pin: event.pin,
    );

    result.fold(
      ifLeft: (failure) => emit(StaffAuthError(failure.message)),
      ifRight: (_) {
        // Stay in current state — PIN set is a side effect
        final current = state;
        if (current is StaffAuthAuthenticated) {
          emit(current);
        }
      },
    );
  }

  void _onReset(
    StaffAuthReset event,
    Emitter<StaffAuthState> emit,
  ) {
    emit(const StaffAuthUnauthenticated());
  }
}
