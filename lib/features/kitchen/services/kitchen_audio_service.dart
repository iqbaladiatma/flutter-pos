import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing audio alerts in the KDS (Kitchen Display System).
///
/// Plays a chime sound when a new order arrives. Uses `audioplayers`
/// to play a short audio file from the `assets/audio/` directory.
class KitchenAudioService {
  KitchenAudioService._();
  static final KitchenAudioService instance = KitchenAudioService._();

  final AudioPlayer _player = AudioPlayer();

  bool _isEnabled = true;
  bool _isPlaying = false;

  bool get isEnabled => _isEnabled;

  /// Enables or disables audio alerts.
  void setEnabled(bool enabled) => _isEnabled = enabled;

  /// Plays the new-order chime.
  ///
  /// If audio is disabled or the sound file is missing, this is a no-op.
  /// The error is caught and logged in debug mode — audio is non-critical.
  Future<void> playNewOrderChime() async {
    if (!_isEnabled || _isPlaying) return;

    _isPlaying = true;
    try {
      await _player.play(AssetSource('audio/order_chime.mp3'));
    } catch (e) {
      // Fallback: try to play a system sound or just log.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Audio chime error (non-fatal): $e');
      }
    } finally {
      // Reset after a short delay to prevent rapid re-triggering.
      Future.delayed(const Duration(seconds: 2), () => _isPlaying = false);
    }
  }

  /// Releases audio player resources.
  void dispose() {
    _player.dispose();
  }
}
