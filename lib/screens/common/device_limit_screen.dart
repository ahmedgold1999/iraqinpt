import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/device_service.dart';
import '../../models/app_models.dart';
import '../../routes.dart';

class DeviceLimitScreen extends StatefulWidget {
  const DeviceLimitScreen({super.key});

  @override
  State<DeviceLimitScreen> createState() => _DeviceLimitScreenState();
}

class _DeviceLimitScreenState extends State<DeviceLimitScreen> {
  bool _isChecking = false;

  Future<void> _retryCheck() async {
    setState(() => _isChecking = true);
    final isAllowed = await DeviceService.checkDeviceLimit();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isAllowed) {
      final user = await AuthService().getCurrentUser();
      if (!mounted) return;
      final targetRoute = (user != null && user.role == UserRole.admin)
          ? AppRoutes.adminDashboard
          : AppRoutes.studentHome;
      Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ ما زال الحساب مقيداً على جهاز آخر. يرجى التواصل مع الإدارة لفك القيد.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_rounded,
                    size: 46,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'الحساب مقفل على جهاز آخر',
                  style: GoogleFonts.notoKufiArabic(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'وفقاً لسياسة الأمان وحماية الاشتراكات، يُسمح بتسجيل الدخول من جهاز واحد فقط لكل حساب.\n\nإذا قمت بتغيير هاتفك أو عمل فورمات، يرجى التواصل مع إدارة التطبيق لفك قيد الجهاز القديم لتتمكن من الدخول مجدداً.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontSize: 13.5,
                    fontFamily: 'Tajawal',
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),

                // زر التحقق مجدداً (في حال قام المدير بفك القيد)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _retryCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      _isChecking ? 'جاري التحقق...' : 'التحقق بعد فك القيد',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // زر تسجيل الخروج
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text(
                    'إغلاق التطبيق',
                    style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Tajawal', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
