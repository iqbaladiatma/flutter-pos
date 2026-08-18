import 'package:equatable/equatable.dart';

/// OTP code for customer phone-number verification (SMS/WhatsApp).
class OtpCodeModel extends Equatable {
  final String id;
  final String phone;
  final String code;
  final String purpose; // login, register, reset
  final bool isUsed;
  final String createdAt;
  final String? expiresAt;

  const OtpCodeModel({
    required this.id,
    required this.phone,
    required this.code,
    this.purpose = 'login',
    this.isUsed = false,
    required this.createdAt,
    this.expiresAt,
  });

  factory OtpCodeModel.fromJson(Map<String, dynamic> json) => OtpCodeModel(
        id: json['id'] ?? '',
        phone: json['phone'] ?? '',
        code: json['code'] ?? '',
        purpose: json['purpose'] ?? 'login',
        isUsed: json['is_used'] ?? false,
        createdAt:
            json['created_at'] ?? DateTime.now().toIso8601String(),
        expiresAt: json['expires_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'code': code,
        'purpose': purpose,
        'is_used': isUsed,
        'created_at': createdAt,
        'expires_at': expiresAt,
      };

  /// Returns `true` if the OTP has expired based on [expiresAt].
  bool get isExpired {
    if (expiresAt == null) return false;
    final expiry = DateTime.tryParse(expiresAt!);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  /// Returns `true` if the OTP is still valid (not used and not expired).
  bool get isValid => !isUsed && !isExpired;

  @override
  List<Object?> get props =>
      [id, phone, code, purpose, isUsed, createdAt, expiresAt];
}
