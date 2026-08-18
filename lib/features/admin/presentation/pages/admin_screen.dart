import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/repositories/admin_repository.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

/// Admin dashboard screen with analytics, charts, and management tabs.
class AdminScreen extends StatelessWidget {
  final String outletId;

  const AdminScreen({super.key, required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(repository: getIt<AdminRepository>())
        ..add(AdminLoadDashboard(outletId: outletId)),
      child: _AdminView(outletId: outletId),
    );
  }
}

class _AdminView extends StatelessWidget {
  final String outletId;
  const _AdminView({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: AppTextStyles.titleLarge),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<AdminBloc>().add(
                    AdminRefresh(outletId: outletId),
                  ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Analytics'),
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
              Tab(icon: Icon(Icons.people), text: 'Staf'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AnalyticsTab(outletId: outletId),
            _MenuTab(outletId: outletId),
            _StaffTab(outletId: outletId),
          ],
        ),
      ),
    );
  }
}

// ── Analytics Tab ──────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final String outletId;
  const _AnalyticsTab({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminError) {
          SnackbarHelper.showError(context, state.message);
        }
        if (state is AdminDashboardLoaded && state.errorMessage != null) {
          SnackbarHelper.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        return switch (state) {
          AdminInitial() => const _LoadingView(),
          AdminLoading() => const _LoadingView(),
          AdminDashboardLoaded() => _AnalyticsContent(state: state),
          AdminProductsLoaded() => const _LoadingView(),
          AdminStaffLoaded() => const _LoadingView(),
          AdminError(:final message) => _ErrorView(message: message),
        };
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final AdminDashboardLoaded state;
  const _AnalyticsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI cards row
        if (summary != null) ...[
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Penjualan Hari Ini',
                  value: CurrencyFormatter.format(summary.totalSales),
                  icon: Icons.payments,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Total Pesanan',
                  value: '${summary.totalOrders}',
                  icon: Icons.receipt_long,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Avg Order Value',
                  value: CurrencyFormatter.format(summary.avgOrderValue),
                  icon: Icons.trending_up,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiCard(
                  title: 'Pelanggan',
                  value: '${summary.totalCustomers}',
                  icon: Icons.people,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Hourly chart
        const Text('Penjualan per Jam', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        _HourlyChart(state: state),
        const SizedBox(height: 16),
        // Payment method breakdown
        const Text('Per Metode Pembayaran', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        if (state.paymentBreakdown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Belum ada data', style: AppTextStyles.caption),
            ),
          )
        else
          ...state.paymentBreakdown.map((m) => _PaymentMethodCard(
                method: m.method,
                total: m.total,
                count: m.count,
              )),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.caption, maxLines: 1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  final AdminDashboardLoaded state;
  const _HourlyChart({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingChart) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hourlyData = state.hourlySales;
    if (hourlyData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Belum ada data', style: AppTextStyles.caption),
        ),
      );
    }

    // Find max for scaling
    double maxSales = 0;
    for (final h in hourlyData) {
      if (h.sales > maxSales) maxSales = h.sales;
    }
    if (maxSales == 0) maxSales = 1;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSales * 1.1,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final hour = hourlyData[group.x.toInt()].hour;
                final sales = hourlyData[group.x.toInt()].sales;
                return BarTooltipItem(
                  '$hour:00\n${CurrencyFormatter.format(sales)}',
                  const TextStyle(
                      color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour % 4 != 0) return const SizedBox.shrink();
                  return Text('$hour', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    CurrencyFormatter.format(value),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: hourlyData
              .map((h) => BarChartGroupData(
                    x: h.hour,
                    barRods: [
                      BarChartRodData(
                        toY: h.sales,
                        color: AppColors.primary,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String method;
  final double total;
  final int count;

  const _PaymentMethodCard({
    required this.method,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (method) {
      'cash' => Icons.money,
      'qris' => Icons.qr_code,
      'card' => Icons.credit_card,
      'transfer' => Icons.account_balance,
      _ => Icons.payment,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(method.toUpperCase(), style: AppTextStyles.bodyMedium),
        subtitle: Text('$count transaksi', style: AppTextStyles.caption),
        trailing: Text(
          CurrencyFormatter.format(total),
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

// ── Menu Management Tab ────────────────────────────────────────────

class _MenuTab extends StatelessWidget {
  final String outletId;
  const _MenuTab({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Manajemen Menu', style: AppTextStyles.titleMedium),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddProductDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state is AdminProductsLoaded
                  ? state.products.isEmpty
                      ? const Center(
                          child: Text('Belum ada produk',
                              style: AppTextStyles.caption),
                        )
                      : ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return ListTile(
                              title: Text(product['name'] ?? ''),
                              subtitle: Text(
                                CurrencyFormatter.format(
                                    (product['base_price'] as num?)
                                            ?.toDouble() ??
                                        0),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: AppColors.error),
                                    onPressed: () => context
                                        .read<AdminBloc>()
                                        .add(AdminDeleteProduct(
                                          productId: product['id'],
                                          outletId: outletId,
                                        )),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Produk'),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Harga'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: catCtrl,
              decoration:
                  const InputDecoration(labelText: 'Category ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0;
              final cat = catCtrl.text.trim();
              if (name.isEmpty || cat.isEmpty) return;
              context.read<AdminBloc>().add(AdminCreateProduct(
                    outletId: outletId,
                    name: name,
                    basePrice: price,
                    categoryId: cat,
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ── Staff Management Tab ───────────────────────────────────────────

class _StaffTab extends StatelessWidget {
  final String outletId;
  const _StaffTab({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Manajemen Staf', style: AppTextStyles.titleMedium),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddStaffDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state is AdminStaffLoaded
                  ? state.staff.isEmpty
                      ? const Center(
                          child: Text('Belum ada staf',
                              style: AppTextStyles.caption),
                        )
                      : ListView.builder(
                          itemCount: state.staff.length,
                          itemBuilder: (context, index) {
                            final item = state.staff[index];
                            final staff = item['staff'] as Map<String, dynamic>? ?? {};
                            final role = item['role'] ?? '-';
                            return ListTile(
                              leading: const Icon(Icons.person, color: AppColors.primary),
                              title: Text(staff['name'] ?? '-'),
                              subtitle: Text('$role • ${staff['phone'] ?? '-'}'),
                              trailing: Switch(
                                value: staff['is_active'] ?? true,
                                activeThumbColor: AppColors.success,
                                onChanged: (value) {
                                  context.read<AdminBloc>().add(
                                        AdminUpdateStaff(
                                          staffId: staff['id'],
                                          isActive: value,
                                        ),
                                      );
                                },
                              ),
                            );
                          },
                        )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'kasir';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Staf'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'No. HP'),
                keyboardType: TextInputType.phone,
              ),
              DropdownButton<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'kasir'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) return;
                context.read<AdminBloc>().add(AdminCreateStaff(
                      outletId: outletId,
                      name: name,
                      phone: phone,
                      role: role,
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────

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
