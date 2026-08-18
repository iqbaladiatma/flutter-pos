import 'package:equatable/equatable.dart';

abstract class CustomerLoyaltyEvent extends Equatable {
  const CustomerLoyaltyEvent();

  @override
  List<Object?> get props => [];
}

/// Load full loyalty data (profile, points, challenges, rewards).
class CustomerLoyaltyLoad extends CustomerLoyaltyEvent {
  final String customerId;
  final String outletId;
  const CustomerLoyaltyLoad({
    required this.customerId,
    required this.outletId,
  });

  @override
  List<Object?> get props => [customerId, outletId];
}

/// Redeem a reward.
class CustomerLoyaltyRedeem extends CustomerLoyaltyEvent {
  final String customerId;
  final String rewardId;
  const CustomerLoyaltyRedeem({
    required this.customerId,
    required this.rewardId,
  });

  @override
  List<Object?> get props => [customerId, rewardId];
}

/// Refresh loyalty data.
class CustomerLoyaltyRefresh extends CustomerLoyaltyEvent {
  const CustomerLoyaltyRefresh();
}
