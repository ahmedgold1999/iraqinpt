import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';
import '../../models/question_model.dart';
import '../../models/specialized_exam_model.dart';
import '../../services/question_service.dart';
import '../../services/specialized_exam_service.dart';
import '../../services/subscription_service.dart';
import '../../services/config_service.dart';
import 'quiz_screen.dart';
import 'subscription_screen.dart';

class SubjectExamsScreen extends StatefulWidget {
  final String subjectName;
  final String subjectKey; // 'arabic', 'computer', 'english'
  final IconData subjectIcon;
  final Color subjectColor;
  final UserModel user;

  const SubjectExamsScreen({
    super.key,
    required this.subjectName,
    required this.subjectKey,
    required this.subjectIcon,
    required this.subjectColor,
    required this.user,
  });

  @override
  State<SubjectExamsScreen> createState() => _SubjectExamsScreenState();
}

class _SubjectExamsScreenState extends State<SubjectExamsScreen> {
  final SpecializedExamService _examService = SpecializedExamService();
  final SubscriptionService _subService = SubscriptionService();
  bool _hasTakenFreeArabic = false;
  bool _isLoadingTrialStatus = true;

  @override
  void initState() {
    super.initState();
    _checkArabicTrialStatus();
  }

  Future<void> _checkArabicTrialStatus() async {
    if (widget.subjectKey == 'arabic' && !widget.user.isPremium) {
      final taken = await _subService.hasTakenFreeArabicTrial();
      if (mounted) {
        setState(() {
          _hasTakenFreeArabic = taken;
          _isLoadingTrialStatus = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingTrialStatus = false);
      }
    }
  }

  void _navigateToSubscription() {
    if (ConfigService().isReviewMode) {
      _showRestrictedAccessDialog();
      return;
    }
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

  void _showRestrictedAccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF60A5FA), size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تنبيه دراسي 📚',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'هذه المادة فقط للطلاب المخصصين لها',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
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

  void _showLuxurySubscriptionPrompt({String? title, String? message}) {
    if (ConfigService().isReviewMode) {
      _showRestrictedAccessDialog();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDark ? Colors.white70 : const Color(0xFF475569);

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // أيقونة التاج الذهبي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 14),
                Text(
                  title ?? 'باقة المشتركين المميزين VIP 👑',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  message ??
                      'احصل على الاعتماد الأكاديمي وافتح كافة بنوك الأسئلة والاختبارات التخصصية لضمان تفوقك في الامتحان الوطني.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                // قائمة تفصيلية: ماذا يحصل المشترك عند الاشتراك
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow(
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF2563EB),
                        title: 'الوصول لكافة بنوك الأسئلة المعتمدة',
                        desc: 'أكثر من 3000 سؤال وزاري وتخصصي لجميع المواد (الحاسوب، العربي، الإنكليزي).',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const Divider(height: 18),
                      _buildBenefitRow(
                        icon: Icons.flash_on_rounded,
                        color: const Color(0xFFF59E0B),
                        title: 'كافة الاختبارات التخصصية والفرعية',
                        desc: 'فتح كامل للاختبارات المركزة (اختصارات المفاتيح، القواعد، المصطلحات، إلخ).',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const Divider(height: 18),
                      _buildBenefitRow(
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF10B981),
                        title: 'الأستاذ الذكي AI للمساعدة والتفسير',
                        desc: 'شرح فوري وتفكيك خطوات الإجابة لأي سؤال غامض أو مسألة يصعب عليك فهمها.',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const Divider(height: 18),
                      _buildBenefitRow(
                        icon: Icons.timer_rounded,
                        color: const Color(0xFF8B5CF6),
                        title: 'محاكاة حقيقية للامتحان الوطني',
                        desc: 'اختيار عدد الأسئلة مع مؤقت زمني ونظام درجات رسمي يحاكي الاختبار الوزاري.',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const Divider(height: 18),
                      _buildBenefitRow(
                        icon: Icons.leaderboard_rounded,
                        color: const Color(0xFFEC4899),
                        title: 'لوحة الشرف وتتبع التقدم الدراسي',
                        desc: 'حفظ مستواك وسجل درجاتك والتنافس مع آلاف الطلاب في عموم محافظات العراق.',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // زر الترقية والاشتراك
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToSubscription();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الترقية والاشتراك في باقة VIP 🚀',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [

                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(fontFamily: 'Tajawal', color: textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.5,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // بدء الامتحان العام
  // ==========================================
  void _onGeneralExamTap() {
    final bool isArabic = widget.subjectKey == 'arabic';
    final bool isPremium = widget.user.isPremium;

    if (isArabic && !isPremium) {
      if (_hasTakenFreeArabic) {
        _showLuxurySubscriptionPrompt(
          title: 'لقد استهلكت تجربتك المجانية ✨',
          message:
              'نأمل أن تكون التجربة قد نالت إعجابك! للاستمرار في إجراء الاختبارات والوصول إلى كافة المواد والميزات، تفضل بالتواصل مع المشرف الأكاديمي.',
        );
        return;
      }
      _showFreeArabicDialog();
      return;
    }

    if (!isPremium) {
      _showLuxurySubscriptionPrompt(
        title: 'مادة ${widget.subjectName} مخصصة للمشتركين 🔒',
        message:
            'امتحانات مادة ${widget.subjectName} متاحة ضمن الحساب المعتمد. تفضل بالتواصل مع المشرف الأكاديمي لفتح كافة بنوك الأسئلة والاختبارات فوراً.',
      );
      return;
    }

    // المستخدم مشترك VIP
    _showQuestionsCountDialog();
  }

  void _showFreeArabicDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220).withOpacity(0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تجربة مجانية: الامتحان العام',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ADE80),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '30 سؤالاً ثابتاً',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تتضمن هذه التجربة 30 سؤالاً تم اختيارها بدقة لاختبار مستواك قبل الترقية.',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: const Text(
                            '⚠️ التجربة متاحة لمرة واحدة فقط',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startQuiz(30, false, isFreeArabicTrial: true);
                          },
                          child: const Text(
                            'ابدأ الاختبار 🚀',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13.5),
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

  void _showQuestionsCountDialog() {
    int selectedQuestions = 40;
    bool showAnswersDuringExam = false;

    final questionOptions = [
      {'count': 20, 'label': '20 سؤال', 'desc': 'اختبار سريع (15 دقيقة)'},
      {'count': 40, 'label': '40 سؤال', 'desc': 'اختبار قياسي (30 دقيقة)'},
      {'count': 60, 'label': '60 سؤال', 'desc': 'اختبار مكثف (45 دقيقة)'},
      {'count': 100, 'label': '100 سؤال', 'desc': 'محاكاة كاملة للوزاري (75 دقيقة)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.subjectColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.tune_rounded, color: widget.subjectColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الامتحان العام: ${widget.subjectName}',
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'اختر عدد الأسئلة ونمط التدريب',
                                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // خيارات عدد الأسئلة
                      ...questionOptions.map((opt) {
                        final count = opt['count'] as int;
                        final isSelected = selectedQuestions == count;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setModalState(() => selectedQuestions = count),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? widget.subjectColor.withOpacity(0.15)
                                    : Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? widget.subjectColor.withOpacity(0.7)
                                      : Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected ? widget.subjectColor : Colors.white38,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt['label'] as String,
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          opt['desc'] as String,
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 11,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      // مفتاح عرض الإجابات أثناء الاختبار (نمط التدريب المباشر)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'إظهار التفسير والإجابة فور الاختيار',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Switch(
                              value: showAnswersDuringExam,
                              activeColor: const Color(0xFF38BDF8),
                              onChanged: (val) => setModalState(() => showAnswersDuringExam = val),
                            ),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.subjectColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _startQuiz(selectedQuestions, showAnswersDuringExam);
                              },
                              child: const Text(
                                'بدء الامتحان 🚀',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
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
          );
        },
      ),
    );
  }

  void _startQuiz(int count, bool showAnswers, {bool isFreeArabicTrial = false}) {
    final url = QuestionService.defaultSubjectUrls[widget.subjectKey] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          subject: widget.subjectName,
          subjectKey: widget.subjectKey,
          questionsUrl: url,
          questionsCount: count,
          showAnswersDuringExam: showAnswers,
          isFreeArabicTrial: isFreeArabicTrial,
        ),
      ),
    );
  }

  // ==========================================
  // بدء اختبار تخصصي فرعي (من الكاش الأوفلاين)
  // ==========================================
  Future<void> _startSpecializedExam(SpecializedExamModel exam) async {
    // كافة الاختبارات التخصصية مدفوعة
    if (!widget.user.isPremium) {
      _showLuxurySubscriptionPrompt(
        title: 'اختبار تخصصي VIP 🔒',
        message: 'اختبار "${exam.title}" مخصص للحسابات المعتمدة. تفضل بالاطلاع على التفاصيل لفتحه بدون قيود.',
      );
      return;
    }

    bool showAnswersDuringExam = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.subjectColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              exam.iconEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.title,
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${exam.questionsCount} سؤالاً • ${exam.durationMinutes} دقيقة',
                                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (exam.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.description,
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70, height: 1.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // مفتاح إظهار التفسير والإجابة فور الاختيار
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'إظهار التفسير والإجابة فور الاختيار',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Switch(
                              value: showAnswersDuringExam,
                              activeColor: const Color(0xFF38BDF8),
                              onChanged: (val) => setModalState(() => showAnswersDuringExam = val),
                            ),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.subjectColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _proceedToSpecializedExam(exam, showAnswersDuringExam);
                              },
                              child: const Text(
                                'بدء الامتحان 🚀',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
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
          );
        },
      ),
    );
  }

  Future<void> _proceedToSpecializedExam(SpecializedExamModel exam, bool showAnswersDuringExam) async {
    // إظهار مؤشر تحميل خفيف أثناء استخراج الأسئلة من الذاكرة المحلية
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.subjectColor),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              const Text(
                'جاري تجهيز الاختبار والأسئلة... ⚡',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final questions = await _examService.getQuestionsForExam(exam);
      if (mounted) Navigator.pop(context); // إغلاق مؤشر التحميل

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر تحميل أسئلة الاختبار حالياً. يرجى التأكد من اتصال الإنترنت لتحميلها للمرة الأولى.',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              subject: '${widget.subjectName} - ${exam.title}',
              subjectKey: widget.subjectKey,
              questionsUrl: exam.jsonUrl,
              questionsCount: questions.length,
              initialQuestions: questions,
              showAnswersDuringExam: showAnswersDuringExam,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل الأسئلة: $e', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ==========================================
  // باقة التدرجات اللونية الفخمة لبطاقات الـ Voucher
  // ==========================================
  static const List<List<Color>> _voucherGradients = [
    [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E3A8A)], // أزرق ملوكي
    [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF4C1D95)], // بنفسجي ملكي
    [Color(0xFF059669), Color(0xFF047857), Color(0xFF064E3B)], // زمردي فاخر
    [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)], // كهرماني عميق
    [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF881337)], // ياقوتي وردي
    [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF134E4A)], // تركواز بترولي
    [Color(0xFF4F46E5), Color(0xFF4338CA), Color(0xFF312E81)], // نيلي كلاسيكي
    [Color(0xFFC026D3), Color(0xFFA21CAF), Color(0xFF701A75)], // ماجينتا ليلكي
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final isArabic = widget.subjectKey == 'arabic';
    final isPremium = widget.user.isPremium;

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131C31) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.subjectIcon, color: widget.subjectColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              widget.subjectName,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 22),
            tooltip: 'تحديث ومزامنة الأسئلة',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('جاري تحديث وجلب أحدث الأسئلة ⚡', style: TextStyle(fontFamily: 'Tajawal')),
                  duration: Duration(seconds: 1),
                ),
              );
              await _examService.syncAllExamsOffline(forceUpdate: true);
              if (mounted) {
                setState(() {});
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث بنك الأسئلة بالكامل بنجاح! ✨', style: TextStyle(fontFamily: 'Tajawal')),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              }
            },
          ),
          if (!isPremium && !ConfigService().isReviewMode)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ActionChip(
                backgroundColor: const Color(0xFFFACC15).withOpacity(0.15),
                side: const BorderSide(color: Color(0xFFFACC15)),
                label: const Text(
                  'ترقية VIP 👑',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEAB308),
                  ),
                ),
                onPressed: _navigateToSubscription,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الشرح المخصص عن المادة المعنية في الأعلى فقط
            _buildSubjectHeaderBanner(isDark),
            const SizedBox(height: 18),

            // تجميع كافة الاختبارات معاً بصيغة Voucher App Design
            _buildAllExamsUnifiedList(isDark, isArabic, isPremium, primaryBg),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // الشرح المخصص عن المادة المعنية في الأعلى
  // ==========================================
  Widget _buildSubjectHeaderBanner(bool isDark) {
    String subjectDesc = 'اختبارات تحاكي النمط الوزاري المعتمد للاختبار الوطني للقبول الجامعي والدراسات العليا.';
    if (widget.subjectKey == 'arabic') {
      subjectDesc = 'منهاج اللغة العربية للاختبار الوطني: تدريبات شاملة ومركزة تغطي قواعد النحو والإعراب، الصرف، البلاغة، وقواعد الإملاء المعتمدة وزارياً.';
    } else if (widget.subjectKey == 'computer') {
      subjectDesc = 'منهاج الحاسوب للاختبار الوطني: تدريبات عملية ومكثفة تغطي المفاهيم البرمجية، شبكات الحاسوب، أمن المعلومات، واختصارات لوحة المفاتيح.';
    } else if (widget.subjectKey == 'english') {
      subjectDesc = 'منهاج اللغة الإنكليزية للاختبار الوطني: تدريبات شاملة على القواعد الأكاديمية (Grammar)، بنك المفردات (Vocabulary)، وقراءة النصوص.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.subjectColor.withOpacity(0.15),
            widget.subjectColor.withOpacity(0.04),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.subjectColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.subjectColor, widget.subjectColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(widget.subjectIcon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'منهاج ${widget.subjectName}',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subjectDesc,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // تجميع كافة الاختبارات معاً في قائمة واحدة
  // ==========================================
  Widget _buildAllExamsUnifiedList(bool isDark, bool isArabic, bool isPremium, Color primaryBg) {
    return StreamBuilder<List<SpecializedExamModel>>(
      stream: _examService.streamExamsForSubject(widget.subjectKey),
      builder: (context, snapshot) {
        final List<SpecializedExamModel> specializedExams = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return FutureBuilder<List<SpecializedExamModel>>(
            future: _examService.getOfflineExamsForSubject(widget.subjectKey),
            builder: (ctx, offlineSnap) {
              final offlineExams = offlineSnap.data ?? [];
              return _renderUnifiedVouchers(offlineExams, isDark, isArabic, isPremium, primaryBg);
            },
          );
        }

        return _renderUnifiedVouchers(specializedExams, isDark, isArabic, isPremium, primaryBg);
      },
    );
  }

  Widget _renderUnifiedVouchers(
    List<SpecializedExamModel> specializedExams,
    bool isDark,
    bool isArabic,
    bool isPremium,
    Color primaryBg,
  ) {
    final bool isGeneralLocked = !isPremium && (!isArabic || (isArabic && _hasTakenFreeArabic));
    final bool isGeneralFreeTrial = isArabic && !isPremium && !_hasTakenFreeArabic;

    String defaultGeneralEmoji = '💻';
    if (widget.subjectKey == 'arabic') defaultGeneralEmoji = '📚';
    if (widget.subjectKey == 'english') defaultGeneralEmoji = '🇬🇧';

    return Column(
      children: [
        // 1. قسيمة الامتحان الرئيسي الشامل (Voucher 0)
        _buildVoucherCard(
          context: context,
          title: 'الامتحان الشامل - ${widget.subjectName}',
          emoji: defaultGeneralEmoji,
          shortDesc: 'الاختبار الوزاري الشامل للبنك الرئيسي مع مؤقت ونظام درجات رسمي',
          detailBadges: [
            _buildVoucherBadge(Icons.format_list_numbered_rounded, 'اختيار 20 - 100 سؤال'),
            _buildVoucherBadge(Icons.timer_outlined, 'مؤقت تفاعلي'),
          ],
          onTap: _onGeneralExamTap,
          isLocked: isGeneralLocked,
          isFreeTrial: isGeneralFreeTrial,
          gradientIndex: 0,
          isDark: isDark,
          primaryBg: primaryBg,
        ),

        // 2. قسائم الاختبارات التخصصية والفرعية (Vouchers 1, 2, 3...)
        ...specializedExams.asMap().entries.map((entry) {
          final exam = entry.value;
          final idx = entry.key + 1;
          final bool isExamLocked = !isPremium;

          return _buildVoucherCard(
            context: context,
            title: exam.title,
            emoji: exam.iconEmoji,
            shortDesc: exam.description.isNotEmpty ? exam.description : null,
            detailBadges: [
              _buildVoucherBadge(Icons.quiz_outlined, '${exam.questionsCount} سؤال'),
              _buildVoucherBadge(Icons.schedule_rounded, '${exam.durationMinutes} دقيقة'),
            ],
            onTap: () => _startSpecializedExam(exam),
            isLocked: isExamLocked,
            isFreeTrial: false,
            gradientIndex: idx,
            isDark: isDark,
            primaryBg: primaryBg,
          );
        }),
      ],
    );
  }

  // ==========================================
  // تصميم بطاقة الاختبار بصيغة Voucher App Design
  // ==========================================
  Widget _buildVoucherCard({
    required BuildContext context,
    required String title,
    String? emoji,
    required String? shortDesc,
    required List<Widget> detailBadges,
    required VoidCallback onTap,
    required bool isLocked,
    required bool isFreeTrial,
    required int gradientIndex,
    required bool isDark,
    required Color primaryBg,
  }) {
    final gradient = _voucherGradients[gradientIndex % _voucherGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(isDark ? 0.35 : 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الجزء العلوي: اسم الامتحان والشرح القصير إن وجد
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: emoji != null
                              ? Text(emoji, style: const TextStyle(fontSize: 22))
                              : Icon(
                                  isLocked ? Icons.lock_outline_rounded : Icons.quiz_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.notoKufiArabic(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (shortDesc != null && shortDesc.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  shortDesc,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white.withOpacity(0.85),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFDE047)),
                                const SizedBox(width: 4),
                                Text(
                                  ConfigService().isReviewMode ? 'مخصص' : 'VIP',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFDE047),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isFreeTrial)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'تجربة مجانية 🎁',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // الخط المخطط مثل Voucher الهدية مع دوائر الثقب على الجانبين
                  _buildVoucherDivider(primaryBg),

                  // الجزء السفلي: تفاصيل الامتحان وزر الدخول والبدء
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // بادجات تفاصيل الامتحان (الأسئلة والوقت)
                        Row(
                          children: detailBadges,
                        ),
                        const SizedBox(height: 12),

                        // زر الدخول والبدء كقسيمة واضحة ومميزة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLocked ? Icons.lock_open_rounded : Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'اضغط هنا للدخول والبدء',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_back_rounded,
                                size: 15,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ==========================================
  // ودجت خط القسيمة المخطط مع دوائر التقطيع (Voucher Notch Divider)
  // ==========================================
  Widget _buildVoucherDivider(Color notchBg) {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الخط المخطط (Dashed Line)
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 6.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth - 44) ~/ (dashWidth + dashSpace);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              );
            },
          ),
          // دائرة القطع اليسرى
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: notchBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // دائرة القطع اليمنى
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: notchBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بادج تفاصيل الامتحان داخل الـ Voucher
  Widget _buildVoucherBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
