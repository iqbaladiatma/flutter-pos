import 'package:geolocator/geolocator.dart';

/// Helper for requesting and reading device GPS location.
class LocationHelper {
  LocationHelper._();

  /// Ensures location permission & service are enabled, then returns
  /// the current [Position]. Throws [LocationServiceDisabledException] or
  /// [PermissionDeniedException] when requirements are not met.
  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const PermissionDeniedException('Location permission denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission permanently denied. Enable in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Returns distance in meters between two coordinates using
  /// the Haversine formula (via Geolocator.distanceBetween).
  static double distanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Returns distance in kilometers (rounded to 1 decimal).
  static double distanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final meters = distanceMeters(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    return double.parse((meters / 1000).toStringAsFixed(1));
  }
}

/// Thrown when the user denies location permission.
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}
