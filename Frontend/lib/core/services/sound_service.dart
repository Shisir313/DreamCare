import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service for managing app sound effects
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  /// Initialize sound service
  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Enable or disable sounds
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _player.stop();
      _backgroundPlayer.stop();
    }
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
    _backgroundPlayer.setVolume(_volume * 0.5); // Background quieter
  }

  /// Play button tap sound
  Future<void> playTap() async {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playSound('tap', volume: 0.3);
  }

  /// Play success sound
  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    await _playSound('success', volume: 0.6);
  }

  /// Play error sound
  Future<void> playError() async {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
    await _playSound('error', volume: 0.5);
  }

  /// Play water drop sound
  Future<void> playWaterDrop() async {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playSound('water_drop', volume: 0.5);
  }

  /// Play notification sound
  Future<void> playNotification() async {
    if (!_soundEnabled) return;
    await _playSound('notification', volume: 0.7);
  }

  /// Play voice message sent
  Future<void> playMessageSent() async {
    if (!_soundEnabled) return;
    HapticFeedback.lightImpact();
    await _playSound('message_sent', volume: 0.4);
  }

  /// Play voice message received
  Future<void> playMessageReceived() async {
    if (!_soundEnabled) return;
    await _playSound('message_received', volume: 0.4);
  }

  /// Play achievement sound
  Future<void> playAchievement() async {
    if (!_soundEnabled) return;
    HapticFeedback.heavyImpact();
    await _playSound('achievement', volume: 0.8);
  }

  /// Play swipe sound
  Future<void> playSwipe() async {
    if (!_soundEnabled) return;
    HapticFeedback.selectionClick();
    await _playSound('swipe', volume: 0.2);
  }

  /// Play camera shutter sound
  Future<void> playCameraShutter() async {
    if (!_soundEnabled) return;
    HapticFeedback.mediumImpact();
    await _playSound('camera', volume: 0.6);
  }

  /// Play ambient background music
  Future<void> playBackgroundMusic() async {
    if (!_soundEnabled) return;
    try {
      await _backgroundPlayer.play(AssetSource('sounds/ambient.mp3'));
    } catch (e) {
      // Ignore if sound file doesn't exist
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    await _backgroundPlayer.stop();
  }

  /// Internal method to play sound
  Future<void> _playSound(String name, {double volume = 1.0}) async {
    try {
      await _player.play(
        AssetSource('sounds/$name.mp3'),
        volume: _volume * volume,
      );
    } catch (e) {
      // Sound file doesn't exist, use system haptics as fallback
      HapticFeedback.lightImpact();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _player.dispose();
    await _backgroundPlayer.dispose();
  }
}
