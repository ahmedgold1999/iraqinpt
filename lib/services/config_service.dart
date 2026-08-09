import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    
    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _config = json.decode(response.body);
        await prefs.setString('app_config_cache', response.body);
        return;
      }
    } catch (e) {
      print('⚠️ Config fetch error: $e');
    }

    // Fallback to cache
    final cached = prefs.getString('app_config_cache');
    if (cached != null) {
      _config = json.decode(cached);
    }
  }

  bool get isMaintenanceOn => _config['is_maintenance_on'] ?? false;
  String get examEndDate => _config['exam_end_date'] ?? '2026-06-15';
  
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
