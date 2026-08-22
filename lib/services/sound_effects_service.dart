import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundEffectsService {
  static final SoundEffectsService _instance = SoundEffectsService._internal();
  factory SoundEffectsService() => _instance;
  SoundEffectsService._internal();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('quiz_sound_muted') ?? false;
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    _isMuted = !_isMuted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quiz_sound_muted', _isMuted);
    } catch (_) {}
  }

  void playCorrect() {
    if (_isMuted) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  void playWrong() {
    if (_isMuted) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void playStreakFanfare() {
    if (_isMuted) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  // Static convenience wrappers
  static void playCorrectSound() => _instance.playCorrect();
  static void playWrongSound() => _instance.playWrong();
  static void playStreakSound() => _instance.playStreakFanfare();
}
