import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../shared/models/customer_loyalty_model.dart';
import '../../../../shared/models/customer_challenge_model.dart';
import '../../../../shared/models/customer_redemption_model.dart';
import '../../../../shared/models/point_transaction_model.dart';
import '../../../../shared/models/reward_model.dart';
import '../../domain/repositories/customer_loyalty_repository.dart';

/// Implementation of [CustomerLoyaltyRepository] using Supabase.
class CustomerLoyaltyRepositoryImpl
    implements CustomerLoyaltyRepository {
  final SupabaseService _supabaseService;

  CustomerLoyaltyRepositoryImpl({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<CustomerModel>> getLoyaltyProfile({
    required String customerId,
  }) async {
    try {
      final data = await _client
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();
      return Right(CustomerModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat profil loyalty', original: e));
    }
  }

  @override
  Future<Result<List<PointTransactionModel>>> getPointHistory({
    required String customerId,
  }) async {
    try {
      final data = await _client
          .from('point_transactions')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(50);
      final items = data
          .map<PointTransactionModel>(
              (e) => PointTransactionModel.fromJson(e))
          .toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat riwayat poin', original: e));
    }
  }

  @override
  Future<Result<List<CustomerChallengeModel>>> getChallenges({
    required String customerId,
  }) async {
    try {
      final data = await _client
          .from('customer_challenges')
          .select('''
            *,
            challenges (*)
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      final items = data
          .map<CustomerChallengeModel>(
              (e) => CustomerChallengeModel.fromJson(e))
          .toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat challenges', original: e));
    }
  }

  @override
  Future<Result<List<RewardModel>>> getAvailableRewards({
    required String outletId,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final data = await _client
          .from('rewards')
          .select()
          .eq('outlet_id', outletId)
          .eq('is_active', true)
          .or('valid_until.is.null,valid_until.gte.$now')
          .order('points_required', ascending: true);
      final items =
          data.map<RewardModel>((e) => RewardModel.fromJson(e)).toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat rewards', original: e));
    }
  }

  @override
  Future<Result<CustomerRedemptionModel>> redeemReward({
    required String customerId,
    required String rewardId,
  }) async {
    try {
      // Fetch reward to check points required
      final reward = await _client
          .from('rewards')
          .select()
          .eq('id', rewardId)
          .single();

      final pointsRequired =
          (reward['points_cost'] as num?)?.toInt() ?? 0;

      // Fetch customer to check balance
      final customer = await _client
          .from('customers')
          .select('total_points')
          .eq('id', customerId)
          .single();

      final currentPoints =
          (customer['total_points'] as num?)?.toInt() ?? 0;

      if (currentPoints < pointsRequired) {
        return const Left(ValidationFailure(
            message: 'Poin tidak cukup untuk menukar reward ini'));
      }

      // Deduct points
      await _client.from('customers').update({
        'total_points': currentPoints - pointsRequired,
      }).eq('id', customerId);

      // Create redemption record
      final redemption = await _client.from('customer_redemptions').insert({
        'customer_id': customerId,
        'reward_id': rewardId,
        'points_spent': pointsRequired,
        'status': 'pending',
        'redeemed_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      // Log point transaction
      await _client.from('point_transactions').insert({
        'customer_id': customerId,
        'points': -pointsRequired,
        'type': 'redemption',
        'description': 'Redeem: ${reward['name'] ?? 'Reward'}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return Right(CustomerRedemptionModel.fromJson(redemption));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal menukar reward', original: e));
    }
  }

  @override
  Future<Result<List<CustomerRedemptionModel>>> getRedemptionHistory({
    required String customerId,
  }) async {
    try {
      final data = await _client
          .from('customer_redemptions')
          .select('''
            *,
            rewards (name, type)
          ''')
          .eq('customer_id', customerId)
          .order('redeemed_at', ascending: false);
      final items = data
          .map<CustomerRedemptionModel>(
              (e) => CustomerRedemptionModel.fromJson(e))
          .toList();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat riwayat redemption', original: e));
    }
  }
}
