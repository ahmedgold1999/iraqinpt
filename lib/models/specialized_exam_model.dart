import 'package:cloud_firestore/cloud_firestore.dart';

class SpecializedExamModel {
  final String id;
  final String subjectKey; // 'arabic', 'computer', 'english'
  final String subjectName;
  final String title;
  final String description;
  final String jsonUrl;
  final int questionsCount;
  final int durationMinutes;
  final String iconEmoji;
  final bool isActive;
  final int order;
  final DateTime createdAt;

  SpecializedExamModel({
    required this.id,
    required this.subjectKey,
    required this.subjectName,
    required this.title,
    required this.description,
    required this.jsonUrl,
    required this.questionsCount,
    this.durationMinutes = 30,
    this.iconEmoji = '📝',
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
  });

  factory SpecializedExamModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      }
    }

    return SpecializedExamModel(
      id: docId,
      subjectKey: map['subjectKey'] ?? 'computer',
      subjectName: map['subjectName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      jsonUrl: map['jsonUrl'] ?? '',
      questionsCount: (map['questionsCount'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
      iconEmoji: (map['iconEmoji'] ?? map['emoji'] ?? '📝').toString(),
      isActive: map['isActive'] ?? true,
      order: (map['order'] as num?)?.toInt() ?? 0,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectKey': subjectKey,
      'subjectName': subjectName,
      'title': title,
      'description': description,
      'jsonUrl': jsonUrl,
      'questionsCount': questionsCount,
      'durationMinutes': durationMinutes,
      'iconEmoji': iconEmoji,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SpecializedExamModel copyWith({
    String? id,
    String? subjectKey,
    String? subjectName,
    String? title,
    String? description,
    String? jsonUrl,
    int? questionsCount,
    int? durationMinutes,
    String? iconEmoji,
    bool? isActive,
    int? order,
    DateTime? createdAt,
  }) {
    return SpecializedExamModel(
      id: id ?? this.id,
      subjectKey: subjectKey ?? this.subjectKey,
      subjectName: subjectName ?? this.subjectName,
      title: title ?? this.title,
      description: description ?? this.description,
      jsonUrl: jsonUrl ?? this.jsonUrl,
      questionsCount: questionsCount ?? this.questionsCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
