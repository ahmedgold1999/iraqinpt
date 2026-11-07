import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService with ChangeNotifier {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // رابط الإعدادات على GitHub (Fallback احتياطي فقط)
  static const String _configUrl = 'https://raw.githubusercontent.com/ahmedgold1999/inptquestions/refs/heads/main/app_config.json';
  
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _firestoreSubscription;

  // خيار اختياري للمدير لمعاينة وتجربة وضع المراجعة حياً على أي جهاز (حتى لو أندرويد)
  bool _forcePreviewMode = false;
  bool get isForcePreviewMode => _forcePreviewMode;
  void setForcePreviewMode(bool val) {
    _forcePreviewMode = val;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchConfig();
    _listenToSettings();
    _isInitialized = true;
  }

  void _listenToSettings() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('system_settings')
        .doc('maintenance_and_updates')
        .snapshots()
        .listen((snap) async {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        bool changed = false;
        if (data.containsKey('ios_review_mode')) {
          final val = data['ios_review_mode'] == true;
          if (_config['ios_review_mode'] != val) {
            _config['ios_review_mode'] = val;
            changed = true;
          }
        }
        if (data.containsKey('is_maintenance_on')) {
          final val = data['is_maintenance_on'] == true;
          if (_config['is_maintenance_on'] != val) {
            _config['is_maintenance_on'] = val;
            changed = true;
          }
        }
        if (data.containsKey('maintenance_platform')) {
          _config['maintenance_platform'] = data['maintenance_platform'].toString();
        }
        if (changed) {
          notifyListeners();
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('app_config_cache', json.encode(_config));
          } catch (_) {}
        }
      }
    }, onError: (e) => debugPrint('ConfigService listener error: $e'));
  }

  Future<void> fetchConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. استرجاع الكاش المحلي فورياً كـ Fallback مؤقت
    final cached = prefs.getString('app_config_cache');
    if (cached != null) {
      try {
        _config = json.decode(cached);
      } catch (_) {}
    }

    // 2. ✅ الأولوية القصوى والمباشرة: فايربيس (المصدر المباشر والحقيقي)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('maintenance_and_updates')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('ios_review_mode')) {
          _config['ios_review_mode'] = data['ios_review_mode'] == true;
        }
        if (data.containsKey('is_maintenance_on')) {
          _config['is_maintenance_on'] = data['is_maintenance_on'] == true;
        }
        if (data.containsKey('maintenance_platform')) {
          _config['maintenance_platform'] = data['maintenance_platform'].toString();
        }
        if (data.containsKey('price_1m') && data['price_1m'] != null) {
          _config['price_1m'] = data['price_1m'].toString();
        }
        if (data.containsKey('price_2m') && data['price_2m'] != null) {
          _config['price_2m'] = data['price_2m'].toString();
        }
        if (data.containsKey('price_3m') && data['price_3m'] != null) {
          _config['price_3m'] = data['price_3m'].toString();
        }
        if (data.containsKey('price_1y') && data['price_1y'] != null) {
          _config['price_1y'] = data['price_1y'].toString();
        }
        if (data.containsKey('exam_end_date') && data['exam_end_date'] != null && data['exam_end_date'].toString().trim().isNotEmpty) {
          _config['exam_end_date'] = data['exam_end_date'].toString().trim();
        }
        if (data.containsKey('admissions_pdf_url') && data['admissions_pdf_url'] != null && data['admissions_pdf_url'].toString().trim().isNotEmpty) {
          _config['admissions_pdf_url'] = data['admissions_pdf_url'].toString().trim();
        } else if (data.containsKey('mohesr_pdf_url') && data['mohesr_pdf_url'] != null && data['mohesr_pdf_url'].toString().trim().isNotEmpty) {
          _config['admissions_pdf_url'] = data['mohesr_pdf_url'].toString().trim();
        }
        await prefs.setString('app_config_cache', json.encode(_config));
      }
    } catch (e) {
      debugPrint('⚠️ Firestore config fetch error: $e');
    }

    // 3. احتياطي إضافي من GitHub في حال تعذر فايربيس فقط
    if (!_config.containsKey('ios_review_mode')) {
      try {
        final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            _config.addAll(decoded);
          }
          await prefs.setString('app_config_cache', json.encode(_config));
        }
      } catch (e) {
        debugPrint('⚠️ Config fetch error: $e');
      }
    }
  }

  void setMaintenanceLocal(bool value) async {
    _config['is_maintenance_on'] = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache', json.encode(_config));
    } catch (_) {}
  }

  bool get isMaintenanceOn {
    final bool raw = _config['is_maintenance_on'] ?? false;
    if (!raw) return false;
    final platform = (_config['maintenance_platform'] ?? 'all').toString().toLowerCase().trim();
    if (platform == 'all') return true;
    if (platform == 'android' && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) return true;
    if (platform == 'ios' && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) return true;
    return false;
  }
  
  /// الافتراضي الصارم هو false (وضع طبيعي) لتجنب ظهور الدليل بالخطأ
  bool get isIosReviewMode => _config['ios_review_mode'] ?? false;

  void setAndroidReviewModeLocal(bool value) {
    // ملغى ومحذوف للأندرويد وفق طلب الإدارة، متوفر لضمان استقرار النداءات
  }

  void setIosReviewModeLocal(bool value) async {
    _config['ios_review_mode'] = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_config_cache', json.encode(_config));
    } catch (_) {}
  }

  /// وضع المراجعة الذكي الشامل (خاص بأجهزة الآيفون فقط بناءً على طلب الإدارة)
  bool get isReviewMode {
    if (_forcePreviewMode) return true;
    if (kIsWeb) return false;
    // ملغى ومحذوف تماماً للأندرويد: الأندرويد يعمل بالوضع الطبيعي دائماً
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return isIosReviewMode;
    }
    return false;
  }

  String get examEndDate => _config['exam_end_date'] ?? '2026-06-15';
  
  String get admissionsPdfUrl {
    final url = _config['admissions_pdf_url'] ?? _config['mohesr_pdf_url'];
    if (url != null && url.toString().trim().isNotEmpty) {
      return url.toString().trim();
    }
    return 'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf';
  }
  
  String getPrice(String plan) {
    switch (plan) {
      case '1m': return _config['price_1m'] ?? '10,000';
      case '2m': return _config['price_2m'] ?? '15,000';
      case '3m': return _config['price_3m'] ?? '20,000';
      case '1y': return _config['price_1y'] ?? '30,000';
      default: return '10,000';
    }
  }

  Map<String, dynamic> get allConfig => _config;

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}
