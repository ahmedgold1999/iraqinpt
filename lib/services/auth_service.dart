// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _webClientId = '527094263196-em54nrkgk7bbll25anr1drkegv7f36h6.apps.googleusercontent.com';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: _webClientId,
  );
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

  /// تسجيل الدخول عبر جوجل
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // تنظيف أي جلسة سابقة معلقة لضمان عرض نافذة اختيار الحساب
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          print('⚠️ تنبيه أثناء الخروج المسبق من GoogleSignIn: $e');
        }

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;
      if (user == null) return null;

      UserModel? userModel = await _getUserFromFirestore(user.uid);
      if (userModel == null) {
        String displayName = user.displayName ?? '';
        if (displayName.trim().isEmpty) {
          displayName = (user.email ?? user.uid).split('@').first;
        }

        userModel = UserModel(
          uid: user.uid,
          name: displayName,
          email: user.email ?? '',
          role: UserRole.student,
          isPremium: false,
          activationCode: '',
          expiryDate: null,
        );
        final userData = userModel.toMap();
        String rawUsername = (user.email ?? user.uid).split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
        if (rawUsername.isEmpty) {
          rawUsername = 'user_${user.uid.substring(0, 6)}';
        }
        userData['username'] = rawUsername;
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['authMethod'] = 'google';
        await _firestore.collection(_usersCollection).doc(user.uid).set(userData);
      }
      return userModel;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول عبر جوجل: $e');
      rethrow;
    }
  }

  /// تسجيل الدخول عبر آبل (Apple Sign In)
  Future<UserModel?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      UserModel? userModel = await _getUserFromFirestore(user.uid);
      if (userModel == null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          name: '${appleCredential.givenName ?? ""} ${appleCredential.familyName ?? ""}'.trim(),
          email: user.email ?? '',
          role: UserRole.student,
          isPremium: false,
          activationCode: '',
          expiryDate: null,
        );
        if (newUser.name.isEmpty) newUser = newUser.copyWith(name: 'مستخدم Apple');

        final userData = newUser.toMap();
        userData['username'] = (user.email ?? user.uid).split('@').first;
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['authMethod'] = 'apple';
        await _firestore.collection(_usersCollection).doc(user.uid).set(userData);
        userModel = newUser;
      }
      return userModel;
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول عبر Apple: $e');
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
      userData['password'] = password.trim();
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
      if (!doc.exists) {
        print('⚠️ لا يوجد مستخدم في Firestore: $uid');
        return null;
      }
      return UserModel.fromMap(doc.data()!);
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
        final userModel = UserModel.fromMap(doc.data()!);
        _cachedUser = userModel;
        return userModel;
      });
    });
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
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