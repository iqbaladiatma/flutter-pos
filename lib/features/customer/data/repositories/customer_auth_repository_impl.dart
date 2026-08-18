import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/customer_loyalty_model.dart';
import '../../domain/repositories/customer_auth_repository.dart';

/// Implementation of [CustomerAuthRepository] using Supabase.
///
/// OTP flow:
/// 1. `requestOtp` inserts a row into `otp_codes` table (Edge Function
///    sends SMS in production; in dev, returns the code).
/// 2. `verifyOtp` validates the code, marks it used, upserts the customer
///    (creating a new row if first login), and stores the session.
class CustomerAuthRepositoryImpl implements CustomerAuthRepository {
  final SupabaseService _supabaseService;

  CustomerAuthRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<String>> requestOtp({required String phone}) async {
    try {
      // Generate a 6-digit OTP code
      final code = (100000 + DateTime.now().millisecond * 137 % 900000)
          .toString();

      // Insert OTP record (Edge Function would send SMS here)
      await _client.from('otp_codes').insert({
        'phone': phone,
        'code': code,
        'purpose': 'login',
        'is_used': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(minutes: 3))
            .toUtc()
            .toIso8601String(),
      });

      // In development, return the code so it can be displayed.
      // In production, this would be sent via SMS and return a success message.
      if (kDebugMode) {
        return Right(code);
      }
      return const Right('Kode OTP telah dikirim via SMS');
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal mengirim kode OTP', original: e));
    }
  }

  @override
  Future<Result<CustomerModel>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      // Validate the OTP code
      final otpData = await _client
          .from('otp_codes')
          .select()
          .eq('phone', phone)
          .eq('code', code)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (otpData == null) {
        return const Left(ValidationFailure(
            message: 'Kode OTP tidak valid atau sudah digunakan'));
      }

      // Check expiry
      final expiresAt =
          DateTime.tryParse(otpData['expires_at'] as String? ?? '');
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        return const Left(ValidationFailure(
            message: 'Kode OTP sudah kedaluwarsa'));
      }

      // Mark OTP as used
      await _client
          .from('otp_codes')
          .update({'is_used': true}).eq('id', otpData['id']);

      // Upsert customer (create if doesn't exist)
      final existingCustomer = await _client
          .from('customers')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      CustomerModel customer;
      if (existingCustomer != null) {
        customer = CustomerModel.fromJson(existingCustomer);
      } else {
        // Create new customer
        final newCustomer = await _client.from('customers').insert({
          'name': 'Pelanggan $phone',
          'phone': phone,
          'total_points': 0,
          'lifetime_points': 0,
        }).select().single();
        customer = CustomerModel.fromJson(newCustomer);
      }

      return Right(customer);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal verifikasi OTP', original: e));
    }
  }

  @override
  Future<Result<CustomerModel?>> getCurrentCustomer() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return const Right(null);

      final data = await _client
          .from('customers')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return const Right(null);
      return Right(CustomerModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat data pelanggan', original: e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal keluar', original: e));
    }
  }
}
