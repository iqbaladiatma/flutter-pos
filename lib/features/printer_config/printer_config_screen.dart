import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/printer/thermal_printer_service.dart';

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({super.key});

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> {
  bool _isScanning = false;
  final List<ThermalPrinterDevice> _devices = [];
  StreamSubscription<ThermalPrinterDevice>? _btSub;
  StreamSubscription<ThermalPrinterDevice>? _usbSub;
  PrinterConnectionType _scanType = PrinterConnectionType.bluetooth;

  @override
  void dispose() {
    _btSub?.cancel();
    _usbSub?.cancel();
    super.dispose();
  }

  Future<void> _scanPrinters() async {
    setState(() => _isScanning = true);
    _devices.clear();

    if (_scanType == PrinterConnectionType.bluetooth) {
      _btSub = ThermalPrinterService()
          .scanBluetoothPrinters()
          .listen((device) {
        setState(() {
          if (!_devices.any((d) => d.address == device.address)) {
            _devices.add(device);
          }
        });
      }, onDone: () => setState(() => _isScanning = false));
    } else if (_scanType == PrinterConnectionType.usb) {
      _usbSub = ThermalPrinterService().scanUsbPrinters().listen((device) {
        setState(() {
          if (!_devices.any((d) => d.address == device.address)) {
            _devices.add(device);
          }
        });
      }, onDone: () => setState(() => _isScanning = false));
    } else {
      // Network scan is a Future, not a stream
      final found = await ThermalPrinterService().scanNetworkPrinters();
      setState(() {
        _devices.addAll(found);
        _isScanning = false;
      });
    }
  }

  void _stopScan() {
    _btSub?.cancel();
    _usbSub?.cancel();
    setState(() => _isScanning = false);
  }

  Future<void> _connect(ThermalPrinterDevice device) async {
    final success = await ThermalPrinterService().connectPrinter(device);
    if (!mounted) return;
    setState(() {});
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer ${device.name} terhubung')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke printer')),
      );
    }
  }

  Future<void> _testPrint(ThermalPrinterDevice device) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mencetak test ke ${device.name}...')),
    );
    final success = await ThermalPrinterService().testPrint(device);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Test cetak berhasil' : 'Test cetak gagal'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ThermalPrinterService();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.print, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('Pengaturan Printer Thermal',
                style: AppTextStyles.titleLarge),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection type selector
            const Text('Tipe Koneksi', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<PrinterConnectionType>(
              segments: const [
                ButtonSegment(
                  value: PrinterConnectionType.bluetooth,
                  label: Text('Bluetooth'),
                  icon: Icon(Icons.bluetooth),
                ),
                ButtonSegment(
                  value: PrinterConnectionType.network,
                  label: Text('Network'),
                  icon: Icon(Icons.wifi),
                ),
                ButtonSegment(
                  value: PrinterConnectionType.usb,
                  label: Text('USB'),
                  icon: Icon(Icons.usb),
                ),
              ],
              selected: {_scanType},
              onSelectionChanged: (set) =>
                  setState(() => _scanType = set.first),
            ),
            const SizedBox(height: 16),

            // Scan button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Perangkat Ditemukan',
                    style: AppTextStyles.titleLarge),
                if (_isScanning)
                  ElevatedButton.icon(
                    onPressed: _stopScan,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _scanPrinters,
                    icon: const Icon(Icons.search),
                    label: const Text('Pindai'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Active printers status
            if (service.isReceiptConnected || service.isKitchenConnected) ...[
              _ActivePrinterCard(
                title: 'Printer Struk',
                device: service.activeReceiptPrinter,
                connected: service.isReceiptConnected,
                onDisconnect: () => service.disconnectPrinter(
                    role: PrinterRole.receipt),
              ),
              const SizedBox(height: 8),
              _ActivePrinterCard(
                title: 'Printer Dapur',
                device: service.activeKitchenPrinter,
                connected: service.isKitchenConnected,
                onDisconnect: () => service.disconnectPrinter(
                    role: PrinterRole.kitchen),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Device list
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'Memindai perangkat...'
                            : 'Klik "Pindai" untuk mencari printer ESC/POS',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (ctx, i) {
                        final d = _devices[i];
                        return _DeviceCard(
                          device: d,
                          onConnect: () => _connect(d),
                          onTestPrint: () => _testPrint(d),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePrinterCard extends StatelessWidget {
  final String title;
  final ThermalPrinterDevice? device;
  final bool connected;
  final Future<void> Function() onDisconnect;

  const _ActivePrinterCard({
    required this.title,
    required this.device,
    required this.connected,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (!connected || device == null) return const SizedBox.shrink();
    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.success),
        title: Text('$title: ${device!.name}',
            style: AppTextStyles.titleMedium),
        subtitle: Text('${device!.address} • ${device!.paperWidth == PaperWidth.mm58 ? "58mm" : "80mm"}'),
        trailing: TextButton(
          onPressed: onDisconnect,
          child: const Text('Putuskan'),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ThermalPrinterDevice device;
  final VoidCallback onConnect;
  final VoidCallback onTestPrint;

  const _DeviceCard({
    required this.device,
    required this.onConnect,
    required this.onTestPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              device.connectionType == PrinterConnectionType.bluetooth
                  ? Icons.bluetooth
                  : device.connectionType == PrinterConnectionType.usb
                      ? Icons.usb
                      : Icons.wifi,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: AppTextStyles.titleMedium),
                  Text(
                    'Alamat: ${device.address} • ${device.connectionType.name.toUpperCase()}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: onConnect,
                  child: const Text('Hubungkan'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onTestPrint,
                  child: const Text('Tes Cetak'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
