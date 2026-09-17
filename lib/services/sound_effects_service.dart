import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('quiz_sound_muted') ?? false;
      await _player.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    _isMuted = !_isMuted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quiz_sound_muted', _isMuted);
    } catch (_) {}
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quiz_sound_muted', _isMuted);
    } catch (_) {}
  }

  void playCorrect() {
    if (_isMuted) return;
    HapticFeedback.lightImpact();
    _playAsset('audio/correct.wav', fallbackSystem: SystemSoundType.click, volume: 0.85);
  }

  void playWrong() {
    if (_isMuted) return;
    HapticFeedback.mediumImpact();
    _playAsset('audio/wrong.wav', fallbackSystem: SystemSoundType.alert, volume: 0.75);
  }

  void playStreakFanfare() {
    if (_isMuted) return;
    HapticFeedback.heavyImpact();
    _playAsset('audio/complete.wav', fallbackSystem: SystemSoundType.click, volume: 0.9);
  }

  void playClick() {
    if (_isMuted) return;
    HapticFeedback.selectionClick();
    _playAsset('audio/click.wav', fallbackSystem: SystemSoundType.click, volume: 0.45);
  }

  void playComplete() {
    if (_isMuted) return;
    HapticFeedback.heavyImpact();
    _playAsset('audio/complete.wav', fallbackSystem: SystemSoundType.click, volume: 0.9);
  }

  Future<void> _playAsset(String path, {required SystemSoundType fallbackSystem, double volume = 0.8}) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(path), volume: volume);
    } catch (e) {
      if (kDebugMode) print('Audio play exception, fallback to system: $e');
      SystemSound.play(fallbackSystem);
    }
  }

  // Static convenience wrappers
  static void playCorrectSound() => _instance.playCorrect();
  static void playWrongSound() => _instance.playWrong();
  static void playStreakSound() => _instance.playStreakFanfare();
  static void playClickSound() => _instance.playClick();
  static void playCompleteSound() => _instance.playComplete();
}
