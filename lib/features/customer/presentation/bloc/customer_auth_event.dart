import 'package:equatable/equatable.dart';

abstract class CustomerAuthEvent extends Equatable {
  const CustomerAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if a customer session exists on app start.
class CustomerAuthCheckSession extends CustomerAuthEvent {
  const CustomerAuthCheckSession();
}

/// Request an OTP code for the given phone number.
class CustomerAuthRequestOtp extends CustomerAuthEvent {
  final String phone;
  const CustomerAuthRequestOtp({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// Verify the OTP code and authenticate.
class CustomerAuthVerifyOtp extends CustomerAuthEvent {
  final String phone;
  final String code;
  const CustomerAuthVerifyOtp({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

/// Sign out the current customer.
class CustomerAuthSignOut extends CustomerAuthEvent {
  const CustomerAuthSignOut();
}

/// Reset to initial state.
class CustomerAuthReset extends CustomerAuthEvent {
  const CustomerAuthReset();
}
