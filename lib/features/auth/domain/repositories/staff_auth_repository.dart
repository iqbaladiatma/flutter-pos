import '../../../../core/error/either.dart';
import '../entities/staff_session.dart';

/// Domain contract for staff authentication.
abstract class StaffAuthRepository {
  /// Authenticates a staff member by phone + PIN.
  ///
  /// Returns a [StaffSession] on success.
  Future<Result<StaffSession>> loginWithPin({
    required String phone,
    required String pin,
  });

  /// Validates a PIN against the stored hash.
  ///
  /// Returns `true` if the PIN matches.
  Future<Result<bool>> validatePin({
    required String staffId,
    required String pin,
  });

  /// Sets or updates a staff member's PIN.
  Future<Result<void>> setPin({
    required String staffId,
    required String pin,
  });

  /// Gets the currently stored session (if any).
  Future<Result<StaffSession?>> getCurrentSession();

  /// Clears the current session (logout).
  Future<Result<void>> logout();

  /// Checks if a session exists and is still valid.
  Future<bool> isAuthenticated();
}
