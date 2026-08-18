import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for integrating with Biteship API.
///
/// Provides:
/// - `getShippingRates` — calculates shipping cost for a delivery
/// - `createShipment` — creates a shipment order
/// - `trackShipment` — tracks shipment status
///
/// API key is expected via `--dart-define=BITESHIP_API_KEY=xxx`.
class BiteshipService {
  static const String _baseUrl = 'https://api.biteship.com/v1';
  final String _apiKey;
  final http.Client _client;

  BiteshipService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? (const String.fromEnvironment('BITESHIP_API_KEY')),
        _client = client ?? http.Client();

  /// Fetches shipping rates for a delivery.
  ///
  /// [originPostalCode] — sender's postal code
  /// [destinationPostalCode] — receiver's postal code
  /// [weight] — in grams
  /// [height], [width], [length] — in cm (optional)
  Future<List<ShippingRate>> getShippingRates({
    required String originPostalCode,
    required String destinationPostalCode,
    required int weight,
    int? height,
    int? width,
    int? length,
  }) async {
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Biteship API key not configured');
      }
      return [];
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/rates/couriers'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'origin_postal_code': originPostalCode,
        'destination_postal_code': destinationPostalCode,
        'couriers': 'jne,jnt,sicepat,gojek,grab',
        'items': [
          {
            'weight': weight,
            'height': height ?? 10,
            'width': width ?? 10,
            'length': length ?? 10,
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Biteship rates failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final pricing = body['pricing'] as Map<String, dynamic>? ?? {};

    return pricing.entries.map((e) {
      final data = e.value as Map<String, dynamic>;
      return ShippingRate(
        courier: e.key,
        courierName: data['courier_name'] as String? ?? e.key,
        service: data['courier_service_name'] as String? ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        etd: data['courier_estimation'] as String? ?? '',
      );
    }).toList();
  }

  /// Creates a shipment order in Biteship.
  Future<String> createShipment({
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
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Biteship API key not configured');
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/orders'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'origin_contact_name': originContactName,
        'origin_contact_phone': originContactPhone,
        'origin_address': originAddress,
        'origin_postal_code': originPostalCode,
        'destination_contact_name': destinationContactName,
        'destination_contact_phone': destinationContactPhone,
        'destination_address': destinationAddress,
        'destination_postal_code': destinationPostalCode,
        'courier_company': courierCompany,
        'courier_service': courierService,
        'items': items
            .map((item) => {
                  'name': item.name,
                  'quantity': item.quantity,
                  'weight': item.weight,
                })
            .toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Biteship create shipment failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['id'] as String? ?? '';
  }

  /// Tracks a shipment by its Biteship order ID.
  Future<ShipmentTracking> trackShipment(String orderId) async {
    if (_apiKey.isEmpty) {
      throw Exception('Biteship API key not configured');
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode != 200) {
      throw Exception('Biteship tracking failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ShipmentTracking(
      orderId: orderId,
      status: body['status'] as String? ?? 'unknown',
      trackingId: body['tracking_id'] as String?,
      trackingUrl: body['tracking_url'] as String?,
    );
  }
}

/// Shipping rate from Biteship.
class ShippingRate {
  final String courier;
  final String courierName;
  final String service;
  final double price;
  final String etd;

  const ShippingRate({
    required this.courier,
    required this.courierName,
    required this.service,
    required this.price,
    required this.etd,
  });
}

/// Item in a Biteship shipment.
class ShipmentItem {
  final String name;
  final int quantity;
  final int weight;

  const ShipmentItem({
    required this.name,
    required this.quantity,
    required this.weight,
  });
}

/// Shipment tracking info from Biteship.
class ShipmentTracking {
  final String orderId;
  final String status;
  final String? trackingId;
  final String? trackingUrl;

  const ShipmentTracking({
    required this.orderId,
    required this.status,
    this.trackingId,
    this.trackingUrl,
  });
}
