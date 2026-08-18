import '../../../../core/error/either.dart';
import '../../services/biteship_service.dart';

/// Domain contract for customer delivery operations.
abstract class CustomerDeliveryRepository {
  /// Fetches saved delivery addresses for a customer.
  Future<Result<List<DeliveryAddress>>> getDeliveryAddresses({
    required String customerId,
  });

  /// Saves a new delivery address.
  Future<Result<DeliveryAddress>> saveDeliveryAddress({
    required String customerId,
    required String label,
    required String recipientName,
    required String phone,
    required String fullAddress,
    required String postalCode,
    String? notes,
    double? latitude,
    double? longitude,
  });

  /// Fetches shipping rates from Biteship.
  Future<Result<List<ShippingRate>>> getShippingRates({
    required String originPostalCode,
    required String destinationPostalCode,
    required int weight,
  });

  /// Creates a shipment via Biteship.
  Future<Result<String>> createShipment({
    required String originContactName,
    required String originContactPhone,
    required String originAddress,
    required String originPostalCode,
    required String destinationContactName,
    required String destinationContactPhone,
    required String destinationAddress,
    required String destinationPostalCode,
    required String courierCompany,
    required String courierService,
    required int weight,
    required List<ShipmentItem> items,
  });
}

/// Delivery address entity.
class DeliveryAddress {
  final String id;
  final String customerId;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String postalCode;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const DeliveryAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    required this.postalCode,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
        id: json['id'] as String? ?? '',
        customerId: json['customer_id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        recipientName: json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        fullAddress: json['full_address'] as String? ?? '',
        postalCode: json['postal_code'] as String? ?? '',
        notes: json['notes'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
