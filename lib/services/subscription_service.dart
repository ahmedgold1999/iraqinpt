import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // التحقق من إمكانية الوصول للمادة
  bool canAccessSubject(String subjectName, bool isPremium) {
    if (subjectName == 'اللغة العربية') return true;
    return isPremium;
  }

  // ✅ التحقق من التجربة المجانية عبر Firestore (مرتبطة بالحساب وليس الجهاز)
  Future<bool> hasTakenFreeArabicTrial() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return false;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['freeArabicTrialUsed'] == true;
    } catch (e) {
      // إذا فشل الاتصال، نمنع التجربة احتياطاً
      return true;
    }
  }

  // ✅ تسجيل استهلاك التجربة المجانية في Firestore (لا يمكن مسحها بمسح بيانات التطبيق)
  Future<void> markFreeArabicTrialUsed() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      await _db.collection('users').doc(uid).update({
        'freeArabicTrialUsed': true,
        'freeArabicTrialDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking trial used: $e');
    }
  }


  // تفعيل الاشتراك مع حماية من السباق والتكرار (Atomic Transaction)
  Future<bool> activateSubscription(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;

    final codeRef = _db.collection('activation_codes').doc(cleanCode);
    final userRef = _db.collection('users').doc(uid);

    try {
      final result = await _db.runTransaction<bool>((transaction) async {
        final codeSnapshot = await transaction.get(codeRef);

        if (!codeSnapshot.exists) {
          return false;
        }

        final data = codeSnapshot.data();
        if (data == null || data['isUsed'] == true) {
          return false;
        }

        final int durationDays = (data['durationDays'] is int)
            ? data['durationDays']
            : (data['days'] is int ? data['days'] : 365);

        final expiryDate = DateTime.now().add(Duration(days: durationDays));

        // 1. قفل الكود فوراً
        transaction.update(codeRef, {
          'isUsed': true,
          'usedBy': uid,
          'usedAt': FieldValue.serverTimestamp(),
        });

        // 2. ترقية حساب المستخدم
        transaction.update(userRef, {
          'isPremium': true,
          'activationCode': cleanCode,
          'expiryDate': expiryDate,
        });

        return true;
      });

      return result;
    } catch (e) {
      print('Activation transaction error: $e');
      return false;
    }
  }

  // تفعيل يدوي من قبل الإدمن
  Future<void> manualActivate(String userId, int days) async {
    try {
      DateTime? expiryDate;
      if (days > 0) {
        expiryDate = DateTime.now().add(Duration(days: days));
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 3650));
      }

      await _db.collection('users').doc(userId).update({
        'isPremium': true,
        'expiryDate': expiryDate,
        'activationCode': 'MANUAL_ADMIN',
      });

      // ✅ إرسال إشعار تلقائي
      _sendSystemNotification(userId, 'تم تفعيل الاشتراك', 'مبروك! تم تفعيل حسابك المميز بنجاح.');
    } catch (e) {
      throw Exception('فشل التفعيل اليدوي: $e');
    }
  }

  // إيقاف الاشتراك عند انتهاء الصلاحية
  Future<void> deactivateSubscription(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isPremium': false,
    });
    
    _sendSystemNotification(userId, 'انتهى الاشتراك', 'لقد انتهت فترة اشتراكك المميز. يمكنك التجديد الآن.');
  }

  // إرسال إشعار داخلي
  void _sendSystemNotification(String userId, String title, String body) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'system',
    });
  }
}
