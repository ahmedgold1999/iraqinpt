import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AuthService _authService = AuthService();
  bool _isUnderstood = false;
  bool _isLoading = false;

  Future<void> _handleDeleteAccount() async {
    if (!_isUnderstood) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تأكيد الموافقة على الشروط أولاً للمتابعة'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الحساب وكافة البيانات بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'حذف الحساب نهائياً',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. بطاقة التحذير الرئيسية
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF450A0A), const Color(0xFF1E293B)]
                        : [const Color(0xFFFEF2F2), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFEF4444),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'هل أنت متأكد من رغبتك في حذف الحساب؟',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'حذف الحساب هو إجراء دائم ونهائي لا رجعة فيه. يرجى قراءة التفاصيل أدناه لمعرفة ما سيحدث لبياناتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13.5,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. ماذا سيحدث عند الحذف؟
              Text(
                '📋 ماذا سيحدث عند حذف حسابك؟',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              _buildImpactTile(
                icon: Icons.person_remove_rounded,
                color: const Color(0xFFEF4444),
                title: 'مسح البيانات والملف الشخصي',
                description: 'سيتم حذف اسمك، بريدك الإلكتروني، رمزك الخاص، وكافة معلوماتك من السيرفر نهائياً.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildImpactTile(
                icon: Icons.history_edu_rounded,
                color: const Color(0xFFF59E0B),
                title: 'فقدان السجل الدراسي والامتحانات',
                description: 'سيتم مسح كافة سجلات اختباراتك السابقة، تقارير الأداء الذكية، ونسب الإنجاز.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildImpactTile(
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'إلغاء الاشتراكات والباقات المميزة',
                description: 'في حال كان لديك اشتراك نشط سيتم إلغاؤه فوراً ولا يمكن استرداد قيمته أو الأيام المتبقية.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildImpactTile(
                icon: Icons.leaderboard_rounded,
                color: const Color(0xFF06B6D4),
                title: 'الشطب من لوحة المتصدرين',
                description: 'سيتم إزالة اسمك ومركزك وترتيبك العام من لوحة الشرف على مستوى العراق.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              _buildImpactTile(
                icon: Icons.devices_rounded,
                color: const Color(0xFF10B981),
                title: 'إلغاء ربط الأجهزة المسجلة',
                description: 'سيتم فك ارتباط الحساب من كافة الهواتف والأجهزة المسجلة فوراً.',
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // 3. مربع الموافقة والإقرار
              InkWell(
                onTap: () {
                  setState(() {
                    _isUnderstood = !_isUnderstood;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isUnderstood
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: _isUnderstood ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isUnderstood,
                        activeColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _isUnderstood = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'أنا أدرك تماماً أن حذف الحساب إجراء نهائي وسيتم مسح كافة بياناتي بدون إمكانية استرجاعها.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 4. أزرار الإجراءات
              ElevatedButton(
                onPressed: _isLoading || !_isUnderstood ? null : _handleDeleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  disabledForegroundColor: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_forever_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'تأكيد وحذف الحساب نهائياً',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'التراجع والعودة للملف الشخصي',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
