import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ✅ ثيم أبل الفاخر (iOS System Luxury Theme + الخط الكوفي Noto Kufi Arabic)
  static final luxuryTheme = ThemeData(
    useMaterial3: true,
    primaryColor: const Color(0xFF2563EB), // أزرق ملكي زاهي
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // خلفية أبل البيضاء الصافية
    fontFamily: GoogleFonts.notoKufiArabic().fontFamily,
    textTheme: GoogleFonts.notoKufiArabicTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF00C853), // أخضر زمردي
      tertiary: const Color(0xFFF59E0B), // ذهبي فاخر
      surface: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: GoogleFonts.notoKufiArabic(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
        textStyle: GoogleFonts.notoKufiArabic(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
  );
}
