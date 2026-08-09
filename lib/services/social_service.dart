import 'package:cloud_firestore/cloud_firestore.dart';

class SocialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // جلب إحصائيات المادة للمستخدم
  Stream<Map<String, dynamic>> getSubjectStats(String userId) {
    return _db.collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      Map<String, List<double>> subjectScores = {
        'arabic': [],
        'computer': [],
        'english': [],
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String subject = data['subjectKey'] ?? '';
        final double score = (data['scorePercentage'] as num?)?.toDouble() ?? 0.0;
        
        if (subjectScores.containsKey(subject)) {
          subjectScores[subject]!.add(score);
        }
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
    });
  }
}
