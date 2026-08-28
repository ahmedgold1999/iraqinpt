import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/question_model.dart';
import '../../services/question_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/mistake_vault_service.dart';
import '../../services/sound_effects_service.dart';

class SpeedQuizScreen extends StatefulWidget {
  const SpeedQuizScreen({super.key});

  @override
  State<SpeedQuizScreen> createState() => _SpeedQuizScreenState();
}

class _SpeedQuizScreenState extends State<SpeedQuizScreen> with SingleTickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isLoading = true;
  bool _isGameOver = false;

  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final List<Question> combined = [];
    for (var url in QuestionService.defaultSubjectUrls.values) {
      try {
        final list = await QuestionService.loadQuestions(url);
        combined.addAll(list);
      } catch (_) {}
    }

    combined.shuffle(Random());

    if (mounted) {
      setState(() {
        _questions = combined;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _answerQuestion(String selectedOption) {
    if (_isGameOver || _currentIndex >= _questions.length) return;

    final q = _questions[_currentIndex];
    final bool isCorrect = selectedOption.trim() == q.answer.trim();

    if (isCorrect) {
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
      final points = 10 + (_streak > 2 ? 5 : 0);
      _score += points;
      _feedbackColor = const Color(0xFF00C853);
      SoundEffectsService.playCorrectSound();
      if (_streak >= 3) {
        SoundEffectsService.playStreakSound();
      }
    } else {
      _streak = 0;
      _feedbackColor = const Color(0xFFEF4444);
      SoundEffectsService.playWrongSound();
      // حفظ في بنك الأخطاء
      MistakeVaultService.saveMistake(
        question: q,
        subjectKey: 'general',
        subjectName: 'تحدي السرعة',
        selectedWrongAnswer: selectedOption,
      );
    }

    setState(() {});

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _feedbackColor = null;
        if (_currentIndex < _questions.length - 1) {
          _currentIndex++;
        } else {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _timer?.cancel();
    if (_isGameOver) return;

    SoundEffectsService.playCompleteSound();
    setState(() => _isGameOver = true);

    // تحديث نقاط المتصدرين
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _score > 0) {
      LeaderboardService.updateStudentScore(
        userId: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? 'بطل السرعة',
        scoreEarned: _score ~/ 10,
        scorePercentage: min(100, (_score / 20) * 10),
      );
    }

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_rounded, size: 50, color: Color(0xFFFACC15)),
              SizedBox(height: 8),
              Text('انتهى الوقت!', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score نقطة',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge('أعلى تتابع 🔥', '$_maxStreak'),
                _buildStatBadge('الأسئلة المجابة', '$_currentIndex'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('خروج', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _streak = 0;
                _maxStreak = 0;
                _timeLeft = 60;
                _isGameOver = false;
                _questions.shuffle(Random());
              });
              _startTimer();
            },
            child: const Text('إعادة التحدي ⚡', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحدي الـ 60 ثانية')),
        body: const Center(child: Text('لا توجد أسئلة متوفرة حالياً')),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: _feedbackColor ?? (isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC)),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Color(0xFFFACC15), size: 26),
            SizedBox(width: 6),
            Text('تحدي الـ 60 ثانية', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              SoundEffectsService().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: SoundEffectsService().isMuted ? Colors.grey : const Color(0xFF38BDF8),
            ),
            tooltip: SoundEffectsService().isMuted ? 'تفعيل المؤثرات الصوتية' : 'كتم المؤثرات الصوتية',
            onPressed: () {
              SoundEffectsService().toggleSound();
              setState(() {});
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    SoundEffectsService().isMuted ? 'تم كتم المؤثرات الصوتية 🔇' : 'تم تفعيل المؤثرات الصوتية 🔊',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: SoundEffectsService().isMuted ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _timeLeft <= 10 ? Colors.red : const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_timeLeft}s',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // لوحة الإحصائيات الحية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'النقاط: $_score',
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 14),
                    ),
                  ),
                  if (_streak > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 $_streak كومبو!',
                        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // بطاقة السؤال
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C31) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        currentQuestion.question,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // خيارات الإجابة
              Expanded(
                flex: 5,
                child: Column(
                  children: currentQuestion.options.map((option) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            elevation: 0,
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () => _answerQuestion(option),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
