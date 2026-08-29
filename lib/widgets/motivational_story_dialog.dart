import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/motivational_service.dart';

class MotivationalStoryDialog extends StatefulWidget {
  final AcademicQuote quote;

  const MotivationalStoryDialog({
    super.key,
    required this.quote,
  });

  static Future<void> show(BuildContext context, AcademicQuote quote) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => MotivationalStoryDialog(quote: quote),
    );
  }

  @override
  State<MotivationalStoryDialog> createState() => _MotivationalStoryDialogState();
}

class _MotivationalStoryDialogState extends State<MotivationalStoryDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareStoryImage() async {
    setState(() => _isSharing = true);
    try {
      // 1. التقاط الـ RepaintBoundary بجودة عالية جداً (Retina 3.0)
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. الحفظ في ملف مؤقت
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/inpt_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // 3. مشاركة الصورة عبر share_plus
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '💡 "${widget.quote.text}"\n— تطبيق دليل الامتحان الوطني العراقي 🎓',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Story share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إنشاء صورة الستوري'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط الأزرار العلوي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFACC15), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'معاينة ستوري انستغرام وفيسبوك',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),

          // بطاقة الستوري بنسبة 9:16 قابلة للالتقاط
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: _buildStoryCard(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // زر التصدير والمشاركة الرئيسي
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C), // لون انستغرام المتوهج
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: const Color(0xFFE1306C).withValues(alpha: 0.4),
              ),
              onPressed: _isSharing ? null : _shareStoryImage,
              icon: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSharing ? 'جاري تجهيز الصورة...' : 'مشاركة كستوري (انستغرام / فيسبوك / واتساب)',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= تصميم بطاقة الستوري الملكية =================
  Widget _buildStoryCard() {
    return Container(
      width: 320,
      constraints: const BoxConstraints(minHeight: 520),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF060B18),
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF0A0F1D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFACC15).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. الترويسة العلوية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFACC15).withValues(alpha: 0.18),
                  const Color(0xFF6366F1).withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFFFACC15), size: 16),
                const SizedBox(width: 6),
                Text(
                  'ومضة أكاديمية • دراسات عليا',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. أيقونة الاقتباس الضخمة المتوهجة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFFACC15),
              size: 32,
            ),
          ),

          const SizedBox(height: 18),

          // 3. نص الاقتباس الأكاديمي
          Text(
            '"${widget.quote.text}"',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.7,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 4. اسم القائل / المرجع مع شارة التوثيق
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(
                  widget.quote.author,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFACC15),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // فاصل زخرفي
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. الفوتر: اسم التطبيق والأيقونة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFACC15), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.school_rounded,
                      color: Color(0xFFFACC15),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دليل الامتحان الوطني العراقي',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'المنصة الأكاديمية الأولى للدراسات العليا 🇮🇶',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 6. شارة المتجر
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!kIsWeb && Platform.isAndroid)
                _buildStoreBadge(
                  icon: FontAwesomeIcons.googlePlay,
                  line1: 'متوفر على',
                  line2: 'Google Play',
                  iconColor: const Color(0xFF00E676),
                ),
              if (!kIsWeb && Platform.isIOS)
                _buildStoreBadge(
                  icon: FontAwesomeIcons.apple,
                  line1: 'متوفر على',
                  line2: 'App Store',
                  iconColor: Colors.white,
                ),
              if (kIsWeb)
                _buildStoreBadge(
                  icon: Icons.language,
                  line1: 'المنصة التعليمية',
                  line2: 'Web App',
                  iconColor: Colors.white,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreBadge({
    required dynamic icon,
    required String line1,
    required String line2,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line1,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 7.5,
                  color: Colors.white60,
                ),
              ),
              Text(
                line2,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
