import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/repositories/customer_delivery_repository.dart';
import '../../services/biteship_service.dart';

/// Implementation of [CustomerDeliveryRepository].
class CustomerDeliveryRepositoryImpl
    implements CustomerDeliveryRepository {
  final SupabaseService _supabaseService;
  final BiteshipService _biteship;

  CustomerDeliveryRepositoryImpl({
    SupabaseService? supabaseService,
    BiteshipService? biteship,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _biteship = biteship ?? BiteshipService();

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Result<List<DeliveryAddress>>> getDeliveryAddresses({
    required String customerId,
  }) async {
    try {
      final data = await _client
          .from('delivery_addresses')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      final addresses = data
          .map<DeliveryAddress>((e) => DeliveryAddress.fromJson(e))
          .toList();
      return Right(addresses);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal memuat alamat pengiriman', original: e));
    }
  }

  @override
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
  }) async {
    try {
      final data = await _client.from('delivery_addresses').insert({
        'customer_id': customerId,
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'full_address': fullAddress,
        'postal_code': postalCode,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
      }).select().single();
      return Right(DeliveryAddress.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal menyimpan alamat', original: e));
    }
  }

  @override
  Future<Result<List<ShippingRate>>> getShippingRates({
    required String originPostalCode,
    required String destinationPostalCode,
    required int weight,
  }) async {
    try {
      final rates = await _biteship.getShippingRates(
        originPostalCode: originPostalCode,
        destinationPostalCode: destinationPostalCode,
        weight: weight,
      );
      return Right(rates);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal menghitung ongkir', original: e));
    }
  }

  @override
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
  }) async {
    try {
      final shipmentId = await _biteship.createShipment(
        originContactName: originContactName,
        originContactPhone: originContactPhone,
        originAddress: originAddress,
        originPostalCode: originPostalCode,
        destinationContactName: destinationContactName,
        destinationContactPhone: destinationContactPhone,
        destinationAddress: destinationAddress,
        destinationPostalCode: destinationPostalCode,
        courierCompany: courierCompany,
        courierService: courierService,
        weight: weight,
        items: items,
      );
      return Right(shipmentId);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Gagal membuat shipment', original: e));
    }
  }
}
