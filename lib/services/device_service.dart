import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    if (kIsWeb) return 'web_user';
    
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // معرّف فريد للأندرويد
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_unknown';
      }
    } catch (e) {
      debugPrint('Error getting device id: $e');
    }
    return 'unknown_device';
  }

  static Future<bool> checkDeviceLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final deviceId = await getDeviceId();
    if (deviceId == 'web_user' || deviceId == 'unknown_device') return true;

    // تحسين: التحقق من التخزين المحلي أولاً لتوفير قراءات Firestore
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'device_verified_${user.uid}_$deviceId';
    if (prefs.getBool(cacheKey) ?? false) {
      return true; // تم التحقق من هذا الجهاز مسبقاً لهذا المستخدم
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return true;

    final data = userDoc.data();
    final role = data?['role'] ?? 'student';
    
    // المدير يتخطى القيد
    if (role == 'admin') {
      await prefs.setBool(cacheKey, true);
      return true;
    }

    List<String> devices = List<String>.from(data?['deviceIds'] ?? []);

    // إذا كان الجهاز مسجلاً مسبقاً في Firestore
    if (devices.contains(deviceId)) {
      await prefs.setBool(cacheKey, true);
      return true;
    }

    // حد الأجهزة المسموح به (مثلاً 2)
    if (devices.length >= 2) {
      return false;
    }

    // إضافة الجهاز الجديد
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'deviceIds': FieldValue.arrayUnion([deviceId])
    });

    await prefs.setBool(cacheKey, true);
    return true;
  }
}
