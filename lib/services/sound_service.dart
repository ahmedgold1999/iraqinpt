import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const String _soundPrefKey = 'quiz_sound_enabled';
  bool _isSoundEnabled = true;
  bool _isInitialized = false;

  final AudioPlayer _player = AudioPlayer();

  bool get isSoundEnabled => _isSoundEnabled;

  /// تهيئة الخدمة وتحميل تفضيل الصوت
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool(_soundPrefKey) ?? true;
      await _player.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SoundService: $e');
      }
    }
  }

  /// تبديل حالة الصوت (تفعيل / كتم)
  Future<bool> toggleSound() async {
    return await setSoundEnabled(!_isSoundEnabled);
  }

  /// تعيين حالة الصوت وحفظها في الذاكرة
  Future<bool> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundPrefKey, enabled);
    } catch (_) {}
    return _isSoundEnabled;
  }

  /// تشغيل صوت الإجابة الصحيحة
  Future<void> playCorrect() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.lightImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/correct.wav'), volume: 0.85);
    } catch (e) {
      if (kDebugMode) print('Audio play error: $e');
    }
  }

  /// تشغيل صوت الإجابة الخاطئة
  Future<void> playWrong() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.mediumImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/wrong.wav'), volume: 0.75);
    } catch (e) {
      if (kDebugMode) print('Audio play error: $e');
    }
  }

  /// تشغيل نغمة إنهاء الاختبار والاحتفال
  Future<void> playComplete() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.heavyImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/complete.wav'), volume: 0.9);
    } catch (e) {
      if (kDebugMode) print('Audio play error: $e');
    }
  }

  /// تشغيل صوت النقر التفاعلي
  Future<void> playClick() async {
    if (!_isSoundEnabled) return;
    try {
      HapticFeedback.selectionClick();
      await _player.stop();
      await _player.play(AssetSource('audio/click.wav'), volume: 0.5);
    } catch (e) {
      if (kDebugMode) print('Audio play error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
