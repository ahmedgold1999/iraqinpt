// lib/models/app_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/config_service.dart';

enum UserRole { student, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool _rawPremium;
  final String activationCode;
  final DateTime? expiryDate;
  final List<String> deviceIds; // ✅ إضافة قائمة معرفات الأجهزة
  final String gender; // 'male', 'female', 'unspecified'
  final String avatarId; // e.g. 'boy_1', 'girl_1', etc.

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required bool isPremium,
    required this.activationCode,
    this.expiryDate,
    this.deviceIds = const [], // ✅ افتراضي فارغ
    this.gender = 'male',
    this.avatarId = 'boy_1',
  }) : _rawPremium = isPremium;

  /// 🍏 النسخة المميزة: يتم تفعيلها تلقائياً على iOS أثناء وضع مراجعة أبل
  bool get isPremium {
    if (ConfigService().isIosReviewMode && defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
    return _rawPremium;
  }

  String get roleName => role.name;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? isPremium,
    String? activationCode,
    DateTime? expiryDate,
    List<String>? deviceIds,
    String? gender,
    String? avatarId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isPremium: isPremium ?? _rawPremium,
      activationCode: activationCode ?? this.activationCode,
      expiryDate: expiryDate ?? this.expiryDate,
      deviceIds: deviceIds ?? this.deviceIds,
      gender: gender ?? this.gender,
      avatarId: avatarId ?? this.avatarId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'isPremium': _rawPremium,
      'activationCode': activationCode,
      'expiryDate': expiryDate,
      'deviceIds': deviceIds, // ✅ حفظ الأجهزة
      'gender': gender,
      'avatarId': avatarId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    dynamic roleData = data['role'];
    UserRole userRole;

    if (roleData == null) {
      userRole = UserRole.student;
    } else if (roleData is String) {
      String roleStr = roleData.toLowerCase().trim();
      switch (roleStr) {
        case 'admin':
          userRole = UserRole.admin;
          break;
        default:
          userRole = UserRole.student;
      }
    } else if (roleData is int) {
      switch (roleData) {
        case 2:
        case 1:
          userRole = UserRole.admin;
          break;
        default:
          userRole = UserRole.student;
      }
    } else {
      userRole = UserRole.student;
    }

    DateTime? expiryDate;
    if (data['expiryDate'] != null) {
      if (data['expiryDate'] is Timestamp) {
        expiryDate = (data['expiryDate'] as Timestamp).toDate();
      } else if (data['expiryDate'] is String) {
        expiryDate = DateTime.tryParse(data['expiryDate'] as String);
      } else if (data['expiryDate'] is int) {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(data['expiryDate'] as int);
      }
    }

    bool isPremium = data['isPremium'] is bool ? data['isPremium'] as bool : false;

    // 🔥 فحص انتهاء صلاحية الاشتراك تلقائياً:
    // إذا كان الحساب مميزاً ولكن تاريخ انتهاء الصلاحية محدد وقد مضى، تتوقف النسخة المميزة فوراً!
    if (isPremium && expiryDate != null && DateTime.now().isAfter(expiryDate)) {
      isPremium = false;
    }

    List<String> deviceIds = [];
    if (data['deviceIds'] != null) {
      deviceIds = List<String>.from(data['deviceIds']);
    }

    return UserModel(
      uid: data['uid']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '${data['username']?.toString() ?? ''}@ahmeed.inpt',
      role: userRole,
      isPremium: isPremium,
      activationCode: data['activationCode']?.toString() ?? '',
      expiryDate: expiryDate,
      deviceIds: deviceIds,
      gender: data['gender']?.toString() ?? 'male',
      avatarId: data['avatarId']?.toString() ?? (data['gender'] == 'female' ? 'girl_1' : 'boy_1'),
    );
  }

  /// هل الحساب مميز ونشط حالياً
  bool get hasActiveSubscription => isPremium && (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  /// هل انتهت صلاحية الاشتراك
  bool get isSubscriptionExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);

  /// عدد الأيام المتبقية على انتهاء الصلاحية
  int get remainingDays {
    if (expiryDate == null) return isPremium ? 9999 : 0;
    final now = DateTime.now();
    if (now.isAfter(expiryDate!)) return 0;
    return expiryDate!.difference(now).inDays;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, isPremium: $isPremium, expiryDate: $expiryDate)';
  }
}