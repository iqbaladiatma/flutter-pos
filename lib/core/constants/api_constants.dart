/// Centralized API endpoints and configuration constants.
///
/// Supabase URL and publishable key are injected at compile time via
/// `--dart-define` so that secrets/config are not committed to source.
///
/// Run the app with:
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=your_url \
///   --dart-define=SUPABASE_ANON_KEY=your_key
/// ```
///
/// See `run_dev.ps1` for a convenience script.
class ApiConstants {
  ApiConstants._();

  /// Supabase project URL.
  /// Must be provided via `--dart-define=SUPABASE_URL=...`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase publishable (anon) key.
  /// Must be provided via `--dart-define=SUPABASE_ANON_KEY=...`.
  ///
  /// Note: the publishable key is designed to be exposed client-side;
  /// data access is protected by Supabase Row-Level Security (RLS) policies.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Returns `true` when both [supabaseUrl] and [supabaseAnonKey] have
  /// been provided via `--dart-define`. Use this to guard initialization.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Storage Buckets
  static const String bucketProducts = 'products';
  static const String bucketBanners = 'banners';

  // Biteship Base Endpoint
  static const String biteshipApiUrl = 'https://api.biteship.com/v1';
}
