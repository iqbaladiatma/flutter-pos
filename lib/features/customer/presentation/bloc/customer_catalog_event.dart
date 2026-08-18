import 'package:equatable/equatable.dart';

abstract class CustomerCatalogEvent extends Equatable {
  const CustomerCatalogEvent();

  @override
  List<Object?> get props => [];
}

/// Load catalog (categories + products + banners) for an outlet.
class CustomerCatalogLoad extends CustomerCatalogEvent {
  final String outletId;
  const CustomerCatalogLoad({required this.outletId});

  @override
  List<Object?> get props => [outletId];
}

/// Filter products by category.
class CustomerCatalogFilter extends CustomerCatalogEvent {
  final String? categoryId;
  const CustomerCatalogFilter(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Scan a QR code to identify a table.
class CustomerCatalogScanQr extends CustomerCatalogEvent {
  final String outletId;
  final String qrCode;
  const CustomerCatalogScanQr({
    required this.outletId,
    required this.qrCode,
  });

  @override
  List<Object?> get props => [outletId, qrCode];
}

/// Clear the scanned table.
class CustomerCatalogClearTable extends CustomerCatalogEvent {
  const CustomerCatalogClearTable();
}
