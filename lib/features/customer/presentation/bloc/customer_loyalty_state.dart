import 'package:equatable/equatable.dart';
import '../../../../shared/models/customer_loyalty_model.dart';
import '../../../../shared/models/customer_challenge_model.dart';
import '../../../../shared/models/customer_redemption_model.dart';
import '../../../../shared/models/point_transaction_model.dart';
import '../../../../shared/models/reward_model.dart';

sealed class CustomerLoyaltyState extends Equatable {
  const CustomerLoyaltyState();

  @override
  List<Object?> get props => [];
}

class CustomerLoyaltyInitial extends CustomerLoyaltyState {
  const CustomerLoyaltyInitial();
}

class CustomerLoyaltyLoading extends CustomerLoyaltyState {
  const CustomerLoyaltyLoading();
}

class CustomerLoyaltyLoaded extends CustomerLoyaltyState {
  final CustomerModel profile;
  final List<PointTransactionModel> pointHistory;
  final List<CustomerChallengeModel> challenges;
  final List<RewardModel> rewards;
  final List<CustomerRedemptionModel> redemptionHistory;
  final bool isRedeeming;

  const CustomerLoyaltyLoaded({
    required this.profile,
    required this.pointHistory,
    required this.challenges,
    required this.rewards,
    required this.redemptionHistory,
    this.isRedeeming = false,
  });

  CustomerLoyaltyLoaded copyWith({
    CustomerModel? profile,
    List<PointTransactionModel>? pointHistory,
    List<CustomerChallengeModel>? challenges,
    List<RewardModel>? rewards,
    List<CustomerRedemptionModel>? redemptionHistory,
    bool? isRedeeming,
  }) =>
      CustomerLoyaltyLoaded(
        profile: profile ?? this.profile,
        pointHistory: pointHistory ?? this.pointHistory,
        challenges: challenges ?? this.challenges,
        rewards: rewards ?? this.rewards,
        redemptionHistory: redemptionHistory ?? this.redemptionHistory,
        isRedeeming: isRedeeming ?? this.isRedeeming,
      );

  @override
  List<Object?> get props =>
      [profile, pointHistory, challenges, rewards, redemptionHistory, isRedeeming];
}

class CustomerLoyaltyError extends CustomerLoyaltyState {
  final String message;
  const CustomerLoyaltyError(this.message);

  @override
  List<Object?> get props => [message];
}
