import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/web_helper.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal() {
    if (!kIsWeb) {
      _initTts();
    }
  }

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentSpeakingText;

  bool get isPlaying => _isPlaying;
  String? get currentSpeakingText => _currentSpeakingText;

  Future<void> _initTts() async {
    if (_isInitialized || kIsWeb) return;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);

      _flutterTts?.setStartHandler(() {
        _isPlaying = true;
      });

      _flutterTts?.setCompletionHandler(() {
        _isPlaying = false;
        _currentSpeakingText = null;
      });

      _flutterTts?.setCancelHandler(() {
        _isPlaying = false;
        _currentSpeakingText = null;
      });

      _flutterTts?.setErrorHandler((msg) {
        _isPlaying = false;
        _currentSpeakingText = null;
        debugPrint('TTS Handler Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  /// نطق النص باللغة المناسبة (يعمل على الويب والهاتف بدون أي مشاكل)
  Future<void> speak(String text, {String? language}) async {
    if (text.trim().isEmpty) return;

    final String lang = language ?? _detectLanguage(text);

    // ✅ إذا كان التطبيق يعمل على الويب ( المتصفح )
    if (kIsWeb) {
      if (_isPlaying && _currentSpeakingText == text) {
        await stop();
        return;
      }
      _isPlaying = true;
      _currentSpeakingText = text;
      speakWebText(text, lang);
      return;
    }

    // ✅ إذا كان التطبيق يعمل على الهاتف (أندرويد / آيفون)
    await _initTts();

    try {
      if (_isPlaying && _currentSpeakingText == text) {
        await stop();
        return;
      }

      await stop();
      _currentSpeakingText = text;

      if (_flutterTts != null) {
        try {
          await _flutterTts!.setLanguage(lang);
          await _flutterTts!.speak(text);
        } catch (e) {
          debugPrint('TTS Engine setLanguage/speak error: $e');
          await _flutterTts!.speak(text);
        }
      }
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
      _isPlaying = false;
      _currentSpeakingText = null;
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _currentSpeakingText = null;

    if (kIsWeb) {
      stopWebSpeech();
      return;
    }

    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      debugPrint('TTS Stop Error: $e');
    }
  }

  String _detectLanguage(String text) {
    // فحص ما إذا كان النص يحتوي على أحرف عربية
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) {
      return 'ar-SA';
    }
    return 'en-US';
  }
}
