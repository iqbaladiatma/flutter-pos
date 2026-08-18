import '../../../../core/error/either.dart';
import '../../../../shared/models/customer_loyalty_model.dart';
import '../../../../shared/models/customer_challenge_model.dart';
import '../../../../shared/models/customer_redemption_model.dart';
import '../../../../shared/models/point_transaction_model.dart';
import '../../../../shared/models/reward_model.dart';

/// Domain contract for customer loyalty operations.
abstract class CustomerLoyaltyRepository {
  /// Fetches the loyalty profile for a customer (points + tier).
  Future<Result<CustomerModel>> getLoyaltyProfile({
    required String customerId,
  });

  /// Fetches point transaction history for a customer.
  Future<Result<List<PointTransactionModel>>> getPointHistory({
    required String customerId,
  });

  /// Fetches available challenges for a customer.
  Future<Result<List<CustomerChallengeModel>>> getChallenges({
    required String customerId,
  });

  /// Fetches available rewards for redemption.
  Future<Result<List<RewardModel>>> getAvailableRewards({
    required String outletId,
  });

  /// Redeems a reward for the customer.
  ///
  /// Deducts points and creates a `customer_redemptions` record.
  Future<Result<CustomerRedemptionModel>> redeemReward({
    required String customerId,
    required String rewardId,
  });

  /// Fetches redemption history for a customer.
  Future<Result<List<CustomerRedemptionModel>>> getRedemptionHistory({
    required String customerId,
  });
}
