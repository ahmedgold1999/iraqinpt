import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// جلب المعرف الفريد للجهاز
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
      debugPrint('⚠️ Error getting device id: $e');
    }
    return 'unknown_device';
  }

  /// التحقق من تقييد الحساب على جهاز واحد فقط (1 Device Limit)
  static Future<bool> checkDeviceLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final deviceId = await getDeviceId();
    if (deviceId == 'unknown_device') return true;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return true;

    final data = userDoc.data();
    final role = data?['role'] ?? 'student';
    
    // المدير يتخطى القيد
    if (role == 'admin') {
      return true;
    }

    // استخراج الأجهزة المسجلة
    List<String> devices = [];
    if (data?['deviceIds'] != null) {
      devices = List<String>.from(data?['deviceIds']);
    } else if (data?['deviceId'] != null && data!['deviceId'].toString().trim().isNotEmpty && data!['deviceId'] != 'غير مقيد' && data!['deviceId'] != 'تمت إعادة التعيين') {
      devices = [data['deviceId'].toString().trim()];
    }

    // 1. إذا كان هذا الجهاز مسجلاً مسبقاً لهذا الطالب -> يسمح له بالدخول
    if (devices.contains(deviceId)) {
      return true;
    }

    // 2. إذا كان الحساب مقيداً على جهاز آخر بالفعل -> منع الجهاز الجديد فوراً
    if (devices.isNotEmpty) {
      debugPrint('🚫 [Security] Device blocked: Account bound to $devices, attempting access from $deviceId');
      return false;
    }

    // 3. إذا لم يكن للحساب أي جهاز مسجل (حساب جديد أو قام المدير بإلغاء القيد) -> ربط هذا الجهاز كجهاز وحيد معتمد
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'deviceIds': [deviceId],
      'deviceId': deviceId,
      'deviceBoundAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ [Security] Account bound to new device successfully: $deviceId');
    return true;
  }

  /// فك قيد الجهاز يدوياً (للطالب أو للمدير)
  static Future<void> resetDeviceBinding(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'deviceId': FieldValue.delete(),
      'deviceIds': [],
      'deviceBoundAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
