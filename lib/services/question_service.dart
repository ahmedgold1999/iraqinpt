import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';
import 'leaderboard_service.dart';

class QuestionService {
  // بنك روابط الأسئلة الرسمية (جلب عبر GitHub لتوفير موارد الفايربيس بنسبة 100%)
  static const Map<String, String> defaultSubjectUrls = {
    'arabic':
        'https://inptiq.ahmeedgold1000.workers.dev/arabic/allquestions',
    'computer':
        'https://inptiq.ahmeedgold1000.workers.dev/computer/allquestions',
    'english':
        'https://inptiq.ahmeedgold1000.workers.dev/english/allquestions',
  };

  /// تحميل الأسئلة مع دعم الوضع غير المتصل (Offline First)
  static Future<List<Question>> loadQuestions(String url, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_${url.hashCode}';

    // 1. إذا لم يُطلب إجبار التحديث، نفحص الكاش المحلي أولاً للسرعة القصوى
    if (!forceRefresh) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final dynamic decoded = json.decode(cachedData);
          List<dynamic> questionsJson = [];
          if (decoded is List) {
            questionsJson = decoded;
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
            questionsJson = decoded['questions'] as List<dynamic>;
          }
          if (questionsJson.isNotEmpty) {
            return questionsJson.map((q) => Question.fromMap(q)).toList();
          }
        } catch (e) {
          print('⚠️ Error parsing local cache: $e');
        }
      }
    }

    // 2. الجلب من الإنترنت وتحديث الكاش المحلي
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'x-app-key': 'INQU_SECURE_KEY_2026'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> questionsJson = [];

        if (decoded is List) {
          questionsJson = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
          questionsJson = decoded['questions'] as List<dynamic>;
        }
        
        // حفظ النسخة الأخيرة محلياً للعمل بدون إنترنت
        await prefs.setString(cacheKey, response.body);
        await prefs.setString('last_questions_sync', DateTime.now().toIso8601String());
        
        return questionsJson.map((q) => Question.fromMap(q)).toList();
      }
    } catch (e) {
      print('🌐 Network error, attempting offline cache fallback: $e');
    }

    // 3. Fallback احتياطي في حال انقطاع الشبكة
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      final dynamic decoded = json.decode(cachedData);
      List<dynamic> questionsJson = [];
      if (decoded is List) {
        questionsJson = decoded;
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
        questionsJson = decoded['questions'] as List<dynamic>;
      }
      return questionsJson.map((q) => Question.fromMap(q)).toList();
    }

    return [];
  }

  /// ✅ تحديث ومزامنة جميع بنوك الأسئلة بضغطة زر واحدة (Offline Sync)
  static Future<Map<String, int>> syncAllQuestions() async {
    final Map<String, int> results = {};
    for (final entry in defaultSubjectUrls.entries) {
      try {
        final questions = await loadQuestions(entry.value, forceRefresh: true);
        results[entry.key] = questions.length;
      } catch (e) {
        results[entry.key] = 0;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_questions_sync', DateTime.now().toIso8601String());
    return results;
  }

  /// جلب تاريخ آخر تحديث للأسئلة
  static Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_questions_sync');
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  /// حفظ نتيجة الاختبار محلياً وتحديث المتصدرين في Firebase بأقل استهلاك
  static Future<void> saveQuizResult({
    required String userId,
    required String userName,
    required String subjectKey,
    required String subjectName,
    required double scorePercentage,
    required int correctAnswers,
    required int wrongAnswers,
    required int totalQuestions,
    required int durationInSeconds,
    required List<Map<String, dynamic>> wrongQuestions,
    bool updateLeaderboard = true, // ⭐ إضافة هذا
  }) async {
    final resultData = {
      'userId': userId,
      'subjectKey': subjectKey,
      'subjectName': subjectName,
      'scorePercentage': scorePercentage,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalQuestions': totalQuestions,
      'durationInSeconds': durationInSeconds,
      'wrongQuestions': wrongQuestions,
      'date': DateTime.now().toIso8601String(),
    };

    try {
      // 1. حفظ تفاصيل الاختبار محلياً بالكامل على هاتف الطالب (0 استهلاك فايربيس)
      final prefs = await SharedPreferences.getInstance();
      List<String> results = prefs.getStringList('saved_quiz_results') ?? [];
      results.add(jsonEncode(resultData));
      await prefs.setStringList('saved_quiz_results', results);

      // 2. تحديث لوحة الشرف في Firebase (فقط وثيقة الطالب بنقاطه بدون أي سجلات ثقيلة)
      if (userId.isNotEmpty && updateLeaderboard) {
        await LeaderboardService.updateStudentScore(
          userId: userId,
          name: userName,
          photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
          subjectKey: subjectKey,
          scoreEarned: correctAnswers,
          scorePercentage: scorePercentage,
        );
      }
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }
}
