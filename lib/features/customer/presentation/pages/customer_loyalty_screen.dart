import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../shared/models/customer_challenge_model.dart';
import '../../../../shared/models/point_transaction_model.dart';
import '../../../../shared/models/reward_model.dart';
import '../../domain/repositories/customer_loyalty_repository.dart';
import '../bloc/customer_loyalty_bloc.dart';
import '../bloc/customer_loyalty_event.dart';
import '../bloc/customer_loyalty_state.dart';

/// Customer loyalty screen: points, tier, challenges, rewards, history.
class CustomerLoyaltyScreen extends StatelessWidget {
  final String customerId;
  final String outletId;

  const CustomerLoyaltyScreen({
    super.key,
    required this.customerId,
    required this.outletId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerLoyaltyBloc(
        repository: getIt<CustomerLoyaltyRepository>(),
      )..add(CustomerLoyaltyLoad(
          customerId: customerId, outletId: outletId)),
      child: _LoyaltyView(),
    );
  }
}

class _LoyaltyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<CustomerLoyaltyBloc>().add(const CustomerLoyaltyRefresh()),
          ),
        ],
      ),
      body: BlocConsumer<CustomerLoyaltyBloc, CustomerLoyaltyState>(
        listener: (context, state) {
          if (state is CustomerLoyaltyError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return switch (state) {
            CustomerLoyaltyInitial() => const _LoadingView(),
            CustomerLoyaltyLoading() => const _LoadingView(),
            CustomerLoyaltyLoaded() => _LoyaltyContent(state: state),
            CustomerLoyaltyError(:final message) =>
              _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

class _LoyaltyContent extends StatelessWidget {
  final CustomerLoyaltyLoaded state;
  const _LoyaltyContent({required this.state});

  String _tierName(int lifetimePoints) {
    if (lifetimePoints >= 100000) return 'Platinum';
    if (lifetimePoints >= 50000) return 'Gold';
    if (lifetimePoints >= 20000) return 'Silver';
    return 'Bronze';
  }

  Color _tierColor(int lifetimePoints) {
    if (lifetimePoints >= 100000) return const Color(0xFFE5E4E2);
    if (lifetimePoints >= 50000) return const Color(0xFFFFD700);
    if (lifetimePoints >= 20000) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierName(state.profile.lifetimePoints);
    final tierColor = _tierColor(state.profile.lifetimePoints);

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<CustomerLoyaltyBloc>().add(const CustomerLoyaltyRefresh()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Points card
          Card(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                children: [
                  const Text('Poin Anda',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    '${state.profile.totalPoints}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: tierColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tier: $tier',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lifetime: ${state.profile.lifetimePoints} poin',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Challenges
          const Text('Challenges', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          if (state.challenges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada challenges aktif',
                  style: AppTextStyles.caption),
            )
          else
            ...state.challenges.map((c) => _ChallengeCard(challenge: c)),
          const SizedBox(height: 16),
          // Rewards
          const Text('Tukar Poin', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          if (state.rewards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada rewards tersedia',
                  style: AppTextStyles.caption),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.rewards.length,
              itemBuilder: (ctx, i) => _RewardCard(
                reward: state.rewards[i],
                canRedeem:
                    state.profile.totalPoints >=
                        state.rewards[i].pointsCost,
                isRedeeming: state.isRedeeming,
                onRedeem: () => context.read<CustomerLoyaltyBloc>().add(
                      CustomerLoyaltyRedeem(
                        customerId: state.profile.id,
                        rewardId: state.rewards[i].id,
                      ),
                    ),
              ),
            ),
          const SizedBox(height: 16),
          // Point history
          const Text('Riwayat Poin', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          if (state.pointHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada riwayat poin',
                  style: AppTextStyles.caption),
            )
          else
            ...state.pointHistory.map((p) => _PointHistoryItem(item: p)),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final CustomerChallengeModel challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progressAmount.clamp(0, 100);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Challenge #${challenge.id.substring(0, 8)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                if (challenge.isCompleted)
                  const Icon(Icons.check_circle, color: AppColors.success)
                else
                  Text('${progress.toInt()}%', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardModel reward;
  final bool canRedeem;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.canRedeem,
    required this.isRedeeming,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.card_giftcard, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(reward.name, style: AppTextStyles.bodyMedium, maxLines: 1),
            Text(
              '${reward.pointsCost} poin',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (canRedeem && !isRedeeming) ? onRedeem : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: Text(
                  canRedeem ? 'Tukar' : 'N/A',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointHistoryItem extends StatelessWidget {
  final PointTransactionModel item;
  const _PointHistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final isPositive = item.points > 0;
    return ListTile(
      leading: Icon(
        isPositive ? Icons.add_circle : Icons.remove_circle,
        color: isPositive ? AppColors.success : AppColors.error,
      ),
      title: Text(item.description, style: AppTextStyles.bodyMedium),
      trailing: Text(
        '${isPositive ? '+' : ''}${item.points} poin',
        style: AppTextStyles.titleMedium.copyWith(
          color: isPositive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
