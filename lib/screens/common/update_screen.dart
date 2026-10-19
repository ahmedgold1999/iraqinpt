import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_update_service.dart';

class UpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateUrl;
  final bool isForceUpdate;
  final String? changeLog;

  const UpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateUrl,
    required this.isForceUpdate,
    this.changeLog,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.06).animate(
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
    final primaryColor = widget.isForceUpdate
        ? const Color(0xFFEF4444)
        : const Color(0xFF2563EB);
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131C31) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return PopScope(
      canPop: !widget.isForceUpdate,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.isForceUpdate
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
          title: Text(
            widget.isForceUpdate ? 'تحديث إجباري هام' : 'تحديث التطبيق',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isForceUpdate,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // أيقونة التحديث المتحركة الفاخرة مع نبض وتوهج
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/update_anim.gif',
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: widget.isForceUpdate
                                            ? [const Color(0xFFDC2626), const Color(0xFFF97316)]
                                            : [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      widget.isForceUpdate
                                          ? Icons.system_update_rounded
                                          : Icons.rocket_launch_rounded,
                                      color: Colors.white,
                                      size: 54,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // شارة نوع التحديث
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isForceUpdate ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                            color: primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isForceUpdate ? 'تحديث إجباري مطلوب للمتابعة' : 'إصدار جديد متوفر الآن',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // العنوان الرئيسي
                    Text(
                      widget.isForceUpdate
                          ? 'يجب تحديث التطبيق الآن للمتابعة'
                          : 'إصدار جديد جاهز للتحميل والتثبيت',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أطلقنا ترقية جديدة للتطبيق تتضمن تحديثات أساسية في بنك الأسئلة وحلولاً لأحدث الامتحانات وتحسينات استقرار فائقة.',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // بطاقة مقارنة الإصدارين
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'الإصدار الحالي لديك',
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'v${widget.currentVersion}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 20),
                          ),
                          Column(
                            children: [
                              Text(
                                'الإصدار الأحدث المتاح',
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'النسخة الجديدة ✨',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // بطاقة مميزات التحديث الأساسية
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.menu_book_rounded,
                            title: 'تحديث بنوك الأسئلة والاختبارات التخصصية الجديدة',
                            color: const Color(0xFF2563EB),
                            textPrimary: textPrimary,
                          ),
                          const Divider(height: 20),
                          _buildFeatureRow(
                            icon: Icons.bolt_rounded,
                            title: 'سرعة فائقة واستقرار تام أثناء أداء الامتحانات أوفلاين',
                            color: const Color(0xFFF59E0B),
                            textPrimary: textPrimary,
                          ),
                          const Divider(height: 20),
                          _buildFeatureRow(
                            icon: Icons.security_rounded,
                            title: 'حماية وتأمين كامل لاشتراكك وحسابك وسجل درجاتك',
                            color: const Color(0xFF10B981),
                            textPrimary: textPrimary,
                          ),
                        ],
                      ),
                    ),

                    // سجل التغييرات إن وجد
                    if (widget.changeLog != null && widget.changeLog!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tips_and_updates_rounded, color: primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'ما الجديد في هذا التحديث:',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.changeLog!.trim(),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // زر التحديث الكبير
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => AppUpdateService.launchUpdateUrl(widget.updateUrl),
                        icon: const Icon(Icons.download_rounded, size: 24),
                        label: const Text(
                          'تحديث التطبيق الآن 🚀',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: primaryColor.withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    // زر التخطي أو ملاحظة الإجبار
                    if (!widget.isForceUpdate) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'تخطي مؤقتاً والمتابعة لاحقاً',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 15, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'هذا التحديث إجباري لضمان متابعة استخدام التطبيق',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required Color color,
    required Color textPrimary,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
