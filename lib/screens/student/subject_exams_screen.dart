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

  void _showLuxurySubscriptionPrompt({String? title, String? message}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                        colors: [Color(0xFFFACC15), Color(0xFFEAB308)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFF0F172A), size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? 'ميزة مخصصة للمشتركين VIP 👑',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFACC15),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message ??
                        'هذا الاختبار متاح حصرياً للمشتركين في الباقة المميزة. اشترك الآن للوصول الكامل إلى كافة الاختبارات العامة والتخصصية بنقرة واحدة.',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.5,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
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
                          child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
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
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _navigateToSubscription();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stars_rounded, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'الترقية والاشتراك 👑',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
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
              'نأمل أن تكون التجربة قد نالت إعجابك! للاستمرار في إجراء الاختبارات والوصول إلى كافة المواد والميزات، اشترك الآن في باقة VIP.',
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
            'امتحانات مادة ${widget.subjectName} متاحة ضمن اشتراك VIP. اشترك الآن وافتح كافة بنوك الأسئلة والاختبارات التخصصية فوراً.',
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
        message: 'اختبار "${exam.title}" مخصص للمشتركين فقط. اشترك الآن وافتحه بدون قيود.',
      );
      return;
    }

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
                'جاري تجهيز الأسئلة أوفلاين... ⚡',
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
              questionsUrl: exam.jsonUrl,
              questionsCount: questions.length,
              initialQuestions: questions,
              showAnswersDuringExam: false,
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
          if (!isPremium)
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
            // ==========================================
            // الهيدر والبانر التعريفي بالمادة
            // ==========================================
            _buildSubjectHeaderBanner(isDark),
            const SizedBox(height: 20),

            // ==========================================
            // القسم الأول: الامتحان العام (National Main Exam)
            // ==========================================
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text(
                  'الامتحان الوطني الموحد (العام)',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildGeneralExamCard(isDark, isArabic, isPremium),
            const SizedBox(height: 26),

            // ==========================================
            // القسم الثاني: الاختبارات التخصصية والفرعية
            // ==========================================
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 8),
                Text(
                  'الاختبارات التخصصية والفرعية',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt_rounded, size: 14, color: Color(0xFF22C55E)),
                      SizedBox(width: 4),
                      Text(
                        'تعمل أوفلاين',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSpecializedExamsList(isDark, isPremium),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ودجت الهيدر
  // ==========================================
  Widget _buildSubjectHeaderBanner(bool isDark) {
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
            child: Icon(widget.subjectIcon, color: Colors.white, size: 36),
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
                  'اختبارات تحاكي النمط الوزاري المعتمد للاختبار الوطني للقبول الجامعي والدراسات العليا.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
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

  // ==========================================
  // ودجت كرت الامتحان العام
  // ==========================================
  Widget _buildGeneralExamCard(bool isDark, bool isArabic, bool isPremium) {
    final cardBg = isDark ? const Color(0xFF131C31) : Colors.white;
    final bool isLocked = !isPremium && (!isArabic || (isArabic && _hasTakenFreeArabic));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? const Color(0xFF22C55E).withOpacity(0.35)
              : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
          width: isPremium ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _onGeneralExamTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.subjectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.school_rounded, color: widget.subjectColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'الامتحان العام',
                                style: GoogleFonts.notoKufiArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'VIP مفعّل 👑',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                )
                              else if (isArabic && !_hasTakenFreeArabic)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'تجربة مجانية 🎁',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'مخصص للمشتركين 🔒',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الاختبار الشامل للبنك الرئيسي (1000 سؤال كامل) مع إمكانية تحديد عدد الأسئلة وتفعيل نمط المراجعة الفورية والتفسير بالذكاء الاصطناعي.',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeatureTag(Icons.format_list_numbered_rounded, 'اختيار 20-100 سؤال'),
                    const SizedBox(width: 8),
                    _buildFeatureTag(Icons.timer_outlined, 'مؤقت ذكي'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLocked
                              ? [const Color(0xFF64748B), const Color(0xFF475569)]
                              : [widget.subjectColor, widget.subjectColor.withOpacity(0.85)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isLocked ? 'اشترك للبدء' : 'ابدأ الامتحان',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
  }

  Widget _buildFeatureTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==========================================
  // ودجت قائمة الاختبارات التخصصية
  // ==========================================
  Widget _buildSpecializedExamsList(bool isDark, bool isPremium) {
    return StreamBuilder<List<SpecializedExamModel>>(
      stream: _examService.streamExamsForSubject(widget.subjectKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return FutureBuilder<List<SpecializedExamModel>>(
            future: _examService.getOfflineExamsForSubject(widget.subjectKey),
            builder: (ctx, offlineSnap) {
              if (offlineSnap.hasData && offlineSnap.data!.isNotEmpty) {
                return _renderExamsList(offlineSnap.data!, isDark, isPremium);
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          );
        }

        final exams = snapshot.data ?? [];
        if (exams.isEmpty) {
          // فحص النسخة الأوفلاين إن وجدت
          return FutureBuilder<List<SpecializedExamModel>>(
            future: _examService.getOfflineExamsForSubject(widget.subjectKey),
            builder: (ctx, offlineSnap) {
              final offlineList = offlineSnap.data ?? [];
              if (offlineList.isNotEmpty) {
                return _renderExamsList(offlineList, isDark, isPremium);
              }
              return _buildEmptySpecializedState(isDark);
            },
          );
        }

        return _renderExamsList(exams, isDark, isPremium);
      },
    );
  }

  Widget _renderExamsList(List<SpecializedExamModel> exams, bool isDark, bool isPremium) {
    return Column(
      children: exams.map((exam) => _buildSpecializedExamCard(exam, isDark, isPremium)).toList(),
    );
  }

  Widget _buildSpecializedExamCard(SpecializedExamModel exam, bool isDark, bool isPremium) {
    final cardBg = isDark ? const Color(0xFF131C31) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _startSpecializedExam(exam),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exam.title,
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (!isPremium)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_rounded, size: 14, color: Colors.redAccent),
                                ),
                            ],
                          ),
                          if (exam.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              exam.description,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildBadge('${exam.questionsCount} سؤال', Icons.quiz_outlined, Colors.blue),
                    const SizedBox(width: 6),
                    _buildBadge('${exam.durationMinutes} دقيقة', Icons.schedule_rounded, Colors.purple),
                    const SizedBox(width: 6),
                    _buildBadge('أوفلاين ⚡', Icons.offline_bolt_rounded, const Color(0xFF22C55E)),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySpecializedState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_clear_rounded, size: 40, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            'لا توجد اختبارات فرعية مضافة حالياً',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'سيقوم الكادر التدريسي بإضافة اختبارات فرعية وتخصصية جديدة قريباً ✨',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
