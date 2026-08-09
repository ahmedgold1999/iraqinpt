import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // التحقق من إمكانية الوصول للمادة
  bool canAccessSubject(String subjectName, bool isPremium) {
    if (subjectName == 'اللغة العربية') return true;
    return isPremium;
  }

  // تفعيل الاشتراك (التفعيل أصبح يتم مباشرة عن طريق الإدمن)
  Future<bool> activateSubscription(String code) async {
    try {
      var codeDoc = await _db.collection('activation_codes').doc(code).get();

      if (codeDoc.exists && codeDoc.data()?['isUsed'] == false) {
        String uid = _auth.currentUser?.uid ?? '';
        if (uid.isEmpty) return false;
        
        await _db.collection('users').doc(uid).update({
          'isPremium': true,
          'activationCode': code,
          'expiryDate': DateTime.now().add(const Duration(days: 365)),
        });

        await _db.collection('activation_codes').doc(code).update({
          'isUsed': true,
          'usedBy': uid,
          'usedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Activation error: $e');
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

  // إيقاف الاشتراك
  Future<void> deactivateSubscription(String userId) async {
    await _db.collection('users').doc(userId).update({
      'isPremium': false,
      'expiryDate': null,
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
