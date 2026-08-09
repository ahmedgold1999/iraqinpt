import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';

class QuestionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // تحميل الأسئلة مع دعم التخزين المؤقت (Caching) لتوفير البيانات والسرعة
  static Future<List<Question>> loadQuestions(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_${url.hashCode}';

    try {
      // 1. محاولة الجلب من GitHub
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> questionsJson = [];

        if (decoded is List) {
          questionsJson = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
          questionsJson = decoded['questions'] as List<dynamic>;
        }
        
        // حفظ النسخة الأخيرة في التخزين المحلي
        await prefs.setString(cacheKey, response.body);
        
        return questionsJson.map((q) => Question.fromMap(q)).toList();
      }
    } catch (e) {
      print('🌐 Network error, trying cache: $e');
    }

    // 2. في حال فشل الإنترنت، جلب النسخة المخزنة محلياً
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      print('📦 Loading questions from local cache');
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

  // حفظ نتيجة الاختبار محلياً فقط (تم إلغاء الرفع لـ Firestore لتوفير المساحة)
  static Future<void> saveQuizResult({
    required String userId,
    required String subjectKey,
    required String subjectName,
    required double scorePercentage,
    required int correctAnswers,
    required int wrongAnswers,
    required int totalQuestions,
    required int durationInSeconds,
    required List<Map<String, dynamic>> wrongQuestions,
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
      // حفظ محلياً فقط (لشاشة الاختبارات السابقة)
      final prefs = await SharedPreferences.getInstance();
      List<String> results = prefs.getStringList('saved_quiz_results') ?? [];
      
      results.add(jsonEncode(resultData));
      await prefs.setStringList('saved_quiz_results', results);
    } catch (e) {
      print('Error saving quiz result locally: $e');
    }
  }
}
