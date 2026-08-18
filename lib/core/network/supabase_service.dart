import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

/// Singleton wrapper around `supabase_flutter`.
///
/// Exposes an [isReady] flag and the last initialization error so callers
/// (repositories, UI) can degrade gracefully when Supabase failed to init
/// (e.g. missing env / no network in dev) instead of throwing a
/// `LateInitializationError` when accessing [client].
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  Object? _initError;

  /// `true` once [init] has completed successfully.
  bool get isReady => _isInitialized;

  /// The error captured during the last [init] attempt, if any.
  /// `null` when initialization succeeded or has not been attempted yet.
  Object? get initError => _initError;

  /// Initializes Supabase. Safe to call multiple times — subsequent calls
  /// are no-ops once initialization has succeeded.
  ///
  /// If initialization fails, the error is captured in [initError] and
  /// [isReady] stays `false`; callers should check [isReady] before using
  /// [client]. A retry is allowed (the next call will attempt init again).
  Future<void> init() async {
    if (_isInitialized) return;

    // Guard: refuse to init when --dart-define keys are missing.
    if (!ApiConstants.hasSupabaseConfig) {
      _initError = StateError(
        'Supabase URL or ANON_KEY not provided. '
        'Run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        'See run_dev.ps1 for a convenience script.',
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('Supabase init skipped: missing --dart-define config');
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: ApiConstants.supabaseUrl,
        publishableKey: ApiConstants.supabaseAnonKey,
      );
      _isInitialized = true;
      _initError = null;
    } catch (e) {
      _initError = e;
      if (kDebugMode) {
        // ignore: avoid_print
        print('Supabase init warning: $e');
      }
    }
  }

  /// Returns the Supabase client.
  ///
  /// Throws a clear [StateError] when accessed before [init] succeeded,
  /// instead of an opaque `LateInitializationError`. Callers should guard
  /// with [isReady] in code paths that may run before init completes.
  SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        'SupabaseService not initialized. '
        'Await SupabaseService().init() before accessing client. '
        'Last init error: $_initError',
      );
    }
    return Supabase.instance.client;
  }

  // Convenience getters
  User? get currentUser =>
      _isInitialized ? Supabase.instance.client.auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;
}
