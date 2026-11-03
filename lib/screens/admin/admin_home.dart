import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../student/quiz_screen.dart';
import '../student/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/subscription_service.dart';
import '../../models/app_models.dart';
import '../../widgets/luxury_loading.dart';
import '../../routes.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

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
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _buildPremiumBanner(BuildContext context, bool isPremium) {
    final title = isPremium ? 'النسخة المميزة الكاملة' : 'اشتراك محدود';
    final subtitle =
    isPremium ? 'استمتع بجميع المميزات' : 'اشترك لفتح بقية المواد';

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
          // subtle shine
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
                              isPremium
                                  ? 'مُفعّل'
                                  : 'اضغط على زر تفعيل في الاسفل',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow(opacity: 0.10),
        border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: base.withOpacity(0.10),
          highlightColor: base.withOpacity(0.06),
          onTap: () {
            // إذا كانت المادة مقفلة
            if (isLocked) {
              // إذا كان المستخدم غير مشترك
              if (!user.isPremium) {
                _showNonPremiumDialog(context);
              } else {
                // مستخدم مشترك ولكن المادة مقفلة (يحتاج تفعيل)
                _showActivationDialog(context);
              }
              return;
            }

            // المادة مفتوحة
            // إذا كانت المادة هي العربية والمستخدم غير مشترك
            if (subject['key'] == 'arabic' && !user.isPremium) {
              // عرض نافذة توضيحية بـ 30 سؤال
              _showFreeArabicDialog(
                  context, subject['name'] as String, subject['key'] as String);
            } else {
              // باقي الحالات: عرض نافذة اختيار عدد الأسئلة
              _showQuestionsCountDialog(
                context,
                subject['name'] as String,
                subject['key'] as String,
                user,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon badge (luxury)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        base.withOpacity(0.25),
                        base.withOpacity(0.08),
                        Colors.white.withOpacity(0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: base.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: base.withOpacity(0.18)),
                  ),
                  child: Icon(
                    subject['icon'] as IconData,
                    color: base.withOpacity(0.95),
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
                        textAlign: TextAlign.right,
                        style: _t(
                          20,
                          w: FontWeight.w900,
                          c: _ink,
                          ls: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                  subject['key'] as String, isLocked)
                                  .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _getStatusColor(
                                    subject['key'] as String, isLocked)
                                    .withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              _getSubjectStatus(
                                  subject['key'] as String, isLocked),
                              style: _t(
                                12.5,
                                w: FontWeight.w800,
                                c: _getStatusColor(
                                    subject['key'] as String, isLocked),
                                ls: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Right action
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isLocked
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFDCFCE7),
                    border: Border.all(
                      color: isLocked
                          ? const Color(0xFFFDA4AF)
                          : const Color(0xFF86EFAC),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: isLocked
                        ? const Color(0xFFBE123C)
                        : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSubjectStatus(String subjectKey, bool isLocked) {
    if (subjectKey == 'arabic') {
      return isLocked
          ? '30 سؤال مجاني • اشترك لفتح 100 سؤال'
          : 'جاهز للامتحان • اضغط للبدء'; // ✅ غيرنا من 50 إلى 30
    }
    return isLocked ? 'يجب الاشتراك للبدء' : 'جاهز للامتحان • اضغط للبدء';
  }

  Color _getStatusColor(String subjectKey, bool isLocked) {
    return isLocked ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
  }

  // ====== نافذة للمستخدم غير المشترك لمادة العربية ======
  void _showFreeArabicDialog(
      BuildContext context, String subjectName, String subjectKey) {
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
                  // أيقونة
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
                            _startQuiz(context, subjectName, subjectKey, 30, false);
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

  // ====== نافذة للمستخدم غير المشترك ======
  void _showNonPremiumDialog(BuildContext context) {
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
                  // أيقونة القفل
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
                    ),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اشتراك مطلوب!',
                    style: _t(24, w: FontWeight.w900, c: _gold, ls: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هذه المادة تتطلب اشتراكاً مميزاً',
                    style: _t(16, w: FontWeight.w700, c: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قم بالاشتراك للوصول إلى جميع المواد والامتحانات الكاملة',
                    style: _t(14, w: FontWeight.w600, c: Colors.white54),
                    textAlign: TextAlign.center,
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
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            // الانتقال إلى شاشة التفعيل (التي في البار السفلي)
                            Navigator.pushNamed(
                                context, AppRoutes.subscription);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 18),
                              const SizedBox(width: 6),
                              Text('الاشتراك',
                                  style: _t(14,
                                      w: FontWeight.w900, c: Colors.black)),
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

  // ====== نافذة اختيار عدد الأسئلة ======
  void _showQuestionsCountDialog(
      BuildContext context,
      String subjectName,
      String subjectKey,
      UserModel user,
      ) {
    final List<int> availableCounts = [30, 60, 90, 120];
    int selectedCount = 30;
    bool showAnswersDuringExam = false; // ⭐ الخيار الجديد

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
                    // أيقونة
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

                    // أزرار اختيار العدد
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

                    // ⭐⭐⭐ خيار إظهار الإجابات أثناء الامتحان ⭐⭐⭐
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
                              Icon(Icons.visibility_rounded,
                                  color: Colors.white70, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
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

                    // الأزرار
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
                                showAnswersDuringExam, // ⭐ تمرير الخيار
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
      int questionsCount, bool showAnswersDuringExam) {  // ⭐ أضف المعامل الجديد
    final Map<String, String> questionsUrls = {
      'arabic':
      'https://raw.githubusercontent.com/ahmedgold1999/inptquestions/refs/heads/main/arabic.json',
      'computer':
      'https://raw.githubusercontent.com/ahmedgold1999/inptquestions/refs/heads/main/computer.json',
      'english':
      'https://raw.githubusercontent.com/ahmedgold1999/inptquestions/refs/heads/main/english.json',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          subject: subjectName,
          subjectKey: subjectKey,
          questionsUrl: questionsUrls[subjectKey]!,
          questionsCount: questionsCount,
          showAnswersDuringExam: showAnswersDuringExam, // ⭐ تمرير الخيار
        ),
      ),
    );
  }

  // ====== Dialogs ======
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
                  Text('عضوية الحساب المميز 👑',
                      style: _t(20, w: FontWeight.w900, c: _gold, ls: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'للحصول على اشتراكك وتفعيل حسابك للوصول الكامل لكافة المواد والامتحانات، يرجى مراسلة إدارة المنصة لإتمام التفعيل فوراً:',
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
                                Uri.parse('https://wa.me/9647824255360?text=${Uri.encodeComponent('مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني')}'),
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.chat_rounded,
                              color: Colors.white, size: 20),
                          label: Text('واتساب الإدارة',
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
                            await launchUrl(Uri.parse('https://t.me/XG0LDX?text=${Uri.encodeComponent('مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني')}'),
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                          label: Text('تليجرام الإدارة',
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

  void _showConfirmationDialog(BuildContext context, String subjectName,
      String subjectKey, UserModel user) {
    final isPremium = user.isPremium;
    final questionsCount = _getQuestionsCount(subjectKey, isPremium);

    if (subjectKey == 'arabic' && !isPremium) {
      _showArabicFreeDialog(context, subjectName, subjectKey, questionsCount);
      return;
    }

    _showPremiumOrOtherDialog(context, subjectName, subjectKey, questionsCount);
  }

  void _showArabicFreeDialog(BuildContext context, String subjectName,
      String subjectKey, int questionsCount) {
    final Map<String, String> questionsUrls = {
      'arabic':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/arabic',
      'computer':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/computer_ar',
      'english':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/english',
    };

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
                        colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text('نسخة مجانية محدودة',
                      style: _t(20,
                          w: FontWeight.w900, c: const Color(0xFF4ADE80))),
                  const SizedBox(height: 10),
                  Text(subjectName,
                      style: _t(17, w: FontWeight.w800, c: Colors.white70)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      children: [
                        Text('النسخة المجانية: $questionsCount سؤال فقط',
                            textAlign: TextAlign.center,
                            style:
                            _t(15.5, w: FontWeight.w900, c: Colors.white)),
                        const SizedBox(height: 10),
                        Text(
                            'للوصول إلى 100 سؤال، يجب الاشتراك في النسخة المميزة',
                            textAlign: TextAlign.center,
                            style: _t(13.5,
                                w: FontWeight.w700, c: Colors.white70, h: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                              style: _t(13,
                                  w: FontWeight.w800, c: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () => _showActivationDialog(context),
                          child: Text('اشترك الآن',
                              style:
                              _t(13, w: FontWeight.w900, c: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  subject: subjectName,
                                  subjectKey: subjectKey,
                                  questionsUrl: questionsUrls[subjectKey]!,
                                  questionsCount: questionsCount,
                                ),
                              ),
                            );
                          },
                          child: Text('ابدأ ($questionsCount)',
                              style:
                              _t(13, w: FontWeight.w900, c: Colors.white)),
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

  void _showPremiumOrOtherDialog(BuildContext context, String subjectName,
      String subjectKey, int questionsCount) {
    final Map<String, String> questionsUrls = {
      'arabic':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/arabic',
      'computer':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/computer_ar',
      'english':
      'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/english',
    };

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
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 16),
                  Text('هل أنت مستعد؟',
                      style: _t(20, w: FontWeight.w900, c: _gold)),
                  const SizedBox(height: 10),
                  Text(subjectName,
                      style: _t(17, w: FontWeight.w800, c: Colors.white70)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      children: [
                        Text('عدد الأسئلة: $questionsCount',
                            textAlign: TextAlign.center,
                            style:
                            _t(15.5, w: FontWeight.w900, c: Colors.white)),
                        const SizedBox(height: 10),
                        Text(
                            'تأكد من جاهزيتك قبل البدء. لا يمكن إيقاف الامتحان بعد البدء.',
                            textAlign: TextAlign.center,
                            style: _t(13.5,
                                w: FontWeight.w700, c: Colors.white70, h: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                              style: _t(13,
                                  w: FontWeight.w800, c: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  subject: subjectName,
                                  subjectKey: subjectKey,
                                  questionsUrl: questionsUrls[subjectKey]!,
                                  questionsCount: questionsCount,
                                ),
                              ),
                            );
                          },
                          child: Text('ابدأ ($questionsCount)',
                              style:
                              _t(13, w: FontWeight.w900, c: Colors.white)),
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

  int _getQuestionsCount(String subjectKey, bool isPremium) {
    if (subjectKey == 'arabic') {
      return isPremium ? 100 : 30; // ✅ غيرنا من 50 إلى 30
    }
    return 100;
  }

  Widget _luxuryBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgMid, _bgBottom],
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
                    const Color(0xFF60A5FA).withOpacity(0.12),
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
                    const Color(0xFFFACC15).withOpacity(0.10),
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
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

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

    return StreamBuilder<UserModel?>(
      stream: authService.userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _bgTop,
            body: LuxuryLoading(message: 'جاري جلب البيانات...'),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: _bgTop,
            body: Center(
              child: Text('جاري جلب البيانات',
                  style: _t(15, w: FontWeight.w800, c: _ink)),
            ),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          // Removed bottomNavigationBar because it's now managed by the shell
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            titleSpacing: 16,
            centerTitle: false,
            iconTheme: const IconThemeData(color: _ink),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحباً بك،',
                    style: _t(14.5, w: FontWeight.w800, c: _muted)),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB), // أزرق جميل
                    fontFamily: 'Tajawal',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            // ✅ استخدام actions بدلاً من leading (تظهر في الجهة اليسرى)
            actions: [
              if (userId != null)
                StreamBuilder<int>(
                  stream: NotificationService.getUnreadCount(userId),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // أيقونة إشعارات فاخرة مع تأثيرات
                        Container(
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const NotificationsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF2563EB).withOpacity(0.1),
                                      const Color(0xFF7C3AED).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // أيقونة الجرس الرئيسية
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 26,
                                      color: unreadCount > 0
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF64748B),
                                    ),
                                    // تأثير رنين إذا كان هناك إشعارات جديدة
                                    if (unreadCount > 0)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration:
                                        const Duration(milliseconds: 500),
                                        builder: (context, value, child) {
                                          return Transform.rotate(
                                            angle: 0.1 * value * 3.14,
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          Icons.notifications_active_rounded,
                                          size: 26,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // علامة الإشعارات الجديدة
                        if (unreadCount > 0)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),

          body: _luxuryBackground(
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPremiumBanner(context, user.isPremium),
                    const SizedBox(height: 10),
                    Text('اختر المادة لتبدأ الامتحان:',
                        style: _t(20, w: FontWeight.w900, c: _ink)),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final bool isLocked = !subService.canAccessSubject(
                              subject['name'] as String, user.isPremium);
                          return _buildSubjectCard(
                              context, subject, isLocked, user);
                        },
                      ),
                    ),

                    // ✅ نزّلنا النص
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreviousExamsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Removed bottomNavigationBar because it's now managed by the shell
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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'saved_quiz_results';
      List<String> resultsList = prefs.getStringList(key) ?? [];

      List<LocalQuizResult> results = [];
      for (String jsonString in resultsList) {
        try {
          Map<String, dynamic> json = jsonDecode(jsonString);
          results.add(LocalQuizResult.fromJson(json));
        } catch (e) {
          print('Error parsing result: $e');
        }
      }

      // ترتيب النتائج من الأحدث إلى الأقدم
      results.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('خطأ في تحميل النتائج: $e'),
            backgroundColor: Colors.red),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'اختباراتك السابقة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      )
          : _results.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return _buildResultCard(result);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'لا توجد اختبارات سابقة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإجراء اختبار جديد وستظهر نتائجك هنا',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(LocalQuizResult result) {
    final scoreColor = _getScoreColor(result.scorePercentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
            // يمكن عرض تفاصيل الاختبار هنا
            _showResultDetails(result);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(result.date)} • ${_formatDuration(result.durationInSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // نسبة النجاح
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
                // إحصائيات
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
                // شريط التقدم
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: result.scorePercentage / 100,
                    backgroundColor: Colors.grey.shade200,
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

  void _showResultDetails(LocalQuizResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
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
              Text(result.subjectName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal')),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildDetailRow('الإجابات الصحيحة',
                        '${result.correctAnswers}', Colors.green),
                    const Divider(),
                    _buildDetailRow('الإجابات الخاطئة',
                        '${result.wrongAnswers}', Colors.red),
                    const Divider(),
                    _buildDetailRow(
                        'المدة',
                        _formatDuration(result.durationInSeconds),
                        Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ الزر الجديد لمراجعة الأسئلة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق الدايلوج
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
                child: const Text('إغلاق',
                    style:
                    TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'مراجعة: ${result.subjectName}',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: result.wrongQuestions.isEmpty
          ? const Center(
        child: Text(
          'لا توجد بيانات متاحة لهذا الاختبار',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.wrongQuestions.length,
        itemBuilder: (context, index) {
          final item = result.wrongQuestions[index];
          // التحقق من حالة الإجابة (صح أم خطأ)
          final bool isCorrect = item['isCorrect'] ?? false;
          final Color statusColor = isCorrect ? Colors.green : Colors.red;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // --- إجابة الطالب ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusColor.withOpacity(0.1)),
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

                // --- الإجابة الصحيحة (تظهر فقط إذا كانت إجابة الطالب خطأ) ---
                if (!isCorrect) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
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
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CleanBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _CleanBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF111418),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      elevation: 8,
      items: [
        for (final item in items)
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  _NavItemData({required this.icon, required this.label});
}
