import 'package:equatable/equatable.dart';

/// Represents an authenticated staff member.
class StaffSession extends Equatable {
  final String staffId;
  final String name;
  final String phone;
  final String role; // admin, manager, kasir, kitchen
  final String outletId;
  final String outletName;
  final String organizationId;
  final String token;
  final DateTime loginAt;

  const StaffSession({
    required this.staffId,
    required this.name,
    required this.phone,
    required this.role,
    required this.outletId,
    required this.outletName,
    required this.organizationId,
    required this.token,
    required this.loginAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'kasir';
  bool get isKitchen => role == 'kitchen';

  /// Whether this staff can access a given feature route.
  bool canAccess(String route) {
    switch (route) {
      case '/pos':
        return isAdmin || isManager || isCashier;
      case '/kitchen':
        return isAdmin || isManager || isKitchen;
      case '/admin':
        return isAdmin || isManager;
      case '/driver':
        return isAdmin || isManager;
      case '/cashier-shift':
        return isAdmin || isManager || isCashier;
      default:
        return isAdmin;
    }
  }

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'name': name,
        'phone': phone,
        'role': role,
        'outlet_id': outletId,
        'outlet_name': outletName,
        'organization_id': organizationId,
        'token': token,
        'login_at': loginAt.toIso8601String(),
      };

  factory StaffSession.fromJson(Map<String, dynamic> json) => StaffSession(
        staffId: json['staff_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        outletId: json['outlet_id'] as String,
        outletName: json['outlet_name'] as String,
        organizationId: json['organization_id'] as String,
        token: json['token'] as String,
        loginAt: DateTime.parse(json['login_at'] as String),
      );

  @override
  List<Object?> get props => [
        staffId, name, phone, role, outletId, outletName,
        organizationId, token, loginAt,
      ];
}
