import 'package:equatable/equatable.dart';

class DeliveryZoneModel extends Equatable {
  final String id;
  final String outletId;
  final String name;
  final double maxDistanceKm;
  final double baseFee;

  const DeliveryZoneModel({
    required this.id,
    required this.outletId,
    required this.name,
    required this.maxDistanceKm,
    required this.baseFee,
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) => DeliveryZoneModel(
        id: json['id'] ?? '',
        outletId: json['outlet_id'] ?? '',
        name: json['name'] ?? '',
        maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble() ?? 5.0,
        baseFee: (json['base_fee'] as num?)?.toDouble() ?? 10000.0,
      );

  @override
  List<Object?> get props =>
      [id, outletId, name, maxDistanceKm, baseFee];

  DeliveryZoneModel copyWith({
    String? id,
    String? outletId,
    String? name,
    double? maxDistanceKm,
    double? baseFee,
  }) {
    return DeliveryZoneModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      baseFee: baseFee ?? this.baseFee,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'name': name,
        'max_distance_km': maxDistanceKm,
        'base_fee': baseFee,
      };
}

class DeliveryAddressModel extends Equatable {
  final String id;
  final String customerId;
  final String recipientName;
  final String recipientPhone;
  final String address;
  final double? latitude;
  final double? longitude;

  const DeliveryAddressModel({
    required this.id,
    required this.customerId,
    required this.recipientName,
    required this.recipientPhone,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) =>
      DeliveryAddressModel(
        id: json['id'] ?? '',
        customerId: json['customer_id'] ?? '',
        recipientName: json['recipient_name'] ?? '',
        recipientPhone: json['recipient_phone'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props =>
      [id, customerId, recipientName, recipientPhone, address, latitude, longitude];

  DeliveryAddressModel copyWith({
    String? id,
    String? customerId,
    String? recipientName,
    String? recipientPhone,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return DeliveryAddressModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class DeliveryModel extends Equatable {
  final String id;
  final String orderId;
  final String outletId;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final String? trackingId;
  final String? waybillNumber;
  final double shippingFee;
  final String status; // pending, allocated, picked_up, in_transit, delivered, cancelled

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.outletId,
    required this.recipientName,
    required this.recipientPhone,
    required this.recipientAddress,
    this.trackingId,
    this.waybillNumber,
    required this.shippingFee,
    required this.status,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        id: json['id'] ?? '',
        orderId: json['order_id'] ?? '',
        outletId: json['outlet_id'] ?? '',
        recipientName: json['recipient_name'] ?? '',
        recipientPhone: json['recipient_phone'] ?? '',
        recipientAddress: json['recipient_address'] ?? '',
        trackingId: json['tracking_id'],
        waybillNumber: json['waybill_number'],
        shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0,
        status: json['status'] ?? 'pending',
      );

  @override
  List<Object?> get props => [
        id,
        orderId,
        outletId,
        recipientName,
        recipientPhone,
        recipientAddress,
        trackingId,
        waybillNumber,
        shippingFee,
        status,
      ];

  DeliveryModel copyWith({
    String? id,
    String? orderId,
    String? outletId,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? trackingId,
    String? waybillNumber,
    double? shippingFee,
    String? status,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      outletId: outletId ?? this.outletId,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      trackingId: trackingId ?? this.trackingId,
      waybillNumber: waybillNumber ?? this.waybillNumber,
      shippingFee: shippingFee ?? this.shippingFee,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'outlet_id': outletId,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'recipient_address': recipientAddress,
        'tracking_id': trackingId,
        'waybill_number': waybillNumber,
        'shipping_fee': shippingFee,
        'status': status,
      };
}

class DriverModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? vehiclePlate;
  final String status; // active, inactive, on_delivery
  final double? latitude;
  final double? longitude;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    this.vehiclePlate,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        vehiclePlate: json['vehicle_plate'],
        status: json['status'] ?? 'active',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props =>
      [id, name, phone, vehiclePlate, status, latitude, longitude];

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehiclePlate,
    String? status,
    double? latitude,
    double? longitude,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicle_plate': vehiclePlate,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
      };
}
