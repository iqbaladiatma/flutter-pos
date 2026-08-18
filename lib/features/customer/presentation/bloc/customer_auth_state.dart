import 'package:equatable/equatable.dart';
import '../../../../shared/models/customer_loyalty_model.dart';

sealed class CustomerAuthState extends Equatable {
  const CustomerAuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no session check yet.
class CustomerAuthInitial extends CustomerAuthState {
  const CustomerAuthInitial();
}

/// Checking for existing session.
class CustomerAuthChecking extends CustomerAuthState {
  const CustomerAuthChecking();
}

/// No active session — customer needs to login.
class CustomerAuthUnauthenticated extends CustomerAuthState {
  const CustomerAuthUnauthenticated();
}

/// OTP has been requested — waiting for code entry.
class CustomerAuthOtpSent extends CustomerAuthState {
  final String phone;
  final String? devCode; // Only in debug mode

  const CustomerAuthOtpSent({required this.phone, this.devCode});

  @override
  List<Object?> get props => [phone, devCode];
}

/// Verifying OTP code.
class CustomerAuthVerifying extends CustomerAuthState {
  const CustomerAuthVerifying();
}

/// Customer is authenticated.
class CustomerAuthAuthenticated extends CustomerAuthState {
  final CustomerModel customer;

  const CustomerAuthAuthenticated({required this.customer});

  @override
  List<Object?> get props => [customer];
}

/// Error state.
class CustomerAuthError extends CustomerAuthState {
  final String message;

  const CustomerAuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
