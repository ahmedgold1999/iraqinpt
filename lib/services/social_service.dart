import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب إحصائيات المادة للمستخدم من التخزين المحلي الكاش (SharedPreferences) وقاعدة البيانات Firestore
  Stream<Map<String, dynamic>> getSubjectStats(String userId) async* {
    final prefs = await SharedPreferences.getInstance();

    // 1. حساب الإحصائيات من التخزين المحلي الكاش
    Map<String, double> calculateStatsFromLocal(List<String> rawList) {
      Map<String, List<double>> subjectScores = {
        'arabic': [],
        'computer': [],
        'english': [],
      };

      for (var jsonStr in rawList) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonStr);

          // تحديد المفتاح
          String subjectKey = (data['subjectKey'] ?? '').toString();
          final String subjectName = (data['subjectName'] ?? data['subject'] ?? '').toString();

          if (subjectKey.isEmpty) {
            if (subjectName.contains('عرب')) {
              subjectKey = 'arabic';
            } else if (subjectName.contains('حاسوب')) {
              subjectKey = 'computer';
            } else if (subjectName.contains('إنجلي') || subjectName.contains('انكلي')) {
              subjectKey = 'english';
            }
          }

          // تحديد النسبة المئوية
          double scorePercentage = 0.0;
          if (data.containsKey('scorePercentage')) {
            scorePercentage = (data['scorePercentage'] as num).toDouble();
          } else if (data.containsKey('score') && data.containsKey('total')) {
            final int score = (data['score'] as num).toInt();
            final int total = (data['total'] as num).toInt();
            if (total > 0) {
              scorePercentage = (score / total) * 100;
            }
          }

          if (subjectScores.containsKey(subjectKey)) {
            subjectScores[subjectKey]!.add(scorePercentage);
          }
        } catch (_) {}
      }

      Map<String, double> averages = {};
      subjectScores.forEach((key, scores) {
        if (scores.isEmpty) {
          averages[key] = 0.0;
        } else {
          averages[key] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      return averages;
    }

    // إرسال النتيجة الفورية من كاش التخزين المحلي فوراً
    final List<String> initialLocal = prefs.getStringList('saved_quiz_results') ?? [];
    yield calculateStatsFromLocal(initialLocal);

    // الاستماع للتحديثات المستمرة ودمج نتائج Firestore إن وجدت
    await for (var snapshot in _db.collection('quiz_results').where('userId', isEqualTo: userId).snapshots()) {
      final List<String> currentLocal = prefs.getStringList('saved_quiz_results') ?? [];
      final Map<String, List<double>> combinedScores = {
        'arabic': [],
        'computer': [],
        'english': [],
      };

      // أ) إضافة نتائج التخزين المحلي
      for (var jsonStr in currentLocal) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          String key = (data['subjectKey'] ?? '').toString();
          final String name = (data['subjectName'] ?? data['subject'] ?? '').toString();
          if (key.isEmpty) {
            if (name.contains('عرب')) {
              key = 'arabic';
            } else if (name.contains('حاسوب')) {
              key = 'computer';
            } else if (name.contains('إنجلي') || name.contains('انكلي')) {
              key = 'english';
            }
          }
          double score = 0.0;
          if (data.containsKey('scorePercentage')) {
            score = (data['scorePercentage'] as num).toDouble();
          } else if (data.containsKey('score') && data.containsKey('total')) {
            final int s = (data['score'] as num).toInt();
            final int t = (data['total'] as num).toInt();
            if (t > 0) score = (s / t) * 100;
          }
          if (combinedScores.containsKey(key)) {
            combinedScores[key]!.add(score);
          }
        } catch (_) {}
      }

      // ب) إضافة نتائج Firestore إن وجدت
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String key = data['subjectKey'] ?? '';
        final double score = (data['scorePercentage'] as num?)?.toDouble() ?? 0.0;
        if (combinedScores.containsKey(key)) {
          combinedScores[key]!.add(score);
        }
      }

      Map<String, double> finalAverages = {};
      combinedScores.forEach((key, scores) {
        if (scores.isEmpty) {
          finalAverages[key] = 0.0;
        } else {
          finalAverages[key] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      yield finalAverages;
    }
  }
}
