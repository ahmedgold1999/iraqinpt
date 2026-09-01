import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';
  
  // ذاكرة مؤقتة للمستخدم لتوفير قراءات Firestore
  static UserModel? _cachedUser;

  /// تهيئة Firebase مع إعدادات Persistence
  Future<void> initialize() async {
    try {
      await _auth.setPersistence(Persistence.LOCAL);
      print('✅ تم ضبط حفظ الجلسات محلياً');
    } catch (e) {
      print('⚠️ تعذر ضبط Persistence: $e');
    }

    final user = _auth.currentUser;
    print('👤 المستخدم الحالي بعد التهيئة: ${user?.uid ?? "لا يوجد"}');
  }

  AuthService() {
    // مراقبة حالة المستخدم
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('🔴 لا يوجد مستخدم مسجل حاليًا');
      } else {
        print('🟢 مستخدم مسجل: ${user.uid}');
      }
    });
  }

  /// الحصول على المستخدم الحالي
  Future<UserModel?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      if (_cachedUser != null && !forceRefresh && _cachedUser!.uid == user.uid) {
        return _cachedUser;
      }
      
      _cachedUser = await _getUserFromFirestore(user.uid);
      return _cachedUser;
    } catch (e) {
      print('❌ خطأ في جلب بيانات المستخدم: $e');
      return null;
    }
  }

  /// تسجيل الدخول
  Future<UserModel?> signIn(String username, String password) async {
    try {
      final email = '$username@ahmeed.inpt';
      print('🔐 محاولة تسجيل الدخول: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      final userModel = await _getUserFromFirestore(user.uid);
      return userModel;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول: $e');
      rethrow;
    }
  }

  /// التحقق من وجود اسم كامل (أمن واقتصادي)
  Future<bool> checkFullNameExists(String fullName) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('name', isEqualTo: fullName.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ خطأ في التحقق من وجود الاسم الكامل: $e');
      return false;
    }
  }

  /// التحقق من وجود اسم مستخدم
  Future<bool> checkUsernameExists(String username) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ خطأ في التحقق من وجود المستخدم: $e');
      return false;
    }
  }

  /// التحقق من تفرد البيانات (استعلامات محددة وليس جلب الكل)
  Future<Map<String, bool>> checkUserUniqueness(String username, String fullName) async {
    Map<String, bool> result = {
      'usernameExists': false,
      'fullNameExists': false,
    };

    try {
      // استعلام محدد لاسم المستخدم
      final usernameQuery = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();
      result['usernameExists'] = usernameQuery.docs.isNotEmpty;

      // استعلام محدد للاسم الكامل
      final nameQuery = await _firestore
          .collection(_usersCollection)
          .where('name', isEqualTo: fullName.trim())
          .limit(1)
          .get();
      result['fullNameExists'] = nameQuery.docs.isNotEmpty;

    } catch (e) {
      print('❌ خطأ في التحقق من تفرد البيانات: $e');
    }

    return result;
  }

  /// تغيير اسم الطالب مع التحقق من عدم تكراره ومزامنته مع لوحة الشرف
  Future<void> updateStudentName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول أولاً';

      final trimmedName = newName.trim();
      if (trimmedName.isEmpty) throw 'يرجى إدخال اسم صحيح';
      if (trimmedName.length < 3) throw 'الاسم قصير جداً، يرجى كتابة اسم ثلاثي أو ثنائي واضح';

      // فحص هل الاسم مستخدم من قبل طالب آخر
      final query = await _firestore
          .collection(_usersCollection)
          .where('name', isEqualTo: trimmedName)
          .limit(2)
          .get();

      final isTakenByOther = query.docs.any((doc) => doc.id != user.uid);
      if (isTakenByOther) {
        throw 'عذراً، هذا الاسم مسجل مسبقاً لطالب آخر. يرجى كتابة اسم ثلاثي أو إضافة اللقب لتمييزه.';
      }

      // تحديث الاسم في وثيقة المستخدم
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'name': trimmedName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // تحديث الاسم في لوحة المتصدرين إن وجد
      try {
        await _firestore.collection('leaderboard').doc(user.uid).set({
          'name': trimmedName,
        }, SetOptions(merge: true));
      } catch (_) {}

      // تحديث الاسم في Firebase Auth profile
      try {
        await user.updateDisplayName(trimmedName);
      } catch (_) {}

      _cachedUser = null;
    } catch (e) {
      print('❌ خطأ في تحديث الاسم: $e');
      rethrow;
    }
  }

  /// حذف الحساب (متطلب إجباري من أبل)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. حذف البيانات من Firestore أولاً
      await _firestore.collection(_usersCollection).doc(user.uid).delete();

      // 2. حذف الحساب من Firebase Auth
      // ملاحظة: قد يتطلب إعادة تسجيل دخول إذا كانت الجلسة قديمة
      await user.delete();
      
      _cachedUser = null;
      print('🗑️ تم حذف الحساب والبيانات بنجاح');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('⚠️ يتطلب حذف الحساب تسجيل دخول حديث');
        throw 'يرجى تسجيل الخروج والدخول مرة أخرى ثم المحاولة لحذف الحساب للأمان.';
      }
      rethrow;
    } catch (e) {
      print('❌ خطأ في حذف الحساب: $e');
      rethrow;
    }
  }

  /// إنشاء حساب جديد
  Future<UserModel?> signUp(String username, String password, String name) async {
    try {
      final email = '$username@ahmeed.inpt';
      print('📝 محاولة إنشاء حساب: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email,
        role: UserRole.student,
        isPremium: false,
        activationCode: '',
        expiryDate: null,
      );

      final userData = userModel.toMap();
      userData['username'] = username.toLowerCase().trim();
      userData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(user.uid).set(userData);
      print('✅ تم إنشاء الحساب بنجاح: ${user.uid}');
      return userModel;
    } catch (e) {
      print('❌ خطأ في إنشاء الحساب: $e');
      rethrow;
    }
  }

  /// جلب بيانات المستخدم من Firestore
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        print('⚠️ لا يوجد مستخدم في Firestore: $uid');
        return null;
      }
      final data = doc.data()!;
      final userModel = UserModel.fromMap(data);
      // إذا كان مسجلاً بالداتابيز كـ Premium ولكن انتهت الصلاحية، نحدث الداتابيز
      if (data['isPremium'] == true && !userModel.isPremium) {
        _firestore.collection(_usersCollection).doc(uid).update({'isPremium': false}).catchError((_) => null);
      }
      return userModel;
    } catch (e) {
      print('❌ خطأ في جلب بيانات المستخدم من Firestore: $e');
      rethrow;
    }
  }

  /// تحديث جنس وأفاتار المستخدم وحفظهما بالسيرفر ولوحة الشرف
  Future<void> updateGenderAndAvatar(String gender, String avatarId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final updateData = {
        'gender': gender,
        'avatarId': avatarId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_usersCollection).doc(user.uid).set(updateData, SetOptions(merge: true));

      // مزامنة فورية مع لوحة الشرف
      try {
        await _firestore.collection('leaderboard').doc(user.uid).set({
          'gender': gender,
          'avatarId': avatarId,
        }, SetOptions(merge: true));
      } catch (_) {}

      _cachedUser = null;
    } catch (e) {
      print('❌ خطأ في تحديث الأفاتار: $e');
      rethrow;
    }
  }

  /// تيار بيانات المستخدم المباشر والمتزامن لحظياً مع التغييرات
  Stream<UserModel?> get userData {
    return _auth.authStateChanges().asyncExpand((User? firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        final data = doc.data()!;
        final userModel = UserModel.fromMap(data);
        if (data['isPremium'] == true && !userModel.isPremium) {
          _firestore.collection(_usersCollection).doc(firebaseUser.uid).update({'isPremium': false}).catchError((_) => null);
        }
        _cachedUser = userModel;
        return userModel;
      });
    });
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _cachedUser = null; // تنظيف الذاكرة المؤقتة
      print('👋 تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
      _cachedUser = null;
    }
  }

  /// هل المستخدم مسجل دخول؟
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// التحقق من وجود جلسة نشطة
  Future<UserModel?> getActiveUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      await user.getIdToken(true);
      final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      await _auth.signOut();
      return null;
    }
  }
}