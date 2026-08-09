import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/question_model.dart';
import '../../services/question_service.dart';

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
  final String subjectKey; // ✅ جديد
  final int durationInSeconds; // ✅ جديد

  const QuizResultsScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.questions,
    required this.userAnswers,
    required this.subject,
    required this.subjectKey, // ✅ جديد
    required this.durationInSeconds, // ✅ جديد
  });

  @override
  Widget build(BuildContext context) {
    // ✅ يجب تمرير كافة المتغيرات المطلوبة للدالة هنا
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
    final icon = isPassed
        ? Icons.workspace_premium_rounded
        : Icons.sentiment_dissatisfied_rounded;
    final title = isPassed ? 'مبروك! لقد نجحت في الاختبار' : 'لم تتجاوز الاختبار هذه المرة';
    final accentColor = isPassed ? const Color(0xFF00C853) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 50, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subject,
            style: const TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 15,
              color: Color(0xFF8E8E93),
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
                      'نحن نقدّر وجودك معنا 🤍\nإذا وجدت في تطبيقنا ما يستحق التقدير،\nتشرفنا بدعمك بتقييم 5 نجوم على متجر Google Play',
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
                              final url = Uri.parse(
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
    return Column(
      children: [
        _FancyButton(
          color: mainColor,
          icon: Icons.refresh_rounded,
          text: 'إعادة الاختبار',
          onTap: onRetry,
        ),
        const SizedBox(height: 12),
        _FancyButton(
          color: Colors.orange,
          icon: Icons.error_outline_rounded,
          text: 'عرض الإجابات الخاطئة',
          onTap: onWrongAnswers,
        ),
        const SizedBox(height: 12),
        _FancyButton(
          color: Colors.blue,
          icon: Icons.quiz_rounded,
          text: 'عرض كل الأسئلة',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllQuestionsScreen(
                  questions: questions, // ✅ تمرير questions
                  userAnswers: userAnswers, // ✅ تمرير userAnswers
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

  const _ResultsStatsCard({
    required this.mainColor,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final wrong = totalQuestions - correctAnswers;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL),
          gradient: LinearGradient(
            colors: [
              mainColor.withOpacity(.10),
              Colors.white,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(color: Colors.black.withOpacity(.06)),
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
                      const Text('ملخّص النتيجة', style: _QuizUI.title),
                      const SizedBox(height: 6),
                      Text(
                        'تابع الإجابات الخاطئة لمعرفة نقاط الضعف وتحسين مستواك بسرعة.',
                        style: _QuizUI.body.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
              color: Colors.black54,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('جميع الأسئلة والنتائج',
            style: TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor, width: 1.5),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
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
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // حاوية الإجابات
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.08)
                          : Colors.red.withOpacity(0.08),
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
                                    color: isCorrect ? Colors.green : Colors.red,
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
                                    color: Colors.green,
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
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue, size: _fontSize),
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
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  explanation,
                                  style: TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: _fontSize - 2,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade800,
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

  const WrongAnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('الإجابات الخاطئة والمراجعة',
            style: TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F172A),
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
              itemBuilder: (context, i) => _WrongCard(item: wrongItems[i]),
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

  const _WrongCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final q = item.question;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_QuizUI.radiusXL),
          border: Border.all(color: Colors.black.withOpacity(.06)),
          boxShadow: [_QuizUI.softShadow(Colors.black)],
          color: Colors.white,
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
            Text(q.question, style: _QuizUI.title.copyWith(fontSize: 18)),
            const SizedBox(height: 14),
            _AnswerBox(
              label: 'اختيارك:',
              answer: q.options[item.userAnswerIndex],
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _AnswerBox(
              label: 'الإجابة الصحيحة:',
              answer: q.originalAnswer,
              color: Colors.green,
            ),
            // ⭐ إضافة التفسير إذا كان موجوداً
            if (q.explanation != null && q.explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExplanationBox(
                explanation: q.explanation!,
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

  const _ExplanationBox({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.05),
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
          Text(
            explanation,
            style: TextStyle(
              fontFamily: _QuizUI.font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
              height: 1.5,
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

  const _AnswerBox({
    required this.label,
    required this.answer,
    required this.color,
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
            style: TextStyle(
              fontFamily: _QuizUI.font,
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
  final String questionsUrl;
  final int questionsCount;
  final bool showAnswersDuringExam; // ⭐ أضف هذا

  const QuizScreen({
    super.key,
    required this.subject,
    required this.questionsUrl,
    this.questionsCount = 100,
    this.showAnswersDuringExam = false, // ⭐ افتراضي false
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

  // ⭐ التحكم في حجم الخط
  double _fontSize = 18.0;

  // ⭐ المتغيرات الجديدة
  bool _showFeedback = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _loadQuestions();
  }

  // ⭐ دالة عرض التغذية الراجعة
  // ⭐ دالة عرض التغذية الراجعة (تبقى ظاهرة)
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
      final questions =
      await QuestionService.loadQuestions(widget.questionsUrl);
      final random = Random();
      questions.shuffle(random);

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
      await QuestionService.saveQuizResult(
        userId: user.uid,
        subjectKey: _getSubjectKey(widget.subject),
        subjectName: widget.subject,
        scorePercentage: scorePercentage,
        correctAnswers: correctAnswers,
        wrongAnswers: _randomQuestions.length - correctAnswers,
        totalQuestions: _randomQuestions.length,
        durationInSeconds: durationUsed,
        wrongQuestions: wrongQuestionsData,
      );
    }

    // ✅ إذا كان الاختبار مجانياً (العربية 30 سؤال)، نضع علامة الاستهلاك
    if (widget.subject.contains('عربية') && widget.questionsCount == 30) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_taken_free_arabic', true);
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
        ),
      ),
    );
  }

// دالة مساعدة لتحويل اسم المادة إلى مفتاح
  String _getSubjectKey(String subject) {
    if (subject.contains('عربية')) return 'arabic';
    if (subject.contains('حاسوب')) return 'computer';
    if (subject.contains('إنجليزي')) return 'english';
    return 'arabic';
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(widget.subject, style: const TextStyle(fontFamily: _QuizUI.font, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0F172A),
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
              icon: const Icon(Icons.text_increase, size: 20),
              onPressed: () => setState(() => _fontSize = (_fontSize < 30) ? _fontSize + 2 : _fontSize),
              tooltip: 'تكبير الخط',
            ),
            IconButton(
              icon: const Icon(Icons.text_decrease, size: 20),
              onPressed: () => setState(() => _fontSize = (_fontSize > 14) ? _fontSize - 2 : _fontSize),
              tooltip: 'تصغير الخط',
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
                      ? const Color(0xFF0F172A)
                      : answered
                      ? const Color(0xFF00C853)
                      : const Color(0xFFE5E5EA);

                  final Color fg = current || answered ? Colors.white : const Color(0xFF8E8E93);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: current ? 42 : 38,
                      height: current ? 42 : 38,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: current
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withOpacity(0.2),
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
                  backgroundColor: const Color(0xFFE5E5EA),
                  color: const Color(0xFF0F172A),
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
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'السؤال ${_currentQuestionIndex + 1} من ${_randomQuestions.length}',
                                  style: const TextStyle(
                                    fontFamily: _QuizUI.font,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            q.question,
                            style: TextStyle(
                              fontFamily: _QuizUI.font,
                              fontWeight: FontWeight.bold,
                              fontSize: _fontSize + 1,
                              color: const Color(0xFF1C1C1E),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // الخيارات بنمط iOS
                          ...List.generate(q.options.length, (index) {
                            final option = q.options[index];
                            final isSelected = _userAnswers[_currentQuestionIndex] == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    _userAnswers[_currentQuestionIndex] = index;
                                    if (widget.showAnswersDuringExam) {
                                      _showAnswerFeedback();
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF00C853) : const Color(0xFFE5E5EA),
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF00C853) : Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontFamily: _QuizUI.font,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontFamily: _QuizUI.font,
                                            fontSize: _fontSize,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: const Color(0xFF1C1C1E),
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
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFFEF2F2),
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
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
                                                style: const TextStyle(
                                                  fontFamily: 'Tajawal',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1C1C1E),
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
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 18),
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
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _randomQuestions[_currentQuestionIndex].explanation!,
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1E3A8A),
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
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
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
                            backgroundColor: const Color(0xFFE5E5EA),
                            foregroundColor: const Color(0xFF1C1C1E),
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
                            backgroundColor: const Color(0xFF0F172A),
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
