import 'package:equatable/equatable.dart';

class StaffModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // admin, manager, kasir, kitchen
  final bool isActive;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'kasir',
        isActive: json['is_active'] ?? true,
      );

  @override
  List<Object?> get props => [id, name, email, role, isActive];

  StaffModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'is_active': isActive,
      };
}

class CashierShiftModel extends Equatable {
  final String id;
  final String outletId;
  final String staffId;
  final String openedAt;
  final String? closedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;

  const CashierShiftModel({
    required this.id,
    required this.outletId,
    required this.staffId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
  });

  factory CashierShiftModel.fromJson(Map<String, dynamic> json) =>
      CashierShiftModel(
        id: json['id'] ?? '',
        outletId: json['outlet_id'] ?? '',
        staffId: json['staff_id'] ?? '',
        openedAt: json['opened_at'] ?? DateTime.now().toIso8601String(),
        closedAt: json['closed_at'],
        openingCash: (json['opening_cash'] as num?)?.toDouble() ?? 0,
        closingCash: (json['closing_cash'] as num?)?.toDouble(),
        expectedCash: (json['expected_cash'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        id,
        outletId,
        staffId,
        openedAt,
        closedAt,
        openingCash,
        closingCash,
        expectedCash,
      ];

  CashierShiftModel copyWith({
    String? id,
    String? outletId,
    String? staffId,
    String? openedAt,
    String? closedAt,
    double? openingCash,
    double? closingCash,
    double? expectedCash,
  }) {
    return CashierShiftModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      staffId: staffId ?? this.staffId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      expectedCash: expectedCash ?? this.expectedCash,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'staff_id': staffId,
        'opened_at': openedAt,
        'closed_at': closedAt,
        'opening_cash': openingCash,
        'closing_cash': closingCash,
        'expected_cash': expectedCash,
      };
}

class BannerModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        imageUrl: json['image_url'] ?? '',
        isActive: json['is_active'] ?? true,
      );

  @override
  List<Object?> get props => [id, title, description, imageUrl, isActive];

  BannerModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}

class OutletPrinterModel extends Equatable {
  final String id;
  final String outletId;
  final String name;
  final String printerType; // network, usb, bluetooth
  final String? ipAddress;
  final String? bluetoothAddress;
  final bool isKitchen;

  const OutletPrinterModel({
    required this.id,
    required this.outletId,
    required this.name,
    required this.printerType,
    this.ipAddress,
    this.bluetoothAddress,
    this.isKitchen = false,
  });

  factory OutletPrinterModel.fromJson(Map<String, dynamic> json) =>
      OutletPrinterModel(
        id: json['id'] ?? '',
        outletId: json['outlet_id'] ?? '',
        name: json['name'] ?? '',
        printerType: json['printer_type'] ?? 'bluetooth',
        ipAddress: json['ip_address'],
        bluetoothAddress: json['bluetooth_address'],
        isKitchen: json['is_kitchen'] ?? false,
      );

  @override
  List<Object?> get props =>
      [id, outletId, name, printerType, ipAddress, bluetoothAddress, isKitchen];

  OutletPrinterModel copyWith({
    String? id,
    String? outletId,
    String? name,
    String? printerType,
    String? ipAddress,
    String? bluetoothAddress,
    bool? isKitchen,
  }) {
    return OutletPrinterModel(
      id: id ?? this.id,
      outletId: outletId ?? this.outletId,
      name: name ?? this.name,
      printerType: printerType ?? this.printerType,
      ipAddress: ipAddress ?? this.ipAddress,
      bluetoothAddress: bluetoothAddress ?? this.bluetoothAddress,
      isKitchen: isKitchen ?? this.isKitchen,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'name': name,
        'printer_type': printerType,
        'ip_address': ipAddress,
        'bluetooth_address': bluetoothAddress,
        'is_kitchen': isKitchen,
      };
}
