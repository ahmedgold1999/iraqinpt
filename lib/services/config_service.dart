import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  // رابط الإعدادات على GitHub (يوفر قراءات Firestore)
  static const String _configUrl = 'https://raw.githubusercontent.com/ahmedgold1999/inptquestions/refs/heads/main/app_config.json';
  
  Map<String, dynamic> _config = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchConfig();
    _isInitialized = true;
  }

  Future<void> fetchConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Fallback to cache first
    final cached = prefs.getString('app_config_cache');
    if (cached != null) {
      try {
        _config = json.decode(cached);
      } catch (_) {}
    }

    // 2. Fetch from GitHub
    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          _config.addAll(decoded);
        }
        await prefs.setString('app_config_cache', json.encode(_config));
      }
    } catch (e) {
      print('⚠️ Config fetch error: $e');
    }

    // 3. ✅ فحص حالة الصيانة والأسعار المباشرة من فايربيس
    try {
      final doc = await FirebaseFirestore.instance.collection('system_settings').doc('maintenance_and_updates').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('ios_review_mode')) {
          _config['ios_review_mode'] = data['ios_review_mode'] == true;
        }
        if (data.containsKey('is_maintenance_on')) {
          _config['is_maintenance_on'] = data['is_maintenance_on'] == true;
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
      print('⚠️ Firestore maintenance & prices check error: $e');
    }
  }

  void setMaintenanceLocal(bool value) {
    _config['is_maintenance_on'] = value;
  }

  bool get isMaintenanceOn => _config['is_maintenance_on'] ?? false;
  bool get isIosReviewMode => _config['ios_review_mode'] ?? true;
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
}
