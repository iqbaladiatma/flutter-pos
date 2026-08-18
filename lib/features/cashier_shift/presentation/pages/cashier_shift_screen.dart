import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/printer/thermal_printer_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/repositories/cashier_shift_repository.dart';
import '../bloc/cashier_shift_bloc.dart';
import '../bloc/cashier_shift_state.dart';
import '../bloc/cashier_shift_event.dart';

/// Screen for managing cashier shifts: open, close, and view Z-Report.
class CashierShiftScreen extends StatelessWidget {
  final String outletId;
  final String staffId;

  const CashierShiftScreen({
    super.key,
    required this.outletId,
    required this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CashierShiftBloc(
        repository: getIt<CashierShiftRepository>(),
      )..add(CashierShiftCheckActive(outletId: outletId, staffId: staffId)),
      child: _CashierShiftView(outletId: outletId, staffId: staffId),
    );
  }
}

class _CashierShiftView extends StatelessWidget {
  final String outletId;
  final String staffId;

  const _CashierShiftView({required this.outletId, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.point_of_sale, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('Shift Kasir', style: AppTextStyles.titleLarge),
          ],
        ),
      ),
      body: BlocConsumer<CashierShiftBloc, CashierShiftState>(
        listener: (context, state) {
          if (state is CashierShiftError) {
            SnackbarHelper.showError(context, state.message);
          }
          if (state is CashierShiftOpened) {
            SnackbarHelper.showSuccess(context, 'Shift dibuka');
          }
          if (state is CashierShiftClosed) {
            SnackbarHelper.showSuccess(context, 'Shift ditutup');
          }
        },
        builder: (context, state) {
          return switch (state) {
            CashierShiftInitial() => const _LoadingView(),
            CashierShiftLoading() => const _LoadingView(),
            CashierShiftNone() => _OpenShiftForm(
                outletId: outletId,
                staffId: staffId,
              ),
            CashierShiftActive(:final shift) => _ActiveShiftView(
                shift: shift,
                outletId: outletId,
                staffId: staffId,
              ),
            CashierShiftOpened(:final shift) => _ActiveShiftView(
                shift: shift,
                outletId: outletId,
                staffId: staffId,
              ),
            CashierShiftClosed(:final shift) => _ClosedShiftView(shift: shift),
            CashierShiftZReportReady(:final report) =>
              _ZReportView(report: report),
            CashierShiftError(:final message) => _ErrorView(message: message),
          };
        },
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
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<CashierShiftBloc>().add(
                    CashierShiftCheckActive(
                      outletId: context
                          .findAncestorWidgetOfExactType<_CashierShiftView>()!
                          .outletId,
                      staffId: context
                          .findAncestorWidgetOfExactType<_CashierShiftView>()!
                          .staffId,
                    ),
                  ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenShiftForm extends StatefulWidget {
  final String outletId;
  final String staffId;

  const _OpenShiftForm({required this.outletId, required this.staffId});

  @override
  State<_OpenShiftForm> createState() => _OpenShiftFormState();
}

class _OpenShiftFormState extends State<_OpenShiftForm> {
  final _controller = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_open, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Buka Shift Kasir', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Masukkan modal kas awal sebelum mulai transaksi.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Modal Kas Awal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '0');
                if (amount == null || amount < 0) {
                  return 'Masukkan jumlah valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<CashierShiftBloc>().add(CashierShiftOpen(
                        outletId: widget.outletId,
                        staffId: widget.staffId,
                        openingCash: double.parse(_controller.text),
                      ));
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Buka Shift'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveShiftView extends StatelessWidget {
  final dynamic shift;
  final String outletId;
  final String staffId;

  const _ActiveShiftView({
    required this.shift,
    required this.outletId,
    required this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    final openedAt = DateTime.parse(shift.openedAt as String);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          const Text('Shift Aktif', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Modal Awal',
                    value: CurrencyFormatter.format(shift.openingCash as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Dibuka Pada',
                    value: '${openedAt.day}/${openedAt.month}/${openedAt.year} '
                        '${openedAt.hour}:${openedAt.minute.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _showCloseShiftDialog(context, shift.id as String),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Tutup Shift'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.read<CashierShiftBloc>().add(
                  CashierShiftGenerateZReport(shiftId: shift.id as String),
                ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Lihat Z-Report'),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context, String shiftId) {
    final controller = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tutup Shift Kasir'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Kas Akhir',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final closingCash = double.tryParse(controller.text) ?? 0;
              context.read<CashierShiftBloc>().add(CashierShiftClose(
                    shiftId: shiftId,
                    closingCash: closingCash,
                    expectedCash: shift.openingCash as double,
                  ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }
}

class _ClosedShiftView extends StatelessWidget {
  final dynamic shift;
  const _ClosedShiftView({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('Shift Ditutup', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Modal Awal',
                    value: CurrencyFormatter.format(shift.openingCash as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Kas Akhir',
                    value: CurrencyFormatter.format(
                        (shift.closingCash as num?)?.toDouble() ?? 0),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Selisih',
                    value: CurrencyFormatter.format(
                        ((shift.closingCash as num?)?.toDouble() ?? 0) -
                            (shift.openingCash as double)),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => context.read<CashierShiftBloc>().add(
                  CashierShiftGenerateZReport(shiftId: shift.id as String),
                ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Lihat Z-Report'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.read<CashierShiftBloc>().add(
                  CashierShiftCheckActive(
                    outletId: context
                        .findAncestorWidgetOfExactType<_CashierShiftView>()!
                        .outletId,
                    staffId: context
                        .findAncestorWidgetOfExactType<_CashierShiftView>()!
                        .staffId,
                  ),
                ),
            icon: const Icon(Icons.refresh),
            label: const Text('Cek Shift Baru'),
          ),
        ],
      ),
    );
  }
}

class _ZReportView extends StatelessWidget {
  final dynamic report;
  const _ZReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Z-Report', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Kasir', value: report.staffName as String),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Total Transaksi',
                    value: '${report.totalOrders}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Penjualan Kotor',
                    value: CurrencyFormatter.format(report.grossSales as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Total Diskon',
                    value: '-${CurrencyFormatter.format(report.totalDiscounts as double)}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Total Pajak',
                    value: CurrencyFormatter.format(report.totalTax as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Penjualan Bersih',
                    value: CurrencyFormatter.format(report.netSales as double),
                  ),
                  const Divider(),
                  _InfoRow(
                    label: 'Modal Awal',
                    value: CurrencyFormatter.format(report.openingCash as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Kas Akhir',
                    value: CurrencyFormatter.format(report.closingCash as double),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Selisih Kas',
                    value: CurrencyFormatter.format(report.cashDifference as double),
                  ),
                  const Divider(),
                  const Text('Penjualan per Metode', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  ...(report.salesByPaymentMethod as Map).entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _InfoRow(
                        label: e.key.toString().toUpperCase(),
                        value: CurrencyFormatter.format(
                            (e.value as num).toDouble()),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _printZReport(context, report),
            icon: const Icon(Icons.print),
            label: const Text('Cetak Z-Report'),
          ),
        ],
      ),
    );
  }

  void _printZReport(BuildContext context, dynamic report) {
    final printer = ThermalPrinterService();
    if (!printer.isReceiptConnected) {
      SnackbarHelper.showWarning(context, 'Printer struk belum terhubung');
      return;
    }
    // Build Z-Report items for printer
    final items = <Map<String, dynamic>>[
      {'qty': 1, 'name': 'Total Transaksi', 'price': 0.0},
      {'qty': report.totalOrders, 'name': 'Penjualan Kotor', 'price': report.grossSales},
      {'qty': 1, 'name': 'Diskon', 'price': -report.totalDiscounts},
      {'qty': 1, 'name': 'Pajak', 'price': report.totalTax},
      {'qty': 1, 'name': 'Penjualan Bersih', 'price': report.netSales},
    ];
    printer.printReceipt(
      orderNumber: 'Z-REPORT-${report.shiftId.toString().substring(0, 8)}',
      outletName: 'Z-REPORT',
      items: items,
      subtotal: report.grossSales,
      discount: report.totalDiscounts,
      tax: report.totalTax,
      total: report.netSales,
      paymentMethod: 'Z-REPORT',
      footerText: 'Kasir: ${report.staffName}',
    );
    SnackbarHelper.showSuccess(context, 'Z-Report dicetak');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(value, style: AppTextStyles.titleMedium),
      ],
    );
  }
}
