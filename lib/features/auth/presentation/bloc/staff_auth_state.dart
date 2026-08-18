import 'package:equatable/equatable.dart';
import '../../domain/entities/staff_session.dart';

sealed class StaffAuthState extends Equatable {
  const StaffAuthState();

  @override
  List<Object?> get props => [];
}

class StaffAuthInitial extends StaffAuthState {
  const StaffAuthInitial();
}

class StaffAuthCheckingSession extends StaffAuthState {
  const StaffAuthCheckingSession();
}

class StaffAuthUnauthenticated extends StaffAuthState {
  final String? errorMessage;
  const StaffAuthUnauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class StaffAuthAuthenticating extends StaffAuthState {
  const StaffAuthAuthenticating();
}

class StaffAuthAuthenticated extends StaffAuthState {
  final StaffSession session;
  const StaffAuthAuthenticated({required this.session});

  @override
  List<Object?> get props => [session];
}

class StaffAuthError extends StaffAuthState {
  final String message;
  const StaffAuthError(this.message);

  @override
  List<Object?> get props => [message];
}
