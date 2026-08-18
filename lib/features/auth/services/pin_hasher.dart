import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for hashing and verifying PINs using SHA-256 with salt.
class PinHasher {
  PinHasher._();

  /// Application-wide salt (in production, use per-user salt stored in DB).
  static const String _salt = 'postsa_salt_2026';

  /// Hashes a PIN with salt using SHA-256.
  static String hash(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a PIN against a stored hash.
  static bool verify(String pin, String storedHash) {
    final inputHash = hash(pin);
    return inputHash == storedHash;
  }
}
