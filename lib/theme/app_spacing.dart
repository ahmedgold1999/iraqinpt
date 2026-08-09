import 'package:flutter/material.dart';

/// المسافات والباذينج الموحد في التطبيق
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // الحواف القياسية
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
}
