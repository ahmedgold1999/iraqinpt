import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/question_model.dart';
import '../../services/question_service.dart';
import '../../services/tts_service.dart';
import '../../services/mistake_vault_service.dart';
import '../../services/ai_explainer_service.dart';
import '../../services/sound_effects_service.dart';
import '../../services/subscription_service.dart';
import '../../services/config_service.dart';
import '../../widgets/luxury_score_certificate.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

// ==================== نموذج نتيجة الاختبار للتخزين المحلي ====================
class LocalQuizResult {
  final String id;
  final String subjectName;
  final String subjectKey;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double scorePercentage;
  final DateTime date;
  final int durationInSeconds;
  final List<Map<String, dynamic>> wrongQuestions;

  LocalQuizResult({
    required this.id,
    required this.subjectName,
    required this.subjectKey,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.scorePercentage,
    required this.date,
    required this.durationInSeconds,
    required this.wrongQuestions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectName': subjectName,
    'subjectKey': subjectKey,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'scorePercentage': scorePercentage,
    'date': date.toIso8601String(),
    'durationInSeconds': durationInSeconds,
    'wrongQuestions': wrongQuestions,
  };

  factory LocalQuizResult.fromJson(Map<String, dynamic> json) =>
      LocalQuizResult(
        id: json['id'],
        subjectName: json['subjectName'],
        subjectKey: json['subjectKey'],
        totalQuestions: json['totalQuestions'],
        correctAnswers: json['correctAnswers'],
        wrongAnswers: json['wrongAnswers'],
        scorePercentage: json['scorePercentage'],
        date: DateTime.parse(json['date']),
        durationInSeconds: json['durationInSeconds'],
        wrongQuestions: List<Map<String, dynamic>>.from(json['wrongQuestions']),
      );
}

// دالة حفظ النتيجة محلياً
Future<void> saveQuizResult(LocalQuizResult result) async {
  final prefs = await SharedPreferences.getInstance();
  final String key = 'saved_quiz_results';
  List<String> resultsList = prefs.getStringList(key) ?? [];
  resultsList.add(jsonEncode(result.toJson()));
  await prefs.setStringList(key, resultsList);
}

/// ==================== Helpers / Theme ====================
class _QuizUI {
  static const String font = 'Tajawal';

  static const double radiusXL = 28;
  static const double radiusL = 20;
  static const double radiusM = 16;

  static TextStyle h1(Color c) => TextStyle(
    fontFamily: font,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: c,
  );

  static const TextStyle title = TextStyle(
    fontFamily: font,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: 16,
    height: 1.5,
  );

  static BoxShadow softShadow(Color c) => BoxShadow(
    color: c.withOpacity(0.18),
    blurRadius: 22,
    spreadRadius: 2,
    offset: const Offset(0, 12),
  );

  static EdgeInsets pagePadding = const EdgeInsets.all(18);

  static LinearGradient fancyGradient(Color base) => LinearGradient(
    colors: [
      base,
      base.withOpacity(.88),
      base.withOpacity(.72),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}

/// ==================== شاشة النتائج ====================
class QuizResultsScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final List<Question> questions;
  final Map<int, int> userAnswers;
  final String subject;
  final String subjectKey;
  final int durationInSeconds;
  final int maxStreak;

  const QuizResultsScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.questions,
    required this.userAnswers,
    required this.subject,
    required this.subjectKey,
    required this.durationInSeconds,
    this.maxStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    _saveResultToLocal(
      questions: questions,
      userAnswers: userAnswers,
      subject: subject,
      subjectKey: subjectKey,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      scorePercentage: scorePercentage,
      durationInSeconds: durationInSeconds,
    );

    final bool isPassed = scorePercentage >= 50;
    final Color main = isPassed ? Colors.green : Colors.red;
    final Color bg = main.withOpacity(.06);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ResultsHeader(
              subject: subject,
              isPassed: isPassed,
              mainColor: main,
              scorePercentage: scorePercentage,
            ),
          ),
          SliverPadding(
            padding: _QuizUI.pagePadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _ResultsStatsCard(
                    mainColor: main,
                    totalQuestions: totalQuestions,
                    correctAnswers: correctAnswers,
                    scorePercentage: scorePercentage,
                    durationInSeconds: durationInSeconds,
                    maxStreak: maxStreak,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFACC15).withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          final name = user?.displayName != null && user!.displayName!.isNotEmpty
                              ? user.displayName!
                              : (user?.email?.split('@').first ?? 'طالب متميز');
                          showDialog(
                            context: context,
                            builder: (_) => LuxuryScoreCertificateDialog(
                              studentName: name,
                              subject: subject,
                              scorePercentage: scorePercentage,
                              correctAnswers: correctAnswers,
                              totalQuestions: totalQuestions,
                              durationInSeconds: durationInSeconds,
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: Color(0xFFFACC15), size: 22),
                              SizedBox(width: 8),
                              Text(
                                'مشاركة بطاقة النتيجة الفخمة 📸',
                                style: TextStyle(
                                  fontFamily: _QuizUI.font,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFACC15),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ResultsActions(
                    mainColor: main,
                    isPassed: isPassed,
                    questions: questions, // ✅ أضف هذا السطر
                    userAnswers: userAnswers, // ✅ أضف هذا السطر
                    onRetry: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            subject: subject,
                            subjectKey: subjectKey,
                            questionsUrl: "",
                            questionsCount: totalQuestions,
                          ),
                        ),
                            (route) => false,
                      );
                    },
                    onWrongAnswers: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WrongAnswersScreen(
                            questions: questions,
                            userAnswers: userAnswers,
                            subjectKey: subjectKey,
                          ),
                        ),
                      );
                    },
                    onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _saveResultToLocal({
  required List<Question> questions,
  required Map<int, int> userAnswers,
  required String subject,
  required String subjectKey,
  required int totalQuestions,
  required int correctAnswers,
  required double scorePercentage,
  required int durationInSeconds,
}) async {
  final List<Map<String, dynamic>> questionsHistory = [];

  for (int i = 0; i < questions.length; i++) {
    final int? ansIndex = userAnswers[i];
    final String correct = questions[i].originalAnswer;
    final String? explanation = questions[i].explanation; // ⭐ أضف هذا

    String userSelected = 'لم يتم اختيار إجابة';
    bool isCorrect = false;

    if (ansIndex != null) {
      userSelected = questions[i].options[ansIndex];
      isCorrect = userSelected.trim() == correct.trim();
    }

    if (!isCorrect) {
      MistakeVaultService.saveMistake(
        question: questions[i],
        subjectKey: subjectKey,
        subjectName: subject,
        selectedWrongAnswer: userSelected,
      );
    } else {
      MistakeVaultService.removeMistake(questions[i].question);
    }

    // نحفظ كل سؤال سواء كان صح أو خطأ مع التفسير
    questionsHistory.add({
      'question': questions[i].question,
      'userAnswer': userSelected,
      'correctAnswer': correct,
      'isCorrect': isCorrect,
      'questionIndex': i + 1,
      'explanation': explanation, // ⭐ أضف حقل التفسير
    });
  }

  final result = LocalQuizResult(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    subjectName: subject,
    subjectKey: subjectKey,
    totalQuestions: totalQuestions,
    correctAnswers: correctAnswers,
    wrongAnswers: totalQuestions - correctAnswers,
    scorePercentage: scorePercentage,
    date: DateTime.now(),
    durationInSeconds: durationInSeconds,
    wrongQuestions: questionsHistory,
  );

  await saveQuizResult(result);
}

class _ResultsHeader extends StatelessWidget {
  final String subject;
  final bool isPassed;
  final Color mainColor;
  final double scorePercentage;

  const _ResultsHeader({
    required this.subject,
    required this.isPassed,
    required this.mainColor,
    required this.scorePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = isPassed
        ? Icons.workspace_premium_rounded
        : Icons.sentiment_dissatisfied_rounded;
    final title = isPassed ? 'مبروك! لقد نجحت في الاختبار' : 'لم تتجاوز الاختبار هذه المرة';
    final accentColor = isPassed ? const Color(0xFF00C853) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 50, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subject,
            style: TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 15,
              color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Text(
              'النتيجة النهائية: ${scorePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: _QuizUI.font,
                fontSize: 16,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsActions extends StatelessWidget {
  final Color mainColor;
  final bool isPassed;
  final VoidCallback onRetry;
  final VoidCallback onWrongAnswers;
  final VoidCallback onHome;
  final List<Question> questions; // ✅ جديد
  final Map<int, int> userAnswers; // ✅ جديد

  const _ResultsActions({
    required this.mainColor,
    required this.isPassed,
    required this.onRetry,
    required this.onWrongAnswers,
    required this.onHome,
    required this.questions, // ✅ جديد
    required this.userAnswers, // ✅ جديد
  });

  Future<void> _showRatingDialogOnce(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    const String key = 'has_been_asked_to_rate';

    bool hasBeenAsked = prefs.getBool(key) ?? false;

    if (!hasBeenAsked) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFACC15), Color(0xFFFB7185)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.star_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'قيم التطبيق',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFACC15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'نحن نقدّر وجودك معنا 🤍\nإذا وجدت في تطبيقنا ما يستحق التقدير،\nتشرفنا بدعمك بتقييم 5 نجوم على المتجر',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        height: 1.6,
                      ),
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
                            onPressed: () async {
                              await prefs.setBool(key, true);
                              Navigator.pop(context);
                              onHome();
                            },
                            child: const Text(
                              'لاحقاً',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white70,
                              ),
                            ),
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
                            onPressed: () async {
                              await prefs.setBool(key, true);
                              final url = (!kIsWeb && Platform.isIOS)
                                  ? Uri.parse(
                                      'https://apps.apple.com/app/id6742571778')
                                  : Uri.parse(
                                      'https://play.google.com/store/apps/details?id=com.inpt.ahmeed.iraqinpt');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                              Navigator.pop(context);
                              onHome();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 20, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'تقييم 5 نجوم',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
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
    } else {
      onHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخراج قائمة الأسئلة التي أخطأ بها الطالب
    final List<Question> wrongQuestionsList = [];
    for (int i = 0; i < questions.length; i++) {
      final int? ans = userAnswers[i];
      final q = questions[i];
      if (ans == null || q.options[ans].trim() != q.originalAnswer.trim()) {
        wrongQuestionsList.add(q);
      }
    }

    return Column(
      children: [
        if (wrongQuestionsList.isNotEmpty) ...[
          _FancyButton(
            color: const Color(0xFFEA580C),
            icon: Icons.track_changes_rounded,
            text: '🎯 إعادة تدريب الأسئلة الخاطئة فقط (${wrongQuestionsList.length})',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    subject: 'إعادة الأخطاء والتدريب',
                    questionsUrl: '',
                    initialQuestions: wrongQuestionsList,
                    questionsCount: wrongQuestionsList.length,
                    showAnswersDuringExam: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        _FancyButton(
          color: mainColor,
          icon: Icons.refresh_rounded,
          text: 'إعادة الاختبار كاملاً',
          onTap: onRetry,
        ),
        const SizedBox(height: 12),
        _FancyButton(
          color: Colors.orange,
          icon: Icons.error_outline_rounded,
          text: 'عرض الإجابات الخاطئة وتفسيرها',
          onTap: onWrongAnswers,
        ),
        const SizedBox(height: 12),
        _FancyButton(
          color: Colors.blue,
          icon: Icons.quiz_rounded,
          text: 'عرض ومراجعة كافة الأسئلة',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllQuestionsScreen(
                  questions: questions,
                  userAnswers: userAnswers,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _FancyButton(
          color: Colors.grey.shade800,
          icon: Icons.home_rounded,
          text: 'العودة للرئيسية',
          onTap: () => _showRatingDialogOnce(context),
        ),
      ],
    );
  }
}

class _ResultsStatsCard extends StatelessWidget {
  final Color mainColor;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final int durationInSeconds;
  final int maxStreak;

  const _ResultsStatsCard({
    required this.mainColor,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    this.durationInSeconds = 0,
    this.maxStreak = 0,
  });

  String _getDiagnosisText() {
    if (scorePercentage >= 90) {
      return 'أداء أسطوري استثنائي! 👑 أنت جاهز تماماً للاختبار الوزاري والدرجات العليا.';
    } else if (scorePercentage >= 75) {
      return 'أداء ممتاز ومتقدم جداً! 🌟 لمسات تدريبية بسيطة وتصل للدرجة الكاملة.';
    } else if (scorePercentage >= 50) {
      return 'مستوى جيد وناجح! ✨ أعد تدريب الأسئلة الخاطئة لترفع نتيجتك لأعلى درجة.';
    } else {
      return 'فرصة رائعة للتعلم والتفوق! 💡 ننصح بإعادة تدريب الأخطاء ومراجعة الشرح.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wrong = totalQuestions - correctAnswers;
    final double avgSeconds = durationInSeconds > 0 && totalQuestions > 0
        ? (durationInSeconds / totalQuestions)
        : 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL),
          gradient: LinearGradient(
            colors: [
              mainColor.withOpacity(.10),
              isDark ? const Color(0xFF1E293B) : Colors.white,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(.06)),
          boxShadow: [_QuizUI.softShadow(Colors.black)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _RingPercent(
                  value: scorePercentage / 100,
                  color: mainColor,
                  label: '${scorePercentage.toStringAsFixed(1)}%',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تقرير الأداء والتشخيص الذكي 📊',
                        style: _QuizUI.title.copyWith(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getDiagnosisText(),
                        style: _QuizUI.body.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Basic Numbers
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    title: 'الصحيحة',
                    value: '$correctAnswers',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    title: 'الخاطئة',
                    value: '$wrong',
                    icon: Icons.cancel_rounded,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    title: 'المجموع',
                    value: '$totalQuestions',
                    icon: Icons.quiz_rounded,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Advanced Analytics (Speed & Streak)
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    title: 'متوسط السرعة',
                    value: '${avgSeconds.toStringAsFixed(1)} ث/سؤال',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    title: 'أعلى تتابع',
                    value: '$maxStreak 🔥',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPercent extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _RingPercent({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: 10,
            backgroundColor: Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: _QuizUI.font,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(_QuizUI.radiusL),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ==================== شاشة عرض كل الأسئلة (صحيحة وخاطئة) ====================
class AllQuestionsScreen extends StatefulWidget {
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const AllQuestionsScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<AllQuestionsScreen> createState() => _AllQuestionsScreenState();
}

class _AllQuestionsScreenState extends State<AllQuestionsScreen> {
  double _fontSize = 16.0; // حجم الخط الافتراضي
  final double _minFontSize = 12.0;
  final double _maxFontSize = 24.0;

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < _maxFontSize) {
        _fontSize += 2.0;
      }
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > _minFontSize) {
        _fontSize -= 2.0;
      }
    });
  }

  void _resetFontSize() {
    setState(() {
      _fontSize = 16.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // تجميع كل الأسئلة مع نتائجها
    final List<Map<String, dynamic>> allItems = [];

    for (int i = 0; i < widget.questions.length; i++) {
      final ansIndex = widget.userAnswers[i];
      final isAnswered = ansIndex != null;
      final selected = isAnswered ? widget.questions[i].options[ansIndex] : 'لم يجب';
      final isCorrect =
          isAnswered && selected.trim() == widget.questions[i].originalAnswer.trim();
      final explanation = widget.questions[i].explanation; // ⭐ جلب التفسير

      allItems.add({
        'index': i + 1,
        'question': widget.questions[i].question,
        'userAnswer': selected,
        'correctAnswer': widget.questions[i].originalAnswer,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'explanation': explanation, // ⭐ إضافة التفسير
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('جميع الأسئلة والنتائج',
            style: TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _decreaseFontSize,
                  icon: const Icon(Icons.zoom_out, size: 18),
                  tooltip: 'تصغير الخط',
                  color: Colors.white,
                ),
                Text(
                  '${_fontSize.round()}',
                  style: const TextStyle(
                    fontFamily: _QuizUI.font,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _increaseFontSize,
                  icon: const Icon(Icons.zoom_in, size: 18),
                  tooltip: 'تكبير الخط',
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: allItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = allItems[index];
          final bool isCorrect = item['isCorrect'] as bool;
          final bool isAnswered = item['isAnswered'] as bool;
          final Color borderColor = isCorrect
              ? Colors.green
              : (isAnswered ? Colors.red : Colors.orange);
          final String? explanation = item['explanation'];

          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor.withOpacity(0.4), width: 1.5),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس البطاقة
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : (isAnswered
                                  ? Icons.cancel
                                  : Icons.help_outline),
                              color: borderColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'السؤال ${item['index']}',
                              style: TextStyle(
                                fontFamily: _QuizUI.font,
                                fontWeight: FontWeight.w900,
                                color: borderColor,
                                fontSize: _fontSize * 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!isAnswered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'لم يجب',
                            style: TextStyle(
                              fontFamily: _QuizUI.font,
                              fontSize: _fontSize * 0.7,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ⭐ نص السؤال (حجمه يتغير)
                  Text(
                    item['question'],
                    style: TextStyle(
                      fontFamily: _QuizUI.font,
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // حاوية الإجابات
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? (isDark ? const Color(0xFF064E3B).withOpacity(0.3) : Colors.green.withOpacity(0.08))
                          : (isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : Colors.red.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // إجابة المستخدم
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: _fontSize,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'إجابتك: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: item['userAnswer']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // الإجابة الصحيحة
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_rounded,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF22C55E),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'الإجابة الصحيحة: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: item['correctAnswer']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ⭐ إضافة التفسير (إذا كان موجوداً)
                  if (explanation != null && explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: const Color(0xFF38BDF8), size: _fontSize),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تعليل / ملاحظة:',
                                  style: TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: _fontSize - 2,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  explanation,
                                  style: TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: _fontSize - 2,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF93C5FD) : Colors.blue.shade800,
                                    height: 1.5,
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
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FancyButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _FancyButton({
    required this.color,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_QuizUI.radiusL),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: _QuizUI.font,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// ==================== شاشة الإجابات الخاطئة ====================
class WrongAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final Map<int, int> userAnswers;
  final String? subjectKey;

  const WrongAnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    this.subjectKey,
  });

  bool get _isLtr {
    final key = (subjectKey ?? '').trim().toLowerCase();
    if (key == 'english' || key == 'computer') return true;
    if (key == 'arabic') return false;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wrongItems = <_WrongItem>[];

    for (int i = 0; i < questions.length; i++) {
      final ansIndex = userAnswers[i];
      if (ansIndex == null) continue;

      final selected = questions[i].options[ansIndex];
      if (selected.trim() != questions[i].originalAnswer.trim()) {
        wrongItems.add(_WrongItem(
            index: i, question: questions[i], userAnswerIndex: ansIndex));
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('الإجابات الخاطئة والمراجعة',
            style: TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: wrongItems.isEmpty
          ? const Center(
              child: Text(
                'ممتاز! لا توجد أية إجابات خاطئة 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: _QuizUI.font,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: wrongItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _WrongCard(
                item: wrongItems[i],
                isLtr: subjectKey != null && (subjectKey == 'english' || subjectKey == 'computer' || subjectKey == 'arabic')
                    ? _isLtr
                    : null,
              ),
            ),
    );
  }
}

class _WrongItem {
  final int index;
  final Question question;
  final int userAnswerIndex;

  _WrongItem({
    required this.index,
    required this.question,
    required this.userAnswerIndex,
  });
}

class _WrongCard extends StatelessWidget {
  final _WrongItem item;
  final bool? isLtr;

  const _WrongCard({required this.item, this.isLtr});

  static bool _detectLtr(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (!hasArabic && RegExp(r'[a-zA-Z]').hasMatch(text)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = item.question;
    final ltr = isLtr ?? _detectLtr(q.question);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(.06)),
          boxShadow: [_QuizUI.softShadow(Colors.black)],
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(.16)),
                  ),
                  child: Text(
                    'السؤال ${item.index + 1}',
                    style: const TextStyle(
                      fontFamily: _QuizUI.font,
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  q.question,
                  textAlign: ltr ? TextAlign.left : TextAlign.right,
                  style: _QuizUI.title.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _AnswerBox(
              label: 'اختيارك:',
              answer: q.options[item.userAnswerIndex],
              color: Colors.red,
              isLtr: ltr,
            ),
            const SizedBox(height: 12),
            _AnswerBox(
              label: 'الإجابة الصحيحة:',
              answer: q.originalAnswer,
              color: Colors.green,
              isLtr: ltr,
            ),
            // ⭐ إضافة التفسير إذا كان موجوداً
            if (q.explanation != null && q.explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExplanationBox(
                explanation: q.explanation!,
                isLtr: ltr,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ⭐ إضافة كلاس جديد لعرض التفسير
class _ExplanationBox extends StatelessWidget {
  final String explanation;
  final bool isLtr;

  const _ExplanationBox({required this.explanation, this.isLtr = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : Colors.blue.withOpacity(.05),
        borderRadius: BorderRadius.circular(_QuizUI.radiusL),
        border: Border.all(color: Colors.blue.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                'ملاحظة / تعليل:',
                style: TextStyle(
                  fontFamily: _QuizUI.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                explanation,
                textAlign: isLtr ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontFamily: isLtr ? null : _QuizUI.font,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  final String label;
  final String answer;
  final Color color;
  final bool isLtr;

  const _AnswerBox({
    required this.label,
    required this.answer,
    required this.color,
    this.isLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _QuizUI.font,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(.05),
            borderRadius: BorderRadius.circular(_QuizUI.radiusL),
            border: Border.all(color: color.withOpacity(.25)),
          ),
          child: Text(
            answer,
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            textAlign: isLtr ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontFamily: isLtr ? null : _QuizUI.font,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// ==================== شاشة الاختبار الرئيسية ====================
class QuizScreen extends StatefulWidget {
  final String subject;
  final String? subjectKey; // ⭐ مفتاح المادة لتحديد اتجاه النص وخصائص المادة
  final String questionsUrl;
  final int questionsCount;
  final bool showAnswersDuringExam; // ⭐ أضف هذا
  final List<Question>? initialQuestions;
  final bool updateLeaderboard; // ⭐ إضافة هذا
  // ✅ علامة التجربة المجانية لتثبيت الأسئلة ومنع التحايل
  final bool isFreeArabicTrial;

  const QuizScreen({
    super.key,
    required this.subject,
    this.subjectKey,
    required this.questionsUrl,
    this.questionsCount = 100,
    this.showAnswersDuringExam = false, // ⭐ افتراضي false
    this.initialQuestions,
    this.updateLeaderboard = true, // ⭐ افتراضي true
    this.isFreeArabicTrial = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}


class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _timeLeft = 40;
  int _totalTimeLeft = 0;
  final Map<int, int> _userAnswers = {};
  List<Question> _randomQuestions = [];
  bool _isLoading = true;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ⭐ أدوات الراحة والتركيز (الخط والمفضلة)
  double _fontSize = 18.0;
  Set<String> _bookmarkedQuestions = {};

  // 🔥 نظام الحماس والتتابع (Combo Streak)
  int _streak = 0;
  int _maxStreak = 0;

  // ⭐ المتغيرات الجديدة
  bool _showFeedback = false;
  Timer? _feedbackTimer;

  // 🌐 تحديد اتجاه النص (يسار لليمين للحاسوب والإنكليزي، يمين لليسار للعربي)
  bool get _isCurrentQuestionLtr {
    // 1. فحص مفتاح المادة المباشر
    final key = (widget.subjectKey ?? '').trim().toLowerCase();
    if (key == 'english' || key == 'computer') return true;
    if (key == 'arabic') return false;

    // 2. فحص اسم المادة
    final sub = widget.subject.toLowerCase();
    if (sub.contains('إنجليز') || sub.contains('انجليز') || sub.contains('english')) return true;
    if (sub.contains('حاسوب') || sub.contains('computer')) return true;
    if (sub.contains('عرب') || sub.contains('arabic')) return false;

    // 3. فحص نص السؤال الحالي في الاختبارات العامة أو المراجعة الذكية
    if (_randomQuestions.isNotEmpty && _currentQuestionIndex < _randomQuestions.length) {
      final qText = _randomQuestions[_currentQuestionIndex].question.trim();
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(qText);
      if (!hasArabic && RegExp(r'[a-zA-Z]').hasMatch(qText)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    // 🔒 منع التقاط لقطات الشاشة أو تسجيل الفيديو أثناء الاختبار للحفاظ على سرية الأسئلة
    _enableSecureScreen();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _loadStudentPreferences();
    // ✅ التحقق من الاشتراك قبل تحميل الأسئلة (حماية مضاعفة لمادة الحاسوب والإنكليزي)
    _checkAccessAndLoadQuestions();
  }

  Future<void> _enableSecureScreen() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (_) {}
  }

  Future<void> _disableSecureScreen() async {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android)) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (_) {}
  }

  /// ✅ حماية مضاعفة: يتحقق من Firestore مباشرة قبل تحميل أسئلة الحاسوب والإنكليزي
  Future<void> _checkAccessAndLoadQuestions() async {
    final isProtectedSubject = widget.subject.contains('حاسوب') ||
        widget.subject.contains('Computer') ||
        widget.subject.contains('computer') ||
        widget.subject.contains('إنكليزي') ||
        widget.subject.contains('English') ||
        widget.subject.contains('english');

    if (isProtectedSubject) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          // غير مسجّل → أخرج فوراً
          if (mounted) Navigator.of(context).pop();
          return;
        }
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        final bool isPremium = data?['isPremium'] == true;
        final expiryRaw = data?['expiryDate'] ?? data?['premiumUntil'];
        bool isValid = isPremium;
        if (isPremium && expiryRaw != null) {
          DateTime? expiry;
          if (expiryRaw is Timestamp) expiry = expiryRaw.toDate();
          if (expiryRaw is String) expiry = DateTime.tryParse(expiryRaw);
          if (expiry != null && expiry.isBefore(DateTime.now())) {
            isValid = false; // انتهت صلاحية الاشتراك
          }
        }
        if (!isValid) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ConfigService().isReviewMode
                      ? 'هذه المادة فقط للطلاب المخصصين لها'
                      : '⛔ هذه المادة مخصصة للمشتركين فقط. يرجى الاشتراك في باقة VIP.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFFDC2626),
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } catch (e) {
        // إذا فشل الاتصال بـ Firestore، نمنع الوصول احتياطاً
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
    _loadQuestions();
  }


  Future<void> _loadStudentPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSize = prefs.getDouble('student_quiz_font_size');
      final savedBookmarks = prefs.getStringList('bookmarked_questions_set');
      if (mounted) {
        setState(() {
          if (savedSize != null) _fontSize = savedSize;
          if (savedBookmarks != null) _bookmarkedQuestions = savedBookmarks.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _updateFontSize(double newSize) async {
    final clamped = newSize.clamp(14.0, 28.0);
    setState(() => _fontSize = clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('student_quiz_font_size', clamped);
  }

  Future<void> _toggleBookmark(Question q) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedQuestions.contains(q.question);

    setState(() {
      if (isBookmarked) {
        _bookmarkedQuestions.remove(q.question);
      } else {
        _bookmarkedQuestions.add(q.question);
      }
    });

    await prefs.setStringList('bookmarked_questions_set', _bookmarkedQuestions.toList());

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBookmarked ? 'تمت إزالة السؤال من المفضلة' : 'تم حفظ السؤال في المفضلة ⭐',
            style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: isBookmarked ? Colors.grey.shade800 : const Color(0xFFD97706),
        ),
      );
    }
  }

  void _triggerStreakCelebration(int streakCount) {
    String message = '🔥 3 إجابات صحيحة متتالية! ممتاز!';
    if (streakCount == 5) message = '⚡ 5 إجابات متتالية! أداء خرافي!';
    if (streakCount == 10) message = '👑 10 إجابات متتالية أسطورية! أنت بطل حقيقي!';
    if (streakCount > 10) message = '🔥 تتابع لا يُقهر: $streakCount إجابة متتالية!';

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEA580C),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ⭐ دالة عرض التغذية الراجعة
  void _showAnswerFeedback() {
    if (mounted && !_showFeedback) {
      setState(() {
        _showFeedback = true;
      });
    }
  }

  // ====== تأكيد الخروج من الامتحان ======
  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تنبيه!',
                    style: TextStyle(
                      fontFamily: _QuizUI.font,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هل أنت متأكد من مغادرة الامتحان؟',
                    style: TextStyle(
                      fontFamily: _QuizUI.font,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لن يتم حفظ تقدمك الحالي',
                    style: TextStyle(
                      fontFamily: _QuizUI.font,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.18),
                                width: 1.2),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontFamily: _QuizUI.font,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'مغادرة',
                            style: TextStyle(
                              fontFamily: _QuizUI.font,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
      ),
    ) ??
        false;
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> questions = [];
      if (widget.initialQuestions != null && widget.initialQuestions!.isNotEmpty) {
        questions = List.from(widget.initialQuestions!);
      } else {
        questions = await QuestionService.loadQuestions(widget.questionsUrl);
      }

      // ✅ التجربة المجانية: seed ثابت دائماً (نفس الأسئلة لكل الحسابات، لا يمكن التحايل)
      // الاختبارات العادية: عشوائية لكل جلسة
      if (widget.isFreeArabicTrial) {
        // Seed ثابت = أسئلة ثابتة دائماً بغض النظر عن الحساب أو الجهاز أو مسح البيانات
        final random = Random(20260101);
        questions.shuffle(random);
      } else {
        final random = Random();
        questions.shuffle(random);
      }

      final selected = questions.take(widget.questionsCount).toList();

      if (!mounted) return;
      setState(() {
        _randomQuestions = selected;
        _isLoading = false;
        _timeLeft = 40;
        _totalTimeLeft = _randomQuestions.length * 40;
        _currentQuestionIndex = 0;
        _userAnswers.clear();
      });

      _startTimer();
    } catch (_) {

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل الأسئلة.')),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        _totalTimeLeft--;
        if (_timeLeft <= 0) _goNextQuestionAutomatically();
      });
    });
  }

  void _goNextQuestionAutomatically() {
    if (_currentQuestionIndex < _randomQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _timeLeft = 40;
      });
    } else {
      _finishQuiz();
    }
  }

  void _nextQuestionOrFinish() {
    if (_userAnswers[_currentQuestionIndex] == null) {
      _shakeController.forward(from: 0);
      return;
    }

    if (_currentQuestionIndex < _randomQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _timeLeft = 40;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    _timer?.cancel();

    int correctAnswers = 0;
    final List<Map<String, dynamic>> wrongQuestionsData = [];

    for (int i = 0; i < _randomQuestions.length; i++) {
      final ansIndex = _userAnswers[i];
      final String correct = _randomQuestions[i].originalAnswer;
      String userSelected = 'لم يتم اختيار إجابة';
      bool isCorrect = false;

      if (ansIndex != null) {
        userSelected = _randomQuestions[i].options[ansIndex];
        isCorrect = userSelected.trim() == correct.trim();
      }

      if (isCorrect) {
        correctAnswers++;
      }

      // إضافة السؤال لقائمة المراجعة
      wrongQuestionsData.add({
        'question': _randomQuestions[i].question,
        'userAnswer': userSelected,
        'correctAnswer': correct,
        'isCorrect': isCorrect,
        'explanation': _randomQuestions[i].explanation,
      });
    }

    final scorePercentage = (correctAnswers / _randomQuestions.length) * 100;
    final int totalTimeAllowed = _randomQuestions.length * 40;
    final int durationUsed = totalTimeAllowed - _totalTimeLeft;

    // ✅ حفظ النتيجة
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userName = user.displayName ?? '';
      try {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (uDoc.exists) {
          final dName = uDoc.data()?['name'] ?? uDoc.data()?['displayName'];
          if (dName != null && dName.toString().trim().isNotEmpty) {
            userName = dName.toString().trim();
          }
        }
      } catch (_) {}
      if (userName.isEmpty) {
        userName = user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName!
            : (user.email?.split('@').first ?? 'طالب متميز');
      }

      await QuestionService.saveQuizResult(
        userId: user.uid,
        userName: userName,
        subjectKey: _getSubjectKey(widget.subject),
        subjectName: widget.subject,
        scorePercentage: scorePercentage,
        correctAnswers: correctAnswers,
        wrongAnswers: _randomQuestions.length - correctAnswers,
        totalQuestions: _randomQuestions.length,
        durationInSeconds: durationUsed,
        wrongQuestions: wrongQuestionsData,
        updateLeaderboard: widget.updateLeaderboard,
      );
    }

    // ✅ إذا كان الاختبار تجربة مجانية، نسجّل الاستهلاك في Firestore (مرتبط بالحساب لا بالجهاز)
    if (widget.isFreeArabicTrial) {
      final subService = SubscriptionService();
      await subService.markFreeArabicTrialUsed();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          totalQuestions: _randomQuestions.length,
          correctAnswers: correctAnswers,
          scorePercentage: scorePercentage,
          questions: _randomQuestions,
          userAnswers: _userAnswers,
          subject: widget.subject,
          subjectKey: _getSubjectKey(widget.subject),
          durationInSeconds: durationUsed,
          maxStreak: _maxStreak,
        ),
      ),
    );
  }

  String _getSubjectKey(String subject) {
    if (widget.subjectKey != null && widget.subjectKey!.isNotEmpty) {
      return widget.subjectKey!;
    }
    final s = subject.toLowerCase();
    if (s.contains('عرب') || s.contains('arab')) return 'arabic';
    if (s.contains('حاس') || s.contains('comp')) return 'computer';
    if (s.contains('إنج') || s.contains('انج') || s.contains('eng')) return 'english';
    return 'general';
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // إعادة السماح بلقطات الشاشة عند مغادرة شاشة الاختبار
    _disableSecureScreen();
    _timer?.cancel();
    _shakeController.dispose();
    TtsService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(widget.subject, style: const TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
      );
    }

    if (_randomQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(widget.subject, style: const TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'لا توجد أسئلة متوفرة حالياً أو ربما ليس لديك إنترنت',
            style: TextStyle(fontFamily: _QuizUI.font, fontSize: 16, color: Color(0xFF8E8E93)),
          ),
        ),
      );
    }

    final q = _randomQuestions[_currentQuestionIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(widget.subject, style: const TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                SoundEffectsService().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: 20,
                color: SoundEffectsService().isMuted ? Colors.white54 : const Color(0xFF38BDF8),
              ),
              onPressed: () {
                SoundEffectsService().toggleSound();
                setState(() {});
              },
              tooltip: SoundEffectsService().isMuted ? 'تفعيل المؤثرات الصوتية' : 'كتم المؤثرات الصوتية',
            ),
            IconButton(
              icon: const Icon(Icons.text_increase_rounded, size: 20),
              onPressed: () => _updateFontSize(_fontSize + 2),
              tooltip: 'تكبير الخط A+',
            ),
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded, size: 20),
              onPressed: () => _updateFontSize(_fontSize - 2),
              tooltip: 'تصغير الخط A-',
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFACC15)),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeLeft),
                    style: const TextStyle(
                      fontFamily: _QuizUI.font,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFACC15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            // شريط أرقام الأسئلة بنمط iOS
            SizedBox(
              height: 42,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _randomQuestions.length,
                itemBuilder: (context, index) {
                  final answered = _userAnswers.containsKey(index);
                  final current = index == _currentQuestionIndex;

                  final Color bg = current
                      ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A))
                      : answered
                      ? const Color(0xFF00C853)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E5EA));

                  final Color fg = current || answered ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF8E8E93));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: current ? 42 : 38,
                      height: current ? 42 : 38,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                        boxShadow: current
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: _QuizUI.font,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: fg,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _randomQuestions.length,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E5EA),
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = _shakeAnimation.value *
                      (_shakeController.status == AnimationStatus.forward ? 1 : -1);
                  return Transform.translate(offset: Offset(offset, 0), child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E5EA), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F2F7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'السؤال ${_currentQuestionIndex + 1} من ${_randomQuestions.length}',
                                      style: TextStyle(
                                        fontFamily: _QuizUI.font,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ),
                                  if (_streak >= 2) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEA580C).withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🔥', style: TextStyle(fontSize: 11)),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$_streak متتالية',
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      _bookmarkedQuestions.contains(q.question)
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: _bookmarkedQuestions.contains(q.question)
                                          ? const Color(0xFFF59E0B)
                                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                                      size: 22,
                                    ),
                                    onPressed: () => _toggleBookmark(q),
                                    tooltip: 'حفظ السؤال في المفضلة',
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => AiExplainerService.showExplanationModal(
                                      context,
                                      question: q,
                                      subject: widget.subject,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF6366F1)),
                                          SizedBox(width: 4),
                                          Text(
                                            'شرح ذكي',
                                            style: TextStyle(
                                              fontFamily: _QuizUI.font,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => TtsService().speak(q.question),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF0F172A).withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volume_up_rounded, size: 15, color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'استماع',
                                            style: TextStyle(
                                              fontFamily: _QuizUI.font,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
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
                          const SizedBox(height: 12),
                          Directionality(
                            textDirection: _isCurrentQuestionLtr ? TextDirection.ltr : TextDirection.rtl,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                q.question,
                                textAlign: _isCurrentQuestionLtr ? TextAlign.left : TextAlign.right,
                                style: TextStyle(
                                  fontFamily: _isCurrentQuestionLtr ? null : _QuizUI.font,
                                  fontWeight: FontWeight.bold,
                                  fontSize: _fontSize + 1,
                                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // الخيارات بنمط iOS (LTR للإنجليزي والحاسوب، RTL للعربي)
                          ...List.generate(q.options.length, (index) {
                            final option = q.options[index];
                            final isSelected = _userAnswers[_currentQuestionIndex] == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final bool isCorrect = option.trim() == q.originalAnswer.trim();
                                  setState(() {
                                    _userAnswers[_currentQuestionIndex] = index;
                                    if (isCorrect) {
                                      _streak++;
                                      if (_streak > _maxStreak) _maxStreak = _streak;
                                      SoundEffectsService().playCorrect();
                                      if (_streak == 3 || _streak == 5 || _streak == 10 || (_streak > 10 && _streak % 5 == 0)) {
                                        SoundEffectsService().playStreakFanfare();
                                        _triggerStreakCelebration(_streak);
                                      }
                                    } else {
                                      _streak = 0;
                                      SoundEffectsService().playWrong();
                                    }
                                    if (widget.showAnswersDuringExam) {
                                      _showAnswerFeedback();
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF064E3B).withOpacity(0.4) : const Color(0xFFF0FDF4))
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F2F7)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF00C853) : (isDark ? Colors.white10 : const Color(0xFFE5E5EA)),
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Directionality(
                                    textDirection: _isCurrentQuestionLtr ? TextDirection.ltr : TextDirection.rtl,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF00C853)
                                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _isCurrentQuestionLtr ? String.fromCharCode(65 + index) : '${index + 1}',
                                            style: TextStyle(
                                              fontFamily: _isCurrentQuestionLtr ? null : _QuizUI.font,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF1C1C1E)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option,
                                            textAlign: _isCurrentQuestionLtr ? TextAlign.left : TextAlign.right,
                                            style: TextStyle(
                                              fontFamily: _isCurrentQuestionLtr ? null : _QuizUI.font,
                                              fontSize: _fontSize,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 22),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 12),

                          if (widget.showAnswersDuringExam && _showFeedback && _userAnswers[_currentQuestionIndex] != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _userAnswers[_currentQuestionIndex] != null &&
                                    _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                        _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                    ? (isDark ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFFF0FDF4))
                                    : (isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEF2F2)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _userAnswers[_currentQuestionIndex] != null &&
                                      _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                          _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFEF4444),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _userAnswers[_currentQuestionIndex] != null &&
                                            _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                                _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        color: _userAnswers[_currentQuestionIndex] != null &&
                                            _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                                _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                            ? const Color(0xFF00C853)
                                            : const Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _userAnswers[_currentQuestionIndex] != null &&
                                            _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                                _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                            ? '✓ إجابة صحيحة'
                                            : '✗ إجابة خاطئة',
                                        style: TextStyle(
                                          fontFamily: _QuizUI.font,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _userAnswers[_currentQuestionIndex] != null &&
                                              _randomQuestions[_currentQuestionIndex].options[_userAnswers[_currentQuestionIndex]!].trim() ==
                                                  _randomQuestions[_currentQuestionIndex].originalAnswer.trim()
                                              ? const Color(0xFF00C853)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.verified_user_rounded, color: Color(0xFF00C853), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'الإجابة الصحيحة:',
                                                style: TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00C853),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _randomQuestions[_currentQuestionIndex].originalAnswer,
                                                textDirection: _isCurrentQuestionLtr ? TextDirection.ltr : TextDirection.rtl,
                                                textAlign: _isCurrentQuestionLtr ? TextAlign.left : TextAlign.right,
                                                style: TextStyle(
                                                  fontFamily: _isCurrentQuestionLtr ? null : 'Tajawal',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (_randomQuestions[_currentQuestionIndex].explanation != null &&
                                      _randomQuestions[_currentQuestionIndex].explanation!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? const Color(0xFF2563EB).withOpacity(0.3) : Colors.transparent),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'ملاحظة / تعليل:',
                                                  style: TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF38BDF8),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _randomQuestions[_currentQuestionIndex].explanation!,
                                                  textDirection: _isCurrentQuestionLtr ? TextDirection.ltr : TextDirection.rtl,
                                                  textAlign: _isCurrentQuestionLtr ? TextAlign.left : TextAlign.right,
                                                  style: TextStyle(
                                                    fontFamily: _isCurrentQuestionLtr ? null : 'Tajawal',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
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
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFFFCA5A5)),
                              ),
                              child: Text(
                                'الوقت الإجمالي المتبقي: ${_formatTime(_totalTimeLeft)}',
                                style: const TextStyle(
                                  fontFamily: _QuizUI.font,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Color(0xFFEF4444),
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
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _currentQuestionIndex > 0
                              ? () => setState(() {
                                    _currentQuestionIndex--;
                                    _timeLeft = 40;
                                  })
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E5EA),
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF1C1C1E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: _QuizUI.font,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('السابق'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _nextQuestionOrFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: _QuizUI.font,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(
                            _currentQuestionIndex < _randomQuestions.length - 1
                                ? 'التالي'
                                : 'إنهاء الاختبار',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
