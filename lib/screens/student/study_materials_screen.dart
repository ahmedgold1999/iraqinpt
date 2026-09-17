import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../routes.dart';
import '../../services/auth_service.dart';
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

  StudyMaterial({
    required this.id,
    required this.name,
    required this.description,
    required this.pdfUrl,
    required this.category,
    required this.createdAt,
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
    );
  }
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
}

// ==================== نافذة الاشتراك المطلوب ====================
class SubscriptionRequiredDialog extends StatelessWidget {
  const SubscriptionRequiredDialog({super.key});

  static const _gold = Color(0xFFFACC15);

  @override
  Widget build(BuildContext context) {
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

// ==================== عارض PDF فاخر ومتكامل داخل التطبيق ====================
class LuxuryPdfViewerScreen extends StatefulWidget {
  final String title;
  final String fileOrUrl;
  final bool isLocalFile;

  const LuxuryPdfViewerScreen({
    super.key,
    required this.title,
    required this.fileOrUrl,
    required this.isLocalFile,
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
  bool _isNightMode = false;

  static const _gold = Color(0xFFFACC15);

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
    _preparePdfFile();
  }

  Future<void> _enableScreenProtection() async {
    try {
      if (Platform.isAndroid) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (e) {
      debugPrint('Error enabling screen protection: $e');
    }
  }

  @override
  void dispose() {
    _disableScreenProtection();
    super.dispose();
  }

  Future<void> _disableScreenProtection() async {
    try {
      if (Platform.isAndroid) {
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

    // إذا كان الملف من أصول المشروع (Assets)
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

    // إذا كان الرابط عن بعد، نقوم بتنزيله مؤقتاً في الكاش لفتحه بسلاسة وبدون شاشة سوداء
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

  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 0.35).clamp(1.0, 5.0);
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 0.35).clamp(1.0, 5.0);
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  void _goToPrevPage() {
    if (_currentPage > 0) {
      _pdfViewController?.setPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_totalPages > 0 && _currentPage < _totalPages - 1) {
      _pdfViewController?.setPage(_currentPage + 1);
    }
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الانتقال إلى صفحة', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
          decoration: InputDecoration(
            hintText: 'اكتب رقم الصفحة (1 - $_totalPages)',
            hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'Tajawal'),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            child: const Text('انتقال', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isNightMode ? Colors.black : const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gold, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'صفحة ${_currentPage + 1} من $_totalPages',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          // كبسولة تقليب الصفحات لأعلى ولأسفل بالأعلى
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, color: _gold, size: 24),
                  tooltip: 'الصفحة السابقة ⬆️',
                  onPressed: _currentPage > 0 ? _goToPrevPage : null,
                ),
                GestureDetector(
                  onTap: _totalPages > 1 ? _showJumpToPageDialog : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      _totalPages > 0 ? '${_currentPage + 1}/$_totalPages' : '...',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold, size: 24),
                  tooltip: 'الصفحة التالية ⬇️',
                  onPressed: (_totalPages > 0 && _currentPage < _totalPages - 1) ? _goToNextPage : null,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.light_mode_rounded : Icons.nightlight_round,
              color: _isNightMode ? _gold : Colors.white70,
              size: 20,
            ),
            tooltip: _isNightMode ? 'الوضع النهاري' : 'الوضع الليلي (قراءة مريحة)',
            onPressed: _toggleNightMode,
          ),
        ],
      ),
      body: Stack(
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
              filePath: _localFilePath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: false,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              nightMode: _isNightMode,
              onRender: (pages) {
                if (mounted) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isLoading = false;
                  });
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

          // شريط أدوات التكبير والتصغير العائم السفلي
          if (!_isLoading && _localFilePath != null)
            Positioned(
              bottom: 24,
              right: 16,
              left: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _gold.withOpacity(0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر التصغير
                      IconButton(
                        onPressed: _currentZoom > 1.01 ? _zoomOut : null,
                        icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                        tooltip: 'تصغير',
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),

                      // مؤشر نسبة التكبير وزر إعادة التعيين
                      GestureDetector(
                        onTap: _resetZoom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentZoom > 1.05 ? _gold.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_currentZoom * 100).toInt()}%',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _currentZoom > 1.05 ? _gold : Colors.white,
                                ),
                              ),
                              if (_currentZoom > 1.05) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.refresh_rounded, color: _gold, size: 13),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // زر التكبير
                      IconButton(
                        onPressed: _currentZoom < 4.99 ? _zoomIn : null,
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        tooltip: 'تكبير',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
      if (Platform.isAndroid) {
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
      if (Platform.isAndroid) {
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

  Future<void> _loadDataFromFirebase() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final results = await Future.wait([
        firestore.collection('study_materials').orderBy('createdAt', descending: true).get(),
        firestore.collection('google_forms').orderBy('createdAt', descending: true).get(),
      ]);

      if (mounted) {
        setState(() {
          _allMaterials = results[0].docs.map((doc) => StudyMaterial.fromFirestore(doc)).toList();
          _allForms = results[1].docs.map((doc) => GoogleFormItem.fromFirestore(doc)).toList();
          _isLoading = false;
        });
      }
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

  void _openPdfViewer(String title, String pathOrUrl, bool isLocal) {
    if (!_checkSubscription()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LuxuryPdfViewerScreen(
          title: title,
          fileOrUrl: pathOrUrl,
          isLocalFile: isLocal,
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
            onPressed: _loadDataFromFirebase,
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
            if (!isPremium)
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
                              onRefresh: _loadDataFromFirebase,
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
          onTap: () {
            if (isDownloaded) {
              _openPdfViewer(material.name, _downloadedFiles[material.id]!, true);
            } else {
              _downloadMaterial(material);
            }
          },
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
