import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/customer_loyalty_repository.dart';
import 'customer_loyalty_event.dart';
import 'customer_loyalty_state.dart';

/// BLoC managing customer loyalty: profile, points, challenges, rewards.
class CustomerLoyaltyBloc
    extends Bloc<CustomerLoyaltyEvent, CustomerLoyaltyState> {
  final CustomerLoyaltyRepository _repository;
  String? _customerId;
  String? _outletId;

  CustomerLoyaltyBloc({required CustomerLoyaltyRepository repository})
      : _repository = repository,
        super(const CustomerLoyaltyInitial()) {
    on<CustomerLoyaltyLoad>(_onLoad);
    on<CustomerLoyaltyRedeem>(_onRedeem);
    on<CustomerLoyaltyRefresh>(_onRefresh);
  }

  void _onLoad(
    CustomerLoyaltyLoad event,
    Emitter<CustomerLoyaltyState> emit,
  ) async {
    _customerId = event.customerId;
    _outletId = event.outletId;
    emit(const CustomerLoyaltyLoading());

    final profileResult =
        await _repository.getLoyaltyProfile(customerId: event.customerId);
    final pointsResult =
        await _repository.getPointHistory(customerId: event.customerId);
    final challengesResult =
        await _repository.getChallenges(customerId: event.customerId);
    final rewardsResult =
        await _repository.getAvailableRewards(outletId: event.outletId);
    final redemptionsResult = await _repository
        .getRedemptionHistory(customerId: event.customerId);

    final profile = profileResult.fold(
      ifLeft: (_) => null,
      ifRight: (p) => p,
    );

    if (profile == null) {
      emit(CustomerLoyaltyError(
        profileResult.fold(
          ifLeft: (f) => f.message,
          ifRight: (_) => 'Gagal memuat profil',
        ),
      ));
      return;
    }

    emit(CustomerLoyaltyLoaded(
      profile: profile,
      pointHistory: pointsResult.fold(
        ifLeft: (_) => [],
        ifRight: (p) => p,
      ),
      challenges: challengesResult.fold(
        ifLeft: (_) => [],
        ifRight: (c) => c,
      ),
      rewards: rewardsResult.fold(
        ifLeft: (_) => [],
        ifRight: (r) => r,
      ),
      redemptionHistory: redemptionsResult.fold(
        ifLeft: (_) => [],
        ifRight: (r) => r,
      ),
    ));
  }

  void _onRedeem(
    CustomerLoyaltyRedeem event,
    Emitter<CustomerLoyaltyState> emit,
  ) async {
    final current = state;
    if (current is! CustomerLoyaltyLoaded) return;

    emit(current.copyWith(isRedeeming: true));

    final result = await _repository.redeemReward(
      customerId: event.customerId,
      rewardId: event.rewardId,
    );

    result.fold(
      ifLeft: (failure) {
        emit(current.copyWith(isRedeeming: false));
        emit(CustomerLoyaltyError(failure.message));
        emit(current);
      },
      ifRight: (_) {
        // Reload profile to reflect new point balance
        if (_customerId != null && _outletId != null) {
          add(CustomerLoyaltyLoad(
            customerId: _customerId!,
            outletId: _outletId!,
          ));
        }
      },
    );
  }

  void _onRefresh(
    CustomerLoyaltyRefresh event,
    Emitter<CustomerLoyaltyState> emit,
  ) {
    if (_customerId != null && _outletId != null) {
      add(CustomerLoyaltyLoad(
        customerId: _customerId!,
        outletId: _outletId!,
      ));
    }
  }
}
