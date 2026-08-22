import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';

class MistakeItem {
  final String id;
  final String subjectKey;
  final String subjectName;
  final Question question;
  final String selectedWrongAnswer;
  final DateTime timestamp;

  MistakeItem({
    required this.id,
    required this.subjectKey,
    required this.subjectName,
    required this.question,
    required this.selectedWrongAnswer,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectKey': subjectKey,
      'subjectName': subjectName,
      'question': question.toMap(),
      'selectedWrongAnswer': selectedWrongAnswer,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MistakeItem.fromMap(Map<String, dynamic> map) {
    return MistakeItem(
      id: map['id'] ?? '',
      subjectKey: map['subjectKey'] ?? 'general',
      subjectName: map['subjectName'] ?? 'مادة عامة',
      question: Question.fromMap(map['question'] as Map<String, dynamic>),
      selectedWrongAnswer: map['selectedWrongAnswer'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}

class MistakeVaultService {
  static const String _key = 'mistake_vault_items_v2';

  /// حفظ سؤال خاطئ في بنك الأخطاء
  static Future<void> saveMistake({
    required Question question,
    required String subjectKey,
    required String subjectName,
    required String selectedWrongAnswer,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_key) ?? [];

      // منع تكرار نفس السؤال
      final existingIndex = list.indexWhere((itemStr) {
        try {
          final decoded = jsonDecode(itemStr);
          return decoded['question']['question'] == question.question;
        } catch (_) {
          return false;
        }
      });

      final newItem = MistakeItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subjectKey: subjectKey,
        subjectName: subjectName,
        question: question,
        selectedWrongAnswer: selectedWrongAnswer,
        timestamp: DateTime.now(),
      );

      if (existingIndex >= 0) {
        list[existingIndex] = jsonEncode(newItem.toMap());
      } else {
        list.add(jsonEncode(newItem.toMap()));
      }

      await prefs.setStringList(_key, list);
    } catch (e) {
      print('⚠️ Error saving mistake to vault: $e');
    }
  }

  /// جلب جميع الأخطاء المحفوظة
  static Future<List<MistakeItem>> getMistakes({String? subjectKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_key) ?? [];
      final List<MistakeItem> mistakes = [];

      for (var itemStr in list) {
        try {
          final decoded = jsonDecode(itemStr) as Map<String, dynamic>;
          final item = MistakeItem.fromMap(decoded);
          if (subjectKey == null || subjectKey == 'all' || item.subjectKey == subjectKey) {
            mistakes.add(item);
          }
        } catch (_) {}
      }

      // ترتيب حسب الأحدث
      mistakes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return mistakes;
    } catch (e) {
      print('⚠️ Error loading mistakes: $e');
      return [];
    }
  }

  /// إزالة سؤال من بنك الأخطاء بعد إتقانه
  static Future<void> removeMistake(String questionText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList(_key) ?? [];
      list.removeWhere((itemStr) {
        try {
          final decoded = jsonDecode(itemStr);
          return decoded['question']['question'] == questionText;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_key, list);
    } catch (e) {
      print('⚠️ Error removing mistake: $e');
    }
  }

  /// مسح جميع الأخطاء
  static Future<void> clearAllMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// جلب عدد الأخطاء المحفوظة
  static Future<int> getMistakesCount({String? subjectKey}) async {
    final list = await getMistakes(subjectKey: subjectKey);
    return list.length;
  }
}
