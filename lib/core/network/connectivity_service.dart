import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity and exposes a stream of online/offline state.
///
/// Used by [SyncQueueService] to trigger sync when connectivity is restored.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// Stream of connectivity results. Empty list = no connection.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Returns `true` if any connection type is active (not "none").
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Current connectivity state as a stream of bool (online/offline).
  Stream<bool> get isOnlineStream =>
      onConnectivityChanged.map((results) =>
          results.any((r) => r != ConnectivityResult.none));
}
