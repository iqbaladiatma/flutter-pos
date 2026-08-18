import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/delivery_assignment_model.dart';
import '../../../../shared/models/delivery_model.dart';
import '../../domain/repositories/driver_repository.dart';

/// Implementation of [DriverRepository] using Supabase.
class DriverRepositoryImpl implements DriverRepository {
  final SupabaseService _supabaseService;

  DriverRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<void>> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    try {
      await _client.from('drivers').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', driverId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal update status driver', original: e));
    }
  }

  @override
  Future<Result<List<DeliveryAssignmentModel>>> getPendingAssignments({
    required String driverId,
  }) async {
    try {
      final data = await _client
          .from('delivery_assignments')
          .select('''
            *,
            deliveries (
              id,
              order_id,
              recipient_name,
              recipient_phone,
              recipient_address,
              status,
              shipping_fee
            )
          ''')
          .eq('driver_id', driverId)
          .eq('status', 'pending')
          .order('assigned_at', ascending: true);
      final assignments = data
          .map<DeliveryAssignmentModel>(
              (e) => DeliveryAssignmentModel.fromJson(e))
          .toList();
      return Right(assignments);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat penugasan', original: e));
    }
  }

  @override
  Future<Result<List<DeliveryAssignmentModel>>> getActiveAssignments({
    required String driverId,
  }) async {
    try {
      final data = await _client
          .from('delivery_assignments')
          .select('''
            *,
            deliveries (
              id,
              order_id,
              recipient_name,
              recipient_phone,
              recipient_address,
              status,
              shipping_fee
            )
          ''')
          .eq('driver_id', driverId)
          .inFilter('status', ['accepted', 'in_transit'])
          .order('assigned_at', ascending: true);
      final assignments = data
          .map<DeliveryAssignmentModel>(
              (e) => DeliveryAssignmentModel.fromJson(e))
          .toList();
      return Right(assignments);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat pengiriman aktif', original: e));
    }
  }

  @override
  Future<Result<void>> acceptAssignment({
    required String assignmentId,
    required String driverId,
  }) async {
    try {
      // Update assignment status
      await _client.from('delivery_assignments').update({
        'status': 'accepted',
        'responded_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', assignmentId);

      // Update driver status to on_delivery
      await _client.from('drivers').update({
        'status': 'on_delivery',
      }).eq('id', driverId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal menerima penugasan', original: e));
    }
  }

  @override
  Future<Result<void>> rejectAssignment({
    required String assignmentId,
    required String driverId,
    String? reason,
  }) async {
    try {
      await _client.from('delivery_assignments').update({
        'status': 'rejected',
        'responded_at': DateTime.now().toUtc().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', assignmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal menolak penugasan', original: e));
    }
  }

  @override
  Future<Result<void>> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? notes,
  }) async {
    try {
      await _client.from('deliveries').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', deliveryId);

      // Log the event
      await _client.from('delivery_logs').insert({
        'delivery_id': deliveryId,
        'status': status,
        'notes': notes,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal update status pengiriman', original: e));
    }
  }

  @override
  Future<Result<void>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.from('drivers').update({
        'latitude': latitude,
        'longitude': longitude,
        'last_location_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', driverId);
      return const Right(null);
    } catch (e) {
      // Location updates are non-critical — log but don't fail
      if (kDebugMode) {
        // ignore: avoid_print
        print('Location update error: $e');
      }
      return const Right(null);
    }
  }

  @override
  Future<Result<void>> logDeliveryEvent({
    required String deliveryId,
    required String status,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      await _client.from('delivery_logs').insert({
        'delivery_id': deliveryId,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal log event', original: e));
    }
  }

  @override
  Future<Result<DeliveryModel>> getDeliveryDetails({
    required String deliveryId,
  }) async {
    try {
      final data = await _client
          .from('deliveries')
          .select()
          .eq('id', deliveryId)
          .single();
      return Right(DeliveryModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat detail pengiriman', original: e));
    }
  }

  @override
  Future<Result<String>> uploadProofPhoto({
    required String deliveryId,
    required String filePath,
  }) async {
    try {
      final fileName = 'proof_$deliveryId.jpg';
      final path = 'delivery-proofs/$fileName';

      await _client.storage.from('deliveries').upload(
            path,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('deliveries').getPublicUrl(path);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal upload foto bukti', original: e));
    }
  }
}
