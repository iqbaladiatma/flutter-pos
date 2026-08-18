import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/repositories/customer_delivery_repository.dart';
import '../../services/biteship_service.dart';

/// Customer checkout screen for delivery orders.
///
/// Flow:
/// 1. Select/add delivery address
/// 2. Calculate shipping rates via Biteship
/// 3. Select courier service
/// 4. Confirm order
class CustomerCheckoutScreen extends StatefulWidget {
  final String customerId;
  final String outletPostalCode;
  final double orderTotal;
  final int totalWeightGrams;

  const CustomerCheckoutScreen({
    super.key,
    required this.customerId,
    required this.outletPostalCode,
    required this.orderTotal,
    required this.totalWeightGrams,
  });

  @override
  State<CustomerCheckoutScreen> createState() =>
      _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState
    extends State<CustomerCheckoutScreen> {
  final _repo = getIt<CustomerDeliveryRepository>();
  List<DeliveryAddress> _addresses = [];
  DeliveryAddress? _selectedAddress;
  List<ShippingRate> _rates = [];
  ShippingRate? _selectedRate;
  bool _isLoadingAddresses = true;
  bool _isLoadingRates = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final result =
        await _repo.getDeliveryAddresses(customerId: widget.customerId);
    result.fold(
      ifLeft: (failure) {
        SnackbarHelper.showError(context, failure.message);
        setState(() => _isLoadingAddresses = false);
      },
      ifRight: (addresses) {
        setState(() {
          _addresses = addresses;
          _isLoadingAddresses = false;
          if (addresses.isNotEmpty) {
            _selectedAddress = addresses.first;
            _loadRates();
          }
        });
      },
    );
  }

  Future<void> _loadRates() async {
    if (_selectedAddress == null) return;
    setState(() => _isLoadingRates = true);

    final result = await _repo.getShippingRates(
      originPostalCode: widget.outletPostalCode,
      destinationPostalCode: _selectedAddress!.postalCode,
      weight: widget.totalWeightGrams,
    );

    result.fold(
      ifLeft: (failure) {
        SnackbarHelper.showError(context, failure.message);
        setState(() => _isLoadingRates = false);
      },
      ifRight: (rates) {
        setState(() {
          _rates = rates;
          _isLoadingRates = false;
          if (rates.isNotEmpty) _selectedRate = rates.first;
        });
      },
    );
  }

  double get _grandTotal =>
      widget.orderTotal + (_selectedRate?.price ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: AppTextStyles.titleLarge),
      ),
      body: _isLoadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address section
                  const Text('Alamat Pengiriman',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  if (_addresses.isEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.add_location,
                            color: AppColors.primary),
                        title: const Text('Tambah Alamat Baru'),
                        onTap: () => _showAddAddressDialog(),
                      ),
                    )
                  else
                    ..._addresses.map((addr) => ListTile(
                          leading: Icon(
                            _selectedAddress?.id == addr.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                          ),
                          title: Text(addr.label),
                          subtitle: Text(
                              '${addr.recipientName} • ${addr.fullAddress}'),
                          onTap: () {
                            setState(() {
                              _selectedAddress = addr;
                              _rates = [];
                              _selectedRate = null;
                            });
                            _loadRates();
                          },
                        )),
                  if (_addresses.isNotEmpty)
                    TextButton.icon(
                      onPressed: _showAddAddressDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Alamat'),
                    ),
                  const SizedBox(height: 16),
                  // Shipping rates
                  const Text('Pilih Kurir', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  if (_isLoadingRates)
                    const Center(child: CircularProgressIndicator())
                  else if (_rates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Pilih alamat untuk melihat opsi pengiriman',
                          style: AppTextStyles.caption),
                    )
                  else
                    ..._rates.map((rate) => ListTile(
                          leading: Icon(
                            _selectedRate?.courier == rate.courier
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: AppColors.primary,
                          ),
                          title: Text(
                              '${rate.courierName} - ${rate.service}'),
                          subtitle: Text('ETD: ${rate.etd}'),
                          trailing: Text(
                            CurrencyFormatter.format(rate.price),
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.primary),
                          ),
                          onTap: () =>
                              setState(() => _selectedRate = rate),
                        )),
                  const SizedBox(height: 16),
                  // Total
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _TotalRow(
                              label: 'Subtotal Pesanan',
                              value: CurrencyFormatter.format(widget.orderTotal)),
                          const SizedBox(height: 8),
                          _TotalRow(
                              label: 'Ongkir',
                              value: _selectedRate != null
                                  ? CurrencyFormatter.format(
                                      _selectedRate!.price)
                                  : '-'),
                          const Divider(),
                          _TotalRow(
                            label: 'Total',
                            value: CurrencyFormatter.format(_grandTotal),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Place order
                  FilledButton.icon(
                    onPressed: (_selectedAddress != null &&
                            _selectedRate != null &&
                            !_isPlacingOrder)
                        ? _placeOrder
                        : null,
                    icon: _isPlacingOrder
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isPlacingOrder
                        ? 'Memproses...'
                        : 'Buat Pesanan'),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddAddressDialog() {
    final labelCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final postalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Alamat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label (Rumah/Kantor)')),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Penerima')),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                  keyboardType: TextInputType.phone),
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                  maxLines: 2),
              TextField(
                  controller: postalCtrl,
                  decoration: const InputDecoration(labelText: 'Kode Pos'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (labelCtrl.text.isEmpty || addrCtrl.text.isEmpty) return;
              final result = await _repo.saveDeliveryAddress(
                customerId: widget.customerId,
                label: labelCtrl.text,
                recipientName: nameCtrl.text,
                phone: phoneCtrl.text,
                fullAddress: addrCtrl.text,
                postalCode: postalCtrl.text,
              );
              result.fold(
                ifLeft: (failure) =>
                    SnackbarHelper.showError(context, failure.message),
                ifRight: (addr) {
                  setState(() {
                    _addresses.insert(0, addr);
                    _selectedAddress = addr;
                  });
                  _loadRates();
                },
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _placeOrder() async {
    if (_selectedAddress == null || _selectedRate == null) return;

    setState(() => _isPlacingOrder = true);

    final result = await _repo.createShipment(
      originContactName: 'PostSA Outlet',
      originContactPhone: '080000000000',
      originAddress: 'Outlet Address',
      originPostalCode: widget.outletPostalCode,
      destinationContactName: _selectedAddress!.recipientName,
      destinationContactPhone: _selectedAddress!.phone,
      destinationAddress: _selectedAddress!.fullAddress,
      destinationPostalCode: _selectedAddress!.postalCode,
      courierCompany: _selectedRate!.courier,
      courierService: _selectedRate!.service,
      weight: widget.totalWeightGrams,
      items: [
        ShipmentItem(name: 'Pesanan', quantity: 1, weight: widget.totalWeightGrams),
      ],
    );

    setState(() => _isPlacingOrder = false);

    result.fold(
      ifLeft: (failure) =>
          SnackbarHelper.showError(context, failure.message),
      ifRight: (shipmentId) {
        SnackbarHelper.showSuccess(
            context, 'Pesanan dibuat! ID: $shipmentId');
        if (mounted) Navigator.pop(context, shipmentId);
      },
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isBold
                ? AppTextStyles.titleMedium
                : AppTextStyles.bodyMedium),
        Text(value,
            style: isBold
                ? AppTextStyles.titleLarge.copyWith(color: AppColors.primary)
                : AppTextStyles.titleMedium),
      ],
    );
  }
}
