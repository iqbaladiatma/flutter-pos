import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/customer_auth_repository.dart';
import 'customer_auth_event.dart';
import 'customer_auth_state.dart';

/// BLoC managing customer authentication lifecycle.
class CustomerAuthBloc
    extends Bloc<CustomerAuthEvent, CustomerAuthState> {
  final CustomerAuthRepository _repository;

  CustomerAuthBloc({required CustomerAuthRepository repository})
      : _repository = repository,
        super(const CustomerAuthInitial()) {
    on<CustomerAuthCheckSession>(_onCheckSession);
    on<CustomerAuthRequestOtp>(_onRequestOtp);
    on<CustomerAuthVerifyOtp>(_onVerifyOtp);
    on<CustomerAuthSignOut>(_onSignOut);
    on<CustomerAuthReset>(_onReset);
  }

  void _onCheckSession(
    CustomerAuthCheckSession event,
    Emitter<CustomerAuthState> emit,
  ) async {
    emit(const CustomerAuthChecking());
    final result = await _repository.getCurrentCustomer();
    result.fold(
      ifLeft: (_) => emit(const CustomerAuthUnauthenticated()),
      ifRight: (customer) => customer != null
          ? emit(CustomerAuthAuthenticated(customer: customer))
          : emit(const CustomerAuthUnauthenticated()),
    );
  }

  void _onRequestOtp(
    CustomerAuthRequestOtp event,
    Emitter<CustomerAuthState> emit,
  ) async {
    emit(const CustomerAuthChecking());
    final result = await _repository.requestOtp(phone: event.phone);
    result.fold(
      ifLeft: (failure) =>
          emit(CustomerAuthError(message: failure.message)),
      ifRight: (response) {
        // If response looks like a 6-digit code, it's a dev code
        final isDevCode =
            response.length == 6 && int.tryParse(response) != null;
        emit(CustomerAuthOtpSent(
          phone: event.phone,
          devCode: isDevCode ? response : null,
        ));
      },
    );
  }

  void _onVerifyOtp(
    CustomerAuthVerifyOtp event,
    Emitter<CustomerAuthState> emit,
  ) async {
    emit(const CustomerAuthVerifying());
    final result = await _repository.verifyOtp(
      phone: event.phone,
      code: event.code,
    );
    result.fold(
      ifLeft: (failure) =>
          emit(CustomerAuthError(message: failure.message)),
      ifRight: (customer) =>
          emit(CustomerAuthAuthenticated(customer: customer)),
    );
  }

  void _onSignOut(
    CustomerAuthSignOut event,
    Emitter<CustomerAuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const CustomerAuthUnauthenticated());
  }

  void _onReset(
    CustomerAuthReset event,
    Emitter<CustomerAuthState> emit,
  ) {
    emit(const CustomerAuthInitial());
  }
}
