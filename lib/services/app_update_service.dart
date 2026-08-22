import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/common/maintenance_screen.dart';

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

  /// فحص التحديث (يدوي أو تلقائي)
  static Future<void> checkAppUpdate(BuildContext context, {bool isManualCheck = false}) async {
    try {
      String latestVersion = '1.0.0';
      String updateUrl = '';
      bool isForceUpdate = false;
      String changeLog = '';

      // 1. القراءة من system_settings/maintenance_and_updates
      final docSettings = await _db.collection('system_settings').doc('maintenance_and_updates').get();
      if (docSettings.exists && docSettings.data() != null) {
        final data = docSettings.data()!;
        latestVersion = (data['latest_version'] ?? data['version'] ?? '1.0.0').toString().trim();
        updateUrl = (data['update_url'] ?? data['url'] ?? '').toString().trim();
        isForceUpdate = data['is_force_update'] ?? data['forceUpdate'] ?? false;
        changeLog = (data['change_log'] ?? data['notes'] ?? '').toString().trim();
      } else {
        // 2. Fallback إلى app_config/version
        final docConfig = await _db.collection('app_config').doc('version').get();
        if (docConfig.exists && docConfig.data() != null) {
          final data = docConfig.data()!;
          latestVersion = (data['version'] ?? '1.0.0').toString().trim();
          updateUrl = (data['url'] ?? '').toString().trim();
          isForceUpdate = data['forceUpdate'] ?? false;
          changeLog = (data['change_log'] ?? '').toString().trim();
        }
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

  /// شاشة ونافذة التحديث الفاخرة ذات النصوص الواضحة والقوية
  static void showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String updateUrl,
    required bool isForceUpdate,
    String? changeLog,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      barrierLabel: 'AppUpdateDialog',
      barrierColor: Colors.black.withOpacity(0.85), // عتمة قوية لتركيز المستخدم
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        return PopScope(
          canPop: !isForceUpdate,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: Center(
                  child: _LuxuryUpdateModalContent(
                    currentVersion: currentVersion,
                    latestVersion: latestVersion,
                    updateUrl: updateUrl,
                    isForceUpdate: isForceUpdate,
                    changeLog: changeLog,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LuxuryUpdateModalContent extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final bool isForceUpdate;
  final String? changeLog;

  const _LuxuryUpdateModalContent({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.isForceUpdate,
    this.changeLog,
  });

  @override
  State<_LuxuryUpdateModalContent> createState() => _LuxuryUpdateModalContentState();
}

class _LuxuryUpdateModalContentState extends State<_LuxuryUpdateModalContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: widget.isForceUpdate
              ? const Color(0xFFEF4444).withOpacity(0.5)
              : const Color(0xFF3B82F6).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isForceUpdate ? const Color(0xFFEF4444) : const Color(0xFF2563EB))
                .withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة الرأس النابضة
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.isForceUpdate
                            ? [const Color(0xFFDC2626), const Color(0xFFF97316)]
                            : [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isForceUpdate ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                              .withOpacity(0.5),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isForceUpdate ? Icons.warning_amber_rounded : Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // شارة نوع التحديث
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isForceUpdate
                    ? const Color(0xFFEF4444).withOpacity(0.12)
                    : const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isForceUpdate
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : const Color(0xFF2563EB).withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.isForceUpdate ? '⚠️ تحديث إجباري هام جداً' : '✨ تحديث جديد متوفر',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.isForceUpdate ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // العنوان الرئيسي الضخم
            Text(
              widget.isForceUpdate ? 'يجب تحديث التطبيق الآن للاستمرار' : 'إصدار جديد جاهز للتحميل',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // بطاقة مقارنة الإصدارين الفخمة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'إصدارك الحالي',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.currentVersion}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB), size: 18),
                  ),
                  Column(
                    children: [
                      const Text(
                        'الإصدار الجديد المطلوب',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.latestVersion} 👑',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // مميزات التحديث الأساسية
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isForceUpdate
                    ? const Color(0xFFDC2626).withOpacity(0.08)
                    : const Color(0xFF2563EB).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'تحديث بنك الأسئلة والمناهج المعتمدة',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildFeatureRow(
                    icon: Icons.speed_rounded,
                    title: 'سرعة مضاعفة واستقرار كامل بدون انقطاع',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildFeatureRow(
                    icon: Icons.shield_rounded,
                    title: 'حماية وتأمين الحساب والاشتراك',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // تفاصيل ما الجديد إن وجدت
            if (widget.changeLog != null && widget.changeLog!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '💡 ما الجديد: ${widget.changeLog}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 22),

            // زر التحديث العملاق
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => AppUpdateService.launchUpdateUrl(widget.updateUrl),
                icon: const Icon(Icons.download_rounded, size: 24),
                label: const Text(
                  'تحديث التطبيق الآن 🚀',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isForceUpdate
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: (widget.isForceUpdate ? const Color(0xFFDC2626) : const Color(0xFF2563EB))
                      .withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            // زر لاحقاً (فقط في التحديث غير الإجباري)
            if (!widget.isForceUpdate) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'تخطي مؤقتاً والبدء لاحقاً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                '🔒 التحديث مطلوب للمتابعة داخل التطبيق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: widget.isForceUpdate ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
