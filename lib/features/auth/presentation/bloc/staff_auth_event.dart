import 'package:equatable/equatable.dart';

abstract class StaffAuthEvent extends Equatable {
  const StaffAuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if a session exists on app start.
class StaffAuthCheckSession extends StaffAuthEvent {
  const StaffAuthCheckSession();
}

/// Login with phone + PIN.
class StaffAuthLogin extends StaffAuthEvent {
  final String phone;
  final String pin;
  const StaffAuthLogin({required this.phone, required this.pin});

  @override
  List<Object?> get props => [phone, pin];
}

/// Logout.
class StaffAuthLogout extends StaffAuthEvent {
  const StaffAuthLogout();
}

/// Set a new PIN for the current staff.
class StaffAuthSetPin extends StaffAuthEvent {
  final String staffId;
  final String pin;
  const StaffAuthSetPin({required this.staffId, required this.pin});

  @override
  List<Object?> get props => [staffId, pin];
}

/// Reset auth state (clear errors).
class StaffAuthReset extends StaffAuthEvent {
  const StaffAuthReset();
}
