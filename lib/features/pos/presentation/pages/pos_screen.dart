import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_retry.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/models/order_model.dart';
import '../../domain/repositories/pos_repository.dart';
import '../bloc/pos_bloc.dart';
import '../bloc/pos_event.dart';
import '../bloc/pos_state.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PosBloc(repository: getIt<PosRepository>())
        ..add(const PosLoadCatalog()),
      child: const _PosView(),
    );
  }
}

class _PosView extends StatelessWidget {
  const _PosView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PosBloc, PosState>(
      listener: (context, state) {
        if (state is PosError) {
          SnackbarHelper.showError(context, state.message);
        } else if (state is PosLoaded &&
            state.lastCompletedOrder != null) {
          _showSuccessDialog(context, state.lastCompletedOrder!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, PosState state) {
    final isConnected = getIt.isRegistered<PosRepository>();
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.point_of_sale, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          const Text('PostSA Cashier POS',
              style: AppTextStyles.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<PosBloc>().add(const PosLoadCatalog()),
          ),
          Chip(
            avatar:
                const Icon(Icons.circle, color: AppColors.success, size: 10),
            label: Text(
              isConnected ? 'Connected' : 'Offline',
              style: AppTextStyles.caption,
            ),
            backgroundColor: AppColors.surfaceLight,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PosState state) {
    return switch (state) {
      PosInitial() || PosLoading() => const LoadingOverlay(fullscreen: true),
      PosError(:final message) => ErrorRetry(
          message: message,
          onRetry: () =>
              context.read<PosBloc>().add(const PosLoadCatalog()),
        ),
      PosLoaded() => _buildCatalogAndCart(context, state),
    };
  }

  Widget _buildCatalogAndCart(BuildContext context, PosLoaded state) {
    // On tablet/desktop: side-by-side layout
    if (!ResponsiveHelper.isMobile(context)) {
      return Stack(
        children: [
          Row(
            children: [
              Expanded(flex: 6, child: _buildCatalogPanel(context, state)),
              Expanded(flex: 4, child: _buildCartPanel(context, state)),
            ],
          ),
          if (state.isProcessingPayment)
            const LoadingOverlay(
                fullscreen: true, message: 'Memproses pembayaran...'),
        ],
      );
    }

    // On mobile: catalog full screen with cart FAB + bottom sheet
    return Stack(
      children: [
        _buildCatalogPanel(context, state),
        // Cart floating button with badge
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showCartBottomSheet(context, state),
            icon: const Icon(Icons.shopping_cart),
            label: Text(
              state.isCartEmpty
                  ? 'Keranjang'
                  : '${state.cart.length} • ${CurrencyFormatter.format(state.cartTotal)}',
            ),
          ),
        ),
        if (state.isProcessingPayment)
          const LoadingOverlay(
              fullscreen: true, message: 'Memproses pembayaran...'),
      ],
    );
  }

  void _showCartBottomSheet(BuildContext context, PosLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Keranjang Transaksi',
                        style: AppTextStyles.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Cart content
              Expanded(
                child: _buildCartList(context, state),
              ),
              const Divider(height: 1),
              // Summary + checkout
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCartSummary(context, state),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'SIMPAN KE SUPABASE & CETAK',
                      onPressed: state.isCartEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              context.read<PosBloc>().add(
                                    const PosProcessPayment(
                                      outletId:
                                          '00000000-0000-0000-0000-000000000001',
                                    ),
                                  );
                            },
                      isLoading: state.isProcessingPayment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Left panel: categories + product grid ──────────────────────────
  Widget _buildCatalogPanel(BuildContext context, PosLoaded state) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryChips(context, state),
          const SizedBox(height: 16),
          Expanded(child: _buildProductGrid(context, state)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, PosLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua Menu'),
              selected: state.selectedCategoryId.isEmpty,
              onSelected: (_) => context
                  .read<PosBloc>()
                  .add(const PosFilterByCategory('')),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
            ),
          ),
          ...state.categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat.name),
                selected: state.selectedCategoryId == cat.id,
                onSelected: (_) => context
                    .read<PosBloc>()
                    .add(PosFilterByCategory(cat.id)),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, PosLoaded state) {
    if (state.products.isEmpty) {
      return const EmptyState(
        icon: Icons.restaurant_menu,
        title: 'Belum ada produk di Supabase',
        subtitle: 'Tambahkan produk dari dashboard admin.',
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.gridColumns(context),
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.85 : 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.products.length,
      itemBuilder: (ctx, i) {
        final p = state.products[i];
        return InkWell(
          onTap: () =>
              context.read<PosBloc>().add(PosAddToCart(product: p)),
          borderRadius: BorderRadius.circular(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_cafe,
                        color: AppColors.primary),
                  ),
                  Text(p.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    CurrencyFormatter.format(p.basePrice),
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Right panel: cart ──────────────────────────────────────────────
  Widget _buildCartPanel(BuildContext context, PosLoaded state) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keranjang Transaksi',
              style: AppTextStyles.titleLarge),
          const Divider(height: 24),
          Expanded(child: _buildCartList(context, state)),
          const Divider(height: 24),
          _buildCartSummary(context, state),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'SIMPAN KE SUPABASE & CETAK',
            onPressed: state.isCartEmpty
                ? null
                : () => context.read<PosBloc>().add(
                      const PosProcessPayment(
                        outletId:
                            '00000000-0000-0000-0000-000000000001',
                      ),
                    ),
            isLoading: state.isProcessingPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, PosLoaded state) {
    if (state.isCartEmpty) {
      return const EmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Pilih item produk dari katalog',
      );
    }

    return ListView.separated(
      itemCount: state.cart.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (ctx, i) {
        final item = state.cart[i];
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.bodyLarge),
                  Text(
                    '${CurrencyFormatter.format(item.unitPrice)} x ${item.qty}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(item.subtotal),
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: AppColors.error),
              onPressed: () => context
                  .read<PosBloc>()
                  .add(PosRemoveFromCart(item.id)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartSummary(BuildContext context, PosLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Subtotal', style: AppTextStyles.titleMedium),
        Text(
          CurrencyFormatter.format(state.cartTotal),
          style: AppTextStyles.titleLarge
              .copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }

  // ── Success dialog ─────────────────────────────────────────────────
  void _showSuccessDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 10),
            Text('Transaksi Berhasil!',
                style: AppTextStyles.titleMedium),
          ],
        ),
        content: Text(
          'Pesanan ${order.orderNumber} sebesar '
          '${CurrencyFormatter.format(order.total)} '
          'telah tersimpan di Supabase & struk dicetak.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PosBloc>().add(const PosDismissSuccess());
            },
            child: const Text('Pesanan Baru'),
          ),
        ],
      ),
    );
  }
}
