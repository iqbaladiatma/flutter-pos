import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../shared/models/product_model.dart';
import '../../domain/repositories/customer_catalog_repository.dart';
import '../bloc/customer_catalog_bloc.dart';
import '../bloc/customer_catalog_event.dart';
import '../bloc/customer_catalog_state.dart';
import 'qr_scanner_screen.dart';

/// Customer-facing catalog screen with banners, category filter, and
/// QR table scanning.
class CustomerCatalogScreen extends StatelessWidget {
  final String outletId;

  const CustomerCatalogScreen({super.key, required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerCatalogBloc(
        repository: getIt<CustomerCatalogRepository>(),
      )..add(CustomerCatalogLoad(outletId: outletId)),
      child: _CustomerCatalogView(outletId: outletId),
    );
  }
}

class _CustomerCatalogView extends StatelessWidget {
  final String outletId;
  const _CustomerCatalogView({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu', style: AppTextStyles.titleLarge),
        actions: [
          BlocBuilder<CustomerCatalogBloc, CustomerCatalogState>(
            builder: (context, state) {
              if (state is CustomerCatalogLoaded) {
                return Row(
                  children: [
                    if (state.table != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.table_restaurant,
                              size: 18, color: Colors.white),
                          label: Text(
                            'Meja ${state.table!.name}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scan QR Meja',
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QrScannerScreen(outletId: outletId),
                          ),
                        );
                        if (result != null && context.mounted) {
                          // BLoC already handles the scan event from scanner
                        }
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CustomerCatalogBloc, CustomerCatalogState>(
        listener: (context, state) {
          if (state is CustomerCatalogError) {
            SnackbarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return switch (state) {
            CustomerCatalogInitial() => const _LoadingView(),
            CustomerCatalogLoading() => const _LoadingView(),
            CustomerCatalogLoaded() => _CatalogContent(state: state),
            CustomerCatalogError(:final message) =>
              _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

class _CatalogContent extends StatelessWidget {
  final CustomerCatalogLoaded state;
  const _CatalogContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Banners
        if (state.banners.isNotEmpty)
          SliverToBoxAdapter(
            child: _BannerCarousel(banners: state.banners),
          ),
        // Category chips
        SliverToBoxAdapter(
          child: _CategoryChips(
            categories: state.categories,
            selectedId: state.selectedCategoryId,
            onSelected: (id) => context
                .read<CustomerCatalogBloc>()
                .add(CustomerCatalogFilter(id)),
          ),
        ),
        // Products
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ProductCard(product: state.products[i]),
              childCount: state.products.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List banners;
  const _BannerCarousel({required this.banners});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: banners.length,
        itemBuilder: (ctx, i) {
          final banner = banners[i];
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title as String,
                        style: AppTextStyles.titleLarge
                            .copyWith(color: Colors.white),
                      ),
                      if (banner.ctaText != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            banner.ctaText as String,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          FilterChip(
            label: const Text('Semua'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat.name),
                  selected: selectedId == cat.id,
                  onSelected: (_) => onSelected(cat.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: double.infinity,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.restaurant, size: 40),
                      ),
                    )
                  : const Center(child: Icon(Icons.restaurant, size: 40)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(product.basePrice),
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
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
