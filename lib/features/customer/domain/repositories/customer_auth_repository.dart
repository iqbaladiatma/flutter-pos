import '../../../../core/error/either.dart';
import '../../../../shared/models/customer_loyalty_model.dart';

/// Domain contract for customer authentication and profile.
abstract class CustomerAuthRepository {
  /// Requests an OTP code to be sent to [phone].
  ///
  /// In production, this triggers an SMS/WhatsApp via Supabase Edge Function.
  /// In development, the OTP is returned for testing.
  Future<Result<String>> requestOtp({required String phone});

  /// Verifies the OTP code and creates/updates the customer session.
  ///
  /// Returns the authenticated [CustomerModel] on success.
  Future<Result<CustomerModel>> verifyOtp({
    required String phone,
    required String code,
  });

  /// Returns the currently logged-in customer, or null.
  Future<Result<CustomerModel?>> getCurrentCustomer();

  /// Signs out the current customer.
  Future<Result<void>> signOut();
}
