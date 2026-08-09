import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
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
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _gold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'الملازم والفورمات متاحة فقط للمشتركين',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بالاشتراك للوصول إلى جميع الملازم والفورمات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
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
                          side: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.2),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
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
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, AppRoutes.subscription);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'الاشتراك',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
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

// ==================== شاشة عرض WebView منبثقة ====================
class WebViewDialog extends StatefulWidget {
  final String title;
  final String url;

  const WebViewDialog({super.key, required this.title, required this.url});

  @override
  State<WebViewDialog> createState() => _WebViewDialogState();
}

class _WebViewDialogState extends State<WebViewDialog> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  static const _gold = Color(0xFFFACC15);
  static const _ink = Color(0xFF0F172A);

  static TextStyle _t(
      double size, {
        FontWeight w = FontWeight.w600,
        Color c = _ink,
        double h = 1.2,
        double ls = 0.0,
      }) {
    return TextStyle(
      fontFamily: 'Tajawal',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: const Color(0xFF0B1220).withOpacity(0.96),
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    border: Border(
                      bottom: BorderSide(color: _gold.withOpacity(0.2), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_gold.withOpacity(0.2), _gold.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _gold.withOpacity(0.3), width: 1.2),
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_controller != null) {
                              _controller!.goBack();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: _gold, size: 24),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: _t(18, w: FontWeight.w900, c: Colors.white, ls: 0.3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _gold.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _gold.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.preview_rounded, size: 12, color: _gold),
                                      const SizedBox(width: 4),
                                      Text(
                                        'معاينة سريعة',
                                        style: _t(10, w: FontWeight.w800, c: _gold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: _gold,
                    minHeight: 3,
                  ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      javaScriptCanOpenWindowsAutomatically: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      allowContentAccess: true,
                      allowFileAccess: true,
                      supportMultipleWindows: true,
                      clearCache: false,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS)
                        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1' 
                        : 'Mozilla/5.0 (Linux; Android 13; SM-S908E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                        _progress = 0.0;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onLoadStop: (controller, url) {
                      setState(() {
                        _isLoading = false;
                      });
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final uri = navigationAction.request.url;
                      if (uri != null) {
                        final isNewWindow = navigationAction.isForMainFrame == false;
                        if (isNewWindow) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierColor: Colors.black.withOpacity(0.8),
                              builder: (context) => WebViewDialog(
                                title: 'رابط خارجي',
                                url: uri.toString(),
                              ),
                            );
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onCreateWindow: (controller, createWindowAction) async {
                      final request = createWindowAction.request;
                      final url = request.url;
                      if (url != null && mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.black.withOpacity(0.8),
                          builder: (context) => WebViewDialog(
                            title: 'نافذة جديدة',
                            url: url.toString(),
                          ),
                        );
                      }
                      return false;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== نموذج المادة مع ملازمها وفورماتها ====================
class SubjectData {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final List<StudyMaterial> materials;
  final List<GoogleFormItem> forms;
  bool isExpanded;

  SubjectData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.materials,
    required this.forms,
    this.isExpanded = false,
  });

  int get materialCount => materials.length;
  int get formCount => forms.length;
}

// ==================== الشاشة الرئيسية ====================
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

  List<StudyMaterial> _allMaterials = [];
  List<GoogleFormItem> _googleForms = [];
  List<SubjectData> _subjects = [];

  final List<Map<String, dynamic>> _subjectConfig = [
    {'id': 'computer', 'name': 'الحاسوب', 'icon': '💻', 'color': const Color(0xFF3B82F6)},
    {'id': 'english', 'name': 'اللغة الإنكليزية', 'icon': '🇬🇧', 'color': const Color(0xFF10B981)},
    {'id': 'arabic', 'name': 'اللغة العربية', 'icon': '📖', 'color': const Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadUserData();
    _loadDataFromFirebase();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    authService.userData.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
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
          _googleForms = results[1].docs.map((doc) => GoogleFormItem.fromFirestore(doc)).toList();
          _buildSubjectsData();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('حدث خطأ في تحميل البيانات', Colors.red);
      }
    }
  }

  void _buildSubjectsData() {
    _subjects = _subjectConfig.map((config) {
      final materials = _allMaterials.where((m) => m.category == config['id']).toList();
      final forms = _googleForms.where((f) => f.category == config['id']).toList();
      return SubjectData(
        id: config['id'],
        name: config['name'],
        icon: config['icon'],
        color: config['color'],
        materials: materials,
        forms: forms,
        isExpanded: false,
      );
    }).toList();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
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

  void _openFormInDialog(String title, String url) {
    if (!_checkSubscription()) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => WebViewDialog(title: title, url: url),
    );
  }

  void _openPdfInDialog(String title, String url) {
    if (!_checkSubscription()) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => WebViewDialog(title: title, url: url),
    );
  }

  void _toggleSubject(int index) {
    setState(() {
      _subjects[index].isExpanded = !_subjects[index].isExpanded;
    });
  }

  Widget _buildSubscriptionWarningCard() {
    if (_currentUser != null && _currentUser!.isPremium) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'محتوى محمي للمشتركين',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اشترك الآن للوصول الكامل لجميع الملازم والاختبارات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    color: const Color(0xFFB45309).withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            child: const Text('ترقية', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // AppBar مع Label "الملازم والفورمات"
          // AppBar هيدر ملكي ملون بنمط أبل آيفون (مدمج ومتناسق مع النص)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x222563EB),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFACC15), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الملازم والفورمات الامتحانية',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'دليلك الشامل لجميع المناهج والاختبارات التفاعلية',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // المحتوى الرئيسي
          Expanded(
            child: _isLoading
                ? const LuxuryLoading(message: 'جاري تحميل الملازم...')
                : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSubscriptionWarningCard(),
                    ...List.generate(_subjects.length, (index) => _buildSubjectCard(index)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(int index) {
    final subject = _subjects[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: subject.color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس المادة - اسم المادة وعدد الملازم والسهم
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleSubject(index),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // أيقونة المادة
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [subject.color, subject.color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          subject.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // اسم المادة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subject.materialCount} ملزمة • ${subject.formCount} فورمة',
                            style: TextStyle(
                              fontSize: 13,
                              color: subject.color,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // عدد الملازم (يظهر بجانب السهم)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: subject.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${subject.materialCount}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: subject.color,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // سهم للأسفل/للأعلى
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: subject.isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: subject.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // المحتوى الموسع - الملازم والفورمات
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: subject.isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: subject.color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان الملازم
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: subject.color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الملازم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: subject.color,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${subject.materials.length} ملزمة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: subject.color,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // قائمة الملازم
                  if (subject.materials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'لا توجد ملازم في هذا القسم',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    )
                  else
                    ...subject.materials.map((material) => _buildMaterialItem(material, subject.color)),

                  const SizedBox(height: 16),

                  // عنوان الفورمات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.google, color: subject.color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'الفورمات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: subject.color,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${subject.forms.length} فورمة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: subject.color,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // قائمة الفورمات
                  if (subject.forms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'لا توجد فورمات في هذا القسم',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    )
                  else
                    ...subject.forms.map((form) => _buildFormItem(form, subject.color)),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(StudyMaterial material, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openPdfInDialog(material.name, material.pdfUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (material.description.isNotEmpty)
                        Text(
                          material.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios, color: color, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormItem(GoogleFormItem form, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openFormInDialog(form.name, form.formUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (form.description.isNotEmpty)
                        Text(
                          form.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'Tajawal',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'فتح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
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
}
