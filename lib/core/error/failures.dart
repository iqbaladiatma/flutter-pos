import 'package:equatable/equatable.dart';

/// Base class for all domain failures.
///
/// Follows the "Failure" pattern from Clean Architecture — repositories
/// and use-cases return `Either<Failure, T>` instead of throwing.
sealed class Failure extends Equatable {
  final String message;
  final dynamic original;

  const Failure({required this.message, this.original});

  @override
  List<Object?> get props => [message, original];
}

/// Supabase / network related failure.
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error', super.original});
}

/// Client-side validation or input failure.
class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Invalid input', super.original});
}

/// Supabase auth failure (not authenticated, expired session, etc.).
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication error', super.original});
}

/// Local cache / database failure.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error', super.original});
}

/// Network connectivity failure (offline).
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No network connection', super.original});
}

/// Catch-all for unexpected errors.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Unexpected error', super.original});
}
