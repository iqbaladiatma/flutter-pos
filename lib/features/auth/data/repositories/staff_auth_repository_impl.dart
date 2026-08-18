import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/staff_session.dart';
import '../../domain/repositories/staff_auth_repository.dart';
import '../../services/pin_hasher.dart';

/// Implementation of [StaffAuthRepository] using Supabase + SharedPreferences.
class StaffAuthRepositoryImpl implements StaffAuthRepository {
  final SupabaseService _supabaseService;
  static const String _sessionKey = 'staff_session';

  StaffAuthRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<StaffSession>> loginWithPin({
    required String phone,
    required String pin,
  }) async {
    try {
      // Fetch staff by phone
      final staffData = await _client
          .from('staff')
          .select('''
            id,
            name,
            phone,
            pin_hash,
            is_active
          ''')
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();

      if (staffData == null) {
        return const Left(ServerFailure(
            message: 'Staf tidak ditemukan atau tidak aktif'));
      }

      final storedHash = staffData['pin_hash'] as String?;
      if (storedHash == null || storedHash.isEmpty) {
        return const Left(ServerFailure(
            message: 'PIN belum diatur. Hubungi admin.'));
      }

      // Verify PIN
      if (!PinHasher.verify(pin, storedHash)) {
        return const Left(ServerFailure(message: 'PIN salah'));
      }

      // Fetch staff_outlets to get role + outlet info
      final staffOutletData = await _client
          .from('staff_outlets')
          .select('''
            role,
            outlet_id,
            outlets (
              id,
              name,
              organization_id
            )
          ''')
          .eq('staff_id', staffData['id'])
          .maybeSingle();

      if (staffOutletData == null) {
        return const Left(ServerFailure(
            message: 'Staf tidak terhubung ke outlet manapun'));
      }

      final outlet =
          staffOutletData['outlets'] as Map<String, dynamic>?;
      if (outlet == null) {
        return const Left(ServerFailure(message: 'Outlet tidak ditemukan'));
      }

      // Create session
      final session = StaffSession(
        staffId: staffData['id'] as String,
        name: staffData['name'] as String,
        phone: staffData['phone'] as String,
        role: staffOutletData['role'] as String,
        outletId: outlet['id'] as String,
        outletName: outlet['name'] as String,
        organizationId: outlet['organization_id'] as String,
        token: _generateToken(staffData['id'] as String),
        loginAt: DateTime.now(),
      );

      // Persist session
      await _persistSession(session);

      return Right(session);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(
          message: 'Gagal login: ${e.message}', original: e));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Terjadi kesalahan saat login', original: e));
    }
  }

  @override
  Future<Result<bool>> validatePin({
    required String staffId,
    required String pin,
  }) async {
    try {
      final data = await _client
          .from('staff')
          .select('pin_hash')
          .eq('id', staffId)
          .maybeSingle();

      if (data == null) {
        return const Left(ServerFailure(message: 'Staf tidak ditemukan'));
      }

      final storedHash = data['pin_hash'] as String?;
      if (storedHash == null || storedHash.isEmpty) {
        return const Right(false);
      }

      return Right(PinHasher.verify(pin, storedHash));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memvalidasi PIN', original: e));
    }
  }

  @override
  Future<Result<void>> setPin({
    required String staffId,
    required String pin,
  }) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        return const Left(ServerFailure(
            message: 'PIN harus 4-6 digit'));
      }

      final hash = PinHasher.hash(pin);
      await _client
          .from('staff')
          .update({'pin_hash': hash}).eq('id', staffId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal mengatur PIN', original: e));
    }
  }

  @override
  Future<Result<StaffSession?>> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_sessionKey);
      if (json == null) return const Right(null);

      final map = jsonDecode(json) as Map<String, dynamic>;
      final session = StaffSession.fromJson(map);

      // Check if session is expired (24 hours)
      final expiry = session.loginAt.add(const Duration(hours: 24));
      if (DateTime.now().isAfter(expiry)) {
        await prefs.remove(_sessionKey);
        return const Right(null);
      }

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat sesi', original: e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal logout', original: e));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final result = await getCurrentSession();
    return result.fold(
      ifLeft: (_) => false,
      ifRight: (session) => session != null,
    );
  }

  Future<void> _persistSession(StaffSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  String _generateToken(String staffId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final input = '$staffId:$timestamp';
    return sha256.convert(utf8.encode(input)).toString().substring(0, 32);
  }
}
