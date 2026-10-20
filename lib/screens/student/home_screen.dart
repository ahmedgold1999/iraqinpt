import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart';
import 'smart_vault_screen.dart';
import 'notifications_screen.dart';
import 'subscription_screen.dart';
import 'subject_exams_screen.dart';
import '../../services/specialized_exam_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../services/announcement_service.dart';
import '../../models/app_models.dart';
import '../../widgets/luxury_loading.dart';
import '../../routes.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  // ====== Luxury Design Tokens ======
  static const _bgTop = Color(0xFFF8FAFC);
  static const _bgMid = Color(0xFFF1F5F9);
  static const _bgBottom = Color(0xFFEFF6FF);

  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  static const _gold = Color(0xFFFACC15);

  static TextStyle _t(
      double size, {
        FontWeight w = FontWeight.w600,
        Color c = _ink,
        double h = 1.2,
        double ls = 0.0,
      }) {
    return TextStyle(
      fontFamily: 'Tajawal',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );
  }

  static List<BoxShadow> _softShadow({double opacity = 0.08}) => [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(opacity * 0.6),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildNotificationBell(BuildContext context, bool isDark) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_active_rounded,
                size: 22,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF2563EB),
              ),
              tooltip: 'الإشعارات والمنبه اليومي',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
          ),
          if (userId != null)
            Positioned(
              top: 6,
              right: 6,
              child: StreamBuilder<int>(
                stream: NotificationService.getUnreadCount(userId),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner(BuildContext context) {
    return StreamBuilder<AppAnnouncement>(
      stream: AnnouncementService.getAnnouncementStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.isEnabled || snapshot.data!.text.isEmpty) {
          return const SizedBox.shrink();
        }

        final ann = snapshot.data!;
        Color bg = const Color(0xFF2563EB);
        IconData icon = Icons.campaign_rounded;
        if (ann.type == 'warning') {
          bg = const Color(0xFFD97706);
          icon = Icons.warning_amber_rounded;
        } else if (ann.type == 'success') {
          bg = const Color(0xFF16A34A);
          icon = Icons.check_circle_outline_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bg.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bg.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: bg, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: ann.link != null && ann.link!.isNotEmpty
                      ? () => _launchUrl(ann.link!)
                      : null,
                  child: MarqueeAnnouncementText(
                    text: ann.text,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: bg,
                    ),
                  ),
                ),
              ),
              if (ann.link != null && ann.link!.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.open_in_new_rounded, color: bg, size: 18),
                  onPressed: () => _launchUrl(ann.link!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'فتح الرابط',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumBanner(BuildContext context, UserModel user) {
    final bool isPremium = user.isPremium;
    final title = isPremium ? 'النسخة المميزة الكاملة' : 'اشتراك محدود';
    final subtitle =
    isPremium ? 'استمتع بجميع المميزات' : 'اشترك لفتح بقية المواد';

    String statusText = isPremium ? 'مُفعّل' : 'اضغط على زر تفعيل في الاسفل';
    if (isPremium && user.expiryDate != null) {
      final days = user.expiryDate!.difference(DateTime.now()).inDays;
      if (days > 365) {
        statusText = 'مُفعّل (دائمي)';
      } else {
        final dateStr = "${user.expiryDate!.year}/${user.expiryDate!.month}/${user.expiryDate!.day}";
        statusText = 'مُفعّل لغاية $dateStr';
      }
    }

    final gradient = isPremium
        ? const LinearGradient(
      colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF0F766E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Color(0xFFFACC15), Color(0xFFFB7185), Color(0xFFEF4444)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow(opacity: 0.12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: _t(
                          14,
                          w: FontWeight.w700,
                          c: Colors.white.withOpacity(0.9),
                          ls: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: _t(
                          20,
                          w: FontWeight.w900,
                          c: Colors.white,
                          h: 1.15,
                          ls: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border:
                          Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPremium ? Icons.verified : Icons.lock_clock,
                              size: 16,
                              color: Colors.white.withOpacity(0.95),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: _t(12,
                                  w: FontWeight.w800,
                                  c: Colors.white.withOpacity(0.95)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.stars_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
      BuildContext context,
      Map<String, dynamic> subject,
      bool isLocked,
      UserModel user,
      ) {
    final Color base = subject['color'] as Color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: base.withOpacity(isDark ? 0.25 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // خلفية البطاقة الفاخرة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF131C31),
                          const Color(0xFF1E293B),
                          base.withOpacity(0.12),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8FAFC),
                          base.withOpacity(0.08),
                        ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: base.withOpacity(isDark ? 0.3 : 0.22),
                  width: 1.2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectExamsScreen(
                          subjectName: subject['name'] as String,
                          subjectKey: subject['key'] as String,
                          subjectIcon: subject['icon'] as IconData,
                          subjectColor: subject['color'] as Color,
                          user: user,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // القسم الأيمن: أيقونة المادة + اسم المادة + اضغط للبدء أو مطلوب اشتراك
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      base.withOpacity(0.22),
                                      base.withOpacity(0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: base.withOpacity(0.3)),
                                ),
                                child: Icon(
                                  subject['icon'] as IconData,
                                  color: base,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject['name'] as String,
                                      style: GoogleFonts.notoKufiArabic(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    if (isLocked)
                                      Row(
                                        children: [
                                          Icon(Icons.lock_rounded, size: 13, color: Colors.redAccent.shade200),
                                          const SizedBox(width: 4),
                                          Text(
                                            'مطلوب اشتراك 🔒',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent.shade200,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.stars_rounded, size: 14, color: Color(0xFF22C55E)),
                                          SizedBox(width: 4),
                                          Text(
                                            'اضغط للبدء ✨',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // القسم الأيسر: زر سهم الانتقال
                      SizedBox(
                        width: 70,
                        child: Center(
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  base.withOpacity(0.22),
                                  base.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: base.withOpacity(0.35)),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: base,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // الخط العمودي المتقطع (Perforated Line)
            Positioned(
              left: 70,
              top: 12,
              bottom: 12,
              child: CustomPaint(
                size: const Size(1, double.infinity),
                painter: _VerticalDashedLinePainter(
                  color: base.withOpacity(isDark ? 0.35 : 0.25),
                ),
              ),
            ),

            // الفتحة النصف دائرية العلوية (Top Notch)
            Positioned(
              left: 59,
              top: -11,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scaffoldBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: base.withOpacity(isDark ? 0.3 : 0.22),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            // الفتحة النصف دائرية السفلية (Bottom Notch)
            Positioned(
              left: 59,
              bottom: -11,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scaffoldBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: base.withOpacity(isDark ? 0.3 : 0.22),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubjectStatus(String subjectKey, bool isLocked) {
    if (subjectKey == 'arabic') {
      return isLocked
          ? 'الامتحان العام والتخصصي • تجربة مجانية'
          : 'الامتحان العام والتخصصي • متاح للبدء';
    }
    return isLocked
        ? 'الامتحان العام والتخصصي • باقة VIP'
        : 'الامتحان العام والتخصصي • متاح للبدء';
  }

  Color _getStatusColor(String subjectKey, bool isLocked) {
    return isLocked ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
  }

  void _navigateToSubscriptionWithSlide(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SubscriptionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  void _showLuxurySubscriptionDialog(BuildContext context, {
    String? title,
    String? subtitle,
  }) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final dialogTitle = title ?? (isIos ? 'عضوية الحساب المميز 👑' : 'فتح الباقة الملكية VIP 👑');
    final dialogSubtitle = subtitle ?? (isIos
        ? 'الوصول الكامل إلى بنوك الأسئلة والأستاذ الذكي والملازم واجتياز الامتحان بتفوق!'
        : 'اشترك الآن للوصول الكامل إلى بنوك الأسئلة والأستاذ الذكي واجتياز الامتحان الوطني بتفوق!');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFACC15).withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFACC15), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFACC15).withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF0F172A), size: 36),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    dialogTitle,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dialogSubtitle,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Color(0xFFCBD5E1),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        _buildVipBenefitRow('بنوك الأسئلة الشاملة (1000 سؤال كامل) لكل مادة'),
                        const SizedBox(height: 8),
                        _buildVipBenefitRow('استخدام غير محدود لـ "الأستاذ الذكي AI" على مدار الساعة'),
                        const SizedBox(height: 8),
                        _buildVipBenefitRow('كافة الملازم ونماذج الفورمات الوزارية المعتمدة'),
                        const SizedBox(height: 8),
                        _buildVipBenefitRow(isIos ? 'إحصائيات متقدمة ودعم فني وإرشادات أكاديمية' : 'إحصائيات متقدمة ودعم فني مباشر عبر الواتساب'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('لاحقاً', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFACC15),
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _navigateToSubscriptionWithSlide(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isIos ? 'تفاصيل العضوية 👑' : 'الترقية والاشتراك 👑',
                                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVipBenefitRow(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showFreeArabicDialog(
      BuildContext context, String subjectName, String subjectKey) async {
    // ✅ التحقق من Firestore أولاً (لا يمكن التحايل عليه بمسح بيانات التطبيق)
    final subService = SubscriptionService();
    final bool hasTakenFree = await subService.hasTakenFreeArabicTrial();

    if (hasTakenFree) {
      if (!context.mounted) return;
      _showLuxurySubscriptionDialog(
        context,
        title: 'لقد استهلكت تجربتك المجانية ✨',
        subtitle: 'نأمل أن تكون التجربة قد نالت إعجابك! للاستمرار في إجراء الاختبارات والوصول إلى كافة المواد والميزات، اشترك الآن في باقة VIP.',
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220).withOpacity(0.92),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نسخة تجريبية مجانية',
                    style: _t(22,
                        w: FontWeight.w900,
                        c: const Color(0xFF4ADE80),
                        ls: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subjectName,
                    style: _t(18, w: FontWeight.w800, c: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.quiz_rounded,
                                color: Color(0xFF4ADE80), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '30 سؤال',
                              style: _t(28,
                                  w: FontWeight.w900,
                                  c: const Color(0xFF4ADE80)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'سيتم عرض 30 سؤال فقط في هذه النسخة المجانية',
                          style: _t(14,
                              w: FontWeight.w600, c: Colors.white70, h: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'للوصول إلى 100 سؤال كامل، يرجى الاشتراك في النسخة المميزة',
                          style: _t(13,
                              w: FontWeight.w500, c: Colors.white54, h: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // ⚠️ تنبيه: التجربة مرة واحدة فقط
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Text(
                            '⚠️ هذه التجربة متاحة مرة واحدة فقط لكل حساب',
                            style: _t(12, w: FontWeight.w700, c: Colors.orange, h: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.18),
                                width: 1.2),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text('إلغاء',
                              style: _t(14,
                                  w: FontWeight.w800, c: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _startQuiz(context, subjectName, subjectKey, 30, false, isFreeArabicTrial: true);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text('ابدأ الاختبار',
                                  style: _t(14,
                                      w: FontWeight.w900, c: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showNonPremiumDialog(BuildContext context) {
    _showLuxurySubscriptionDialog(
      context,
      title: 'باقة VIP الملكية مطلوبة 👑',
      subtitle: 'هذه المادة والامتحان الكامل مخصص لمشتركي باقة VIP. اشترك الآن وافتح كافة المواد والميزات فوراً!',
    );
  }

  void _showQuestionsCountDialog(
      BuildContext context,
      String subjectName,
      String subjectKey,
      UserModel user,
      ) {
    final List<int> availableCounts = [30, 60, 90, 120];
    int selectedCount = 30;
    bool showAnswersDuringExam = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: StatefulBuilder(
              builder: (context, setState) => Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.quiz_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختر عدد الأسئلة',
                      style: _t(22,
                          w: FontWeight.w900,
                          c: const Color(0xFFC084FC),
                          ls: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subjectName,
                      style: _t(16, w: FontWeight.w700, c: Colors.white70),
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: availableCounts.map((count) {
                        final isSelected = selectedCount == count;
                        return InkWell(
                          onTap: () => setState(() => selectedCount = count),
                          child: Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6D28D9)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.18),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: _t(18,
                                    w: FontWeight.w900,
                                    c: isSelected
                                        ? Colors.white
                                        : Colors.white70),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات إضافية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC084FC),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.visibility_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'إظهار الإجابات الصحيحة والتعليل أثناء الامتحان',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              Switch(
                                value: showAnswersDuringExam,
                                onChanged: (value) {
                                  setState(() {
                                    showAnswersDuringExam = value;
                                  });
                                },
                                activeColor: const Color(0xFF8B5CF6),
                                activeTrackColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            showAnswersDuringExam
                                ? 'عند اختيار الإجابة، ستظهر الإجابة الصحيحة والتعليل مباشرة'
                                : 'اذا قمت بتفعيل الخيار اعلاه سيتم عرض الإجابات الصحيحة والتعليل اثناء الاختبار واذا لا ستظهر نهاية الاختبار',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11,
                              color: showAnswersDuringExam
                                  ? Colors.green.withOpacity(0.7)
                                  : Colors.orange.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                  width: 1.2),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('إلغاء',
                                style: _t(14,
                                    w: FontWeight.w800, c: Colors.white70)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _startQuiz(
                                context,
                                subjectName,
                                subjectKey,
                                selectedCount,
                                showAnswersDuringExam,
                              );
                            },
                            child: Text('ابدأ ($selectedCount سؤال)',
                                style: _t(14,
                                    w: FontWeight.w900, c: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, String subjectName, String subjectKey,
      int questionsCount, bool showAnswersDuringExam, {bool isFreeArabicTrial = false}) {
    final Map<String, String> questionsUrls = {
      'arabic':
          'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/arabic',
      'computer':
          'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/computer_ar',
      'english':
          'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/english',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          subject: subjectName,
          subjectKey: subjectKey,
          questionsUrl: questionsUrls[subjectKey]!,
          questionsCount: questionsCount,
          showAnswersDuringExam: showAnswersDuringExam,
          isFreeArabicTrial: isFreeArabicTrial,
        ),
      ),
    );
  }


  void _showActivationDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220).withOpacity(0.92),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFACC15),
                          Color(0xFFFB7185),
                          Color(0xFFEF4444)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text('تفعيل الاشتراك المميز',
                      style: _t(20, w: FontWeight.w900, c: _gold, ls: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'تفعيل الاشتراك يتم مباشرة عن طريق التواصل مع الدعم الفني للإدارة. قم باختيار إحدى الوسائل التالية للترقية:',
                    style: _t(13.5, w: FontWeight.w600, c: Colors.white70, h: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await launchUrl(
                                Uri.parse('https://wa.me/9647824255360'),
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.chat_rounded,
                              color: Colors.white, size: 20),
                          label: Text('واتساب',
                              style: _t(13.5,
                                  w: FontWeight.w900, c: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await launchUrl(Uri.parse('https://t.me/XG0LDX'),
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                          label: Text('تليجرام',
                              style: _t(13.5,
                                  w: FontWeight.w900, c: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.18),
                            width: 1.2),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('إغلاق',
                          style: _t(13,
                              w: FontWeight.w800, c: Colors.white70)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousExamsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviousExamsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختباراتك السابقة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عرض نتائج جميع الاختبارات التي قمت بها',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTutorBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.aiTutor);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'الأستاذ الذكي المساعد (AI) 🤖',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'اسأل الأستاذ الذكي عن أي سؤال أو قاعدة وافهمها فوراً!',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFC7D2FE),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF818CF8), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _luxuryBackground(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A0F1D), Color(0xFF131C31), Color(0xFF0A0F1D)]
              : const [_bgTop, _bgMid, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF60A5FA).withOpacity(isDark ? 0.06 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -140,
            bottom: -160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFACC15).withOpacity(isDark ? 0.05 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final SubscriptionService subService = SubscriptionService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: authService.userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LuxuryLoading(message: 'جاري جلب البيانات...'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Text('جاري جلب البيانات',
                  style: _t(15, w: FontWeight.w800, c: isDark ? Colors.white : _ink)),
            ),
          );
        }

        final user = snapshot.data!;

        final subjects = [
          {
            'name': 'اللغة العربية',
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF22C55E),
            'key': 'arabic'
          },
          {
            'name': 'الحاسوب',
            'icon': Icons.computer_rounded,
            'color': const Color(0xFF3B82F6),
            'key': 'computer'
          },
          {
            'name': 'اللغة الإنجليزية',
            'icon': Icons.language_rounded,
            'color': const Color(0xFFF59E0B),
            'key': 'english'
          },
        ];

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
            surfaceTintColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
            titleSpacing: 16,
            centerTitle: false,
            iconTheme: IconThemeData(color: isDark ? Colors.white : _ink),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك،',
                        style: _t(13, w: FontWeight.w700, c: isDark ? Colors.white60 : _muted)),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? const [Colors.white, Color(0xFF60A5FA)]
                            : const [Color(0xFF1E293B), Color(0xFF2563EB)],
                      ).createShader(bounds),
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: const [],
          ),

          body: _luxuryBackground(
            context,
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnnouncementBanner(context),
                    _buildPremiumBanner(context, user),
                    const SizedBox(height: 10),
                    Text('اختر المادة لتبدأ الامتحان:',
                        style: _t(20, w: FontWeight.w900, c: _ink)),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          ...subjects.map((subject) {
                            final bool isLocked = !subService.canAccessSubject(
                                subject['name'] as String, user.isPremium);
                            return _buildSubjectCard(
                                context, subject, isLocked, user);
                          }),
                          
                          const SizedBox(height: 14),
                          _buildAiTutorBanner(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PreviousExamsScreen extends StatefulWidget {
  const PreviousExamsScreen({super.key});

  @override
  State<PreviousExamsScreen> createState() => _PreviousExamsScreenState();
}

class _PreviousExamsScreenState extends State<PreviousExamsScreen> {
  List<LocalQuizResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      const String key = 'saved_quiz_results';
      List<String> resultsList = prefs.getStringList(key) ?? [];

      List<LocalQuizResult> results = [];
      for (String jsonString in resultsList) {
        try {
          Map<String, dynamic> json = jsonDecode(jsonString);
          results.add(LocalQuizResult.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing result: $e');
        }
      }

      results.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في تحميل النتائج: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes دقيقة $remainingSeconds ثانية';
    }
    return '$remainingSeconds ثانية';
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF22C55E);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        title: Text(
          'اختباراتك السابقة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : const Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      )
          : _results.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return _buildResultCard(result, isDark);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد اختبارات سابقة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإجراء اختبار جديد وستظهر نتائجك هنا',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(LocalQuizResult result, bool isDark) {
    final scoreColor = _getScoreColor(result.scorePercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            _showResultDetails(result, isDark);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            result.subjectKey == 'arabic'
                                ? const Color(0xFF22C55E)
                                : result.subjectKey == 'computer'
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFF59E0B),
                            result.subjectKey == 'arabic'
                                ? const Color(0xFF16A34A)
                                : result.subjectKey == 'computer'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFD97706),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        result.subjectKey == 'arabic'
                            ? Icons.menu_book_rounded
                            : result.subjectKey == 'computer'
                            ? Icons.computer_rounded
                            : Icons.language_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.subjectName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(result.date)} • ${_formatDuration(result.durationInSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade500,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scoreColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${result.scorePercentage.round()}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          Text(
                            'نسبة',
                            style: TextStyle(
                              fontSize: 10,
                              color: scoreColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      '${result.correctAnswers}',
                      'صحيح',
                      const Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      '${result.wrongAnswers}',
                      'خطأ',
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      '${result.totalQuestions}',
                      'إجمالي',
                      const Color(0xFF3B82F6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: result.scorePercentage / 100,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    color: scoreColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'اليوم';
    if (dateOnly == yesterday) return 'أمس';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showResultDetails(LocalQuizResult result, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                  _getScoreColor(result.scorePercentage).withOpacity(0.1),
                ),
                child: Icon(
                  result.scorePercentage >= 60
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: 48,
                  color: _getScoreColor(result.scorePercentage),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.subjectName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'النتيجة: ${result.scorePercentage.round()}%',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(result.scorePercentage),
                    fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildDetailRow('الإجابات الصحيحة',
                        '${result.correctAnswers}', Colors.green, isDark),
                    Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    _buildDetailRow('الإجابات الخاطئة',
                        '${result.wrongAnswers}', Colors.red, isDark),
                    Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    _buildDetailRow(
                        'المدة',
                        _formatDuration(result.durationInSeconds),
                        Colors.orange, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PreviousExamReviewScreen(result: result),
                      ),
                    );
                  },
                  icon:
                  const Icon(Icons.fact_check_rounded, color: Colors.white),
                  label: const Text('مراجعة الأسئلة',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إغلاق',
                    style:
                    TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white60 : Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontFamily: 'Tajawal',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

class PreviousExamReviewScreen extends StatelessWidget {
  final LocalQuizResult result;

  const PreviousExamReviewScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'مراجعة: ${result.subjectName}',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: result.wrongQuestions.isEmpty
          ? Center(
        child: Text(
          'لا توجد بيانات متاحة لهذا الاختبار',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.wrongQuestions.length,
        itemBuilder: (context, index) {
          final item = result.wrongQuestions[index];
          final bool isCorrect = item['isCorrect'] ?? false;
          final Color statusColor = isCorrect ? Colors.green : Colors.red;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'سؤال ${index + 1} (${isCorrect ? "صحيح" : "خاطئ"})',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item['question'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: statusColor,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: 'إجابتك: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: '${item['userAnswer']}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.green,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(text: 'الإجابة الصحيحة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 40, top: 4),
                    child: Text(
                      '${item['correctAnswer']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                  if (item['explanation'] != null && item['explanation'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تعليل / ملاحظة:',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['explanation'],
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                    color: Colors.blueGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class MarqueeAnnouncementText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeAnnouncementText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<MarqueeAnnouncementText> createState() => _MarqueeAnnouncementTextState();
}

class _MarqueeAnnouncementTextState extends State<MarqueeAnnouncementText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _textWidth = 0.0;
  double _textHeight = 24.0;
  double _containerWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _measureText();
  }

  void _measureText() {
    if (widget.text.isEmpty) return;
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.rtl,
    )..layout();

    _textWidth = textPainter.width;
    _textHeight = textPainter.height > 0 ? textPainter.height : 24.0;
  }

  void _setupAnimation(double containerWidth) {
    if (containerWidth <= 0 || widget.text.isEmpty) return;

    _measureText();
    _containerWidth = containerWidth;

    // المسافة الإجمالية التي يقطعها النص: يبدأ من أقصى اليمين (عرض الحاوية) حتى يختفي تماماً في أقصى اليسار (-عرض النص)
    final double totalDistance = _containerWidth + _textWidth;
    
    // سرعة متناسقة ومريحة للقراءة (~45 بكسل بالثانية)
    final double durationSeconds = (totalDistance / 45.0).clamp(6.0, 60.0);

    _controller.duration = Duration(milliseconds: (durationSeconds * 1000).round());
    _controller.reset();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(MarqueeAnnouncementText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _measureText();
      _setupAnimation(_containerWidth);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double safeHeight = _textHeight.clamp(20.0, 36.0);

    return SizedBox(
      height: safeHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth != _containerWidth && constraints.maxWidth > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _setupAnimation(constraints.maxWidth);
                });
              }
            });
          }

          return ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // التحرك المعكوس: يبدأ من أقصى اليسار إلى أقصى اليمين
                final double dx = -_textWidth + _controller.value * (_containerWidth + _textWidth);

                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: OverflowBox(
                minWidth: 0.0,
                maxWidth: double.infinity,
                minHeight: safeHeight,
                maxHeight: safeHeight,
                alignment: Alignment.centerRight,
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  textDirection: TextDirection.rtl,
                  style: widget.style,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  _VerticalDashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + 4).clamp(0.0, size.height)),
        paint,
      );
      startY += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


