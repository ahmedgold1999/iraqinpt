// lib/models/app_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool isPremium;
  final String activationCode;
  final DateTime? expiryDate;
  final List<String> deviceIds; // ✅ إضافة قائمة معرفات الأجهزة

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isPremium,
    required this.activationCode,
    this.expiryDate,
    this.deviceIds = const [], // ✅ افتراضي فارغ
  });

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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      activationCode: activationCode ?? this.activationCode,
      expiryDate: expiryDate ?? this.expiryDate,
      deviceIds: deviceIds ?? this.deviceIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': email.split('@').first,
      'role': role.name,
      'isPremium': isPremium,
      'activationCode': activationCode,
      'expiryDate': expiryDate,
      'deviceIds': deviceIds, // ✅ حفظ الأجهزة
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
      }
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
      isPremium: data['isPremium'] is bool ? data['isPremium'] as bool : false,
      activationCode: data['activationCode']?.toString() ?? '',
      expiryDate: expiryDate,
      deviceIds: deviceIds,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, isPremium: $isPremium)';
  }
}