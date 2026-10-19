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
  static const String _offlineUrlPrefix = 'offline_specialized_url_';

  static const String workerBaseUrl = 'https://inptiq.ahmeedgold1000.workers.dev';
  static const String appSecureKey = 'INQU_SECURE_KEY_2026';
  static const Map<String, String> secureHeaders = {
    'x-app-key': appSecureKey,
  };

  /// تحويل أي رابط GitHub عادي أو مسار ملف إلى رابط Cloudflare Worker الآمن
  static String normalizeGitHubUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return '';

    // إذا كان الرابط يمر بالـ Worker بالفعل
    if (url.startsWith(workerBaseUrl)) {
      return url;
    }

    // إذا أدخل الأدمن مساراً نسبياً مثل: english/conversations.json
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final cleanPath = url.replaceFirst(RegExp(r'^/+'), '');
      return '$workerBaseUrl/$cleanPath';
    }

    // إذا كان الرابط من مستودع INQU (سواء كان github.com أو raw.githubusercontent.com)
    final inquRegex = RegExp(
      r'https?:\/\/(?:raw\.githubusercontent\.com|github\.com)\/ahmedgold1999\/INQU\/(?:blob\/|raw\/)?(?:main\/|master\/|refs\/heads\/main\/)?(.+)',
      caseSensitive: false,
    );
    final match = inquRegex.firstMatch(url);
    if (match != null && match.group(1) != null) {
      return '$workerBaseUrl/${match.group(1)}';
    }

    // الروابط الأخرى العادية
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
          .get(
            Uri.parse(directUrl),
            headers: secureHeaders,
          )
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

  /// حذف الكاش المحلي لاختبار معين
  Future<void> clearExamCache(String examId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_offlineExamPrefix$examId');
      await prefs.remove('$_offlineUrlPrefix$examId');
      await prefs.remove('${_offlineExamPrefix + examId}_timestamp');
    } catch (_) {}
  }

  /// حفظ أسئلة الاختبار محلياً في الهاتف (أوف لاين) مع حفظ الرابط الأصلي
  Future<void> saveExamQuestionsLocally(String examId, String rawJson, {String? url}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_offlineExamPrefix$examId', rawJson);
      await prefs.setString('${_offlineExamPrefix + examId}_timestamp', DateTime.now().toIso8601String());
      if (url != null && url.isNotEmpty) {
        await prefs.setString('$_offlineUrlPrefix$examId', url);
      }
    } catch (e) {
      print('⚠️ Failed to cache exam questions locally: $e');
    }
  }

  /// جلب أسئلة الاختبار مع أولوية التحديث الحي وملاءمة الأوفلاين (Online-First with Offline Fallback)
  Future<List<Question>> getQuestionsForExam(SpecializedExamModel exam, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_offlineExamPrefix${exam.id}';
    final urlKey = '$_offlineUrlPrefix${exam.id}';
    final directUrl = normalizeGitHubUrl(exam.jsonUrl);

    final cachedUrl = prefs.getString(urlKey);
    final String? cachedData = prefs.getString(cacheKey);

    // 1. إذا تغير رابط الـ JSON الخاص بالاختبار، فإن الكاش القديم أصبح غير صالح ويجب حذفه فوراً
    final bool urlChanged = cachedUrl != null && directUrl.isNotEmpty && cachedUrl != directUrl;
    if (urlChanged) {
      await prefs.remove(cacheKey);
      await prefs.remove(urlKey);
    }

    // 2. إذا كان هناك رابط متاح، نحاول الجلب الحي من GitHub فوراً لتطبيق أي تصحيحات بالأسئلة
    if (directUrl.isNotEmpty) {
      try {
        // نضع معامل زمني لمنع تخزين CDN لـ GitHub Raw مؤقتاً
        final Uri fetchUri = Uri.parse(directUrl).replace(
          queryParameters: {
            ...Uri.parse(directUrl).queryParameters,
            '_t': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        final response = await http.get(
          fetchUri,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'x-app-key': appSecureKey,
          },
        ).timeout(const Duration(seconds: 4)); // مهلة 4 ثوانٍ فقط لتجنب أي بطء

        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes);
          final dynamic decoded = json.decode(body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
            list = decoded['questions'] as List<dynamic>;
          }

          if (list.isNotEmpty) {
            // تحديث الكاش المحلي بالنسخة المصححة فوراً للعمل أوفلاين لاحقاً
            await saveExamQuestionsLocally(exam.id, body, url: directUrl);
            return list.map((q) => Question.fromMap(Map<String, dynamic>.from(q))).toList();
          }
        }
      } catch (e) {
        print('🌐 Live questions fetch skipped/timeout, falling back to local offline cache: $e');
      }
    }

    // 3. Fallback: عند انقطاع الإنترنت أو بطئه، نقرأ من الكاش المحلي المحفوظ مسبقاً
    final fallbackData = prefs.getString(cacheKey) ?? (urlChanged ? null : cachedData);
    if (fallbackData != null && fallbackData.isNotEmpty) {
      try {
        final dynamic decoded = json.decode(fallbackData);
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
        final urlKey = '$_offlineUrlPrefix${exam.id}';
        final directUrl = normalizeGitHubUrl(exam.jsonUrl);

        final hasCache = prefs.containsKey(cacheKey);
        final cachedUrl = prefs.getString(urlKey);
        final bool urlChanged = cachedUrl != null && directUrl.isNotEmpty && cachedUrl != directUrl;

        // إذا طلب التحديث الإجباري، أو لم يكن محملاً، أو تغير رابط الاختبار في لوحة التحكم
        if ((forceUpdate || !hasCache || urlChanged) && directUrl.isNotEmpty) {
          try {
            final Uri fetchUri = Uri.parse(directUrl).replace(
              queryParameters: {
                ...Uri.parse(directUrl).queryParameters,
                '_t': DateTime.now().millisecondsSinceEpoch.toString(),
              },
            );

            final response = await http.get(
              fetchUri,
              headers: {
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                'Expires': '0',
                'x-app-key': appSecureKey,
              },
            ).timeout(const Duration(seconds: 12));

            if (response.statusCode == 200) {
              final body = utf8.decode(response.bodyBytes);
              await saveExamQuestionsLocally(exam.id, body, url: directUrl);
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
    final examData = exam.copyWith(
      jsonUrl: directUrl,
      updatedAt: DateTime.now(),
    );
    final docRef = await _examsRef.add(examData.toMap());

    // تنزيل الأسئلة محلياً فور إضافتها
    try {
      final Uri fetchUri = Uri.parse(directUrl).replace(
        queryParameters: {
          ...Uri.parse(directUrl).queryParameters,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final res = await http.get(
        fetchUri,
        headers: {
          'Cache-Control': 'no-cache',
          'x-app-key': appSecureKey,
        },
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await saveExamQuestionsLocally(docRef.id, utf8.decode(res.bodyBytes), url: directUrl);
      }
    } catch (_) {}
  }

  Future<void> updateExam(SpecializedExamModel exam) async {
    final directUrl = normalizeGitHubUrl(exam.jsonUrl);
    final examData = exam.copyWith(
      jsonUrl: directUrl,
      updatedAt: DateTime.now(),
    );
    await _examsRef.doc(exam.id).update(examData.toMap());

    // حذف الكاش القديم وتحديثه بالجديد
    await clearExamCache(exam.id);
    try {
      final Uri fetchUri = Uri.parse(directUrl).replace(
        queryParameters: {
          ...Uri.parse(directUrl).queryParameters,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final res = await http.get(
        fetchUri,
        headers: {
          'Cache-Control': 'no-cache',
          'x-app-key': appSecureKey,
        },
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        await saveExamQuestionsLocally(exam.id, utf8.decode(res.bodyBytes), url: directUrl);
      }
    } catch (_) {}
  }

  Future<void> deleteExam(String examId) async {
    await _examsRef.doc(examId).delete();
    await clearExamCache(examId);
  }

  Future<void> toggleExamStatus(String examId, bool currentStatus) async {
    await _examsRef.doc(examId).update({'isActive': !currentStatus});
  }
}
