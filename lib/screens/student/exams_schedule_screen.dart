import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../services/config_service.dart';
import '../../services/question_service.dart';
import 'smart_vault_screen.dart';
import 'notifications_screen.dart';
import 'about_national_exam_screen.dart';
import 'qualification_score_screen.dart';
import 'exam_centers_screen.dart';
import 'certificate_verification_screen.dart';
import 'exam_instructions_screen.dart';
import 'home_screen.dart';
import '../../widgets/luxury_exam_countdown_card.dart';
import '../../routes.dart';
import 'motivational_quotes_screen.dart';
import 'study_materials_screen.dart';
import 'exam_schedule_viewer_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class ExamsScheduleScreen extends StatefulWidget {
  const ExamsScheduleScreen({super.key});

  @override
  State<ExamsScheduleScreen> createState() => _ExamsScheduleScreenState();
}

class _ExamsScheduleScreenState extends State<ExamsScheduleScreen> {
  // ===== Bottom Nav =====
  int _currentIndex = 2; // جدول الامتحانات
  bool _showImage = false; // التحكم في إظهار الصورة
  bool _isSyncingQuestions = false;
  DateTime? _lastSyncDate;
  static const String _admissionsRegulationsUrl =
      'https://drive.google.com/file/d/1x5aQwSpyEZP_AS0VbfDoR0ZsEPEDOnou/preview';
  static const String _competitiveExamsUrl =
      'https://ahmedgold1999.github.io/INPT/competitive_exams.html';
  static const String _telegramChannelUrl = 'https://t.me/inptiq';

  bool _isLoadingPdf = false;

  Map<String, dynamic> _subjectsData = {
    'arabic': {'name': 'اللغة العربية', 'count': 0, 'loading': true},
    'computer': {'name': 'الحاسوب', 'count': 0, 'loading': true},
    'english': {'name': 'اللغة الإنجليزية', 'count': 0, 'loading': true},
  };

  final Map<String, String> _questionsUrls = {
    'arabic':
    'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/arabic',
    'computer':
    'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/computer_ar',
    'english':
    'https://raw.githubusercontent.com/ahmedgold1999/questionsinpt/refs/heads/main/english',
  };

  @override
  void initState() {
    super.initState();
    _loadAllQuestionsCounts();
    _loadLastSyncDate();
  }

  Future<void> _loadLastSyncDate() async {
    final date = await QuestionService.getLastSyncDate();
    if (mounted) {
      setState(() => _lastSyncDate = date);
    }
  }

  Future<void> _syncQuestionsNow() async {
    setState(() => _isSyncingQuestions = true);
    try {
      final results = await QuestionService.syncAllQuestions();
      int total = results.values.fold(0, (a, b) => a + b);
      await _loadAllQuestionsCounts();
      await _loadLastSyncDate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم تحديث وحفظ $total سؤال بنجاح للاستخدام بدون إنترنت!',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            content: Text('تعذر مزامنة الأسئلة: $e', style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingQuestions = false);
      }
    }
  }

  void _showAdmissionsWebView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // لجعل النافذة ملء الشاشة تقريباً
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // شريط العنوان
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFFFACC15)),
                      ),
                      const Expanded(
                        child: Text(
                          'ضوابط التقديم والقبول',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // عرض الرابط عبر WebView
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_admissionsRegulationsUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      supportMultipleWindows: true,
                      // التمويه بأن المتصفح هو كمبيوتر لضمان فتح معاينة جوجل درايف
                      userAgent:
                      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapNav(int index) {
    if (index == _currentIndex) return;

    String route = AppRoutes.studentHome;
    switch (index) {
      case 0: route = AppRoutes.studentHome; break;
      case 1: route = AppRoutes.subscription; break;
      case 2: route = AppRoutes.examsSchedule; break;
      case 3: route = AppRoutes.studyMaterials; break;
      case 4: route = AppRoutes.profile; break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  // صورة الجدول داخل الكود (بدون رابط)
  final String _examImageUrl = 'assets/icons/exam_schedule.png';

  // رابط معرفة التأهيل
  static const String _qualificationUrl =
      'https://ahmedgold1999.github.io/INPT/';

  // رابط المراكز الامتحانية
  static const String _examCentersUrl = 'https://ahmedgold1999.github.io/htiq/';

  // رابط فحص الشهادة
  static const String _certificateCheckUrl = 'https://qr.uob.edu.iq/';

  Future<void> _loadAllQuestionsCounts() async {
    for (var entry in _questionsUrls.entries) {
      await _loadQuestionsCount(entry.key, entry.value);
    }
  }

  Future<void> _loadQuestionsCount(String key, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> questions = data['questions'];
        if (mounted) {
          setState(() {
            _subjectsData[key] = {
              ..._subjectsData[key]!,
              'count': questions.length,
              'loading': false,
            };
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subjectsData[key] = {
              ..._subjectsData[key]!,
              'count': 0,
              'loading': false
            };
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subjectsData[key] = {
            ..._subjectsData[key]!,
            'count': 0,
            'loading': false
          };
        });
      }
    }
  }

  // التحقق من الاتصال بالإنترنت
  Future<bool> _checkInternetConnection() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('خطأ في التحقق من الاتصال: $e');
      return false;
    }
  }

  // ==================== طلب إذن الكاميرا ====================
  Future<bool> _requestCameraPermission() async {
    try {
      // نتحقق من حالة الإذن الحالية
      PermissionStatus status = await Permission.camera.status;
      print('حالة الإذن الحالية: $status');

      // إذا كان الإذن ممنوح بالفعل
      if (status.isGranted) {
        print('الإذن ممنوح بالفعل');
        return true;
      }

      // إذا كان الإذن مرفوض (لم يطلب بعد أو رفض مرة واحدة)
      if (status.isDenied) {
        print('جاري طلب الإذن...');
        // طلب الإذن
        status = await Permission.camera.request();
        print('حالة الإذن بعد الطلب: $status');

        if (status.isGranted) {
          print('تم منح الإذن');
          return true;
        } else if (status.isPermanentlyDenied) {
          print('الإذن مرفوض بشكل دائم');
          if (mounted) {
            _showCameraPermissionSettingsDialog();
          }
          return false;
        } else {
          print('الإذن مرفوض - سيتم عرض رسالة للمستخدم');
          if (mounted) {
            _showCameraPermissionDeniedMessage();
          }
          return false;
        }
      }

      // إذا كان الإذن مرفوض بشكل دائم
      if (status.isPermanentlyDenied) {
        print('الإذن مرفوض بشكل دائم');
        if (mounted) {
          _showCameraPermissionSettingsDialog();
        }
        return false;
      }

      // إذا كان الإذن محدود (لأندرويد 11+)
      if (status.isLimited) {
        print('الإذن محدود');
        return true;
      }

      return false;
    } catch (e) {
      print('خطأ في طلب إذن الكاميرا: $e');
      return false;
    }
  }

// ==================== رسالة رفض الإذن ====================
  void _showCameraPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'لم يتم منح صلاحية الكاميرا. يرجى السماح بالوصول إلى الكاميرا لفحص الشهادة',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'طلب مجدداً',
          textColor: Colors.white,
          onPressed: () {
            // طلب الإذن مرة أخرى
            _requestCameraPermission().then((granted) {
              if (granted && mounted) {
                _showCertificateWebView();
              }
            });
          },
        ),
      ),
    );
  }

// ==================== نافذة طلب إذن الكاميرا ====================
  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.orange,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'صلاحية الكاميرا مطلوبة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تحتاج إلى منح صلاحية الوصول إلى الكاميرا لفحص رمز QR الخاص بالشهادة',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // إغلاق النافذة الحالية

                          // طلب الإذن مرة أخرى
                          bool granted = await _requestCameraPermission();

                          if (granted && mounted) {
                            // إذا تم منح الإذن، نعرض WebView
                            _showCertificateWebView();
                          }
                          // إذا لم يتم منح الإذن، الدالة _requestCameraPermission ستظهر الرسالة المناسبة
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'السماح',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ==================== نافذة إعدادات الكاميرا (عند الرفض الدائم) ====================
  void _showCameraPermissionSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'صلاحية الكاميرا مرفوضة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تم رفض صلاحية الكاميرا بشكل دائم. يرجى فتح إعدادات التطبيق ومنح الصلاحية يدوياً',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // إغلاق النافذة الحالية
                          await openAppSettings(); // فتح إعدادات التطبيق

                          // بعد العودة من الإعدادات، نتحقق مرة أخرى
                          if (mounted) {
                            bool granted = await _requestCameraPermission();
                            if (granted) {
                              _showCertificateWebView();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'فتح الإعدادات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ==================== نافذة عدم وجود إنترنت ====================
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'يرجى التحقق من اتصال جهازك بالإنترنت',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openCertificateCheckDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== فتح ضوابط التقديم والقبول ====================
  // ==================== فتح ضوابط التقديم والقبول (من ملفات المشروع) ====================
  Future<void> _openAdmissionsRegulations() async {
    try {
      // التحقق من وجود اتصال بالإنترنت (لأن PDFViewer يحتاج أحياناً إلى internet)
      bool hasInternet = await _checkInternetConnection();

      if (!hasInternet) {
        if (mounted) _showNoInternetDialog();
        return;
      }

      // عرض نافذة PDF من الملف المضمن
      _showLocalPdfViewer();
    } catch (e) {
      print('خطأ في فتح ضوابط التقديم: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ==================== عرض PDF من الملفات المحلية ====================
  void _showLocalPdfViewer() {
    // مسار الملف داخل المشروع
    final String pdfPath = 'assets/icons/mohesr.pdf';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // شريط العنوان
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF0F172A),
                            size: 22,
                          ),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ضوابط التقديم والقبول',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'الدراسات العليا (ملف محلي)',
                              style: TextStyle(
                                color: Color(0xFFFACC15),
                                fontSize: 12,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),

                // InAppWebView لعرض PDF من الملف المحلي
                Expanded(
                  child: InAppWebView(
                    initialFile: pdfPath, // ✅ استخدام ملف محلي بدلاً من URL
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
                      userAgent:
                      'Mozilla/5.0 (Linux; Android 13; SM-S908E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ==================== الدالة الرئيسية لفتح فحص الشهادة ====================
  Future<void> _openCertificateCheckDialog() async {
    try {
      // التحقق من وجود اتصال بالإنترنت
      bool hasInternet = await _checkInternetConnection();

      if (!hasInternet) {
        if (mounted) _showNoInternetDialog();
        return;
      }

      // التحقق من إذن الكاميرا
      bool cameraPermission = await _requestCameraPermission();
      print('نتيجة التحقق من الإذن: $cameraPermission');

      if (cameraPermission) {
        // إذا كان الإذن ممنوح، نعرض WebView
        if (mounted) _showCertificateWebView();
      } else {
        // إذا لم يكن الإذن ممنوح، نعرض نافذة طلب الإذن
        if (mounted) _showCameraPermissionDialog();
      }
    } catch (e) {
      print('خطأ في _openCertificateCheckDialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ==================== نافذة فحص الشهادة الرئيسية ====================
  void _showCertificateWebView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // إزالة الـ padding الداخلي
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width, // عرض كامل الشاشة
            height: MediaQuery.of(context).size.height, // ارتفاع كامل الشاشة
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // شريط العنوان
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF0F172A),
                            size: 22,
                          ),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فحص الشهادة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'وزارة التعليم العالي والبحث العلمي',
                              style: TextStyle(
                                color: Color(0xFFFACC15),
                                fontSize: 12,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),

                // InAppWebView
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_certificateCheckUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      supportMultipleWindows: true,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS) 
                        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1' 
                        : 'Mozilla/5.0 (Linux; Android 13; SM-S908E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
                    ),
                    onPermissionRequest: (controller, request) async {
                      return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ==================== دوال WebView المعدلة لاستخدام InAppWebView ====================
  void _openQualificationWebView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.visibility_off,
                            color: Color(0xFF0F172A),
                            size: 22,
                          ),
                          tooltip: 'إخفاء',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'معرفة تأهيلك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_qualificationUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS) ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTelegramChannel() {
    _tryOpenTelegramApp();
  }

  Future<void> _tryOpenTelegramApp() async {
    final tgUri = Uri.parse('tg://resolve?domain=inptiq');
    if (await canLaunchUrl(tgUri)) {
      await launchUrl(tgUri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse('https://t.me/inptiq');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstagramAccount() async {
    final nativeUri = Uri.parse('instagram://user?username=a0g0a');
    final webUri = Uri.parse('https://www.instagram.com/a0g0a');
    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _openCompetitiveExamsWebView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.visibility_off,
                            color: Color(0xFF0F172A),
                            size: 22,
                          ),
                          tooltip: 'إخفاء',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'شنو هو الامتحان الوطني؟',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_competitiveExamsUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS) ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openExamCentersWebView() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.visibility_off,
                            color: Color(0xFF0F172A),
                            size: 22,
                          ),
                          tooltip: 'إخفاء',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'المراكز الامتحانية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'إغلاق',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_examCentersUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      userAgent: (defaultTargetPlatform == TargetPlatform.iOS) ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openZoomImage() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                child: Center(
                  child: Image.asset(
                    _examImageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openExamInstructions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F172A),
                  Colors.deepPurple.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -70,
                  left: -70,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.withOpacity(0.05),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFACC15),
                                  Colors.amber.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFF0F172A),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              'تعليمات الحجز والامتحانات',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              tooltip: 'إغلاق',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade800.withOpacity(0.3),
                                    Colors.blue.shade600.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.blue.shade300.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'تعليمات الحجز والتأكيد',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInstructionPoint(
                              icon: Icons.badge,
                              title: 'المستمسكات المطلوبة:',
                              content:
                              'يجب جلب مستمسك أصلي (بطاقة وطنية أو جواز سفر) حصراً أثناء التأكيد وحضور الاختبار.',
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 15),
                            _buildInstructionPoint(
                              icon: Icons.access_time,
                              title: 'مواعيد الحجز:',
                              content:
                              'يغلق تأكيد الحجز قبل ساعة من بدء الاختبار.',
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 15),
                            _buildInstructionPoint(
                              icon: Icons.money_off,
                              title: 'إلغاء الحجز:',
                              content:
                              'يحق للمركز الامتحاني إلغاء الحجز بعد 48 ساعة من تاريخ الحجز في حال عدم دفع الرسوم وتأكيد الحجز.',
                              color: Colors.red,
                            ),
                            const SizedBox(height: 25),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade900.withOpacity(0.4),
                                    Colors.red.shade800.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.red.shade400.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.yellow.shade300,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        '⚠ تحذير هام',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'يُرم الطالب من التقديم في حال ثبوت أي حالة غش، وتشمل:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Tajawal',
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheatingCase('التكلم أثناء الامتحان'),
                                _buildCheatingCase('النظر إلى حاسبة طالب آخر'),
                                _buildCheatingCase('انتحال الشخصية'),
                                _buildCheatingCase(
                                    'استخدام قصاصات ورقية أو وسائل غير مسموح بها'),
                                _buildCheatingCase(
                                    'استبدال ورقة دخول الامتحان مع طالب آخر'),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade800.withOpacity(0.3),
                                    Colors.teal.shade700.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.green.shade300.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    color: Colors.yellow,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '📌 يرجى الالتزام بالتعليمات لتجنب حرمانك من التقديم',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: const Text(
                                'ملاحظة: جميع التعليمات أعلاه هي قواعد معتمدة من المركز الامتحاني، ويجب الالتزام بها للحفاظ على نزاهة الاختبارات.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontFamily: 'Tajawal',
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFACC15),
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            shadowColor: Colors.amber.withOpacity(0.5),
                          ),
                          child: const Text(
                            'تمت قراءة التعليمات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownTimer() {
    // استخدام ConfigService لتوفير قراءات Firestore
    final String dateStr = ConfigService().examEndDate;
    final targetDate = DateTime.tryParse(dateStr) ?? DateTime(2026, 6, 15);
    final now = DateTime.now();

    if (now.isAfter(targetDate)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.white, size: 40),
            SizedBox(height: 12),
            Text(
              'انتهت فترة أداء الامتحان الوطني',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final difference = targetDate.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2B4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: Color(0xFFFACC15), size: 24),
              SizedBox(width: 8),
              Text(
                'المتبقي على انتهاء الامتحان الوطني',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFACC15), fontFamily: 'Tajawal'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit('$days', 'يوم'),
              const SizedBox(width: 12),
              _buildTimeUnit('$hours', 'ساعة'),
              const SizedBox(width: 12),
              _buildTimeUnit('$minutes', 'دقيقة'),
              const SizedBox(width: 12),
              _buildTimeUnit('$seconds', 'ثانية'),
            ],
          ),
          const SizedBox(height: 12),
          Text('📅 ينتهي في $dateStr', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFCD34D), fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  Widget _buildSubjectQuestionCount(String key, Color color, IconData icon, String subtitle) {
    final data = _subjectsData[key];
    final bool isLoading = data?['loading'] ?? true;
    final int count = data?['count'] ?? 0;
    final String name = data?['name'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: color.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppRadius.borderFull,
                border: Border.all(color: color.withOpacity(0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.style_rounded, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '$count سؤال',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: AppTextStyles.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 65,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Tajawal'),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70, fontFamily: 'Tajawal')),
      ],
    );
  }

  Widget _buildInstructionPoint({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheatingCase(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 15)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Tajawal',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'), textAlign: TextAlign.center),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Tajawal'), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // هيدر أبل آيفون الفاخر لشاشة الأدوات
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: Color(0xFFFACC15), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مركز الأدوات والخدمات',
                            style: GoogleFonts.notoKufiArabic(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'وصول سريع لخدمات وفحوصات الامتحان الوطني',
                            style: GoogleFonts.notoKufiArabic(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // بنر لوحة المتصدرين الفاخر
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.35), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFACC15).withOpacity(0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFACC15), Color(0xFFD97706)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFACC15).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF0F172A), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'لوحة الشرف والمتصدرين',
                                      style: GoogleFonts.notoKufiArabic(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFACC15).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'جديد',
                                        style: TextStyle(
                                          color: Color(0xFFFACC15),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'شاهد تصنيف وترتيب الطلاب الأوائل على العراق',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFACC15), size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // بطاقة خزنة المذاكرة والبطاقات الذكية الفخمة (Featured Smart Vault)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SmartVaultScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.style_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'خزنة المذاكرة والبطاقات الذكية',
                                      style: GoogleFonts.notoKufiArabic(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'جديد 🔥',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'بطاقات فلاشية تفاعلية 3D • الأسئلة المفضلة • معالجة الأخطاء',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ⚡ بطاقة تحدي صح أم خطأ السريع الفاخرة
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.trueFalseQuiz);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.flash_on_rounded, color: Color(0xFFFDE68A), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'اختبار صح أم خطأ السريع',
                                      style: GoogleFonts.notoKufiArabic(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '⚡ برق',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'تحدي 10 ثوانٍ • تثبيت المفاهيم والقواعد الوزارية بلمسة واحدة',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // شبكة الأدوات بنمط أبل التفاعلي (Apple Control Grid)
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.history_edu_rounded,
                    title: 'الاختبارات السابقة',
                    subtitle: 'سجل درجاتي ومراجعتها',
                    color: const Color(0xFF6366F1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PreviousExamsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.psychology_alt_rounded,
                    title: 'بنك أخطائي',
                    subtitle: 'مراجعة أخطائي السابقة',
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.mistakes),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.search_rounded,
                    title: 'البحث في الأسئلة',
                    subtitle: 'محرك بحث فوري',
                    color: const Color(0xFF2563EB),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.questionSearch),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.bolt_rounded,
                    title: 'تحدي الـ 60 ثانية',
                    subtitle: 'اختبار السرعة الحماسي',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.speedQuiz),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.alarm_rounded,
                    title: 'المنبه وسؤال اليوم',
                    subtitle: 'تحدي مسائي 8:00 م',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'فحص الشهادة',
                    subtitle: 'مسح QR المباشر',
                    color: const Color(0xFF00C853),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CertificateVerificationScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.calculate_rounded,
                    title: 'الحاسبة التنافسية',
                    subtitle: 'حساب المعدل التفاضلي',
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.competitiveCalculator),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.stars_rounded,
                    title: 'درجة التأهيل',
                    subtitle: 'حسب تخصصك الدراسي',
                    color: const Color(0xFF2563EB),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QualificationScoreScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.menu_book_rounded,
                    title: 'ضوابط القبول',
                    subtitle: 'الدليل الوزاري الرسمي',
                    color: const Color(0xFF4F46E5),
                    onTap: () {
                      final admissionsUrl = ConfigService().admissionsPdfUrl;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LuxuryPdfViewerScreen(
                            title: 'ضوابط التقديم والقبول',
                            fileOrUrl: admissionsUrl,
                            isLocalFile: admissionsUrl.startsWith('assets/'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.location_on_rounded,
                    title: 'المراكز الامتحانية',
                    subtitle: 'دليل المراكز بالمحافظات',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExamCentersScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'تحفيز الدراسات',
                    subtitle: 'ومضات وهمم القبول',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.motivationalQuotes),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'جدول الامتحانات',
                    subtitle: 'عرض الجدول الرسمي',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.examScheduleViewer),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.gavel_rounded,
                    title: 'تعليمات الامتحان',
                    subtitle: 'إرشادات هامة للطالب',
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExamInstructionsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.help_outline_rounded,
                    title: 'عن الامتحان',
                    subtitle: 'تفاصيل الاختبار الوطني',
                    color: const Color(0xFF0284C7),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutNationalExamScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildIosToolCard(
                    icon: Icons.send_rounded,
                    title: 'قناة التليجرام',
                    subtitle: 'القناة الرسمية للتطبيق',
                    color: const Color(0xFF0088CC),
                    onTap: _openTelegramChannel,
                  ),
                  const SizedBox(width: 12),
                  _buildIosToolCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'حساب الانستغرام',
                    subtitle: '@a0g0a الرسمية',
                    color: const Color(0xFFE1306C),
                    onTap: _openInstagramAccount,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // بطاقة إحصائيات الأسئلة بنمط آيفون المجمع (Grouped iOS Card)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Icon(Icons.quiz_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'أسئلة التطبيق المتوفرة',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.borderFull,
                          ),
                          child: Text(
                            'البنك المعتمد',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSubjectQuestionCount(
                      'arabic',
                      const Color(0xFF00C853),
                      Icons.menu_book_rounded,
                      'أسئلة وقواعد اللغة العربية',
                    ),
                    const SizedBox(height: 10),
                    _buildSubjectQuestionCount(
                      'computer',
                      AppColors.primary,
                      Icons.computer_rounded,
                      'مبادئ وأساسيات الحاسوب',
                    ),
                    const SizedBox(height: 10),
                    _buildSubjectQuestionCount(
                      'english',
                      AppColors.warning,
                      Icons.language_rounded,
                      'القواعد والمفردات الإنجليزية',
                    ),
                    const SizedBox(height: 16),
                    // زر التحديث والمزامنة للأوفلاين
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isSyncingQuestions ? null : _syncQuestionsNow,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSyncingQuestions)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFFACC15),
                                    ),
                                  )
                                else
                                  const Icon(Icons.sync_rounded, color: Color(0xFFFACC15), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isSyncingQuestions ? 'جاري تحديث الأسئلة...' : 'تحديث بنك الأسئلة (أوفلاين)',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_lastSyncDate != null) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'آخر تحديث: ${_lastSyncDate!.year}/${_lastSyncDate!.month}/${_lastSyncDate!.day}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // تنبيه مصدر الأسئلة بنمط أبل
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مصدر الأسئلة المعتمد',
                            style: GoogleFonts.notoKufiArabic(
                              color: const Color(0xFF1E40AF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'الأسئلة مستخرجة ومطابقة للامتحانات الفعالية المعتمدة في الجامعات العراقية.',
                            style: GoogleFonts.notoKufiArabic(
                              color: const Color(0xFF3B82F6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const LuxuryExamCountdownCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIosToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C31) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 14),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
