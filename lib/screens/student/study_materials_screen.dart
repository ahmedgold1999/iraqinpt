import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';
import '../../models/app_models.dart';
import '../../widgets/luxury_loading.dart';

// ==================== نماذج البيانات ====================
class StudyMaterial {
  final String id;
  final String name;
  final String description;
  final String pdfUrl;
  final String category;
  final DateTime createdAt;
  final String? fileSize;
  final int? pageCount;

  StudyMaterial({
    required this.id,
    required this.name,
    required this.description,
    required this.pdfUrl,
    required this.category,
    required this.createdAt,
    this.fileSize,
    this.pageCount,
  });

  factory StudyMaterial.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyMaterial(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      category: data['category'] ?? 'computer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileSize: data['fileSize'],
      pageCount: data['pageCount'] is int
          ? data['pageCount']
          : (data['pageCount'] != null ? int.tryParse(data['pageCount'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'pdfUrl': pdfUrl,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'fileSize': fileSize,
    'pageCount': pageCount,
  };

  factory StudyMaterial.fromMap(Map<String, dynamic> data) => StudyMaterial(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    pdfUrl: data['pdfUrl'] ?? '',
    category: data['category'] ?? 'computer',
    createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    fileSize: data['fileSize'],
    pageCount: data['pageCount'] is int
        ? data['pageCount']
        : (data['pageCount'] != null ? int.tryParse(data['pageCount'].toString()) : null),
  );
}

class GoogleFormItem {
  final String id;
  final String name;
  final String description;
  final String formUrl;
  final String category;
  final DateTime createdAt;

  GoogleFormItem({
    required this.id,
    required this.name,
    required this.description,
    required this.formUrl,
    required this.category,
    required this.createdAt,
  });

  factory GoogleFormItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoogleFormItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      formUrl: data['formUrl'] ?? '',
      category: data['category'] ?? 'computer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'formUrl': formUrl,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GoogleFormItem.fromMap(Map<String, dynamic> data) => GoogleFormItem(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    description: data['description'] ?? '',
    formUrl: data['formUrl'] ?? '',
    category: data['category'] ?? 'computer',
    createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

// ==================== نافذة الاشتراك المطلوب ====================
class SubscriptionRequiredDialog extends StatelessWidget {
  const SubscriptionRequiredDialog({super.key});

  static const _gold = Color(0xFFFACC15);

  @override
  Widget build(BuildContext context) {
    if (ConfigService().isReviewMode) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF60A5FA), size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تنبيه دراسي 📚',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'هذه المادة فقط للطلاب المخصصين لها',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220).withOpacity(0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFACC15), Color(0xFFFB7185), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'اشتراك مطلوب!',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'الملازم والفورمات التدريبية متاحة فقط للمشتركين في الباقات المميزة.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.2),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.subscription);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'الاشتراك الآن',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== رسم وتظليل قلم التمييز الأصفر ====================
class HighlightStroke {
  final int page;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  HighlightStroke({
    required this.page,
    required this.points,
    this.color = const Color(0x66FFEB3B), // أصفر شفاف كقلم التمييز
    this.strokeWidth = 22.0,
  });
}

class HighlighterPainter extends CustomPainter {
  final List<HighlightStroke> strokes;
  final List<Offset> activePoints;
  final Color activeColor;
  final double activeWidth;

  HighlighterPainter({
    required this.strokes,
    required this.activePoints,
    this.activeColor = const Color(0x66FFEB3B),
    this.activeWidth = 22.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // رسم التحديدات السابقة
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // رسم السكتة الحالية أثناء سحب الإصبع
    if (activePoints.isNotEmpty) {
      final paint = Paint()
        ..color = activeColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = activeWidth
        ..style = PaintingStyle.stroke;

      if (activePoints.length == 1) {
        canvas.drawCircle(activePoints.first, activeWidth / 2, paint);
      } else {
        final path = Path();
        path.moveTo(activePoints.first.dx, activePoints.first.dy);
        for (int i = 1; i < activePoints.length; i++) {
          path.lineTo(activePoints[i].dx, activePoints[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HighlighterPainter oldDelegate) => true;
}

// ==================== واجهة تفاصيل وغلاف الملزمة الفاخرة ====================
class MaterialDetailScreen extends StatefulWidget {
  final StudyMaterial material;
  final bool isDownloaded;
  final String? localFilePath;
  final bool isPremium;
  final VoidCallback onDownloadRequested;
  final Function(String path, bool isLocal) onReadRequested;

  const MaterialDetailScreen({
    super.key,
    required this.material,
    required this.isDownloaded,
    this.localFilePath,
    required this.isPremium,
    required this.onDownloadRequested,
    required this.onReadRequested,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  static const _gold = Color(0xFFFACC15);
  String _fileSizeStr = 'جاري الحساب...';
  int? _pageCount;
  bool _isLoadingMeta = true;
  bool _isDownloaded = false;
  String? _localFilePath;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _isDownloaded = widget.isDownloaded;
    _localFilePath = widget.localFilePath;
    _fetchMetadata();
  }

  Future<void> _startDownload() async {
    if (_isDownloading || _isDownloaded) return;
    if (kIsWeb) {
      widget.onDownloadRequested();
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.05;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('\/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }

      final savePath = '\/\.pdf';
      final file = File(savePath);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.material.pdfUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && mounted) {
            setState(() {
              _downloadProgress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            });
          }
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isDownloaded = true;
              _localFilePath = savePath;
              _downloadProgress = 1.0;
            });
            widget.onDownloadRequested();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تحميل \ بنجاح للقراءة بدون إنترنت ✅',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تعذر إكمال التحميل: ', style: const TextStyle(fontFamily: 'Tajawal')),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _fetchMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPages = prefs.getInt('pages_${widget.material.id}');
    final cachedSize = prefs.getString('size_${widget.material.id}');

    if (cachedPages != null) {
      _pageCount = cachedPages;
    } else if (widget.material.pageCount != null) {
      _pageCount = widget.material.pageCount;
    }

    if (widget.isDownloaded && widget.localFilePath != null) {
      try {
        final file = File(widget.localFilePath!);
        if (await file.exists()) {
          final bytes = await file.length();
          _fileSizeStr = _formatBytes(bytes);
          await prefs.setString('size_${widget.material.id}', _fileSizeStr);
          if (mounted) setState(() => _isLoadingMeta = false);
          return;
        }
      } catch (_) {}
    }

    if (cachedSize != null) {
      _fileSizeStr = cachedSize;
      if (mounted) setState(() => _isLoadingMeta = false);
      return;
    }

    if (widget.material.fileSize != null && widget.material.fileSize!.isNotEmpty) {
      _fileSizeStr = widget.material.fileSize!;
      if (mounted) setState(() => _isLoadingMeta = false);
      return;
    }

    // استعلام سريع لخادم الملف لمعرفة الحجم الدقيق
    try {
      final cleanUrl = widget.material.pdfUrl.trim();
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        final res = await http.head(uri).timeout(const Duration(seconds: 4));
        final cl = res.headers['content-length'];
        if (cl != null) {
          final bytes = int.tryParse(cl) ?? 0;
          if (bytes > 0) {
            _fileSizeStr = _formatBytes(bytes);
            await prefs.setString('size_${widget.material.id}', _fileSizeStr);
          } else {
            _fileSizeStr = 'ملف عالي الدقة';
          }
        } else {
          _fileSizeStr = 'ملف رسمي معتمد';
        }
      }
    } catch (_) {
      _fileSizeStr = 'ملف PDF متكامل';
    }

    if (mounted) {
      setState(() => _isLoadingMeta = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'ملف متكامل';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميغابايت';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} كيلوبايت';
  }

  Color _getCategoryThemeColor() {
    switch (widget.material.category.toLowerCase()) {
      case 'computer':
        return const Color(0xFF2563EB);
      case 'arabic':
        return const Color(0xFFD97706);
      case 'english':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _getCategoryArabicName() {
    switch (widget.material.category.toLowerCase()) {
      case 'computer':
        return 'الحاسوب وتقنية المعلومات';
      case 'arabic':
        return 'اللغة العربية وفنونها';
      case 'english':
        return 'اللغة الإنكليزية';
      default:
        return 'المناهج العامة';
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.material.category.toLowerCase()) {
      case 'computer':
        return Icons.computer_rounded;
      case 'arabic':
        return Icons.menu_book_rounded;
      case 'english':
        return Icons.language_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryThemeColor();
    final catName = _getCategoryArabicName();
    final catIcon = _getCategoryIcon();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل وغلاف الملزمة',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ================= غلاف الملزمة ثلاثي الأبعاد الفاخر =================
            Center(
              child: Container(
                width: 195,
                height: 275,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      catColor,
                      catColor.withOpacity(0.85),
                      const Color(0xFF0B1220),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 16,
                      offset: const Offset(4, 8),
                    ),
                  ],
                  border: Border.all(
                    color: _gold.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // تأثير كعب الكتاب من اليسار (Spine effect)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.black.withOpacity(0.5),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),

                    // إطار ذهبي داخلي مزدوج
                    Positioned.fill(
                      left: 18,
                      top: 10,
                      right: 10,
                      bottom: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _gold.withOpacity(0.3), width: 1),
                        ),
                      ),
                    ),

                    // محتوى الغلاف
                    Positioned.fill(
                      left: 20,
                      top: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // شعار الامتحان الوطني العلوي
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _gold.withOpacity(0.5), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: _gold, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'دليل الامتحان الوطني',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: _gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                  border: Border.all(color: _gold.withOpacity(0.6), width: 1.2),
                                ),
                                child: Icon(catIcon, color: _gold, size: 24),
                              ),
                            ],
                          ),

                          // اسم الملزمة بمنتصف الغلاف
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                Text(
                                  widget.material.name,
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 40,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: _gold,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // شريط أسفل الغلاف
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'نسخة رسمية معتمدة 4K',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // شريط العلامة المرجعية المتدلي
                    Positioned(
                      top: 0,
                      right: 28,
                      child: Container(
                        width: 14,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.bookmark_rounded, color: Color(0xFF0F172A), size: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ================= اسم الملزمة والتصنيف =================
            Text(
              widget.material.name,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: catColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(catIcon, color: catColor, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        catName,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isDownloaded
                        ? const Color(0xFF10B981).withOpacity(0.18)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isDownloaded
                          ? const Color(0xFF10B981).withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isDownloaded ? Icons.check_circle_rounded : Icons.cloud_done_rounded,
                        color: widget.isDownloaded ? const Color(0xFF10B981) : Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isDownloaded ? 'محفوظة أوفلاين' : 'جاهزة للمطالعة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: widget.isDownloaded ? const Color(0xFF10B981) : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ================= بار التفاصيل الفخم =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // حجم الملف
                  Expanded(
                    child: _buildDetailStatTile(
                      icon: Icons.sd_storage_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      title: 'حجم الملف',
                      value: _fileSizeStr,
                    ),
                  ),
                  Container(width: 1, height: 42, color: Colors.white.withOpacity(0.1)),

                  // عدد الصفحات
                  Expanded(
                    child: _buildDetailStatTile(
                      icon: Icons.auto_stories_rounded,
                      iconColor: _gold,
                      title: 'عدد الصفحات',
                      value: _pageCount != null ? '$_pageCount صفحة' : 'شاملة الفصول',
                    ),
                  ),
                  Container(width: 1, height: 42, color: Colors.white.withOpacity(0.1)),

                  // التنسيق
                  Expanded(
                    child: _buildDetailStatTile(
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'التنسيق',
                      value: 'PDF عالي الدقة',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= نبذة عن الملزمة =================
            if (widget.material.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: _gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'عن هذا المحتوى الدراسي',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.material.description,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ================= مميزات القارئ المتكامل الذكي =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مزايا تجربة القراءة المتكاملة 🌟',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.auto_stories_rounded, 'تصفح كالكتاب (تقليب أفقي) أو تمرير متصل عمودياً'),
                  _buildFeatureRow(Icons.wb_sunny_rounded, 'أوضاع قراءة مريحة للعين: نهاري، دافئ (Sepia)، وليلي'),
                  _buildFeatureRow(Icons.border_color_rounded, 'قلم تظليل وتمييز أصفر ذكي لحفظ أهم النقاط بالملزمة'),
                  _buildFeatureRow(Icons.grid_view_rounded, 'شبكة تصفح سريعة لجميع الصفحات (3 في كل صف) وعلامات مرجعية'),
                  _buildFeatureRow(Icons.security_rounded, 'حماية متقدمة للمحتوى مشغلة تلقائياً بدون إعلانات'),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ================= أزرار الإجراءات الرئيسية =================
            // زر القراءة الفورية
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (_isDownloaded && (_localFilePath != null || widget.localFilePath != null)) {
                    widget.onReadRequested(_localFilePath ?? widget.localFilePath!, true);
                  } else {
                    widget.onReadRequested(widget.material.pdfUrl, false);
                  }
                },
                icon: const Icon(Icons.menu_book_rounded, size: 22),
                label: Text(
                  'قراءة الملزمة الآن',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // زر التحميل للأوفلاين مع أنميشن عداد التنزيل
            if (_isDownloading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(_gold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'جاري تحميل وحفظ الملزمة...',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // عداد النسبة المئوية المتحرك
                        Text(
                          '\%',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // شريط التقدم الانسيابي
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        minHeight: 7,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                      ),
                    ),
                  ],
                ),
              )
            else if (!_isDownloaded)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download_for_offline_rounded, color: _gold, size: 20),
                  label: const Text(
                    'تحميل الملزمة للمذاكرة بدون إنترنت ⚡',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'الملزمة محفوظة على هاتفك ومتاحة للقراءة أوفلاين ✅',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStatTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.notoKufiArabic(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== عارض PDF فاخر ومتكامل داخل التطبيق ====================
class LuxuryPdfViewerScreen extends StatefulWidget {
  final String title;
  final String fileOrUrl;
  final bool isLocalFile;
  final String? materialId;

  const LuxuryPdfViewerScreen({
    super.key,
    required this.title,
    required this.fileOrUrl,
    required this.isLocalFile,
    this.materialId,
  });

  @override
  State<LuxuryPdfViewerScreen> createState() => _LuxuryPdfViewerScreenState();
}

class _LuxuryPdfViewerScreenState extends State<LuxuryPdfViewerScreen> {
  PDFViewController? _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  String? _errorMessage;

  // إعدادات العرض الفاخرة
  bool _swipeHorizontal = false; // false = تتابع عمودي متصل، true = تقليب أفقي كالكتاب
  String _colorTheme = 'light'; // 'light' (فاتح), 'warm' (دافئ Sepia), 'night' (ليلي)
  bool _showBars = true; // وضع القراءة الغامرة

  // أدوات التكبير والتصغير
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;

  // قلم التظليل والتمييز الأصفر
  bool _isPenActive = false;
  final List<HighlightStroke> _highlights = [];
  final List<Offset> _activeStrokePoints = [];

  // العلامات المرجعية المحفوظة
  final Set<int> _bookmarkedPages = {};

  static const _gold = Color(0xFFFACC15);

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _loadSavedBookmarks();
    _preparePdfFile();
  }

  Future<void> _loadSavedBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'bookmarks_${widget.materialId ?? widget.title.hashCode}';
      final list = prefs.getStringList(key);
      if (list != null && mounted) {
        setState(() {
          _bookmarkedPages.addAll(list.map((e) => int.tryParse(e) ?? 0));
        });
      }
    } catch (_) {}
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'bookmarks_${widget.materialId ?? widget.title.hashCode}';
      await prefs.setStringList(key, _bookmarkedPages.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  Future<void> _enableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Error enabling screen protection: $e');
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _disableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Error disabling screen protection: $e');
    }
  }

  Future<void> _preparePdfFile() async {
    if (kIsWeb) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.isLocalFile && File(widget.fileOrUrl).existsSync()) {
      setState(() {
        _localFilePath = widget.fileOrUrl;
        _isLoading = false;
      });
      return;
    }

    // ملفات من المشروع assets
    if (widget.fileOrUrl.startsWith('assets/')) {
      try {
        final byteData = await rootBundle.load(widget.fileOrUrl);
        final dir = await getTemporaryDirectory();
        final fileName = widget.fileOrUrl.split('/').last;
        final tempFile = File('${dir.path}/asset_$fileName');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        if (mounted) {
          setState(() {
            _localFilePath = tempFile.path;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        if (kDebugMode) print('Asset PDF loading error: $e');
      }
    }

    // تنزيل مؤقت للرابط عن بعد
    try {
      final cleanUrl = widget.fileOrUrl.trim();
      final dir = await getTemporaryDirectory();
      final sanitizedName = widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\u0600-\u06FF]'), '_');
      final tempFile = File('${dir.path}/temp_${sanitizedName}_${cleanUrl.hashCode}.pdf');

      if (await tempFile.exists() && await tempFile.length() > 1000) {
        setState(() {
          _localFilePath = tempFile.path;
          _isLoading = false;
        });
        return;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(cleanUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && mounted) {
            setState(() {
              _downloadProgress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            });
          }
        },
        onDone: () async {
          await tempFile.writeAsBytes(bytes);
          if (mounted) {
            setState(() {
              _localFilePath = tempFile.path;
              _isLoading = false;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'تعذر تحميل ملف الملزمة: $e';
              _isLoading = false;
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ أثناء تجهيز الملف: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ================= وظائف التحكم =================
  void _resetZoom() {
    _pdfViewController?.setScale(1.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إعادة حجم الصفحة إلى الوضع الأصلي (100%)', style: TextStyle(fontFamily: 'Tajawal')),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSwipeMode() {
    setState(() {
      _swipeHorizontal = !_swipeHorizontal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _swipeHorizontal ? 'تم التبديل إلى: تقليب أفقي كالكتاب 📖' : 'تم التبديل إلى: تتابع عمودي متصل 📜',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(
                'اختر نمط إضاءة ولون الصفحة',
                style: GoogleFonts.notoKufiArabic(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildThemeOptionTile(
                id: 'light',
                title: 'الوضع الفاتح (النهاري الأصلي)',
                subtitle: 'صفحات بيضاء واضحة بأعلى دقة',
                icon: Icons.wb_sunny_rounded,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 10),
              _buildThemeOptionTile(
                id: 'warm',
                title: 'الوضع الدافئ (حماية العين - Sepia)',
                subtitle: 'إضاءة كهرمانية دافئة ومريحة للقراءة المطولة',
                icon: Icons.coffee_rounded,
                iconColor: const Color(0xFFD97706),
              ),
              const SizedBox(height: 10),
              _buildThemeOptionTile(
                id: 'night',
                title: 'الوضع الليلي (عالي التباين)',
                subtitle: 'خلفية سوداء لتقليل إجهاد العين بالظلام',
                icon: Icons.nightlight_round,
                iconColor: _gold,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _colorTheme == id;
    return InkWell(
      onTap: () {
        setState(() => _colorTheme = id);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _gold.withOpacity(0.12) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _gold : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? _gold : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: _gold, size: 20),
          ],
        ),
      ),
    );
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.pin_outlined, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'انتقال إلى صفحة معينة',
              style: GoogleFonts.notoKufiArabic(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل رقم الصفحة المراد الانتقال إليها مباشرة (1 - $_totalPages):',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'مثال: 15',
                hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Tajawal'),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final pageNum = int.tryParse(textController.text.trim());
              if (pageNum != null && pageNum >= 1 && pageNum <= _totalPages) {
                _pdfViewController?.setPage(pageNum - 1);
              }
              Navigator.pop(ctx);
            },
            child: const Text('انتقال فوري', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  // ================= منبثقة المحتويات والفهرس والعلامات وشبكة الصفحات =================
  void _showContentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetContext, setModalState) {
          return DefaultTabController(
            length: 2,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 12),

                  // عنوان النافذة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'محتويات الملزمة وتصفح الصفحات',
                          style: GoogleFonts.notoKufiArabic(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // شريط التبويب
                  TabBar(
                    indicatorColor: _gold,
                    labelColor: _gold,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        text: 'شبكة الصفحات ($_totalPages)',
                      ),
                      Tab(
                        icon: const Icon(Icons.bookmark_rounded, size: 18),
                        text: 'العلامات (${_bookmarkedPages.length})',
                      ),
                    ],
                  ),

                  // محتوى التبويبات
                  Expanded(
                    child: TabBarView(
                      children: [
                        // التبويب الأول: شبكة الصفحات (كل صف به 3 صفحات)
                        _totalPages == 0
                            ? const Center(child: CircularProgressIndicator(color: _gold))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: _totalPages,
                                itemBuilder: (context, index) {
                                  final isCurrent = index == _currentPage;
                                  final isBookmarked = _bookmarkedPages.contains(index);

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pdfViewController?.setPage(index);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? _gold.withOpacity(0.14)
                                            : const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isCurrent
                                              ? _gold
                                              : (isBookmarked ? Colors.amber.withOpacity(0.7) : Colors.white12),
                                          width: isCurrent ? 1.8 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // شكل الصفحة الفعلية ثلاثية الأبعاد لمحاكاة ورقة الكتاب
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isCurrent ? _gold : const Color(0xFFE2E8F0),
                                                  width: isCurrent ? 1.5 : 0.8,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isCurrent
                                                        ? _gold.withOpacity(0.35)
                                                        : Colors.black.withOpacity(0.18),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(5),
                                                child: Stack(
                                                  children: [
                                                    // محاكاة خطوط نصوص وفقرات الصفحة الفعلية
                                                    Padding(
                                                      padding: const EdgeInsets.all(6.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // عنوان ترويسة الصفحة
                                                          Row(
                                                            children: [
                                                              Container(
                                                                height: 3.5,
                                                                width: 22,
                                                                decoration: BoxDecoration(
                                                                  color: isCurrent ? _gold : const Color(0xFF64748B),
                                                                  borderRadius: BorderRadius.circular(2),
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Container(
                                                                height: 2.5,
                                                                width: 8,
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFF94A3B8),
                                                                  borderRadius: BorderRadius.circular(2),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 5),
                                                          // خطوط أسطر النصوص للمحاكاة
                                                          Container(height: 2, width: double.infinity, color: const Color(0xFFCBD5E1)),
                                                          const SizedBox(height: 3),
                                                          FractionallySizedBox(widthFactor: 0.85, child: Container(height: 2, color: const Color(0xFFCBD5E1))),
                                                          const SizedBox(height: 3),
                                                          FractionallySizedBox(widthFactor: 0.95, child: Container(height: 2, color: const Color(0xFFCBD5E1))),
                                                          const SizedBox(height: 3),
                                                          FractionallySizedBox(widthFactor: 0.70, child: Container(height: 2, color: const Color(0xFFCBD5E1))),
                                                          const SizedBox(height: 5),
                                                          // فقرة إضافية
                                                          Container(height: 2, width: double.infinity, color: const Color(0xFFE2E8F0)),
                                                          const SizedBox(height: 3),
                                                          FractionallySizedBox(widthFactor: 0.78, child: Container(height: 2, color: const Color(0xFFE2E8F0))),
                                                          const SizedBox(height: 3),
                                                          FractionallySizedBox(widthFactor: 0.60, child: Container(height: 2, color: const Color(0xFFE2E8F0))),
                                                        ],
                                                      ),
                                                    ),

                                                    // شريط العلامة المرجعية في أعلى زاوية الصفحة
                                                    if (isBookmarked)
                                                      Positioned(
                                                        top: 0,
                                                        right: 5,
                                                        child: Container(
                                                          width: 8,
                                                          height: 13,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.amber,
                                                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                                                            boxShadow: [
                                                              BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                    // شارة أنت هنا عند الصفحة المفتوحة حالياً
                                                    if (isCurrent)
                                                      Positioned(
                                                        bottom: 3,
                                                        left: 3,
                                                        right: 3,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: _gold,
                                                            borderRadius: BorderRadius.circular(3),
                                                          ),
                                                          child: const Text(
                                                            'أنت هنا',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontFamily: 'Tajawal',
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF0F172A),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // رقم الصفحة أسفل شكل الورقة
                                          Text(
                                            '',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrent ? _gold : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // التبويب الثاني: العلامات المرجعية والصفحات المميزة
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // زر إضافة / إزالة تمييز الصفحة الحالية
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _bookmarkedPages.contains(_currentPage)
                                        ? const Color(0xFFEF4444)
                                        : _gold,
                                    foregroundColor: _bookmarkedPages.contains(_currentPage)
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_bookmarkedPages.contains(_currentPage)) {
                                        _bookmarkedPages.remove(_currentPage);
                                      } else {
                                        _bookmarkedPages.add(_currentPage);
                                      }
                                      _saveBookmarks();
                                    });
                                    setModalState(() {});
                                  },
                                  icon: Icon(
                                    _bookmarkedPages.contains(_currentPage)
                                        ? Icons.bookmark_remove_rounded
                                        : Icons.bookmark_add_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _bookmarkedPages.contains(_currentPage)
                                        ? 'إزالة تمييز الصفحة الحالية (${_currentPage + 1})'
                                        : 'تمييز الصفحة الحالية (${_currentPage + 1}) كعلامة ⭐',
                                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // قائمة العلامات
                              Expanded(
                                child: _bookmarkedPages.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'لا توجد علامات مرجعية مضافة بعد',
                                              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60, fontSize: 13.5),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'يمكنك تمييز أي صفحة للرجوع إليها سريعاً بنقرة واحدة',
                                              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white38, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView(
                                        physics: const BouncingScrollPhysics(),
                                        children: (_bookmarkedPages.toList()..sort()).map((page) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white12),
                                            ),
                                            child: ListTile(
                                              leading: const Icon(Icons.bookmark_rounded, color: _gold),
                                              title: Text(
                                                'الصفحة ${page + 1}',
                                                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              subtitle: Text(
                                                page == _currentPage ? 'الصفحة الحالية' : 'انقر للانتقال الفوري',
                                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _bookmarkedPages.remove(page);
                                                    _saveBookmarks();
                                                  });
                                                  setModalState(() {});
                                                },
                                              ),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _pdfViewController?.setPage(page);
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= أدوات قلم التمييز بالأصفر =================
  void _togglePen() {
    setState(() {
      _isPenActive = !_isPenActive;
    });
    if (_isPenActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل قلم التمييز بالأصفر ✍️ - اسحب بإصبعك لتحديد أي سطر', style: TextStyle(fontFamily: 'Tajawal')),
          duration: Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _undoHighlight() {
    setState(() {
      final index = _highlights.lastIndexWhere((s) => s.page == _currentPage);
      if (index != -1) {
        _highlights.removeAt(index);
      }
    });
  }

  void _clearPageHighlights() {
    setState(() {
      _highlights.removeWhere((s) => s.page == _currentPage);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح جميع التحديدات في هذه الصفحة', style: TextStyle(fontFamily: 'Tajawal')),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color scaffoldBg = const Color(0xFF0F172A);
    if (_colorTheme == 'warm') {
      scaffoldBg = const Color(0xFF231E17);
    } else if (_colorTheme == 'night') {
      scaffoldBg = Colors.black;
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= قارئ PDF الرئيسي وطبقات التظليل =================
            Positioned.fill(
              child: Stack(
                children: [
                  if (kIsWeb)
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(widget.fileOrUrl)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        supportMultipleWindows: false,
                        allowsInlineMediaPlayback: true,
                      ),
                    )
                  else if (_localFilePath != null && File(_localFilePath!).existsSync())
                    PDFView(
                      key: ValueKey('pdf_${widget.fileOrUrl}_${_swipeHorizontal}_$_colorTheme'),
                      filePath: _localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: _swipeHorizontal,
                      autoSpacing: _swipeHorizontal,
                      pageFling: _swipeHorizontal,
                      pageSnap: _swipeHorizontal,
                      defaultPage: _currentPage,
                      fitPolicy: _swipeHorizontal ? FitPolicy.BOTH : FitPolicy.WIDTH,
                      preventLinkNavigation: false,
                      nightMode: _colorTheme == 'night',
                      showScrollIndicators: true,
                      maxZoom: 4.0,
                      minZoom: 1.0,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                      },
                          onRender: (pages) {
                            if (mounted) {
                              setState(() {
                                _totalPages = pages ?? 0;
                                _isLoading = false;
                              });
                              if (widget.materialId != null && pages != null) {
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setInt('pages_${widget.materialId}', pages);
                                });
                              }
                            }
                          },
                          onError: (error) {
                            if (mounted) {
                              setState(() {
                                _errorMessage = error.toString();
                                _isLoading = false;
                              });
                            }
                          },
                          onPageError: (page, error) {
                            if (mounted) {
                              setState(() {
                                _errorMessage = 'خطأ في الصفحة $page: $error';
                              });
                            }
                          },
                          onViewCreated: (PDFViewController pdfViewController) {
                            _pdfViewController = pdfViewController;
                          },
                          onPageChanged: (int? page, int? total) {
                            if (mounted) {
                              setState(() {
                                _currentPage = page ?? 0;
                                _totalPages = total ?? 0;
                              });
                            }
                          },
                        )
                      else if (_errorMessage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13.5),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                    });
                                    _preparePdfFile();
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _gold,
                                    foregroundColor: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // طبقة الوضع الدافئ (Sepia)
                      if (_colorTheme == 'warm')
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: const Color(0xFFFBF0D9).withOpacity(0.32),
                            ),
                          ),
                        ),

                      // طبقة قلم التمييز الأصفر
                      if (_isPenActive)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _activeStrokePoints.clear();
                                _activeStrokePoints.add(details.localPosition);
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _activeStrokePoints.add(details.localPosition);
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                if (_activeStrokePoints.isNotEmpty) {
                                  _highlights.add(
                                    HighlightStroke(
                                      page: _currentPage,
                                      points: List.from(_activeStrokePoints),
                                    ),
                                  );
                                  _activeStrokePoints.clear();
                                }
                              });
                            },
                            child: CustomPaint(
                              painter: HighlighterPainter(
                                strokes: _highlights.where((s) => s.page == _currentPage).toList(),
                                activePoints: _activeStrokePoints,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: HighlighterPainter(
                                strokes: _highlights.where((s) => s.page == _currentPage).toList(),
                                activePoints: const [],
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

            // ================= شريط علوي أنيق قابل للإخفاء =================
            if (_showBars)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gold, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_totalPages > 0)
                              Text(
                                'صفحة ${_currentPage + 1} من $_totalPages • ${_swipeHorizontal ? "كتاب أفقي" : "تتابع عمودي"}',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 10.5,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // زر العلامة المرجعية السريع
                      IconButton(
                        icon: Icon(
                          _bookmarkedPages.contains(_currentPage) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _bookmarkedPages.contains(_currentPage) ? _gold : Colors.white70,
                          size: 22,
                        ),
                        tooltip: 'تمييز الصفحة',
                        onPressed: () {
                          setState(() {
                            if (_bookmarkedPages.contains(_currentPage)) {
                              _bookmarkedPages.remove(_currentPage);
                            } else {
                              _bookmarkedPages.add(_currentPage);
                            }
                            _saveBookmarks();
                          });
                        },
                      ),

                      // زر إخفاء الأشرطة للقراءة الغامرة
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 22),
                        tooltip: 'إخفاء الأشرطة',
                        onPressed: () => setState(() => _showBars = false),
                      ),
                    ],
                  ),
                ),
              ),

            // زر إظهار أشرطة الأدوات عندما تكون مخفية
            if (!_showBars && !_isLoading && _localFilePath != null)
              Positioned(
                top: 12,
                left: 12,
                child: InkWell(
                  onTap: () => setState(() => _showBars = true),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _gold.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, color: _gold, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'أدوات القراءة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ================= شريط أدوات قلم التمييز إذا كان نشطاً =================
            if (_isPenActive)
              Positioned(
                top: _showBars ? 60 : 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.amber, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.border_color_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'تظليل أصفر ✍️',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 18),
                          tooltip: 'تراجع',
                          onPressed: _undoHighlight,
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          tooltip: 'مسح صفحة',
                          onPressed: _clearPageHighlights,
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _togglePen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10)),
                            child: const Text(
                              'تم ✓',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ================= شريط الأزرار المتكامل السفلي الفاخر =================
            if (_showBars && !_isLoading && _localFilePath != null)
              Positioned(
                bottom: 14,
                left: 12,
                right: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.94),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _gold.withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر المحتويات والفهرس
                          _buildBottomBarAction(
                            icon: Icons.menu_book_rounded,
                            label: 'المحتويات',
                            onTap: _showContentsBottomSheet,
                          ),

                          _buildDivider(),

                          // زر طريقة العرض (عمودي متصل / كتاب أفقي)
                          _buildBottomBarAction(
                            icon: _swipeHorizontal ? Icons.auto_stories_rounded : Icons.swap_vert_rounded,
                            label: _swipeHorizontal ? 'كتاب أفقي' : 'متصل عمودي',
                            onTap: _toggleSwipeMode,
                            isActive: _swipeHorizontal,
                          ),

                          _buildDivider(),

                          // زر لون وثيم الصفحة
                          _buildBottomBarAction(
                            icon: _colorTheme == 'warm'
                                ? Icons.coffee_rounded
                                : (_colorTheme == 'night' ? Icons.nightlight_round : Icons.wb_sunny_rounded),
                            label: _colorTheme == 'warm' ? 'دافئ' : (_colorTheme == 'night' ? 'ليلي' : 'فاتح'),
                            onTap: _showThemeSelector,
                          ),

                          _buildDivider(),

                          // زر إعادة الحجم الأصلي 100%
                          _buildBottomBarAction(
                            icon: Icons.restart_alt_rounded,
                            label: '${(_currentZoom * 100).toInt()}%',
                            onTap: _resetZoom,
                            isActive: _currentZoom > 1.05,
                          ),

                          _buildDivider(),

                          // زر انتقال لصفحة معينة
                          _buildBottomBarAction(
                            icon: Icons.pin_outlined,
                            label: _totalPages > 0 ? '${_currentPage + 1}/$_totalPages' : 'انتقال',
                            onTap: _showJumpToPageDialog,
                          ),

                          _buildDivider(),

                          // زر قلم التمييز الأصفر
                          _buildBottomBarAction(
                            icon: Icons.border_color_rounded,
                            label: 'تظليل',
                            onTap: _togglePen,
                            isActive: _isPenActive,
                            activeColor: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // مؤشر التحميل والتجهيز المتقدم
            if (_isLoading)
              Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(_gold),
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _downloadProgress > 0
                            ? 'جاري تجهيز وقراءة الملزمة (${(_downloadProgress * 100).toInt()}%)...'
                            : 'جاري فتح وقراءة الملزمة...',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'يتم تشغيل قارئ PDF عالي الدقة بدون استهلاك إضافي للإنترنت ⚡',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      if (_downloadProgress > 0) ...[
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _downloadProgress,
                              backgroundColor: Colors.white10,
                              color: _gold,
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white.withOpacity(0.12),
    );
  }

  Widget _buildBottomBarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = _gold,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white70, size: 19),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? activeColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== نافذة عرض الفورمات التفاعلية ====================
class GoogleFormDialog extends StatefulWidget {
  final String title;
  final String url;

  const GoogleFormDialog({super.key, required this.title, required this.url});

  @override
  State<GoogleFormDialog> createState() => _GoogleFormDialogState();
}

class _GoogleFormDialogState extends State<GoogleFormDialog> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  static const _gold = Color(0xFFFACC15);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B1220),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white10, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      tooltip: 'إغلاق',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _controller?.reload(),
                      icon: const Icon(Icons.refresh_rounded, color: _gold, size: 20),
                      tooltip: 'إعادة التحميل',
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  color: _gold,
                  minHeight: 3,
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    supportMultipleWindows: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    useShouldOverrideUrlLoading: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    allowContentAccess: true,
                    allowFileAccess: true,
                  ),
                  onWebViewCreated: (controller) => _controller = controller,
                  onCreateWindow: (controller, createWindowAction) async {
                    final targetUrl = createWindowAction.request.url;
                    if (targetUrl != null) {
                      await controller.loadUrl(urlRequest: URLRequest(url: targetUrl));
                      return true;
                    }
                    return false;
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStart: (controller, url) => setState(() {
                    _isLoading = true;
                    _progress = 0.0;
                  }),
                  onProgressChanged: (controller, progress) => setState(() {
                    _progress = progress / 100;
                  }),
                  onLoadStop: (controller, url) => setState(() {
                    _isLoading = false;
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== الشاشة الرئيسية المطورة ====================
class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  UserModel? _currentUser;
  String _selectedCategory = 'all'; // 'all', 'computer', 'arabic', 'english'
  String _contentTypeFilter = 'all'; // 'all', 'materials', 'forms'
  final String _searchQuery = '';

  List<StudyMaterial> _allMaterials = [];
  List<GoogleFormItem> _allForms = [];

  // تتبع حالة التحميل المحلي
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedFiles = {};

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'الكل',
      'icon': Icons.apps_rounded,
      'color': const Color(0xFF6366F1),
      'gradient': [Color(0xFF6366F1), Color(0xFF4F46E5)],
    },
    {
      'id': 'computer',
      'name': 'حاسوب',
      'icon': Icons.laptop_chromebook_rounded,
      'color': const Color(0xFF2563EB),
      'gradient': [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    },
    {
      'id': 'arabic',
      'name': 'عربي',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFD97706),
      'gradient': [Color(0xFFF59E0B), Color(0xFFB45309)],
    },
    {
      'id': 'english',
      'name': 'إنكليزي',
      'icon': Icons.language_rounded,
      'color': const Color(0xFF059669),
      'gradient': [Color(0xFF10B981), Color(0xFF047857)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadUserData();
    _checkLocalDownloadedFiles();
    _loadDataFromFirebase();
  }

  Future<void> _enableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Error enabling screen protection: $e');
    }
  }

  @override
  void dispose() {
    _disableScreenProtection();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _disableScreenProtection() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Error disabling screen protection: $e');
    }
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    authService.userData.listen((user) {
      if (mounted) {
        setState(() => _currentUser = user);
      }
    });
  }

  Future<void> _checkLocalDownloadedFiles() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${dir.path}/materials');
      if (await materialsDir.exists()) {
        final files = materialsDir.listSync();
        final Map<String, String> localFiles = {};
        for (final file in files) {
          if (file is File && file.path.endsWith('.pdf')) {
            final fileName = file.uri.pathSegments.last;
            final materialId = fileName.replaceAll('.pdf', '');
            localFiles[materialId] = file.path;
          }
        }
        if (mounted) {
          setState(() {
            _downloadedFiles.addAll(localFiles);
          });
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _loadDataFromFirebase({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedMaterialsRaw = prefs.getString('cached_study_materials');
      final cachedFormsRaw = prefs.getString('cached_google_forms');
      final lastSyncMs = prefs.getInt('last_study_materials_sync') ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final isCacheValid = (nowMs - lastSyncMs) < (24 * 60 * 60 * 1000);

      // تحميل فوري من الكاش المحلي بدون أي قراءة من فايربيس (0ms, 0 reads)
      if (cachedMaterialsRaw != null && cachedFormsRaw != null) {
        try {
          final List<dynamic> materialsList = jsonDecode(cachedMaterialsRaw);
          final List<dynamic> formsList = jsonDecode(cachedFormsRaw);

          if (mounted) {
            setState(() {
              _allMaterials = materialsList.map((m) => StudyMaterial.fromMap(m as Map<String, dynamic>)).toList();
              _allForms = formsList.map((f) => GoogleFormItem.fromMap(f as Map<String, dynamic>)).toList();
              _isLoading = false;
            });
          }

          // إذا كانت البيانات مخزنة ولم يمضِ عليها 24 ساعة، نتوقف هنا لحفظ قراءات الفايربيس
          if (!forceRefresh && isCacheValid) {
            return;
          }
        } catch (e) {
          debugPrint('Error reading cached materials: $e');
        }
      }

      if (_allMaterials.isEmpty && _allForms.isEmpty) {
        setState(() => _isLoading = true);
      }

      final firestore = FirebaseFirestore.instance;
      final results = await Future.wait([
        firestore.collection('study_materials').orderBy('createdAt', descending: true).get(),
        firestore.collection('google_forms').orderBy('createdAt', descending: true).get(),
      ]);

      final loadedMaterials = results[0].docs.map((doc) => StudyMaterial.fromFirestore(doc)).toList();
      final loadedForms = results[1].docs.map((doc) => GoogleFormItem.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _allMaterials = loadedMaterials;
          _allForms = loadedForms;
          _isLoading = false;
        });
      }

      // حفظ في الكاش المحلي وتحديث وقت المزامنة
      await prefs.setString('cached_study_materials', jsonEncode(loadedMaterials.map((m) => m.toMap()).toList()));
      await prefs.setString('cached_google_forms', jsonEncode(loadedForms.map((f) => f.toMap()).toList()));
      await prefs.setInt('last_study_materials_sync', nowMs);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _checkSubscription() {
    if (_currentUser == null || !_currentUser!.isPremium) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (_) => const SubscriptionRequiredDialog(),
      );
      return false;
    }
    return true;
  }

  Future<void> _downloadMaterial(StudyMaterial material) async {
    if (!_checkSubscription()) return;
    if (kIsWeb) {
      _openPdfViewer(material.name, material.pdfUrl, false);
      return;
    }

    try {
      setState(() {
        _downloadProgress[material.id] = 0.05;
      });

      final dir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${dir.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }

      final savePath = '${materialsDir.path}/${material.id}.pdf';
      final file = File(savePath);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(material.pdfUrl));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final List<int> bytes = [];

      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && mounted) {
            setState(() {
              _downloadProgress[material.id] = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            });
          }
        },
        onDone: () async {
          await file.writeAsBytes(bytes);
          if (mounted) {
            setState(() {
              _downloadProgress.remove(material.id);
              _downloadedFiles[material.id] = savePath;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تحميل ${material.name} بنجاح للقراءة أوفلاين', style: const TextStyle(fontFamily: 'Tajawal')),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _openPdfViewer(material.name, savePath, true);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _downloadProgress.remove(material.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل التحميل، جاري الفتح المباشر...', style: const TextStyle(fontFamily: 'Tajawal')),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _openPdfViewer(material.name, material.pdfUrl, false);
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(material.id);
        });
        _openPdfViewer(material.name, material.pdfUrl, false);
      }
    }
  }

  void _openPdfViewer(String title, String pathOrUrl, bool isLocal, {String? materialId}) {
    if (!_checkSubscription()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LuxuryPdfViewerScreen(
          title: title,
          fileOrUrl: pathOrUrl,
          isLocalFile: isLocal,
          materialId: materialId,
        ),
      ),
    );
  }

  void _openMaterialDetails(StudyMaterial material) {
    if (!_checkSubscription()) return;
    final isDownloaded = _downloadedFiles.containsKey(material.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaterialDetailScreen(
          material: material,
          isDownloaded: isDownloaded,
          localFilePath: _downloadedFiles[material.id],
          isPremium: _currentUser?.isPremium == true,
          onDownloadRequested: () => _downloadMaterial(material),
          onReadRequested: (path, isLocal) => _openPdfViewer(
            material.name,
            path,
            isLocal,
            materialId: material.id,
          ),
        ),
      ),
    );
  }

  void _openFormDialog(String title, String url) {
    if (!_checkSubscription()) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => GoogleFormDialog(title: title, url: url),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'computer':
        return const Color(0xFF2563EB);
      case 'arabic':
        return const Color(0xFFD97706);
      case 'english':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _getCategoryName(String cat) {
    switch (cat.toLowerCase()) {
      case 'computer':
        return 'حاسوب';
      case 'arabic':
        return 'لغة عربية';
      case 'english':
        return 'لغة إنكليزية';
      default:
        return 'عام';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = _currentUser?.isPremium == true;

    // تصفية المواد والفورمات
    List<StudyMaterial> filteredMaterials = _allMaterials.where((m) {
      final matchesCategory = (_selectedCategory == 'all') || (m.category == _selectedCategory);
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    List<GoogleFormItem> filteredForms = _allForms.where((f) {
      final matchesCategory = (_selectedCategory == 'all') || (f.category == _selectedCategory);
      final matchesSearch = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final totalCount = filteredMaterials.length + filteredForms.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Text(
              'الملازم والفورمات الامتحانية',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'دليلك الشامل لجميع المناهج والاختبارات التفاعلية',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'تحديث البيانات',
            onPressed: () => _loadDataFromFirebase(forceRefresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ================= شريط الأزرار العلوية الملكية (الكل / حاسوب / عربي / إنكليزي) =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  final List<Color> gradient = cat['gradient'] as List<Color>;

                  int catCount = 0;
                  if (cat['id'] == 'all') {
                    catCount = _allMaterials.length + _allForms.length;
                  } else {
                    catCount = _allMaterials.where((m) => m.category == cat['id']).length +
                        _allForms.where((f) => f.category == cat['id']).length;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['id'];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (gradient.first).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat['name'] as String,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$catCount',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ================= شريط فلترة النوع (الكل / ملازم PDF / فورمات) =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _buildTypeChip('all', 'الكل (${filteredMaterials.length + filteredForms.length})', isDark),
                  const SizedBox(width: 8),
                  _buildTypeChip('materials', 'الملازم 📄 (${filteredMaterials.length})', isDark),
                  const SizedBox(width: 8),
                  _buildTypeChip('forms', 'الفورمات 📝 (${filteredForms.length})', isDark),
                ],
              ),
            ),

            // ================= شريط تنبيه الاشتراك لغير المشتركين =================
            if (!isPremium && !ConfigService().isReviewMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'الملازم والفورمات متاحة للمشتركين فقط',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.subscription),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ترقية ⚡', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // ================= قائمة الملازم والفورمات التفاعلية =================
            Expanded(
              child: _isLoading
                  ? const LuxuryLoading(message: 'جاري تحميل الملازم والفورمات...')
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: totalCount == 0
                          ? _buildEmptyState(isDark)
                          : RefreshIndicator(
                              onRefresh: () => _loadDataFromFirebase(forceRefresh: true),
                              color: const Color(0xFF2563EB),
                              child: ListView(
                                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                children: [
                                  // عرض الملازم
                                  if (_contentTypeFilter == 'all' || _contentTypeFilter == 'materials') ...[
                                    if (filteredMaterials.isNotEmpty) ...[
                                      _buildSectionHeader('الملازم الدراسية الرسمية (PDF)', Icons.picture_as_pdf_rounded, const Color(0xFFDC2626), filteredMaterials.length, isDark),
                                      const SizedBox(height: 8),
                                      ...filteredMaterials.map((m) => _buildLuxuryMaterialCard(m, isDark, isPremium)),
                                      const SizedBox(height: 16),
                                    ],
                                  ],

                                  // عرض الفورمات
                                  if (_contentTypeFilter == 'all' || _contentTypeFilter == 'forms') ...[
                                    if (filteredForms.isNotEmpty) ...[
                                      _buildSectionHeader('الفورمات والاختبارات التفاعلية', Icons.quiz_rounded, const Color(0xFF2563EB), filteredForms.length, isDark),
                                      const SizedBox(height: 8),
                                      ...filteredForms.map((f) => _buildLuxuryFormCard(f, isDark, isPremium)),
                                      const SizedBox(height: 16),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, bool isDark) {
    final isSelected = _contentTypeFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _contentTypeFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFACC15)
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFFFACC15) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.notoKufiArabic(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count عنصر',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryMaterialCard(StudyMaterial material, bool isDark, bool isPremium) {
    final catColor = _getCategoryColor(material.category);
    final catName = _getCategoryName(material.category);
    final isDownloaded = _downloadedFiles.containsKey(material.id);
    final double? progress = _downloadProgress[material.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDownloaded
              ? const Color(0xFF10B981).withOpacity(0.4)
              : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openMaterialDetails(material),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // أيقونة PDF الفاخرة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDownloaded
                          ? [const Color(0xFF10B981), const Color(0xFF047857)]
                          : [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isDownloaded ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDownloaded ? Icons.menu_book_rounded : Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // تفاصيل الملزمة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              catName,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isDownloaded)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'محفوظة أوفلاين ⚡',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            )
                          else
                            const Text(
                              'ملزمة رسمية',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        material.name,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (material.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          material.description,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // زر التحميل / القراءة الفورية
                if (progress != null)
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          color: const Color(0xFF2563EB),
                          backgroundColor: Colors.white10,
                          strokeWidth: 3,
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: !isPremium
                          ? const Color(0xFFFEF3C7)
                          : isDownloaded
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isPremium
                            ? const Color(0xFFF59E0B)
                            : isDownloaded
                                ? Colors.transparent
                                : const Color(0xFFFACC15).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          !isPremium
                              ? Icons.lock_rounded
                              : isDownloaded
                                  ? Icons.menu_book_rounded
                                  : Icons.download_rounded,
                          size: 14,
                          color: !isPremium
                              ? const Color(0xFFD97706)
                              : isDownloaded
                                  ? Colors.white
                                  : const Color(0xFFFACC15),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !isPremium
                              ? 'مقفل'
                              : isDownloaded
                                  ? 'قراءة'
                                  : 'تحميل',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !isPremium
                                ? const Color(0xFF92400E)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryFormCard(GoogleFormItem form, bool isDark, bool isPremium) {
    final catColor = _getCategoryColor(form.category);
    final catName = _getCategoryName(form.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openFormDialog(form.name, form.formUrl),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // أيقونة الفورمات الفاخرة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),

                // تفاصيل الفورمة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              catName,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'فورمة تدريبية',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        form.name,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (form.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          form.description,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // زر الفتح / القفل
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isPremium ? const Color(0xFF2563EB) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPremium ? Colors.transparent : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.open_in_new_rounded : Icons.lock_rounded,
                        size: 14,
                        color: isPremium ? Colors.white : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? 'بدء' : 'مقفل',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPremium ? Colors.white : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد ملازم أو فورمات في هذا القسم حالياً',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'سيتم إضافة ملازم واختبارات جديدة دورياً من قبل الإدارة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
