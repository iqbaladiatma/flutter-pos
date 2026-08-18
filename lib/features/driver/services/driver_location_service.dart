import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service for background GPS tracking of driver location.
///
/// Uses `geolocator` to get periodic location updates and
/// uploads them via the [DriverRepository].
class DriverLocationService {
  DriverLocationService._();
  static final DriverLocationService instance = DriverLocationService._();

  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;

  /// Callback invoked with new location data.
  void Function(double lat, double lng)? onLocationUpdate;

  /// Whether location tracking is currently active.
  bool get isTracking => _positionSub != null || _fallbackTimer != null;

  /// Requests location permissions and starts tracking.
  ///
  /// Returns `true` if tracking started successfully.
  Future<bool> startTracking() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Location services are disabled');
        }
        return false;
      }

      // Check/request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Location permissions are denied');
        }
        return false;
      }

      // Start listening to position changes
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (position) {
          onLocationUpdate?.call(position.latitude, position.longitude);
        },
        onError: (e) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('Position stream error: $e');
          }
        },
      );

      // Also start a fallback timer for periodic updates
      _fallbackTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _getCurrentPosition(),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Start tracking error: $e');
      }
      return false;
    }
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      onLocationUpdate?.call(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('GetCurrentPosition error: $e');
      }
    }
  }

  /// Stops location tracking.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  /// Gets the current position once.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('GetCurrentPosition error: $e');
      }
      return null;
    }
  }
}
