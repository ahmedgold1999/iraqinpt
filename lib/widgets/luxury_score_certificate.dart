import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class LuxuryScoreCertificateDialog extends StatelessWidget {
  final String studentName;
  final String subject;
  final double scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final int durationInSeconds;

  const LuxuryScoreCertificateDialog({
    super.key,
    required this.studentName,
    required this.subject,
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationInSeconds,
  });

  static const _navy = Color(0xFF0F172A);
  static const _gold = Color(0xFFFACC15);

  String get _ratingText {
    if (scorePercentage >= 90) return 'امتياز 🎖️';
    if (scorePercentage >= 80) return 'جيد جداً 🌟';
    if (scorePercentage >= 70) return 'جيد 👍';
    if (scorePercentage >= 50) return 'ناجح 🎯';
    return 'محاولة جيدة 💪';
  }

  void _shareResult(BuildContext context) {
    final text = '''
🎓 نتيجتي في الاختبار الوطني الموحد (INPT):
━━━━━━━━━━━━━━━━━━
👤 الطالب: $studentName
📚 المادة: $subject
📊 النسبة: ${scorePercentage.toStringAsFixed(1)}% ($correctAnswers من $totalQuestions)
⭐ التقدير: $_ratingText
⏱️ الوقت المستغرق: ${durationInSeconds ~/ 60} دقيقة
━━━━━━━━━━━━━━━━━━
📲 تدرب وتصدر قائمة الأوائل عبر تطبيق الاختبار الوطني الموحد (العراق):
https://t.me/inptiq
''';

    Share.share(text, subject: 'نتيجة اختبار $subject - تطبيق INPT');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _gold.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شارة التتويج
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFD97706)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 42, color: _navy),
            ),
            const SizedBox(height: 14),

            const Text(
              'شهادة إنجاز واجتياز اختبار',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تطبيق الاختبار الوطني العراقي الموحد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 16),

            // اسم الطالب
            Text(
              studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أكمل بنجاح اختبار $subject',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 18),

            // بطاقة النتيجة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${scorePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _gold,
                        ),
                      ),
                      const Text(
                        'النسبة المئوية',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 35, color: Colors.white24),
                  Column(
                    children: [
                      Text(
                        _ratingText,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'التقدير النهائي',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // أزرار المشاركة والإغلاق
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareResult(context),
                    icon: const Icon(Icons.share_rounded, size: 18, color: _navy),
                    label: const Text(
                      'مشاركة النتيجة 📤',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _navy,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
