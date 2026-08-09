import 'package:flutter/material.dart';

/// نظام الألوان الموحد والمستوحى من هوية iOS الحديثة والهادئة
class AppColors {
  // الخلفيات والأسطح
  static const Color background = Color(0xFFF8FAFC); // أبيض مائل للرمادي الناعم
  static const Color surface = Color(0xFFFFFFFF); // أبيض نقي للكروت
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // رمادي خفيف جداً
  
  // الألوان الرئيسية
  static const Color primary = Color(0xFF2563EB); // أزرق ملكي مريح
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF); // خلفية اختيار ناعمة
  
  // الألوان الثانوية
  static const Color secondary = Color(0xFF4F46E5); // إنديجو ناعم
  static const Color accent = Color(0xFF0EA5E9); // أزرق سماوي
  
  // النصوص
  static const Color textPrimary = Color(0xFF0F172A); // رمادي داكن فاخر بديل الأسود الصريح
  static const Color textSecondary = Color(0xFF64748B); // رمادي متوسط للنصوص الفرعية
  static const Color textMuted = Color(0xFF94A3B8); // رمادي فاتح للتلميحات
  
  // الحدود والفاصل
  static const Color border = Color(0xFFE2E8F0); // حد خفيف جداً
  static const Color borderLight = Color(0xFFF1F5F9);
  
  // الحالات (Success, Warning, Error, Info)
  static const Color success = Color(0xFF10B981); // أخضر زمردي هادئ
  static const Color successLight = Color(0xFFECFDF5);
  
  static const Color warning = Color(0xFFF59E0B); // برتقالي ذهبي ناعم
  static const Color warningLight = Color(0xFFFFFBEB);
  
  static const Color error = Color(0xFFEF4444); // أحمر لطيف
  static const Color errorLight = Color(0xFFFEF2F2);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  
  // حالات التعطيل والظلال
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledText = Color(0xFF94A3B8);
  static const Color shadow = Color(0x0C0F172A); // ظل خفيف وميكروسكوبي
}
