import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';
import '../models/specialized_exam_model.dart';

class SpecializedExamService {
  static final SpecializedExamService _instance = SpecializedExamService._internal();
  factory SpecializedExamService() => _instance;
  SpecializedExamService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _examsRef => _db.collection('specialized_exams');

  static const String _offlineExamPrefix = 'offline_specialized_exam_';
  static const String _offlineListPrefix = 'offline_specialized_list_';

  /// تحويل أي رابط GitHub عادي إلى رابط Raw مباشر يمكن تحميله فوراً
  static String normalizeGitHubUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return '';

    // إذا كان الرابط بالشكل: https://github.com/user/repo/blob/branch/path/file.json
    // يتحول إلى: https://raw.githubusercontent.com/user/repo/branch/path/file.json
    if (url.contains('github.com') && url.contains('/blob/')) {
      url = url.replaceFirst('github.com', 'raw.githubusercontent.com');
      url = url.replaceFirst('/blob/', '/');
    }
    return url;
  }

  /// اختبار رابط الـ JSON وفحصه واستخراج عدد الأسئلة وعينة منها
  static Future<Map<String, dynamic>> validateAndPreviewJson(String url) async {
    final directUrl = normalizeGitHubUrl(url);
    if (directUrl.isEmpty) {
      return {'success': false, 'error': 'الرابط غير صالح أو فارغ'};
    }

    try {
      final response = await http
          .get(Uri.parse(directUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'تعذر جلب الملف (رمز الاستجابة: ${response.statusCode})',
        };
      }

      final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
      List<dynamic> questionsList = [];

      if (decoded is List) {
        questionsList = decoded;
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
        questionsList = decoded['questions'] as List<dynamic>;
      } else {
        return {
          'success': false,
          'error': 'هيكل ملف JSON غير متوافق. يجب أن يكون قائمة أسئلة أو كائن يحتوي حقل "questions"',
        };
      }

      if (questionsList.isEmpty) {
        return {
          'success': false,
          'error': 'الملف لا يحتوي على أي أسئلة',
        };
      }

      // فحص صحة السؤال الأول للتأكد من بنية الأسئلة
      final firstItem = questionsList.first;
      if (firstItem is! Map<String, dynamic> ||
          !firstItem.containsKey('question') ||
          !firstItem.containsKey('options') ||
          !firstItem.containsKey('answer')) {
        return {
          'success': false,
          'error': 'بنية الأسئلة غير مطابقة (يجب توفر question, options, answer في كل سؤال)',
        };
      }

      return {
        'success': true,
        'count': questionsList.length,
        'sampleQuestion': firstItem['question'],
        'sampleOptions': firstItem['options'],
        'sampleAnswer': firstItem['answer'],
        'rawBody': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'خطأ أثناء الاتصال أو قراءة ملف JSON: ${e.toString()}',
      };
    }
  }

  // ==========================================
  // إدارة التخزين المحلي والأوفلاين
  // ==========================================

  /// فحص هل أسئلة الاختبار محفوظة محلياً في الهاتف
  Future<bool> isExamCachedLocally(String examId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_offlineExamPrefix$examId';
      final cached = prefs.getString(key);
      return cached != null && cached.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// حفظ أسئلة الاختبار محلياً في الهاتف (أوف لاين)
  Future<void> saveExamQuestionsLocally(String examId, String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_offlineExamPrefix$examId', rawJson);
      await prefs.setString('${_offlineExamPrefix + examId}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('⚠️ Failed to cache exam questions locally: $e');
    }
  }

  /// جلب أسئلة الاختبار (مع أولوية التخزين المحلي Offline First)
  Future<List<Question>> getQuestionsForExam(SpecializedExamModel exam) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_offlineExamPrefix${exam.id}';

    // 1. فحص التخزين المحلي أولاً
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final dynamic decoded = json.decode(cachedData);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
          list = decoded['questions'] as List<dynamic>;
        }
        if (list.isNotEmpty) {
          return list.map((q) => Question.fromMap(Map<String, dynamic>.from(q))).toList();
        }
      } catch (e) {
        print('⚠️ Error parsing local offline questions for ${exam.id}: $e');
      }
    }

    // 2. إذا لم يكن محفوظاً محلياً، نجلبه من الرابط ونحفظه فوراً
    final directUrl = normalizeGitHubUrl(exam.jsonUrl);
    if (directUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(directUrl))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes);
          await saveExamQuestionsLocally(exam.id, body);

          final dynamic decoded = json.decode(body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
            list = decoded['questions'] as List<dynamic>;
          }
          return list.map((q) => Question.fromMap(Map<String, dynamic>.from(q))).toList();
        }
      } catch (e) {
        print('⚠️ Error fetching questions online for ${exam.id}: $e');
      }
    }

    // إذا فشل كل شيء وكان هناك كاش قديم
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final dynamic decoded = json.decode(cachedData);
        List<dynamic> list = decoded is List ? decoded : (decoded['questions'] ?? []);
        return list.map((q) => Question.fromMap(Map<String, dynamic>.from(q))).toList();
      } catch (_) {}
    }

    return [];
  }

  /// مزامنة وتحميل جميع الاختبارات التخصصية والأسئلة تلقائياً إلى ذاكرة الهاتف أوفلاين
  Future<void> syncAllExamsOffline({bool forceUpdate = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = await _examsRef.where('isActive', isEqualTo: true).get();

      // تجميع الاختبارات حسب المادة وتخزين قائمتها محلياً
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      final List<SpecializedExamModel> activeExams = [];

      for (final doc in snapshot.docs) {
        final exam = SpecializedExamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        activeExams.add(exam);
        grouped.putIfAbsent(exam.subjectKey, () => []).add(exam.toMap()..['id'] = exam.id);
      }

      // حفظ القوائم محلياً
      for (final entry in grouped.entries) {
        await prefs.setString('$_offlineListPrefix${entry.key}', json.encode(entry.value));
      }

      // تحميل ملفات الـ JSON في الخلفية وحفظها محلياً
      for (final exam in activeExams) {
        final cacheKey = '$_offlineExamPrefix${exam.id}';
        final hasCache = prefs.containsKey(cacheKey);

        // إذا طلب التحديث الإجباري أو لم يكن محملاً مسبقاً، نحمله الآن
        if ((forceUpdate || !hasCache) && exam.jsonUrl.isNotEmpty) {
          try {
            final directUrl = normalizeGitHubUrl(exam.jsonUrl);
            final response = await http
                .get(Uri.parse(directUrl))
                .timeout(const Duration(seconds: 15));

            if (response.statusCode == 200) {
              final body = utf8.decode(response.bodyBytes);
              await prefs.setString(cacheKey, body);
            }
          } catch (e) {
            print('⚠️ Sync failed for exam ${exam.title}: $e');
          }
        }
      }

      await prefs.setString('last_specialized_exams_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('⚠️ Failed to sync specialized exams offline: $e');
    }
  }

  /// جلب الاختبارات التخصصية المحفوظة محلياً (عند انقطاع النت)
  Future<List<SpecializedExamModel>> getOfflineExamsForSubject(String subjectKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_offlineListPrefix$subjectKey');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        return decoded
            .map((item) => SpecializedExamModel.fromMap(Map<String, dynamic>.from(item), item['id'] ?? ''))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ==========================================
  // استعلامات الواجهات (Stream & Realtime)
  // ==========================================

  /// تدفق الاختبارات التخصصية لمادة معينة للمستخدم
  Stream<List<SpecializedExamModel>> streamExamsForSubject(String subjectKey) {
    return _examsRef
        .where('subjectKey', isEqualTo: subjectKey)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final exams = snapshot.docs.map((doc) {
        return SpecializedExamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      exams.sort((a, b) => a.order.compareTo(b.order));
      return exams;
    });
  }

  /// تدفق جميع الاختبارات للإدارة
  Stream<List<SpecializedExamModel>> streamAllExamsForAdmin() {
    return _examsRef.snapshots().map((snapshot) {
      final exams = snapshot.docs.map((doc) {
        return SpecializedExamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      exams.sort((a, b) {
        final subjectComp = a.subjectKey.compareTo(b.subjectKey);
        if (subjectComp != 0) return subjectComp;
        return a.order.compareTo(b.order);
      });
      return exams;
    });
  }

  // ==========================================
  // عمليات الإدارة (CRUD)
  // ==========================================

  Future<void> createExam(SpecializedExamModel exam) async {
    final directUrl = normalizeGitHubUrl(exam.jsonUrl);
    final examData = exam.copyWith(jsonUrl: directUrl);
    final docRef = await _examsRef.add(examData.toMap());

    // تنزيل الأسئلة محلياً فور إضافتها
    try {
      final res = await http.get(Uri.parse(directUrl)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await saveExamQuestionsLocally(docRef.id, utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
  }

  Future<void> updateExam(SpecializedExamModel exam) async {
    final directUrl = normalizeGitHubUrl(exam.jsonUrl);
    final examData = exam.copyWith(jsonUrl: directUrl);
    await _examsRef.doc(exam.id).update(examData.toMap());

    // تحديث الكاش المحلي أيضاً
    try {
      final res = await http.get(Uri.parse(directUrl)).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await saveExamQuestionsLocally(exam.id, utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
  }

  Future<void> deleteExam(String examId) async {
    await _examsRef.doc(examId).delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_offlineExamPrefix$examId');
  }

  Future<void> toggleExamStatus(String examId, bool currentStatus) async {
    await _examsRef.doc(examId).update({'isActive': !currentStatus});
  }
}
