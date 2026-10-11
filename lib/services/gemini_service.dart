import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    text: map['text'] ?? '',
    isUser: map['isUser'] ?? false,
    timestamp: map['timestamp'] != null
        ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
        : DateTime.now(),
  );
}

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // مفتاح مخصص شغال ومجاني 100% من Google AI Studio
  static const String _defaultApiKey = 'AQ.Ab8RN6L3PoUe9sdNH5qaDP0_koFFpwmJWlgxF7cT9GPZflffUg';
  
  static const int freeDailyLimit = 5;

  static const String _systemInstruction = '''
أنت "الأستاذ الذكي المساعد (INPT AI Tutor)"، مساعد تعليمي متخصص وذكي جداً في منهاج "الامتحان الوطني الموحد (INPT)" للقبول بالدراسات العليا (الماجستير والدكتوراه) في الجامعات العراقية.
تغطي المواد الثلاث الأساسية:
1. اللغة الإنكليزية (English Grammar, Reading Comprehension, Vocabulary, Sentence Structure).
2. الحاسوب وتكنولوجيا المعلومات (Computer Skills, MS Office: Word, Excel, PowerPoint, Windows, Computer Networks, Security, Shortcuts).
3. اللغة العربية (قواعد النحو والإملاء، العدد والمعدود، الهمزات، الصياغة السليمة، علامات الترقيم).

إرشاداتك في الإجابة:
- أجب دائماً باللغة العربية الواضحة والمشجعة، مع كتابة المصطلحات الإنجليزية عند الحاجة.
- رتّب إجاباتك بنقاط منسقة ورموز تعبيرية تعليمية 💡 📌 🎯.
- إذا سألك الطالب عن سؤال خيارات متعددة، وضح له الإجابة الصحيحة واشرح له باختصار لماذا هي صحيحة ولماذا بقية الخيارات خاطئة.
- قدّم أمثلة تدريبية سريعة تثبت المعلومة في ذهنه.
- كن إيجابياً، متفائلاً، ومحفزاً للنجاح والتفوق.
''';

  /// الحصول على مفتاح API من Firestore أو استخدام الافتراضي
  Future<String> _getApiKey() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('gemini_config')
          .get();
      if (doc.exists && doc.data()?['api_key'] != null) {
        final key = doc.data()!['api_key'].toString().trim();
        if (key.isNotEmpty) return key;
      }
    } catch (_) {}
    return _defaultApiKey;
  }

  /// فحص وتحديث عدد الأسئلة اليومية للمستخدم المجاني
  Future<int> getRemainingFreeQueries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = 'ai_queries_$todayStr';
      final used = prefs.getInt(key) ?? 0;
      return (freeDailyLimit - used).clamp(0, freeDailyLimit);
    } catch (_) {
      return freeDailyLimit;
    }
  }

  /// تسجيل استخدام سؤال جديد
  Future<void> _incrementDailyUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = 'ai_queries_$todayStr';
      final used = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, used + 1);
    } catch (_) {}
  }

  static const List<String> _candidateModels = [
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  /// إرسال رسالة إلى Gemini API مع دعم المحادثة المتصلة والتبديل التلقائي الذكي بين النماذج
  Future<String> sendMessage({
    required String prompt,
    required List<ChatMessage> conversationHistory,
    required bool isPremium,
  }) async {
    if (!isPremium) {
      final remaining = await getRemainingFreeQueries();
      if (remaining <= 0) {
        throw Exception('QUOTA_EXCEEDED');
      }
    }

    final apiKey = await _getApiKey();

    // بناء سياق المحادثة
    final List<Map<String, dynamic>> contents = [];

    // إضافة رسائل سابقة من المحادثة (بحد أقصى آخر 8 رسائل)
    final recentHistory = conversationHistory.length > 8
        ? conversationHistory.sublist(conversationHistory.length - 8)
        : conversationHistory;

    for (var msg in recentHistory) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }

    // إضافة الرسالة الحالية
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final payload = {
      'system_instruction': {
        'parts': [{'text': _systemInstruction}]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1500,
      }
    };

    String lastError = '';

    // تجربة النماذج الاحتياطية بالترتيب في حال كان أحدهم تحت ضغط لحظي (503 / 429)
    for (var modelName in _candidateModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
      );

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text']?.toString() ?? '';
              if (!isPremium) {
                await _incrementDailyUsage();
              }
              return text.trim();
            }
          }
        } else {
          debugPrint('⚠️ Model $modelName returned ${response.statusCode}, switching to fallback...');
          lastError = '(${response.statusCode})';
          continue; // تجربة النموذج التالي فوراً
        }
      } catch (e) {
        debugPrint('⚠️ Model $modelName failed: $e, switching to fallback...');
        lastError = e.toString();
        continue;
      }
    }

    throw Exception('تعذر الاتصال بالأستاذ الذكي حالياً $lastError، يرجى المحاولة ثانية.');
  }
}
