import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class CustomerCatalogScreen extends StatefulWidget {
  const CustomerCatalogScreen({super.key});

  @override
  State<CustomerCatalogScreen> createState() => _CustomerCatalogScreenState();
}

class _CustomerCatalogScreenState extends State<CustomerCatalogScreen> {
  final List<Map<String, dynamic>> _catalogItems = [
    {
      'id': 'p1',
      'name': 'Kopi Susu Gula Aren',
      'price': 22000,
      'category': 'Coffee',
      'description': 'Kopi susu khas PostSA dengan manis alami gula aren pilihan.',
    },
    {
      'id': 'p2',
      'name': 'Matcha Latte Iced',
      'price': 28000,
      'category': 'Non-Coffee',
      'description': 'Matcha Uji Jepang asli dipadu dengan susu segar.',
    },
    {
      'id': 'p3',
      'name': 'Nasi Goreng Wagyu',
      'price': 45000,
      'category': 'Food',
      'description': 'Nasi goreng harum dengan potongan daging wagyu lembut.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('Self-Order Catalog', style: AppTextStyles.titleLarge),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo Banner Slider Mockup
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Chip(
                    label: Text('PROMO SPESIAL', style: AppTextStyles.caption),
                    backgroundColor: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                  Text('Diskon 30% Semua Menu Kopi!',
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                  Text('Gunakan kode promo POSTSA30 saat checkout.',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pilihan Menu Favorit', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _catalogItems.length,
              itemBuilder: (ctx, i) {
                final item = _catalogItems[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood, color: AppColors.primary),
                    ),
                    title: Text(item['name'], style: AppTextStyles.titleMedium),
                    subtitle: Text(item['description'], style: AppTextStyles.caption),
                    trailing: Text(
                      'Rp ${item["price"]}',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
