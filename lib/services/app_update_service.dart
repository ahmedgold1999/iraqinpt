import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/common/maintenance_screen.dart';
import '../screens/common/update_screen.dart';

class AppUpdateService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// فحص تلقائي عند بدء تشغيل التطبيق (يشمل الصيانة والتحديث)
  static Future<void> checkUpdateOnStartup(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;

    // 1. فحص الصيانة المباشرة
    try {
      final docSettings = await _db.collection('system_settings').doc('maintenance_and_updates').get();
      if (docSettings.exists && docSettings.data() != null) {
        final isMaintenance = docSettings.data()!['is_maintenance_on'] == true;
        if (isMaintenance) {
          final user = FirebaseAuth.instance.currentUser;
          bool isAdmin = false;
          if (user != null) {
            final userDoc = await _db.collection('users').doc(user.uid).get();
            if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
              isAdmin = true;
            }
          }
          if (!isAdmin && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              (route) => false,
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Maintenance startup check error: $e');
    }

    // 2. فحص التحديث
    if (!context.mounted) return;
    await checkAppUpdate(context, isManualCheck: false);
  }

  /// فحص التحديث (يدوي أو تلقائي) مع دعم الاستهداف حسب المنصة (أندرويد / آيفون / ويب)
  static Future<void> checkAppUpdate(BuildContext context, {bool isManualCheck = false}) async {
    try {
      String latestVersion = '1.0.0';
      String updateUrl = '';
      bool isForceUpdate = false;
      String changeLog = '';
      bool targetAndroid = true;
      bool targetIos = true;
      bool targetWeb = true;

      // 1. القراءة من system_settings/maintenance_and_updates
      final docSettings = await _db.collection('system_settings').doc('maintenance_and_updates').get();
      if (docSettings.exists && docSettings.data() != null) {
        final data = docSettings.data()!;
        latestVersion = (data['latest_version'] ?? data['version'] ?? '1.0.0').toString().trim();
        updateUrl = (data['update_url'] ?? data['url'] ?? '').toString().trim();
        isForceUpdate = data['is_force_update'] ?? data['forceUpdate'] ?? false;
        changeLog = (data['change_log'] ?? data['notes'] ?? '').toString().trim();
        targetAndroid = data['target_android'] ?? true;
        targetIos = data['target_ios'] ?? true;
        targetWeb = data['target_web'] ?? true;

        // دعم روابط مخصصة لكل منصة
        if (kIsWeb && (data['web_update_url'] ?? '').toString().trim().isNotEmpty) {
          updateUrl = data['web_update_url'].toString().trim();
        } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && (data['android_update_url'] ?? '').toString().trim().isNotEmpty) {
          updateUrl = data['android_update_url'].toString().trim();
        } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && (data['ios_update_url'] ?? '').toString().trim().isNotEmpty) {
          updateUrl = data['ios_update_url'].toString().trim();
        }
      } else {
        // 2. Fallback إلى app_config/version
        final docConfig = await _db.collection('app_config').doc('version').get();
        if (docConfig.exists && docConfig.data() != null) {
          final data = docConfig.data()!;
          latestVersion = (data['version'] ?? '1.0.0').toString().trim();
          updateUrl = (data['url'] ?? '').toString().trim();
          isForceUpdate = data['forceUpdate'] ?? false;
          changeLog = (data['change_log'] ?? '').toString().trim();
          targetAndroid = data['target_android'] ?? true;
          targetIos = data['target_ios'] ?? true;
          targetWeb = data['target_web'] ?? true;
        }
      }

      // 🔍 فحص هل منصة جهاز المستخدم الحالية مفعّلة ومستهدفة بالإشعار والتحديث
      bool isPlatformIncluded = true;
      if (kIsWeb) {
        isPlatformIncluded = targetWeb;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        isPlatformIncluded = targetAndroid;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        isPlatformIncluded = targetIos;
      }

      // إذا كانت منصة المستخدم غير مستهدفة، نتجاهل التحديث كلياً ولا يظهر أي إشعار أو قفل إجباري
      if (!isPlatformIncluded) {
        debugPrint('⏭️ AppUpdate: Skipped because current platform is disabled in update targets.');
        if (isManualCheck && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'لا تتوفر تحديثات جديدة لمنصتك حالياً ✨',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              backgroundColor: const Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      if (isVersionLower(currentVersion, latestVersion)) {
        if (!context.mounted) return;
        showUpdateDialog(
          context: context,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateUrl: updateUrl,
          isForceUpdate: isForceUpdate,
          changeLog: changeLog,
        );
      } else if (isManualCheck) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'أنت تستخدم أحدث وأقوى إصدار بالفعل (v$currentVersion) ✨',
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error in AppUpdateService: $e');
    }
  }

  /// مقارنة دقيقة لرقم الإصدار
  static bool isVersionLower(String current, String latest) {
    try {
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');

      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = math.max(currentParts.length, latestParts.length);
      while (currentParts.length < maxLen) {
        currentParts.add(0);
      }
      while (latestParts.length < maxLen) {
        latestParts.add(0);
      }

      for (int i = 0; i < maxLen; i++) {
        if (currentParts[i] < latestParts[i]) return true;
        if (currentParts[i] > latestParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// فتح رابط التحديث
  static Future<void> launchUpdateUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('⚠️ Error launching update url: $e');
    }
  }

  /// فتح شاشة التحديث الكاملة (Full Screen)
  static void showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String updateUrl,
    required bool isForceUpdate,
    String? changeLog,
  }) {
    final page = UpdateScreen(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      updateUrl: updateUrl,
      isForceUpdate: isForceUpdate,
      changeLog: changeLog,
    );

    if (isForceUpdate) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }
}
