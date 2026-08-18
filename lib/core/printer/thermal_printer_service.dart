import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pos_printer_platform_image_3_sdt/flutter_pos_printer_platform_image_3_sdt.dart';

/// Paper width specification for thermal printers.
enum PaperWidth { mm58, mm80 }

/// Role of a printer in the outlet (receipt vs kitchen ticket).
enum PrinterRole { receipt, kitchen }

/// Connection type for a thermal printer device.
enum PrinterConnectionType { bluetooth, network, usb }

/// Represents a discovered or configured thermal printer device.
class ThermalPrinterDevice {
  final String name;
  final String address; // MAC address (BT) or IP:port (network) or device path (USB)
  final PrinterConnectionType connectionType;
  final PrinterRole role;
  final PaperWidth paperWidth;
  final int? vendorId; // USB only
  final int? productId; // USB only

  const ThermalPrinterDevice({
    required this.name,
    required this.address,
    required this.connectionType,
    this.role = PrinterRole.receipt,
    this.paperWidth = PaperWidth.mm80,
    this.vendorId,
    this.productId,
  });

  ThermalPrinterDevice copyWith({
    String? name,
    String? address,
    PrinterConnectionType? connectionType,
    PrinterRole? role,
    PaperWidth? paperWidth,
    int? vendorId,
    int? productId,
  }) =>
      ThermalPrinterDevice(
        name: name ?? this.name,
        address: address ?? this.address,
        connectionType: connectionType ?? this.connectionType,
        role: role ?? this.role,
        paperWidth: paperWidth ?? this.paperWidth,
        vendorId: vendorId ?? this.vendorId,
        productId: productId ?? this.productId,
      );
}

/// Real thermal printer service using `flutter_pos_printer_platform`.
///
/// Supports Bluetooth, Network (TCP/IP), and USB connections.
/// Generates ESC/POS commands for 58mm and 80mm paper widths.
class ThermalPrinterService {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  final PrinterManager _manager = PrinterManager.instance;

  ThermalPrinterDevice? _activeReceiptPrinter;
  ThermalPrinterDevice? _activeKitchenPrinter;

  bool _isReceiptConnected = false;
  bool _isKitchenConnected = false;

  // ── Connection state ───────────────────────────────────────────────
  ThermalPrinterDevice? get activeReceiptPrinter => _activeReceiptPrinter;
  ThermalPrinterDevice? get activeKitchenPrinter => _activeKitchenPrinter;
  bool get isReceiptConnected => _isReceiptConnected;
  bool get isKitchenConnected => _isKitchenConnected;
  bool get isConnected => _isReceiptConnected || _isKitchenConnected;

  // ── Discovery ──────────────────────────────────────────────────────

  /// Scans for Bluetooth printers (Android/iOS only).
  ///
  /// Returns a stream of discovered devices. Callers should listen
  /// until the stream completes or a timeout is reached.
  Stream<ThermalPrinterDevice> scanBluetoothPrinters({bool isBle = false}) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const Stream.empty();
    }
    return _manager
        .discovery(type: PrinterType.bluetooth, isBle: isBle)
        .map((device) => ThermalPrinterDevice(
              name: device.name,
              address: device.address ?? '',
              connectionType: PrinterConnectionType.bluetooth,
            ));
  }

  /// Scans for USB printers (Android/Windows only).
  Stream<ThermalPrinterDevice> scanUsbPrinters() {
    if (!Platform.isAndroid && !Platform.isWindows) {
      return const Stream.empty();
    }
    return _manager.discovery(type: PrinterType.usb).map((device) {
      return ThermalPrinterDevice(
        name: device.name,
        address: device.vendorId ?? device.productId ?? '',
        connectionType: PrinterConnectionType.usb,
        vendorId: int.tryParse(device.vendorId ?? ''),
        productId: int.tryParse(device.productId ?? ''),
      );
    });
  }

  /// Discovers network printers on the local subnet (TCP port 9100).
  ///
  /// [hostIp] is the device's local IP for subnet detection.
  /// On mobile, this is auto-detected; on desktop, pass it explicitly.
  Future<List<ThermalPrinterDevice>> scanNetworkPrinters({
    String? hostIp,
    int port = 9100,
  }) async {
    try {
      final discovered = await TcpPrinterConnector.discoverPrinters(
        ipAddress: hostIp,
        port: port,
      );
      return discovered
          .map((d) => ThermalPrinterDevice(
                name: d.name,
                address: d.detail.address,
                connectionType: PrinterConnectionType.network,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Network printer scan error: $e');
      }
      return [];
    }
  }

  // ── Connection ─────────────────────────────────────────────────────

  /// Connects to a printer and assigns it a [PrinterRole].
  Future<bool> connectPrinter(ThermalPrinterDevice device) async {
    try {
      final input = _buildInput(device);
      final printerType = _mapConnectionType(device.connectionType);

      final success = await _manager.connect(
        type: printerType,
        model: input,
      );

      if (success) {
        if (device.role == PrinterRole.kitchen) {
          _activeKitchenPrinter = device;
          _isKitchenConnected = true;
        } else {
          _activeReceiptPrinter = device;
          _isReceiptConnected = true;
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Printer connect error: $e');
      }
      return false;
    }
  }

  /// Disconnects a printer by role.
  Future<bool> disconnectPrinter({PrinterRole role = PrinterRole.receipt}) async {
    try {
      final device =
          role == PrinterRole.kitchen ? _activeKitchenPrinter : _activeReceiptPrinter;
      if (device == null) return true;

      final printerType = _mapConnectionType(device.connectionType);
      final success = await _manager.disconnect(type: printerType);

      if (success) {
        if (role == PrinterRole.kitchen) {
          _isKitchenConnected = false;
          _activeKitchenPrinter = null;
        } else {
          _isReceiptConnected = false;
          _activeReceiptPrinter = null;
        }
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Printer disconnect error: $e');
      }
      return false;
    }
  }

  // ── Printing: Receipt ──────────────────────────────────────────────

  /// Prints a customer receipt to the receipt printer.
  ///
  /// Uses the currently connected receipt printer. If none connected,
  /// falls back to debug console output.
  Future<void> printReceipt({
    required String orderNumber,
    required String outletName,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMethod,
    double subtotal = 0,
    double discount = 0,
    double tax = 0,
    double paidAmount = 0,
    double changeAmount = 0,
    String? cashierName,
    String? footerText,
  }) async {
    final device = _activeReceiptPrinter;
    if (device == null || !_isReceiptConnected) {
      _debugPrintReceipt(orderNumber, outletName, items, total, paymentMethod);
      return;
    }

    final bytes = EscPosBuilder.buildReceipt(
      outletName: outletName,
      orderNumber: orderNumber,
      items: items,
      subtotal: subtotal > 0 ? subtotal : total,
      discount: discount,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      cashierName: cashierName,
      footerText: footerText,
      paperWidth: device.paperWidth,
    );

    await _sendBytes(bytes, device.connectionType);
  }

  // ── Printing: Kitchen Ticket ───────────────────────────────────────

  /// Prints a kitchen ticket (label) to the kitchen printer.
  Future<void> printKitchenLabel({
    required String orderNumber,
    required String orderType,
    required List<Map<String, dynamic>> kitchenItems,
    String? tableNumber,
  }) async {
    final device = _activeKitchenPrinter ?? _activeReceiptPrinter;
    if (device == null || !_isKitchenConnected && !_isReceiptConnected) {
      _debugPrintKitchen(orderNumber, orderType, kitchenItems);
      return;
    }

    final bytes = EscPosBuilder.buildKitchenTicket(
      orderNumber: orderNumber,
      orderType: orderType,
      kitchenItems: kitchenItems,
      tableNumber: tableNumber,
      paperWidth: device.paperWidth,
    );

    await _sendBytes(bytes, device.connectionType);
  }

  // ── Test Print ─────────────────────────────────────────────────────

  /// Prints a test pattern to verify printer connectivity.
  Future<bool> testPrint(ThermalPrinterDevice device) async {
    final connected = await connectPrinter(device);
    if (!connected) return false;

    final bytes = EscPosBuilder.buildTestPattern(paperWidth: device.paperWidth);
    await _sendBytes(bytes, device.connectionType);

    await Future.delayed(const Duration(milliseconds: 500));
    await disconnectPrinter(role: device.role);
    return true;
  }

  // ── Internal helpers ───────────────────────────────────────────────

  BasePrinterInput _buildInput(ThermalPrinterDevice device) {
    switch (device.connectionType) {
      case PrinterConnectionType.bluetooth:
        return BluetoothPrinterInput(address: device.address);
      case PrinterConnectionType.network:
        final parts = device.address.split(':');
        return TcpPrinterInput(
          ipAddress: parts.first,
          port: parts.length > 1 ? int.tryParse(parts[1]) ?? 9100 : 9100,
        );
      case PrinterConnectionType.usb:
        return UsbPrinterInput(
          vendorId: device.vendorId?.toString(),
          productId: device.productId?.toString(),
        );
    }
  }

  PrinterType _mapConnectionType(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return PrinterType.bluetooth;
      case PrinterConnectionType.network:
        return PrinterType.network;
      case PrinterConnectionType.usb:
        return PrinterType.usb;
    }
  }

  Future<void> _sendBytes(
    List<int> bytes,
    PrinterConnectionType connectionType,
  ) async {
    try {
      final printerType = _mapConnectionType(connectionType);
      await _manager.send(type: printerType, bytes: bytes);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Print send error: $e');
      }
    }
  }

  void _debugPrintReceipt(
    String orderNumber,
    String outletName,
    List<Map<String, dynamic>> items,
    double total,
    String paymentMethod,
  ) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('=== RECEIPT (no printer connected) ===');
    // ignore: avoid_print
    print('Outlet: $outletName');
    // ignore: avoid_print
    print('Order #: $orderNumber');
    for (final item in items) {
      // ignore: avoid_print
      print('${item["qty"]}x ${item["name"]} - Rp${item["price"]}');
    }
    // ignore: avoid_print
    print('TOTAL: Rp$total ($paymentMethod)');
    // ignore: avoid_print
    print('======================================');
  }

  void _debugPrintKitchen(
    String orderNumber,
    String orderType,
    List<Map<String, dynamic>> kitchenItems,
  ) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('=== KITCHEN TICKET (no printer) ===');
    // ignore: avoid_print
    print('Order #: $orderNumber [$orderType]');
    for (final item in kitchenItems) {
      // ignore: avoid_print
      print('${item["qty"]}x ${item["name"]} (Note: ${item["note"] ?? "-"})');
    }
    // ignore: avoid_print
    print('====================================');
  }
}

/// ESC/POS command builder for 58mm and 80mm thermal printers.
///
/// Generates raw ESC/POS byte arrays without external dependencies.
/// Supports text styling, alignment, barcodes, and paper cut.
class EscPosBuilder {
  EscPosBuilder._();

  // ESC/POS command constants
  static const int _esc = 0x1B;
  static const int _gs = 0x1D;
  static const int _lf = 0x0A;
  static const int _init = 0x40;

  // Paper width in characters (approx)
  static int _maxChars(PaperWidth width) =>
      width == PaperWidth.mm58 ? 32 : 48;

  /// Initializes the printer (ESC @).
  static List<int> _initPrinter() => [_esc, _init];

  /// Line feed.
  static List<int> _feed({int lines = 1}) =>
      List.filled(lines, _lf);

  /// Cut paper (GS V 1 = partial cut).
  static List<int> _cut() => [_gs, 0x56, 0x01];

  /// Set text double width + height (GS ! 0x30).
  static List<int> _doubleSize() => [_gs, 0x21, 0x30];

  /// Set text normal size (GS ! 0x00).
  static List<int> _normalSize() => [_gs, 0x21, 0x00];

  /// Bold ON (ESC E 1).
  static List<int> _boldOn() => [_esc, 0x45, 0x01];

  /// Bold OFF (ESC E 0).
  static List<int> _boldOff() => [_esc, 0x45, 0x00];

  /// Center align (ESC a 1).
  static List<int> _center() => [_esc, 0x61, 0x01];

  /// Left align (ESC a 0).
  static List<int> _left() => [_esc, 0x61, 0x00];

  /// Right align (ESC a 2).
  static List<int> _right() => [_esc, 0x61, 0x02];

  /// Builds a full customer receipt.
  static List<int> buildReceipt({
    required String outletName,
    required String orderNumber,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double total,
    required String paymentMethod,
    double discount = 0,
    double tax = 0,
    double paidAmount = 0,
    double changeAmount = 0,
    String? cashierName,
    String? footerText,
    PaperWidth paperWidth = PaperWidth.mm80,
  }) {
    List<int> bytes = <int>[];
    final maxChars = _maxChars(paperWidth);

    bytes += _initPrinter();

    // Header
    bytes += _center();
    bytes += _doubleSize();
    bytes += _boldOn();
    bytes += _encodeText(outletName);
    bytes += _boldOff();
    bytes += _normalSize();
    bytes += _feed(lines: 1);
    bytes += _encodeText('Order: $orderNumber');
    bytes += _feed(lines: 1);
    bytes += _encodeText(
        DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '));
    if (cashierName != null) {
      bytes += _feed(lines: 1);
      bytes += _encodeText('Kasir: $cashierName');
    }
    bytes += _feed(lines: 2);

    // Separator
    bytes += _left();
    bytes += _encodeText('-' * maxChars);
    bytes += _feed(lines: 1);

    // Items
    for (final item in items) {
      final qty = item['qty'] ?? 1;
      final name = item['name'] ?? '';
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final lineTotal = price * qty;
      bytes += _encodeText('$qty x $name');
      bytes += _feed(lines: 1);
      bytes += _right();
      bytes += _encodeText(_formatRp(lineTotal));
      bytes += _left();
      bytes += _feed(lines: 1);
    }

    // Separator
    bytes += _encodeText('-' * maxChars);
    bytes += _feed(lines: 1);

    // Totals
    bytes += _formatLine('Subtotal', _formatRp(subtotal), maxChars);
    if (discount > 0) {
      bytes += _formatLine('Diskon', '-${_formatRp(discount)}', maxChars);
    }
    if (tax > 0) {
      bytes += _formatLine('Pajak', _formatRp(tax), maxChars);
    }
    bytes += _feed(lines: 1);
    bytes += _boldOn();
    bytes += _formatLine('TOTAL', _formatRp(total), maxChars);
    bytes += _boldOff();
    bytes += _feed(lines: 1);

    // Payment
    bytes += _formatLine('Bayar ($paymentMethod)', _formatRp(paidAmount > 0 ? paidAmount : total), maxChars);
    if (changeAmount > 0) {
      bytes += _formatLine('Kembalian', _formatRp(changeAmount), maxChars);
    }
    bytes += _feed(lines: 2);

    // Footer
    bytes += _center();
    bytes += _encodeText(footerText ?? 'Terima kasih atas kunjungan Anda!');
    bytes += _feed(lines: 2);

    // Cut
    bytes += _cut();

    return bytes;
  }

  /// Builds a kitchen ticket (label) for kitchen staff.
  static List<int> buildKitchenTicket({
    required String orderNumber,
    required String orderType,
    required List<Map<String, dynamic>> kitchenItems,
    String? tableNumber,
    PaperWidth paperWidth = PaperWidth.mm80,
  }) {
    List<int> bytes = <int>[];
    final maxChars = _maxChars(paperWidth);

    bytes += _initPrinter();

    // Header
    bytes += _center();
    bytes += _doubleSize();
    bytes += _boldOn();
    bytes += _encodeText(orderType.toUpperCase());
    bytes += _boldOff();
    bytes += _normalSize();
    bytes += _feed(lines: 1);
    bytes += _encodeText('Order: $orderNumber');
    if (tableNumber != null) {
      bytes += _feed(lines: 1);
      bytes += _encodeText('Meja: $tableNumber');
    }
    bytes += _feed(lines: 1);
    bytes += _encodeText(
        DateTime.now().toIso8601String().substring(11, 19));
    bytes += _feed(lines: 2);

    // Separator
    bytes += _left();
    bytes += _encodeText('=' * maxChars);
    bytes += _feed(lines: 1);

    // Items
    for (final item in kitchenItems) {
      final qty = item['qty'] ?? 1;
      final name = item['name'] ?? '';
      final note = item['note'] ?? item['notes'];

      bytes += _boldOn();
      bytes += _encodeText('$qty x $name');
      bytes += _boldOff();
      bytes += _feed(lines: 1);

      if (note != null && note.toString().isNotEmpty) {
        bytes += _encodeText('  Note: $note');
        bytes += _feed(lines: 1);
      }
    }

    bytes += _feed(lines: 2);
    bytes += _cut();

    return bytes;
  }

  /// Builds a test print pattern.
  static List<int> buildTestPattern({
    PaperWidth paperWidth = PaperWidth.mm80,
  }) {
    List<int> bytes = <int>[];
    final maxChars = _maxChars(paperWidth);

    bytes += _initPrinter();
    bytes += _center();
    bytes += _doubleSize();
    bytes += _boldOn();
    bytes += _encodeText('PRINTER TEST');
    bytes += _boldOff();
    bytes += _normalSize();
    bytes += _feed(lines: 2);
    bytes += _left();
    bytes += _encodeText('PostSA Thermal Printer');
    bytes += _feed(lines: 1);
    bytes += _encodeText('Paper: ${paperWidth == PaperWidth.mm58 ? "58mm" : "80mm"} ($maxChars chars)');
    bytes += _feed(lines: 1);
    bytes += _encodeText('Time: ${DateTime.now().toIso8601String()}');
    bytes += _feed(lines: 1);
    bytes += _encodeText('-' * maxChars);
    bytes += _feed(lines: 1);
    bytes += _boldOn();
    bytes += _encodeText('Bold text test');
    bytes += _boldOff();
    bytes += _feed(lines: 1);
    bytes += _center();
    bytes += _encodeText('Center aligned');
    bytes += _feed(lines: 1);
    bytes += _right();
    bytes += _encodeText('Right aligned');
    bytes += _feed(lines: 2);
    bytes += _cut();

    return bytes;
  }

  // ── Utility ────────────────────────────────────────────────────────

  /// Encodes text to bytes (Latin-1 / Windows-1252 compatible).
  static List<int> _encodeText(String text) {
    try {
      return text.codeUnits;
    } catch (_) {
      return text.replaceAll(RegExp(r'[^\x20-\x7E]'), '?').codeUnits;
    }
  }

  /// Formats a line with label on the left and value on the right.
  static List<int> _formatLine(String label, String value, int maxChars) {
    final spaces = maxChars - label.length - value.length;
    final padding = spaces > 0 ? ' ' * spaces : ' ';
    return _encodeText('$label$padding$value') + _feed(lines: 1);
  }

  /// Formats a number as Indonesian Rupiah string.
  static String _formatRp(double amount) {
    return 'Rp${amount.toStringAsFixed(0)}';
  }
}
