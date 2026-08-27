import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? photoUrl;
  final String? avatarId;
  final String? gender;
  final bool isPremium;
  final int totalScore;
  final int arabicScore;
  final int computerScore;
  final int englishScore;
  final int quizzesCount;
  final double highestPercentage;
  final DateTime? lastActive;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.avatarId,
    this.gender,
    this.isPremium = false,
    required this.totalScore,
    this.arabicScore = 0,
    this.computerScore = 0,
    this.englishScore = 0,
    required this.quizzesCount,
    required this.highestPercentage,
    this.lastActive,
  });

  /// جلب النقاط المخصصة للمادة المختارة مع دعم التوافق للدرجات السابقة
  int getScoreForSubject(String subject) {
    switch (subject) {
      case 'arabic':
        // إذا كان هناك رصيد عربي أو كانت الدرجات القديمة مسجلة قبل التحديث
        return arabicScore > 0 ? arabicScore : (computerScore == 0 && englishScore == 0 ? totalScore : 0);
      case 'computer':
        return computerScore > 0 ? computerScore : 0;
      case 'english':
        return englishScore > 0 ? englishScore : 0;
      default:
        return totalScore;
    }
  }

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      userId: doc.id,
      name: data['name'] ?? 'طالب متميز',
      photoUrl: data['photoUrl'],
      avatarId: data['avatarId']?.toString(),
      gender: data['gender']?.toString(),
      isPremium: data['isPremium'] == true,
      totalScore: (data['totalScore'] ?? 0) as int,
      arabicScore: (data['arabicScore'] ?? 0) as int,
      computerScore: (data['computerScore'] ?? 0) as int,
      englishScore: (data['englishScore'] ?? 0) as int,
      quizzesCount: (data['quizzesCount'] ?? 0) as int,
      highestPercentage: ((data['highestPercentage'] ?? 0.0) as num).toDouble(),
      lastActive: data['lastActive'] != null && data['lastActive'] is Timestamp
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
    );
  }
}

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _leaderboardRef =
      _firestore.collection('leaderboard');

  /// ✅ تحديث وتخزين النقاط بحسب نوع المادة في Firebase
  static Future<void> updateStudentScore({
    required String userId,
    required String name,
    required int scoreEarned,
    required double scorePercentage,
    String? photoUrl,
    String? subjectKey,
  }) async {
    if (userId.isEmpty) return;

    try {
      final cleanSubject = _normalizeSubjectKey(subjectKey);
      final docRef = _leaderboardRef.doc(userId);
      final docSnapshot = await docRef.get();

      // ✅ جلب الاسم الفعلي وحالة الأفاتار والاشتراك من وثيقة المستخدم users/{uid}
      String realName = name;
      String? userAvatarId;
      String? userGender;
      bool userIsPremium = false;

      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final docName = userData?['name'] ?? userData?['displayName'];
          if (docName != null && docName.toString().trim().isNotEmpty) {
            realName = docName.toString().trim();
          }
          userAvatarId = userData?['avatarId']?.toString();
          userGender = userData?['gender']?.toString();
          userIsPremium = userData?['isPremium'] == true;
        }
      } catch (_) {}

      if (realName.isEmpty) realName = 'طالب متميز';

      if (!docSnapshot.exists) {
        final Map<String, dynamic> initialData = {
          'name': realName,
          'photoUrl': photoUrl,
          'avatarId': userAvatarId,
          'gender': userGender,
          'isPremium': userIsPremium,
          'totalScore': scoreEarned,
          'arabicScore': cleanSubject == 'arabic' ? scoreEarned : 0,
          'computerScore': cleanSubject == 'computer' ? scoreEarned : 0,
          'englishScore': cleanSubject == 'english' ? scoreEarned : 0,
          'quizzesCount': 1,
          'highestPercentage': scorePercentage,
          'lastActive': FieldValue.serverTimestamp(),
        };
        await docRef.set(initialData, SetOptions(merge: true));
      } else {
        final data = docSnapshot.data() as Map<String, dynamic>? ?? {};
        final currentHighest = ((data['highestPercentage'] ?? 0.0) as num).toDouble();
        final newHighest = scorePercentage > currentHighest ? scorePercentage : currentHighest;

        final Map<String, dynamic> updateData = {
          'name': realName,
          'totalScore': FieldValue.increment(scoreEarned),
          'quizzesCount': FieldValue.increment(1),
          'highestPercentage': newHighest,
          'lastActive': FieldValue.serverTimestamp(),
        };

        if (userAvatarId != null) updateData['avatarId'] = userAvatarId;
        if (userGender != null) updateData['gender'] = userGender;
        updateData['isPremium'] = userIsPremium;

        if (photoUrl != null && photoUrl.isNotEmpty) {
          updateData['photoUrl'] = photoUrl;
        }

        if (cleanSubject == 'arabic') {
          updateData['arabicScore'] = FieldValue.increment(scoreEarned);
        }
        if (cleanSubject == 'computer') {
          updateData['computerScore'] = FieldValue.increment(scoreEarned);
        }
        if (cleanSubject == 'english') {
          updateData['englishScore'] = FieldValue.increment(scoreEarned);
        }

        await docRef.set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      print('⚠️ Leaderboard update error: $e');
    }
  }

  /// تطبيع مفتاح المادة
  static String _normalizeSubjectKey(String? key) {
    if (key == null) return 'general';
    final lower = key.toLowerCase();
    if (lower.contains('arab') || lower.contains('عرب')) return 'arabic';
    if (lower.contains('comp') || lower.contains('حاس')) return 'computer';
    if (lower.contains('eng') || lower.contains('إنج') || lower.contains('انج')) return 'english';
    return 'general';
  }

  /// ✅ جلب قائمة المتصدرين مع الفرز حسب المادة
  static Stream<List<LeaderboardEntry>> getLeaderboardStream({
    String subject = 'all',
    int limit = 50,
  }) {
    return _leaderboardRef
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LeaderboardEntry.fromFirestore(doc))
              .toList();

          if (subject != 'all') {
            // فرز بحسب نقاط المادة المختارة
            final filtered = list.where((e) => e.getScoreForSubject(subject) > 0).toList();
            filtered.sort((a, b) {
              final scoreB = b.getScoreForSubject(subject);
              final scoreA = a.getScoreForSubject(subject);
              return scoreB.compareTo(scoreA);
            });
            return filtered;
          }

          return list;
        });
  }
}
