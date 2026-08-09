// lib/models/question_model.dart
class Question {
  String question;
  List<String> options;
  String answer;
  String originalAnswer;
  String? explanation; // ⭐ أضف هذا الحقل الجديد

  Question({
    required this.question,
    required this.options,
    required this.answer,
    required this.originalAnswer,
    this.explanation, // ⭐ أضف هذا
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
      answer: map['answer'] as String,
      originalAnswer: map['answer'] as String,
      explanation: map['explanation'], // ⭐ اقرأ حقل التفسير
    );
  }
}