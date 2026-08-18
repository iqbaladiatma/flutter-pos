import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.stars, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Loyalty & Rewards', style: AppTextStyles.titleLarge),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold Tier Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GOLD TIER MEMBER',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white70, letterSpacing: 1.5)),
                      const Icon(Icons.workspace_premium, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('1,450 Poin',
                      style: AppTextStyles.displayLarge
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.72,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text('550 poin lagi menuju Platinum Tier',
                      style: AppTextStyles.caption.copyWith(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Active Stamp Challenge
            const Text('Tantangan Aktif (Stamp Card)',
                style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Beli 5 Kopi Susu, Gratis 1 Pastry!',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Kumpulkan 5 stamp untuk mendapatkan voucher pastry gratis.',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        5,
                        (index) => CircleAvatar(
                          radius: 22,
                          backgroundColor: index < 3
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          child: Icon(
                            index < 3 ? Icons.local_cafe : Icons.lock_outline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
