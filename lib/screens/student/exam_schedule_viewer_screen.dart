import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamScheduleViewerScreen extends StatefulWidget {
  const ExamScheduleViewerScreen({super.key});

  @override
  State<ExamScheduleViewerScreen> createState() => _ExamScheduleViewerScreenState();
}

class _ExamScheduleViewerScreenState extends State<ExamScheduleViewerScreen> {
  final TransformationController _transformationController = TransformationController();
  static const String _examImageUrl = 'assets/icons/exam_schedule.png';
  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFFACC15);

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'جدول الامتحانات الرسمي',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _gold),
            tooltip: 'إعادة ضبط الحجم',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // شريط إرشادي علوي خفيف
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pinch_rounded, size: 16, color: _gold),
                  const SizedBox(width: 8),
                  Text(
                    'يمكنك التكبير والتصغير بإصبعين أو التمرير لمعاينة تفاصيل الجدول',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // عارض الجدول التفاعلي بتقنية InteractiveViewer
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 6.0,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: Image.asset(
                    _examImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'تعذر تحميل صورة الجدول',
                            style: TextStyle(color: Colors.white70, fontFamily: 'Tajawal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
