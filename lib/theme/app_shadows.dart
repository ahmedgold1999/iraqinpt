import 'package:flutter/material.dart';
import 'app_colors.dart';

/// الظلال الناعمة جداً بنمط iOS
class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> none = [];
}
