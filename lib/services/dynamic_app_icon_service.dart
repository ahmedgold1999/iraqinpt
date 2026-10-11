import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicAppIconService {
  static final DynamicAppIconService _instance = DynamicAppIconService._internal();
  factory DynamicAppIconService() => _instance;
  DynamicAppIconService._internal();

  static const MethodChannel _channel = MethodChannel('com.inpt.ahmeed.iraqinpt/app_icon');
  static const String _prefCurrentIconKey = 'current_active_app_icon';

  StreamSubscription<DocumentSnapshot>? _subscription;

  static const Map<String, Map<String, String>> availableIcons = {
    'default': {
      'name': 'الافتراضية (الرسمية)',
      'description': 'شعار التطبيق الملكي الكلاسيكي',
      'asset': 'assets/icons/app_icon.png',
      'alias': 'MainActivity',
    },
    'winter': {
      'name': 'فصل الشتاء ❄️',
      'description': 'تصميم شتوي أنيق وجذاب',
      'asset': 'assets/icons/winter.png',
      'alias': 'MainActivityWinter',
    },
    'newyear': {
      'name': 'رأس السنة الميلادية 🎉',
      'description': 'أجواء احتفالية بمناسبة العام الجديد',
      'asset': 'assets/icons/newyear.png',
      'alias': 'MainActivityNewYear',
    },
    'ramadan': {
      'name': 'شهر رمضان المبارك 🌙',
      'description': 'أيقونة إيمانية رمضانية متميزة',
      'asset': 'assets/icons/ramdan.png',
      'alias': 'MainActivityRamadan',
    },
    'iraq': {
      'name': 'العلم العراقي 🇮🇶',
      'description': 'شعار الهوية الوطنية العراقية',
      'asset': 'assets/icons/iraq.png',
      'alias': 'MainActivityIraq',
    },
  };

  /// بدء المزامنة التلقائية مع Firebase فور تشغيل التطبيق
  void initializeSync() {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('system_settings')
        .doc('app_icon_config')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final targetIcon = doc.data()!['active_icon']?.toString().toLowerCase().trim() ?? 'default';
        _applyIconIfChanged(targetIcon);
      }
    }, onError: (e) {
      debugPrint('⚠️ Error in DynamicAppIconService sync: $e');
    });
  }

  /// تطبيق الأيقونة محلياً إذا كانت تختلف عن الأيقونة الحالية
  Future<void> _applyIconIfChanged(String iconKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLocal = prefs.getString(_prefCurrentIconKey) ?? 'default';

      if (currentLocal == iconKey) return;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final bool success = await _channel.invokeMethod('changeIcon', {'iconKey': iconKey}) ?? false;
        if (success) {
          await prefs.setString(_prefCurrentIconKey, iconKey);
          debugPrint('✅ App icon updated successfully to: $iconKey');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to apply app icon: $e');
    }
  }

  /// تعيين الأيقونة عبر لوحة الأدمن وحفظها في Firebase لتتزامن مع كافة المستخدمين
  static Future<bool> setGlobalAppIcon(String iconKey) async {
    try {
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('app_icon_config')
          .set({
        'active_icon': iconKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تطبيقها أيضاً على جهاز الأدمن الحالي
      final prefs = await SharedPreferences.getInstance();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod('changeIcon', {'iconKey': iconKey});
      }
      await prefs.setString(_prefCurrentIconKey, iconKey);
      return true;
    } catch (e) {
      debugPrint('⚠️ Error setting global app icon: $e');
      return false;
    }
  }

  /// جلب الأيقونة النشطة حالياً من Firestore
  static Future<String> getActiveGlobalIcon() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('app_icon_config')
          .get();
      if (doc.exists && doc.data()?['active_icon'] != null) {
        return doc.data()!['active_icon'].toString().toLowerCase().trim();
      }
    } catch (_) {}
    return 'default';
  }

  void dispose() {
    _subscription?.cancel();
  }
}
