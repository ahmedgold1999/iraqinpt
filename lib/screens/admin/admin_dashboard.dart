import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/question_model.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_update_service.dart';
import '../../services/question_service.dart';
import '../../services/config_service.dart';
import '../../services/notification_service.dart';
import '../../services/dynamic_app_icon_service.dart';
import '../../routes.dart';
import 'leaderboard_management_screen.dart';
import 'specialized_exams_management_screen.dart';
import '../student/about_national_exam_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Active Tab: 0 = KPIs, 1 = Students, 2 = Notifications, 3 = Announcement
  int _selectedTabIndex = 0;

  // KPI Data
  int _totalUsers = 0;
  int _premiumUsers = 0;
  int _leaderboardCount = 0;
  bool _isLoadingKpi = true;

  // Search & Pagination
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userFilter = 'all'; // all, premium, free
  Timer? _debounceTimer;

  List<DocumentSnapshot> _userDocs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoadingUsers = false;
  bool _isLoadingMore = false;
  bool _hasMoreUsers = true;
  static const int _pageSize = 50;

  // Notification Composer
  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifBodyController = TextEditingController();
  String _notifType = 'info';
  String _notifTargetSegment = 'all'; // 'all', 'premium', 'free'
  bool _isSendingNotif = false;

  // JSON Bulk Questions Importer State
  final TextEditingController _jsonQuestionsController = TextEditingController();
  String _selectedBulkSubject = 'arabic';
  List<Question> _parsedQuestions = [];
  String? _jsonParseError;
  bool _isImportingQuestions = false;

  // Announcement State
  bool _annEnabled = false;
  final TextEditingController _annTextController = TextEditingController();
  final TextEditingController _annLinkController = TextEditingController();
  String _annType = 'info';
  bool _isSavingAnn = false;

  // App Update & Maintenance State
  TextEditingController _versionController = TextEditingController();
  TextEditingController _updateUrlController = TextEditingController();
  TextEditingController _changeLogController = TextEditingController();

  // إعدادات أندرويد المنفصلة
  TextEditingController _androidVersionController = TextEditingController();
  TextEditingController _androidUpdateUrlController = TextEditingController();
  bool _androidForceUpdate = false;

  // إعدادات آيفون المنفصلة
  TextEditingController _iosVersionController = TextEditingController();
  TextEditingController _iosUpdateUrlController = TextEditingController();
  bool _iosForceUpdate = false;
  // وضع مراجعة أبل ستور (خاص بالآيفون فقط)
  bool _iosReviewMode = false;

  // منصة الصيانة المستهدفة
  String _maintenancePlatform = 'all'; // 'all', 'android', 'ios'
  TextEditingController _price1mController = TextEditingController(text: '10,000');
  TextEditingController _price2mController = TextEditingController(text: '15,000');
  TextEditingController _price3mController = TextEditingController(text: '20,000');
  TextEditingController _price1yController = TextEditingController(text: '30,000');
  TextEditingController _examEndDateController = TextEditingController(text: '2026-06-15');
  TextEditingController _admissionsPdfUrlController = TextEditingController(
      text: 'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf');
  TextEditingController _fcmServerKeyController =
      TextEditingController(text: 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0');
  TextEditingController _serviceAccountJsonController =
      TextEditingController(text: NotificationService.defaultServiceAccountJson);
  bool _isForceUpdate = false;
  bool _isMaintenanceOn = false;
  bool _targetAndroid = true;
  bool _targetIos = true;
  bool _targetWeb = true;
  bool _isLoadingUpdateConfig = false;
  bool _isSavingUpdateConfig = false;
  String _currentInstalledVersion = '';

  // Materials & Google Forms Manager State
  String _materialCategoryFilter = 'all'; // all, computer, arabic, english
  String _materialTypeFilter = 'all'; // all, materials, forms

  // Support Tickets Manager State
  String _supportFilterStatus = 'all'; // all, pending, resolved
  String _supportCategoryFilter = 'all'; // all, question, technical_issue, subscription, suggestion, materials, other

  @override
  void initState() {
    super.initState();
    _ensureUpdateControllers();
    _loadKpis();
    _fetchUsers(isRefresh: true);
    _loadAnnouncement();
    _loadUpdateConfig();
  }

  void _ensureUpdateControllers() {
    _androidVersionController ??= TextEditingController();
    _androidUpdateUrlController ??= TextEditingController();
    _iosVersionController ??= TextEditingController();
    _iosUpdateUrlController ??= TextEditingController();
    _versionController ??= TextEditingController();
    _updateUrlController ??= TextEditingController();
    _changeLogController ??= TextEditingController();
    _price1mController ??= TextEditingController(text: '10,000');
    _price2mController ??= TextEditingController(text: '15,000');
    _price3mController ??= TextEditingController(text: '20,000');
    _price1yController ??= TextEditingController(text: '30,000');
    _examEndDateController ??= TextEditingController(text: '2026-06-15');
    _admissionsPdfUrlController ??= TextEditingController(
        text: 'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf');
    _fcmServerKeyController ??=
        TextEditingController(text: 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0');
    _serviceAccountJsonController ??= TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _jsonQuestionsController.dispose();
    _annTextController.dispose();
    _annLinkController.dispose();
    _versionController.dispose();
    _updateUrlController.dispose();
    _changeLogController.dispose();
    _price1mController.dispose();
    _price2mController.dispose();
    _price3mController.dispose();
    _price1yController.dispose();
    _examEndDateController.dispose();
    _admissionsPdfUrlController.dispose();
    _fcmServerKeyController.dispose();
    _serviceAccountJsonController.dispose();
    super.dispose();
  }

  Future<void> _loadKpis() async {
    setState(() => _isLoadingKpi = true);
    try {
      final totalUsersSnap = await _db.collection('users').count().get();
      final premiumUsersSnap =
          await _db.collection('users').where('isPremium', isEqualTo: true).count().get();
      final leaderboardSnap = await _db.collection('leaderboard').count().get();

      if (mounted) {
        setState(() {
          _totalUsers = totalUsersSnap.count ?? 0;
          _premiumUsers = premiumUsersSnap.count ?? 0;
          _leaderboardCount = leaderboardSnap.count ?? 0;
          _isLoadingKpi = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingKpi = false);
    }
  }

  // ✅ دالة تطبيع النصوص العربية لجعل البحث دقيقاً وشاملاً لكافة الحالات
  String _normalizeSearchText(String input) {
    var s = input.trim().toLowerCase();
    // إزالة التشكيل وحركات الإعراب
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // تطبيع الألف والهمزات المختلفة
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // تطبيع التاء المربوطة والهاء
    s = s.replaceAll('ة', 'ه');
    // تطبيع الياء والألف المقصورة
    s = s.replaceAll('ى', 'ي');
    // إزالة الفراغات المكررة
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  // ✅ جلب كافة الطلاب والمشتركين مباشرة بدون قيود أو زر عرض المزيد
  Future<void> _fetchUsers({bool isRefresh = false}) async {
    setState(() {
      _isLoadingUsers = true;
      _userDocs.clear();
      _lastDoc = null;
      _hasMoreUsers = false;
    });

    try {
      final snapshot = await _db.collection('users').get();

      if (mounted) {
        setState(() {
          _userDocs = snapshot.docs;
          _isLoadingUsers = false;
          _isLoadingMore = false;
          _hasMoreUsers = false;
          _totalUsers = snapshot.docs.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
      }
    });
  }

  // ✅ استخراج البريد الإلكتروني للمستخدم حتى لو كان مسجلاً باسم المستخدم فقط
  String _resolveUserEmail(Map<String, dynamic> data) {
    final email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty && email != 'null' && email != 'بدون بريد' && email != 'بدون بريد إلكتروني') {
      return email;
    }
    final username = (data['username'] ?? '').toString().trim();
    if (username.isNotEmpty && username != 'null') {
      return '$username@ahmeed.inpt';
    }
    return 'بدون بريد';
  }

  // ✅ استخراج اسم المستخدم
  String _resolveUsername(Map<String, dynamic> data) {
    final username = (data['username'] ?? '').toString().trim();
    if (username.isNotEmpty && username != 'null') {
      return username;
    }
    final email = (data['email'] ?? '').toString().trim();
    if (email.contains('@ahmeed.inpt')) {
      return email.split('@')[0];
    }
    return '';
  }

  Future<void> _loadAnnouncement() async {
    try {
      final doc = await _db.collection('system_settings').doc('announcement').get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _annEnabled = data['isEnabled'] ?? false;
          _annTextController.text = data['text'] ?? '';
          _annLinkController.text = data['link'] ?? '';
          _annType = data['type'] ?? 'info';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAnnouncement() async {
    setState(() => _isSavingAnn = true);
    try {
      await AnnouncementService.updateAnnouncement(
        AppAnnouncement(
          isEnabled: _annEnabled,
          text: _annTextController.text.trim(),
          link: _annLinkController.text.trim().isNotEmpty
              ? _annLinkController.text.trim()
              : null,
          type: _annType,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث شريط الإعلانات بنجاح!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAnn = false);
    }
  }

  Future<void> _sendBroadcastNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة عنوان ونص الإشعار')),
      );
      return;
    }

    setState(() => _isSendingNotif = true);
    try {
      final docRef = _db.collection('all_notifications').doc();
      final notifData = {
        'id': docRef.id,
        'title': title,
        'body': body,
        'message': body,
        'type': _notifType,
        'createdAt': FieldValue.serverTimestamp(),
        'target': _notifTargetSegment,
        'isGlobal': true,
        'readBy': [],
      };

      await docRef.set(notifData);

      // إرسال عبر FCM Push لضمان وصوله لجميع الهواتف والتطبيق مغلق
      final fcmResult = await NotificationService.sendBroadcastPush(
        title: title,
        body: body,
        targetSegment: _notifTargetSegment,
      );

      _notifTitleController.clear();
      _notifBodyController.clear();

      if (mounted) {
        String targetText = 'لجميع الطلاب';
        if (_notifTargetSegment == 'premium') targetText = 'للطلاب المميزين فقط 👑';
        if (_notifTargetSegment == 'free') targetText = 'للطلاب المجانيين فقط 🆓';

        if (fcmResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚀 تم حفظ الإشعار وإرساله سحابياً لجميع الأجهزة ($targetText)!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ تم حفظ الإشعار في التطبيق ولكن: ${fcmResult.message}'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingNotif = false);
    }
  }

  void _validateAndParseJson(String rawText) {
    if (rawText.trim().isEmpty) {
      setState(() {
        _parsedQuestions = [];
        _jsonParseError = null;
      });
      return;
    }

    try {
      final dynamic decoded = json.decode(rawText);
      List<dynamic> list = [];
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('questions')) {
        list = decoded['questions'] as List<dynamic>;
      } else {
        throw const FormatException('يجب أن يكون الـ JSON إما مصفوفة [] أو كائناً يحتوي على المفتاح "questions"');
      }

      final List<Question> validList = [];
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is! Map<String, dynamic>) {
          throw FormatException('العنصر رقم ${i + 1} ليس كائناً صحيحاً (JSON Object)');
        }
        final qText = (item['question'] ?? '').toString().trim();
        final ansText = (item['originalAnswer'] ?? item['answer'] ?? '').toString().trim();
        List<String> options = [];
        if (item['options'] is List) {
          options = (item['options'] as List).map((e) => e.toString().trim()).toList();
        }

        if (qText.isEmpty) {
          throw FormatException('السؤال رقم ${i + 1} لا يحتوي على نص السؤال ("question")');
        }
        if (ansText.isEmpty) {
          throw FormatException('السؤال رقم ${i + 1} لا يحتوي على الإجابة الصحيحة ("originalAnswer")');
        }
        if (!options.contains(ansText) && options.isNotEmpty) {
          options.insert(0, ansText);
        }

        validList.add(
          Question(
            question: qText,
            options: options,
            answer: ansText,
            originalAnswer: ansText,
            explanation: item['explanation']?.toString(),
          ),
        );
      }

      setState(() {
        _parsedQuestions = validList;
        _jsonParseError = null;
      });
    } catch (e) {
      setState(() {
        _parsedQuestions = [];
        _jsonParseError = e.toString().replaceAll('FormatException: ', '');
      });
    }
  }

  Future<void> _importQuestionsToFirebase() async {
    if (_parsedQuestions.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد استيراد الأسئلة 📦', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من رغبتك في رفع ${_parsedQuestions.length} سؤال إلى بنك أسئلة (${_getSubjectArabicName(_selectedBulkSubject)})؟',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تأكيد وحفظ', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isImportingQuestions = true);
    try {
      final questionsMaps = _parsedQuestions.map((q) => q.toMap()).toList();

      // Save to Firebase system_settings collection
      await _db.collection('system_settings').doc('questions_data').set({
        _selectedBulkSubject: questionsMaps,
        'last_updated_${_selectedBulkSubject}': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also save to dedicated subject doc for high scalability
      await _db.collection('questions_bank').doc(_selectedBulkSubject).set({
        'subject': _selectedBulkSubject,
        'count': questionsMaps.length,
        'questions': questionsMaps,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 تم استيراد وحفظ ${_parsedQuestions.length} سؤال في بنك الأسئلة بنجاح!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _jsonQuestionsController.clear();
        setState(() {
          _parsedQuestions = [];
          _jsonParseError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاستيراد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingQuestions = false);
    }
  }

  String _getSubjectArabicName(String key) {
    switch (key) {
      case 'arabic':
        return 'اللغة العربية';
      case 'computer':
        return 'علوم الحاسوب';
      case 'english':
        return 'اللغة الإنجليزية';
      default:
        return 'الثقافة العامة والتنافسي';
    }
  }

  Future<void> _loadUpdateConfig() async {
    _ensureUpdateControllers();
    setState(() => _isLoadingUpdateConfig = true);
    try {
      final info = await PackageInfo.fromPlatform();
      _currentInstalledVersion = info.version;

      final doc = await _db.collection('system_settings').doc('maintenance_and_updates').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _versionController.text = (data['latest_version'] ?? data['version'] ?? '1.0.0').toString();
        _updateUrlController.text = (data['update_url'] ?? data['url'] ?? '').toString();
        _changeLogController.text = (data['change_log'] ?? data['notes'] ?? '').toString();
        _isForceUpdate = data['is_force_update'] ?? data['forceUpdate'] ?? false;
        _isMaintenanceOn = data['is_maintenance_on'] ?? false;
        _maintenancePlatform = (data['maintenance_platform'] ?? 'all').toString();
        _targetAndroid = data['target_android'] ?? true;
        _targetIos = data['target_ios'] ?? true;
        _targetWeb = data['target_web'] ?? true;

        // تحميل بيانات أندرويد المستقلة
        _androidVersionController.text = (data['android_latest_version'] ?? data['latest_version'] ?? '').toString();
        _androidUpdateUrlController.text = (data['android_update_url'] ?? data['update_url'] ?? '').toString();
        _androidForceUpdate = data['android_force_update'] ?? data['is_force_update'] ?? false;

        // تحميل بيانات آيفون المستقلة (عزل كامل دون أي اعتماد على بيانات الأندرويد)
        _iosVersionController.text = (data['ios_latest_version'] ?? '').toString();
        _iosUpdateUrlController.text = (data['ios_update_url'] ?? '').toString();
        _iosForceUpdate = data['ios_force_update'] ?? false;
        _iosReviewMode = data['ios_review_mode'] ?? false;
        _price1mController.text = (data['price_1m'] ?? '10,000').toString();
        _price2mController.text = (data['price_2m'] ?? '15,000').toString();
        _price3mController.text = (data['price_3m'] ?? '20,000').toString();
        _price1yController.text = (data['price_1y'] ?? '30,000').toString();
        _examEndDateController.text = (data['exam_end_date'] ?? '2026-06-15').toString();
        _admissionsPdfUrlController.text = (data['admissions_pdf_url'] ??
                data['mohesr_pdf_url'] ??
                'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf')
            .toString();
        final loadedKey = (data['fcm_server_key'] ?? '').toString().trim();
        _fcmServerKeyController.text = loadedKey.isNotEmpty ? loadedKey : 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0';
        final loadedJson = (data['service_account_json'] ?? '').toString().trim();
        _serviceAccountJsonController.text = loadedJson.isNotEmpty
            ? loadedJson
            : NotificationService.defaultServiceAccountJson;
      } else {
        final fallback = await _db.collection('app_config').doc('version').get();
        if (fallback.exists && fallback.data() != null) {
          final data = fallback.data()!;
          _versionController.text = (data['version'] ?? '1.0.0').toString();
          _updateUrlController.text = (data['url'] ?? '').toString();
          _changeLogController.text = (data['change_log'] ?? '').toString();
          _isForceUpdate = data['forceUpdate'] ?? false;
          _targetAndroid = data['target_android'] ?? true;
          _targetIos = data['target_ios'] ?? true;
          _targetWeb = data['target_web'] ?? true;

          _androidVersionController.text = (data['android_latest_version'] ?? data['version'] ?? '').toString();
          _androidUpdateUrlController.text = (data['android_update_url'] ?? data['url'] ?? '').toString();
          _androidForceUpdate = data['android_force_update'] ?? data['forceUpdate'] ?? false;

          _iosVersionController.text = (data['ios_latest_version'] ?? '').toString();
          _iosUpdateUrlController.text = (data['ios_update_url'] ?? '').toString();
          _iosForceUpdate = data['ios_force_update'] ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error loading update config: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUpdateConfig = false);
    }
  }

  Future<void> _saveUpdateConfig() async {
    _ensureUpdateControllers();
    final androidVer = _androidVersionController.text.trim();
    final androidUrl = _androidUpdateUrlController.text.trim();
    final iosVer = _iosVersionController.text.trim();
    final iosUrl = _iosUpdateUrlController.text.trim();

    if (androidVer.isEmpty && iosVer.isEmpty && _versionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة رقم الإصدار للأندرويد أو الآيفون')),
      );
      return;
    }

    if (_versionController.text.trim().isEmpty) {
      _versionController.text = androidVer.isNotEmpty ? androidVer : iosVer;
    }
    if (_updateUrlController.text.trim().isEmpty) {
      _updateUrlController.text = androidUrl.isNotEmpty ? androidUrl : iosUrl;
    }

    setState(() => _isSavingUpdateConfig = true);
    try {

      final updateData = {
        // أندرويد
        'android_latest_version': androidVer,
        'android_update_url': androidUrl,
        'android_force_update': _androidForceUpdate,
        'target_android': _targetAndroid,

        // آيفون
        'ios_latest_version': iosVer,
        'ios_update_url': iosUrl,
        'ios_force_update': _iosForceUpdate,
        'target_ios': _targetIos,
        'ios_review_mode': _iosReviewMode,

        // الصيانة
        'is_maintenance_on': _isMaintenanceOn,
        'maintenance_platform': _maintenancePlatform,

        // الحقول العامة للتوافقية
        'latest_version': androidVer.isNotEmpty ? androidVer : (_versionController.text.trim().isNotEmpty ? _versionController.text.trim() : iosVer),
        'version': androidVer.isNotEmpty ? androidVer : (_versionController.text.trim().isNotEmpty ? _versionController.text.trim() : iosVer),
        'update_url': androidUrl.isNotEmpty ? androidUrl : (_updateUrlController.text.trim().isNotEmpty ? _updateUrlController.text.trim() : iosUrl),
        'url': androidUrl.isNotEmpty ? androidUrl : (_updateUrlController.text.trim().isNotEmpty ? _updateUrlController.text.trim() : iosUrl),
        'is_force_update': _androidForceUpdate || _iosForceUpdate || _isForceUpdate,
        'forceUpdate': _androidForceUpdate || _iosForceUpdate || _isForceUpdate,
        'target_web': _targetWeb,
        'change_log': _changeLogController.text.trim(),
        'price_1m': _price1mController.text.trim().isNotEmpty ? _price1mController.text.trim() : '10,000',
        'price_2m': _price2mController.text.trim().isNotEmpty ? _price2mController.text.trim() : '15,000',
        'price_3m': _price3mController.text.trim().isNotEmpty ? _price3mController.text.trim() : '20,000',
        'price_1y': _price1yController.text.trim().isNotEmpty ? _price1yController.text.trim() : '30,000',
        'exam_end_date': _examEndDateController.text.trim().isNotEmpty ? _examEndDateController.text.trim() : '2026-06-15',
        'admissions_pdf_url': _admissionsPdfUrlController.text.trim().isNotEmpty
            ? _admissionsPdfUrlController.text.trim()
            : 'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf',
        'fcm_server_key': _fcmServerKeyController.text.trim(),
        'service_account_json': _serviceAccountJsonController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('system_settings').doc('maintenance_and_updates').set(updateData, SetOptions(merge: true));
      await _db.collection('app_config').doc('version').set(updateData, SetOptions(merge: true));

      // تحديث الحالة محلياً وفورياً
      ConfigService().setMaintenanceLocal(_isMaintenanceOn);
      ConfigService().setIosReviewModeLocal(_iosReviewMode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isMaintenanceOn
                  ? 'تم تفعيل وضع الصيانة الشامل وتعميمه على التطبيق بنجاح! 🛠️'
                  : 'تم حفظ وتعميم إعدادات التحديث لجميع الطلاب بنجاح! 🚀',
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingUpdateConfig = false);
    }
  }

  Future<void> _updateStudentData(String uid, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(uid).update(updateData);

      // مزامنة الاسم الفعلي مع لوحة الشرف فوراً
      if (updateData.containsKey('name')) {
        try {
          await _db.collection('leaderboard').doc(uid).update({
            'name': updateData['name'],
          });
        } catch (_) {}
      }

      _fetchUsers(isRefresh: true);
      _loadKpis();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحديث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePasswordDialog(String uid, String name) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعيين كلمة مرور لـ $name',
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اكتب كلمة المرور الجديدة لحفظها في الحساب لتظهر لك وللطالب مباشرة:',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(
                hintText: 'كلمة المرور الجديدة (مثال: 123456)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = passCtrl.text.trim();
              if (newPass.isNotEmpty) {
                await _db.collection('users').doc(uid).set({'password': newPass}, SetOptions(merge: true));
                if (mounted) {
                  Navigator.pop(ctx);
                  if (Navigator.canPop(context)) Navigator.pop(context); // close bottom sheet to refresh
                  _fetchUsers(isRefresh: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ وتحديث كلمة المرور بنجاح!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حفظ كلمة المرور', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // مساعدات فحص الصلاحية والاشتراك
  // =========================================================================
  static DateTime? _extractUserExpiryDate(Map<String, dynamic> data) {
    final rawExpiry = data['expiryDate'] ?? data['premiumUntil'];
    if (rawExpiry == null) return null;
    if (rawExpiry is Timestamp) {
      return rawExpiry.toDate();
    } else if (rawExpiry is String) {
      return DateTime.tryParse(rawExpiry);
    } else if (rawExpiry is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawExpiry);
    }
    return null;
  }

  static bool _isUserSubscriptionActive(Map<String, dynamic> data) {
    final isPremium = data['isPremium'] == true;
    if (!isPremium) return false;
    final expiry = _extractUserExpiryDate(data);
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      return false; // انتهت الصلاحية
    }
    return true;
  }

  // =========================================================================
  // نافذة تفاصيل الطالب وتعديل الاسم والاشتراك (Student Details & Editor Sheet)
  // =========================================================================
  void _showStudentDetailsSheet(BuildContext context, String uid, Map<String, dynamic> data) {
    final initialName = data['name'] ?? data['displayName'] ?? 'طالب';
    final TextEditingController nameEditController = TextEditingController(text: initialName);
    
    // استخراج تاريخ انتهاء الصلاحية بدقة وفحص الانتهاء
    final expiryDate = _extractUserExpiryDate(data);
    final bool isExpired = expiryDate != null && DateTime.now().isAfter(expiryDate);
    final bool isPremium = (data['isPremium'] == true) && !isExpired;

    // حساب نوع الاشتراك الفعلي
    String selectedSubscription = 'none';
    final savedPlan = (data['subscriptionPlan'] ?? data['plan'] ?? data['subscriptionType'])?.toString();

    if (savedPlan != null && ['none', '1_month', '2_months', '3_months', '1_year', 'lifetime'].contains(savedPlan)) {
      selectedSubscription = isExpired ? 'none' : savedPlan;
    } else if (isPremium && expiryDate != null) {
      final now = DateTime.now();
      final daysLeft = expiryDate.difference(now).inDays;
      
      DateTime? startDate;
      final dynamic rawStart = data['activatedAt'] ?? data['subscriptionDate'] ?? data['updatedAt'] ?? data['createdAt'];
      if (rawStart is Timestamp) {
        startDate = rawStart.toDate();
      } else if (rawStart is String) {
        startDate = DateTime.tryParse(rawStart);
      }

      int totalDays = daysLeft;
      if (startDate != null && expiryDate.isAfter(startDate)) {
        totalDays = expiryDate.difference(startDate).inDays;
      }

      if (totalDays > 730 || daysLeft > 500) {
        selectedSubscription = 'lifetime';
      } else if (totalDays >= 150 || daysLeft > 95) {
        selectedSubscription = '1_year';
      } else if (totalDays >= 75 || daysLeft > 62) {
        selectedSubscription = '3_months';
      } else if (totalDays >= 45 || daysLeft > 32) {
        selectedSubscription = '2_months';
      } else {
        selectedSubscription = '1_month';
      }
    } else if (isPremium) {
      selectedSubscription = '1_year';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentName = nameEditController.text.trim();
          final email = _resolveUserEmail(data);
          final username = _resolveUsername(data);
          final password = (data['password'] ?? data['pass'] ?? data['plainPassword'] ?? '').toString().trim();
          final phone = data['phone'] ?? data['phoneNumber'] ?? 'غير مسجل';
          final role = data['role'] ?? 'student';
          final deviceId = data['deviceId'] ?? 'غير مقيد';
          bool isSavingChanges = false;

          DateTime? createdAt;
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }

          int daysLeft = 0;
          if (isPremium && expiryDate != null) {
            daysLeft = expiryDate.difference(DateTime.now()).inDays;
            if (daysLeft < 0) daysLeft = 0;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C31) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 6),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تعديل بيانات واشتراك الطالب',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. حقل تعديل اسم الطالب
                          Text(
                            '👤 اسم الطالب الكامل:',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameEditController,
                            decoration: InputDecoration(
                              hintText: 'اكتب اسم الطالب الجديد هنا...',
                              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                              ),
                            ),
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2. قائمة اختيار نوع ومدة الاشتراك
                          Text(
                            '⭐ باقة وصلاحية الاشتراك:',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSubscription,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF131C31) : Colors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'none',
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock_outline_rounded, color: Colors.red, size: 18),
                                        SizedBox(width: 10),
                                        Text('غير مفعل (حساب مجاني)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '1_month',
                                    child: Row(
                                      children: [
                                        Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 18),
                                        SizedBox(width: 10),
                                        Text('اشتراك شهر واحد (30 يوم)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '2_months',
                                    child: Row(
                                      children: [
                                        Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 18),
                                        SizedBox(width: 10),
                                        Text('اشتراك شهرين (60 يوم)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '3_months',
                                    child: Row(
                                      children: [
                                        Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 18),
                                        SizedBox(width: 10),
                                        Text('اشتراك 3 أشهر (90 يوم)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '1_year',
                                    child: Row(
                                      children: [
                                        Icon(Icons.workspace_premium_rounded, color: Color(0xFF16A34A), size: 18),
                                        SizedBox(width: 10),
                                        Text('اشتراك سنة كاملة (365 يوم) ⭐', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'lifetime',
                                    child: Row(
                                      children: [
                                        Icon(Icons.military_tech_rounded, color: Color(0xFFD97706), size: 18),
                                        SizedBox(width: 10),
                                        Text('تفعيل دائمي (مدى الحياة) 👑', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      selectedSubscription = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // شريط توضيحي لحالة الاشتراك الحالية
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.red.withOpacity(0.08)
                                  : (isPremium
                                      ? const Color(0xFF16A34A).withOpacity(0.08)
                                      : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isExpired
                                    ? Colors.red.withOpacity(0.3)
                                    : (isPremium
                                        ? const Color(0xFF16A34A).withOpacity(0.3)
                                        : (isDark ? Colors.white10 : Colors.grey.shade300)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isExpired
                                      ? Icons.error_outline_rounded
                                      : (isPremium ? Icons.check_circle_rounded : Icons.info_outline_rounded),
                                  color: isExpired
                                      ? Colors.red
                                      : (isPremium ? const Color(0xFF16A34A) : Colors.grey.shade600),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isExpired
                                        ? '⚠️ هذا الحساب منتهي الصلاحية بتاريخ ${expiryDate != null ? DateFormat('yyyy/MM/dd').format(expiryDate) : ''}. يمكنك اختيار مدة جديدة وحفظ التعديل للتجديد.'
                                        : (isPremium && expiryDate != null
                                            ? '✅ الاشتراك نشط لغاية ${DateFormat('yyyy/MM/dd').format(expiryDate)} (متبقي $daysLeft يوم).'
                                            : (isPremium ? '✅ اشتراك نشط (بدون انتهاء محدد).' : '🔒 الحساب حالياً غير مفعّل (مجاني).')),
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isExpired
                                          ? Colors.red.shade700
                                          : (isPremium
                                              ? const Color(0xFF15803D)
                                              : (isDark ? Colors.white70 : Colors.black87)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3. معلومات الطالب التفصيلية
                          Text(
                            '📋 تفاصيل الحساب:',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (username.isNotEmpty)
                            _buildDetailTile(
                              icon: Icons.alternate_email_rounded,
                              label: 'اسم المستخدم (Username)',
                              value: username,
                              actionIcon: Icons.copy_rounded,
                              actionTooltip: 'نسخ اسم المستخدم',
                              onAction: () {
                                Clipboard.setData(ClipboardData(text: username));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ اسم المستخدم!')),
                                );
                              },
                              isDark: isDark,
                            ),
                          _buildDetailTile(
                            icon: Icons.email_rounded,
                            label: 'البريد الإلكتروني',
                            value: email,
                            actionIcon: Icons.copy_rounded,
                            actionTooltip: 'نسخ البريد الإلكتروني',
                            onAction: () {
                              Clipboard.setData(ClipboardData(text: email));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ البريد!')),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDetailTile(
                            icon: Icons.lock_rounded,
                            label: 'كلمة المرور (Password)',
                            value: password.isNotEmpty ? password : 'مشفرة عبر Firebase Auth 🔒',
                            valueColor: password.isNotEmpty ? const Color(0xFF10B981) : null,
                            actionIcon: password.isNotEmpty ? Icons.copy_rounded : Icons.edit_rounded,
                            actionTooltip: password.isNotEmpty ? 'نسخ كلمة المرور' : 'تعيين كلمة مرور جديدة',
                            onAction: () {
                              if (password.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: password));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ كلمة المرور!')),
                                );
                              } else {
                                _showChangePasswordDialog(uid, currentName);
                              }
                            },
                            isDark: isDark,
                          ),
                          _buildDetailTile(
                            icon: Icons.phone_rounded,
                            label: 'رقم الهاتف',
                            value: phone,
                            isDark: isDark,
                          ),
                          _buildDetailTile(
                            icon: Icons.fingerprint_rounded,
                            label: 'معرف الطالب (UID)',
                            value: uid,
                            actionIcon: Icons.copy_rounded,
                            onAction: () {
                              Clipboard.setData(ClipboardData(text: uid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ الـ UID!')),
                              );
                            },
                            isDark: isDark,
                          ),
                          _buildDetailTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'تاريخ الإنشاء',
                            value: createdAt != null ? DateFormat('yyyy/MM/dd - hh:mm a').format(createdAt) : 'غير متوفر',
                            isDark: isDark,
                          ),
                          _buildDetailTile(
                            icon: Icons.phonelink_lock_rounded,
                            label: 'قفل الحساب على جهاز واحد (Device Lock)',
                            value: (deviceId == 'غير مقيد' || deviceId == 'تمت إعادة التعيين' || (data['deviceIds'] is List && (data['deviceIds'] as List).isEmpty))
                                ? 'غير مقيد (متاح للربط على أي جهاز جديد) 🟢'
                                : 'مقيد على جهاز: $deviceId 📱',
                            valueColor: (deviceId == 'غير مقيد' || deviceId == 'تمت إعادة التعيين' || (data['deviceIds'] is List && (data['deviceIds'] as List).isEmpty))
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            actionIcon: Icons.restart_alt_rounded,
                            actionTooltip: 'حذف المعرّف وإلغاء قيد الجهاز',
                            onAction: () async {
                              await _updateStudentData(uid, {
                                'deviceId': FieldValue.delete(),
                                'deviceIds': [],
                                'deviceBoundAt': FieldValue.delete(),
                              });
                              setModalState(() {
                                data['deviceId'] = 'غير مقيد';
                                data['deviceIds'] = [];
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ تم حذف معرف الجهاز وفك القيد! يستطيع الطالب الآن تسجيل الدخول من جهازه الجديد.'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),
                          // 4. زر حذف الحساب نهائياً
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.withOpacity(0.25)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => _confirmDeleteUser(context, ctx, uid, currentName),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'حذف حساب الطالب نهائياً من النظام 🗑️',
                                        style: GoogleFonts.notoKufiArabic(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Save Action Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSavingChanges
                            ? null
                            : () async {
                                final newName = nameEditController.text.trim();
                                if (newName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('يرجى كتابة اسم الطالب')),
                                  );
                                  return;
                                }

                                final Map<String, dynamic> updates = {
                                  'name': newName,
                                  'displayName': newName,
                                };

                                DateTime? newExpiry;
                                if (selectedSubscription == 'none') {
                                  updates['isPremium'] = false;
                                  updates['subscriptionPlan'] = 'none';
                                  updates['expiryDate'] = null;
                                  updates['premiumUntil'] = null;
                                } else {
                                  int durationDays = 30;
                                  if (selectedSubscription == '1_month') {
                                    durationDays = 30;
                                  } else if (selectedSubscription == '2_months') {
                                    durationDays = 60;
                                  } else if (selectedSubscription == '3_months') {
                                    durationDays = 90;
                                  } else if (selectedSubscription == '1_year') {
                                    durationDays = 365;
                                  } else if (selectedSubscription == 'lifetime') {
                                    durationDays = 3650;
                                  }

                                  newExpiry = DateTime.now().add(Duration(days: durationDays));
                                  updates['isPremium'] = true;
                                  updates['subscriptionPlan'] = selectedSubscription;
                                  updates['expiryDate'] = newExpiry;
                                  updates['premiumUntil'] = Timestamp.fromDate(newExpiry);
                                  updates['activatedAt'] = FieldValue.serverTimestamp();
                                }

                                await _updateStudentData(uid, updates);
                                if (Navigator.canPop(ctx)) {
                                  Navigator.pop(ctx);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ تم حفظ التعديلات والاشتراك بنجاح!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text(
                          'حفظ التعديلات والاشتراك 💾',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
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

  Future<void> _confirmDeleteUser(
    BuildContext rootContext,
    BuildContext sheetContext,
    String uid,
    String studentName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'تأكيد حذف الحساب',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف حساب الطالب "$studentName" نهائياً؟\n\n⚠️ سيتم مسح وثيقة الطالب وبياناته بالكامل من السيرفر ولا يمكن التراجع عن هذا الإجراء.',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13.5,
            color: Color(0xFFCBD5E1),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('نعم، احذف نهائياً', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.collection('users').doc(uid).delete();
        setState(() {
          _userDocs.removeWhere((doc) => doc.id == uid);
          if (_totalUsers > 0) _totalUsers--;
        });
        if (Navigator.canPop(sheetContext)) {
          Navigator.pop(sheetContext);
        }
        if (rootContext.mounted) {
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
              content: Text('✅ تم حذف حساب الطالب "$studentName" بنجاح!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (rootContext.mounted) {
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
              content: Text('❌ حدث خطأ أثناء حذف الحساب: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    IconData? actionIcon,
    String? actionTooltip,
    VoidCallback? onAction,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF94A3B8))),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actionIcon != null && onAction != null)
            IconButton(
              icon: Icon(actionIcon, size: 18, color: const Color(0xFF2563EB)),
              tooltip: actionTooltip,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131C31) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب المدير؟',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService().signOut();
              } catch (_) {}
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('نعم، تسجيل الخروج', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureUpdateControllers();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131C31) : Colors.white;

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
            }
          },
          tooltip: 'العودة',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'لوحة الإدارة الفاخرة',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.studentHome),
            icon: const Icon(Icons.school_rounded, size: 16, color: Color(0xFF2563EB)),
            label: const Text(
              'وضع الطالب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'تسجيل الخروج',
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTabButton(0, '📊 المؤشرات', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(1, '👥 إدارة الطلاب (${_totalUsers > 0 ? _totalUsers : _userDocs.length})', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(2, '📚 إدارة الملازم والفورمات', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(3, '📬 رسائل وتذاكر الدعم', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(4, '📢 إشعار جماعي', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(5, '📣 شريط التنبيه', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(6, '⚙️ التحديثات والصيانة', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(7, '🔥 استضافة وسيرفر Firebase', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(8, '🎨 أيقونة التطبيق الحية', isDark),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpecializedExamsManagementScreen()),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 5),
                          Text(
                            '🎯 الاختبارات التخصصية (GitHub JSON)',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildKpiOverviewTab(isDark),
          _buildStudentsManagerTab(isDark),
          _buildStudyMaterialsManagerTab(isDark),
          _buildSupportTicketsTab(isDark),
          _buildBroadcastNotificationTab(isDark),
          _buildAnnouncementTab(isDark),
          _buildUpdateSettingsTab(isDark),
          _buildFirebaseHostingTab(isDark),
          _buildAppIconManagerTab(isDark),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: 📊 Smart KPI Overview
  // ==========================================
  Widget _buildKpiOverviewTab(bool isDark) {
    if (_isLoadingKpi) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    final double premiumRatio =
        _totalUsers > 0 ? (_premiumUsers / _totalUsers) * 100 : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'إجمالي الطلاب المسجلين',
                  value: '$_totalUsers',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF2563EB),
                  subtitle: 'طالب في قاعدة البيانات',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'المشتركون المميزون',
                  value: '$_premiumUsers',
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFF16A34A),
                  subtitle: '${premiumRatio.toStringAsFixed(1)}% نسبة التفعيل',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'لوحة الشرف',
                  value: '$_leaderboardCount',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFD97706),
                  subtitle: 'طالب خاض الاختبارات',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaderboardManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'الاختبارات التخصصية',
                  value: 'GitHub JSON',
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFF7C3AED),
                  subtitle: 'إدارة وحفظ أوفلاين',
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpecializedExamsManagementScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الوصول السريع للأقسام',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  _loadKpis();
                  _fetchUsers(isRefresh: true);
                },
                tooltip: 'تحديث البيانات',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إدارة وتفعيل الطلاب',
            subtitle: 'البحث عن طالب، عرض تفاصيله وتعديل اشتراكه',
            icon: Icons.person_search_rounded,
            color: const Color(0xFF16A34A),
            onTap: () => setState(() => _selectedTabIndex = 1),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إدارة لوحة المتصدرين وقائمة الشرف 🏆',
            subtitle: 'تعديل شامل للدرجات، حذف، وتغيير الأفاتارات لجميع المتصدرين',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFD97706),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardManagementScreen()),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إدارة الملازم والفورمات (PDF / Forms)',
            subtitle: 'إضافة وتعديل وحذف الملازم المرفوعة والفورمات',
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => setState(() => _selectedTabIndex = 2),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'رسائل وتذاكر الدعم الفني 📬',
            subtitle: 'مراجعة استفسارات ومشاكل الطلاب والمراسلة عبر واتساب',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF10B981),
            onTap: () => setState(() => _selectedTabIndex = 3),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إرسال إشعار جماعي فوري',
            subtitle: 'إشعار مباشر يصل لجميع الطلاب المشتركين',
            icon: Icons.campaign_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => setState(() => _selectedTabIndex = 4),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'تعديل شريط التنبيه والإعلان العام',
            subtitle: 'تثبيت إعلان حي يظهر أعلى الشاشة الرئيسية',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFD97706),
            onTap: () => setState(() => _selectedTabIndex = 5),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إدارة التحديثات والصيانة والتثبيت الإجباري',
            subtitle: 'تغيير رقم الإصدار، رابط التحديث، وتفعيل القفل الإجباري',
            icon: Icons.system_update_alt_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => setState(() => _selectedTabIndex = 6),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'تسجيل الخروج من الحساب',
            subtitle: 'الخروج والعودة لشاشة تسجيل الدخول',
            icon: Icons.logout_rounded,
            color: Colors.red,
            onTap: () => _showLogoutDialog(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAppleKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.arrow_upward_rounded, color: color, size: 15),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      );
    }
    return card;
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF131C31) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoKufiArabic(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: 👥 Students Manager & Search
  // ==========================================
  Widget _buildStudentsManagerTab(bool isDark) {
    var filteredDocs = _userDocs.toList();

    // 1. فرز دقيق بحسب تاريخ التسجيل: الأخير أولاً ثم الأقدم
    filteredDocs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>? ?? {};
      final dataB = b.data() as Map<String, dynamic>? ?? {};
      DateTime timeA = DateTime(2000);
      DateTime timeB = DateTime(2000);

      if (dataA['createdAt'] is Timestamp) {
        timeA = (dataA['createdAt'] as Timestamp).toDate();
      }
      if (dataB['createdAt'] is Timestamp) {
        timeB = (dataB['createdAt'] as Timestamp).toDate();
      }
      return timeB.compareTo(timeA); // الأحدث أولاً
    });

    // 2. تصفية الاشتراكات: الكل / النشطون فقط / المنتهية / المجاني فقط
    if (_userFilter == 'premium') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final expiry = _extractUserExpiryDate(data);
        final isExpired = expiry != null && DateTime.now().isAfter(expiry);
        return data['isPremium'] == true && !isExpired;
      }).toList();
    } else if (_userFilter == 'expired') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final expiry = _extractUserExpiryDate(data);
        final isExpired = expiry != null && DateTime.now().isAfter(expiry);
        return (data['isPremium'] == true && isExpired) || (expiry != null && DateTime.now().isAfter(expiry));
      }).toList();
    } else if (_userFilter == 'free') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final expiry = _extractUserExpiryDate(data);
        final isExpired = expiry != null && DateTime.now().isAfter(expiry);
        return data['isPremium'] != true && !isExpired;
      }).toList();
    } else if (_userFilter == 'admins') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final role = (data['role'] ?? '').toString().toLowerCase();
        return role == 'admin' || data['isAdmin'] == true;
      }).toList();
    }

    // 3. تصفية البحث الذكية والمطابقة الدقيقة للحروف والهمزات العربية
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = _normalizeSearchText(_searchQuery);
      final rawQuery = _searchQuery.toLowerCase();

      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = doc.id.toLowerCase();
        final rawName = (data['name'] ?? data['displayName'] ?? '').toString();
        final normalizedName = _normalizeSearchText(rawName);
        final email = _resolveUserEmail(data).toLowerCase();
        final username = _resolveUsername(data).toLowerCase();
        final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
        final code = (data['activationCode'] ?? data['code'] ?? '').toString().toLowerCase();
        final password = (data['password'] ?? data['pass'] ?? data['plainPassword'] ?? '').toString().toLowerCase();

        return normalizedName.contains(normalizedQuery) ||
            rawName.toLowerCase().contains(rawQuery) ||
            username.contains(rawQuery) ||
            email.contains(rawQuery) ||
            phone.contains(rawQuery) ||
            uid.contains(rawQuery) ||
            code.contains(rawQuery) ||
            password.contains(rawQuery);
      }).toList();
    }

    return Column(
      children: [
        // Search & Filters Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C31) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم، اسم المستخدم، الإيميل، رقم الهاتف، أو كود التفعيل...',
                  hintStyle:
                      const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF2563EB), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0B1120)
                      : const Color(0xFFF1F5F9),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('الكل (${_userDocs.length})', 'all', isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('⭐ النشطون', 'premium', isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('⌛ المنتهية', 'expired', isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('🔓 المجاني', 'free', isDark),
                    const SizedBox(width: 6),
                    _buildFilterChip('🛡️ المشرفين', 'admins', isDark),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      onPressed: () => _fetchUsers(isRefresh: true),
                      tooltip: 'تحديث القائمة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Students List with Click-to-Details
        Expanded(
          child: _isLoadingUsers
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : filteredDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_rounded,
                              size: 45, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('لا يوجد طلاب مطابقون للبحث',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 130),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final name =
                            data['name'] ?? data['displayName'] ?? 'طالب';
                        final email = _resolveUserEmail(data);
                        final username = _resolveUsername(data);

                        final expiryDate = _extractUserExpiryDate(data);
                        final bool isExpired = expiryDate != null && DateTime.now().isAfter(expiryDate);
                        final bool isActuallyPremium = (data['isPremium'] == true) && !isExpired;

                        // إذا كان الحساب مسجلاً كـ isPremium في الداتابيز لكن انتهت صلاحيته فعلياً، نحدث الداتابيز في الخلفية
                        if (data['isPremium'] == true && isExpired) {
                          FirebaseFirestore.instance.collection('users').doc(uid).update({
                            'isPremium': false,
                          }).catchError((_) => null);
                        }

                        return _buildCompactStudentItem(
                          uid: uid,
                          data: data,
                          name: name,
                          email: email,
                          username: username,
                          isPremium: isActuallyPremium,
                          isExpired: isExpired,
                          expiryDate: expiryDate,
                          isDark: isDark,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _userFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      onSelected: (selected) {
        if (selected) {
          setState(() => _userFilter = value);
        }
      },
    );
  }

  Widget _buildCompactStudentItem({
    required String uid,
    required Map<String, dynamic> data,
    required String name,
    required String email,
    String? username,
    required bool isPremium,
    required bool isExpired,
    DateTime? expiryDate,
    required bool isDark,
  }) {
    String statusText = 'مجاني';
    Color statusColor = const Color(0xFF64748B);
    Color borderColor = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    Color avatarColor = const Color(0xFF2563EB);

    if (isExpired) {
      statusText = expiryDate != null
          ? 'منتهي (${DateFormat('yyyy/MM/dd').format(expiryDate)}) ⚠️'
          : 'منتهي الصلاحية ⚠️';
      statusColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFEF4444).withOpacity(0.4);
      avatarColor = const Color(0xFFEF4444);
    } else if (isPremium) {
      if (expiryDate != null) {
        final days = expiryDate.difference(DateTime.now()).inDays;
        if (days > 365 * 2) {
          statusText = 'دائمي 👑';
        } else {
          statusText = 'مفعل (${DateFormat('yyyy/MM/dd').format(expiryDate)}) ⭐';
        }
      } else {
        statusText = 'مفعل ⭐';
      }
      statusColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFF16A34A).withOpacity(0.35);
      avatarColor = const Color(0xFF16A34A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _showStudentDetailsSheet(context, uid, data),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'ط',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Tajawal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        (username != null && username.isNotEmpty) ? '@$username • $email' : email,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: 📢 Broadcast Notification System
  // ==========================================
  Widget _buildBroadcastNotificationTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'إرسال إشعار جماعي فوري',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notifTitleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الإشعار',
                    hintText: 'مثال: تحديث مهم في بنك الأسئلة 🚀',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    hintStyle:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notifBodyController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نص الإشعار',
                    hintText: 'اكتب نص الرسالة التي ستصل للطلاب...',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    hintStyle:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('النوع: ',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('عام ℹ️',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _notifType == 'info',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (_) => setState(() => _notifType = 'info'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('عاجل ⚠️',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _notifType == 'warning',
                      selectedColor: const Color(0xFFD97706),
                      onSelected: (_) =>
                          setState(() => _notifType = 'warning'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('الجمهور المستهدف: ',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('الجميع 👥',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _notifTargetSegment == 'all',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (_) => setState(() => _notifTargetSegment = 'all'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('المميزون 👑',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _notifTargetSegment == 'premium',
                      selectedColor: const Color(0xFF16A34A),
                      onSelected: (_) => setState(() => _notifTargetSegment = 'premium'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('المجانيون 🆓',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _notifTargetSegment == 'free',
                      selectedColor: const Color(0xFFD97706),
                      onSelected: (_) => setState(() => _notifTargetSegment = 'free'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSendingNotif ? null : _sendBroadcastNotification,
                    icon: _isSendingNotif
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isSendingNotif
                          ? 'جاري الإرسال...'
                          : 'إرسال الإشعار الفوري 🚀',
                      style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: 📣 Global Announcement Banner
  // ==========================================
  Widget _buildAnnouncementTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'تفعيل شريط التنبيه العام',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _annEnabled,
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) => setState(() => _annEnabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _annTextController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نص الإعلان الذي سيظهر في الشريط المتحرك',
                    hintText: 'اكتب نص الإعلان هنا...',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    hintStyle:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _annLinkController,
                  decoration: InputDecoration(
                    labelText: 'رابط خارجي عند النقر على الإعلان (اختياري)',
                    hintText: 'https://t.me/... أو https://...',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    hintStyle:
                        const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('نوع التنبيه: ',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('معلومة ℹ️',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _annType == 'info',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (_) =>
                          setState(() => _annType = 'info'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('تحذير ⚠️',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _annType == 'warning',
                      selectedColor: const Color(0xFFD97706),
                      onSelected: (_) =>
                          setState(() => _annType = 'warning'),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('أخضر ✅',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                      selected: _annType == 'success',
                      selectedColor: const Color(0xFF16A34A),
                      onSelected: (_) =>
                          setState(() => _annType = 'success'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingAnn ? null : _saveAnnouncement,
                    icon: _isSavingAnn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(
                      _isSavingAnn
                          ? 'جاري الحفظ...'
                          : 'حفظ ونشر الإعلان فوراً 💾',
                      style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateSettingsTab(bool isDark) {
    if (_isLoadingUpdateConfig) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_alt_rounded,
                      color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة التحديثات والتثبيت الإجباري 🚀',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _currentInstalledVersion.isNotEmpty
                            ? 'الإصدار المثبت حالياً لديك: v$_currentInstalledVersion'
                            : 'التحكم في إصدار التطبيق وروابط التحديث لجميع الطلاب',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= بطاقة تحديثات أندرويد 🤖 =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(isDark ? 0.35 : 0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إعدادات تحديث أندرويد 🤖 (Google Play / APK)',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            'التحكم في إصدار ورابط وإجبارية التحديث لأجهزة الأندرويد',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: isDark ? Colors.grey : const Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _targetAndroid,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _targetAndroid = v),
                    ),
                  ],
                ),
                const Divider(height: 20),
                TextField(
                  controller: _androidVersionController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'رقم إصدار الأندرويد المطلوب (مثال: 2.1.1)',
                    hintText: '2.1.1',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _androidUpdateUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'رابط التوجيه (Google Play أو رابط تحميل APK)',
                    hintText: 'https://play.google.com/store/apps/details?id=...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تحديث إجباري للأندرويد ⚠️', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 13)),
                  subtitle: const Text('يمنع مستخدم الأندرويد من المتابعة دون التحديث للإصدار المحدد', style: TextStyle(fontSize: 11, fontFamily: 'Tajawal', color: Colors.grey)),
                  value: _androidForceUpdate,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) => setState(() => _androidForceUpdate = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= بطاقة تحديثات آيفون 🍎 =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0284C7).withOpacity(isDark ? 0.35 : 0.6),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.apple_rounded, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إعدادات تحديث آيفون 🍎 (App Store)',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0369A1),
                            ),
                          ),
                          Text(
                            'التحكم في إصدار ورابط وإجبارية التحديث لأجهزة الآيفون',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: isDark ? Colors.grey : const Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _targetIos,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (v) => setState(() => _targetIos = v),
                    ),
                  ],
                ),
                const Divider(height: 20),
                TextField(
                  controller: _iosVersionController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'رقم إصدار الآيفون المطلوب (مثال: 2.1.0)',
                    hintText: '2.1.0',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _iosUpdateUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'رابط التوجيه (متجر App Store)',
                    hintText: 'https://apps.apple.com/app/...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تحديث إجباري للآيفون ⚠️', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 13)),
                  subtitle: const Text('يمنع مستخدم الآيفون من المتابعة دون التحديث للإصدار المحدد', style: TextStyle(fontSize: 11, fontFamily: 'Tajawal', color: Colors.grey)),
                  value: _iosForceUpdate,
                  activeColor: const Color(0xFF0284C7),
                  onChanged: (v) => setState(() => _iosForceUpdate = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ================= بطاقة وضع مراجعة أبل ستور 🍎 (خاص بالآيفون فقط) =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _iosReviewMode
                    ? const Color(0xFF0284C7)
                    : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                width: _iosReviewMode ? 1.6 : 1.0,
              ),
              boxShadow: [
                if (_iosReviewMode)
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.14),
                    blurRadius: 16,
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
                        color: _iosReviewMode
                            ? const Color(0xFF0284C7).withOpacity(0.18)
                            : Colors.grey.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: _iosReviewMode ? const Color(0xFF0284C7) : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'وضع مراجعة أبل ستور 🍎 (خاص بالآيفون فقط)',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: _iosReviewMode
                                      ? const Color(0xFF0284C7)
                                      : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'إخفاء شاشة الاشتراكات واستبدالها بشاشة (دليل الامتحان) وفتح المحتوى لمراجعي Apple',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _iosReviewMode,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (v) async {
                        setState(() => _iosReviewMode = v);
                        ConfigService().setIosReviewModeLocal(v);
                        try {
                          await _db.collection('system_settings').doc('maintenance_and_updates').set({
                            'ios_review_mode': v,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                          await _db.collection('app_config').doc('version').set({
                            'ios_review_mode': v,
                          }, SetOptions(merge: true));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? 'تم تفعيل وضع مراجعة Apple للآيفون بنجاح! 🍎'
                                      : 'تم إيقاف وضع مراجعة Apple وعودة شاشة الاشتراكات للآيفون! ✨',
                                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: v ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error toggling ios_review_mode: $e');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _iosReviewMode
                        ? const Color(0xFF0284C7).withOpacity(0.08)
                        : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _iosReviewMode
                          ? const Color(0xFF0284C7).withOpacity(0.2)
                          : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iosReviewMode ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 15,
                        color: _iosReviewMode ? const Color(0xFF0284C7) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _iosReviewMode
                              ? 'الوضع مفعل حالياً في السحابة: أجهزة الآيفون تشاهد دليل الامتحان بدلاً من شاشة الاشتراكات. الأندرويد يعمل طبيعياً كالمعتاد.'
                              : 'الوضع معطل حالياً: تظهر شاشة الاشتراكات والأسعار والتواصل الطبيعية للجميع (آيفون وأندرويد). قم بتفعيله فقط عند إرسال تحديث لمتجر Apple.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _iosReviewMode ? const Color(0xFF0284C7) : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // أزرار المعاينة والتجربة المباشرة للأدمن
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutNationalExamScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_rounded, size: 15, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Text(
                              'معاينة شاشة دليل الامتحان (التي يراها المراجع) 👁️',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final current = ConfigService().isForcePreviewMode;
                        ConfigService().setForcePreviewMode(!current);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !current
                                  ? 'تم تفعيل المعاينة الحية على هذا الجهاز! تفقد التبويب السفلي (العضوية أصبحت الدليل) 🧪'
                                  : 'تم إيقاف المعاينة الحية وعودة الواجهة الطبيعية لهذا الجهاز! ✨',
                              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: !current ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: ConfigService().isForcePreviewMode
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ConfigService().isForcePreviewMode
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ConfigService().isForcePreviewMode ? Icons.check_circle_rounded : Icons.science_rounded,
                              size: 15,
                              color: ConfigService().isForcePreviewMode ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ConfigService().isForcePreviewMode
                                  ? 'إيقاف المعاينة الحية على هذا الجهاز ⏹️'
                                  : 'تجربة حية على هذا الجهاز (حتى لو أندرويد) 🧪',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: ConfigService().isForcePreviewMode ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
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
          const SizedBox(height: 16),

          // ================= بطاقة وضع الصيانة الشامل واستهداف المنصة 🛠️ =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isMaintenanceOn ? Colors.orange : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                width: _isMaintenanceOn ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isMaintenanceOn ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.build_rounded, color: _isMaintenanceOn ? Colors.orange : Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وضع الصيانة واستهداف المنصة 🛠️',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isMaintenanceOn ? Colors.orange : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          Text(
                            'إيقاف التطبيق مؤقتاً وعرض شاشة الصيانة للمنصة المحددة أدناه',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isMaintenanceOn,
                      activeColor: Colors.orange,
                      onChanged: (v) => setState(() => _isMaintenanceOn = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'اختيار منصة الصيانة المستهدفة:',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('كليهما (الجميع)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                        selected: _maintenancePlatform == 'all',
                        selectedColor: Colors.orange.withOpacity(0.2),
                        labelStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: _maintenancePlatform == 'all' ? FontWeight.bold : FontWeight.normal,
                          color: _maintenancePlatform == 'all' ? Colors.deepOrange : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _maintenancePlatform = 'all');
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('🤖 أندرويد فقط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                        selected: _maintenancePlatform == 'android',
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        labelStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: _maintenancePlatform == 'android' ? FontWeight.bold : FontWeight.normal,
                          color: _maintenancePlatform == 'android' ? const Color(0xFF059669) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _maintenancePlatform = 'android');
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('🍎 آيفون فقط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5)),
                        selected: _maintenancePlatform == 'ios',
                        selectedColor: const Color(0xFF0284C7).withOpacity(0.2),
                        labelStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: _maintenancePlatform == 'ios' ? FontWeight.bold : FontWeight.normal,
                          color: _maintenancePlatform == 'ios' ? const Color(0xFF0284C7) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (v) {
                          if (v) setState(() => _maintenancePlatform = 'ios');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Settings Card for other settings (Change Log)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Change Log
                TextField(
                  controller: _changeLogController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ما الجديد في هذا التحديث (اختياري)',
                    hintText: 'تحسينات في الأداء وإضافة مواد جديدة...',
                    prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pricing Configuration Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFD97706), size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'أسعار باقات الاشتراك (تعديل حي وفوري) 💳',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _price1mController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'سعر شهر واحد (1m)',
                                hintText: '10,000',
                                suffixText: 'د.ع',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _price2mController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'سعر شهرين (2m)',
                                hintText: '15,000',
                                suffixText: 'د.ع',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _price3mController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'سعر 3 أشهر (3m)',
                                hintText: '20,000',
                                suffixText: 'د.ع',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _price1yController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'سعر سنة كاملة (1y)',
                                hintText: '30,000',
                                suffixText: 'د.ع',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _examEndDateController,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'تاريخ انتهاء فترة الامتحان الوطني (exam_end_date)',
                          hintText: '2026-06-15',
                          prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 20),
                          helperText: 'صيغة التاريخ: YYYY-MM-DD (مثال: 2026-06-15)',
                          helperStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _admissionsPdfUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'رابط ضوابط القبول السحابي (Cloudflare R2 PDF)',
                          hintText: 'https://pub-xxxx.r2.dev/.../mohesr.pdf',
                          prefixIcon: const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 20),
                          helperText: 'ملف الـ PDF الرسمي لضوابط القبول والتنافسي المعروض للطلاب',
                          helperStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fcmServerKeyController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'مفتاح خادم الإشعارات السحابية القديم (FCM Legacy Server Key)',
                          hintText: 'AAAA... أو مفتاح FCM Legacy',
                          prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFFD97706), size: 20),
                          helperText: 'مفتاح الخادم القديم (يبدأ بـ AAAA)',
                          helperStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _serviceAccountJsonController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'مفتاح حساب خدمة فايربيس الحديث (Firebase Service Account JSON - FCM V1)',
                          hintText: '{"type": "service_account", "project_id": "...", "private_key": "..."}',
                          prefixIcon: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                          helperText: 'مفتاح حساب الخدمة الرسمي من Firebase Console -> Service accounts -> Generate new private key',
                          helperStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 11),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingUpdateConfig ? null : _saveUpdateConfig,
                    icon: _isSavingUpdateConfig
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _isSavingUpdateConfig
                          ? 'جاري الحفظ والتعميم...'
                          : 'حفظ ونشر التحديث لجميع الطلاب 💾',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Preview / Test Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppUpdateService.showUpdateDialog(
                        context: context,
                        currentVersion: _currentInstalledVersion.isNotEmpty
                            ? _currentInstalledVersion
                            : '1.0.0',
                        latestVersion: _androidVersionController.text.trim().isNotEmpty
                            ? _androidVersionController.text.trim()
                            : (_iosVersionController.text.trim().isNotEmpty
                                ? _iosVersionController.text.trim()
                                : (_versionController.text.trim().isNotEmpty ? _versionController.text.trim() : '1.1.0')),
                        updateUrl: _androidUpdateUrlController.text.trim().isNotEmpty
                            ? _androidUpdateUrlController.text.trim()
                            : (_iosUpdateUrlController.text.trim().isNotEmpty
                                ? _iosUpdateUrlController.text.trim()
                                : _updateUrlController.text.trim()),
                        isForceUpdate: _androidForceUpdate || _iosForceUpdate || _isForceUpdate,
                        changeLog: _changeLogController.text.trim().isNotEmpty
                            ? _changeLogController.text.trim()
                            : 'ميزات وتحديثات استثنائية جديدة!',
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                    label: const Text(
                      'معاينة واختبار شاشة التحديث فوراً 👁️',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isSelected ? 'مفعّل ✅' : 'معطّل ❌',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 6: 📦 JSON Bulk Questions Importer
  // ==========================================
  Widget _buildJsonBulkQuestionsTab(bool isDark) {
    const sampleJson = '''[
  {
    "question": "ما هو المبتدأ في جملة (العلمُ نورٌ)؟",
    "options": ["العلمُ", "نورٌ", "محذوف", "ضمير مستتر"],
    "originalAnswer": "العلمُ",
    "explanation": "العلم اسم معرفة مرفوع ابتدأت به الجملة فهو مبتدأ."
  },
  {
    "question": "ما هي وحدة قياس سرعة المعالج المركزي CPU؟",
    "options": ["Gigahertz (GHz)", "Gigabyte (GB)", "Mbps", "Pixels"],
    "originalAnswer": "Gigahertz (GHz)",
    "explanation": "تُقاس ترددات وسرعات المعالجات الحديثة بالجيجاهرتز GHz."
  }
]''';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.data_object_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استيراد الأسئلة بالجملة (JSON Bulk)',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'الصق مصفوفة الأسئلة بصيغة JSON وسيتم فحصها ورفعها مباشرة',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Settings Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. اختر المادة المستهدفة:',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('اللغة العربية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      selected: _selectedBulkSubject == 'arabic',
                      selectedColor: const Color(0xFF10B981),
                      onSelected: (_) => setState(() => _selectedBulkSubject = 'arabic'),
                    ),
                    ChoiceChip(
                      label: const Text('علوم الحاسوب', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      selected: _selectedBulkSubject == 'computer',
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (_) => setState(() => _selectedBulkSubject = 'computer'),
                    ),
                    ChoiceChip(
                      label: const Text('اللغة الإنجليزية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      selected: _selectedBulkSubject == 'english',
                      selectedColor: const Color(0xFF8B5CF6),
                      onSelected: (_) => setState(() => _selectedBulkSubject = 'english'),
                    ),
                    ChoiceChip(
                      label: const Text('الثقافة العامة والتنافسي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      selected: _selectedBulkSubject == 'general',
                      selectedColor: const Color(0xFFF59E0B),
                      onSelected: (_) => setState(() => _selectedBulkSubject = 'general'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2. الصق نص JSON هنا:',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _jsonQuestionsController.text = sampleJson;
                        _validateAndParseJson(sampleJson);
                      },
                      icon: const Icon(Icons.content_paste_rounded, size: 16),
                      label: const Text('لصق نموذج تجريبي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                TextField(
                  controller: _jsonQuestionsController,
                  maxLines: 8,
                  onChanged: (text) => _validateAndParseJson(text),
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: '[\n  {\n    "question": "...",\n    "options": ["...", "..."],\n    "originalAnswer": "..."\n  }\n]',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
                  ),
                ),

                const SizedBox(height: 12),

                // Validation Status Banner
                if (_jsonParseError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'خطأ في التحقق من JSON: $_jsonParseError',
                            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.redAccent, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_parsedQuestions.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✓ تم التحقق بنجاح: تم التعرف على (${_parsedQuestions.length}) سؤال مكتمل وجاهز للرفع!',
                            style: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isImportingQuestions || _parsedQuestions.isEmpty
                        ? null
                        : _importQuestionsToFirebase,
                    icon: _isImportingQuestions
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _isImportingQuestions
                          ? 'جاري الرفع والحفظ...'
                          : 'حفظ واستيراد ${_parsedQuestions.length} سؤال في بنك الأسئلة 🚀',
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB: 📚 إدارة الملازم والفورمات (CRUD)
  // ==========================================
  Widget _buildStudyMaterialsManagerTab(bool isDark) {
    final categories = [
      {'id': 'all', 'name': 'الكل', 'icon': Icons.apps_rounded, 'color': const Color(0xFF6366F1)},
      {'id': 'computer', 'name': 'حاسوب', 'icon': Icons.laptop_chromebook_rounded, 'color': const Color(0xFF2563EB)},
      {'id': 'arabic', 'name': 'عربي', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFFD97706)},
      {'id': 'english', 'name': 'إنكليزي', 'icon': Icons.language_rounded, 'color': const Color(0xFF059669)},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. شريط الأزرار العلوية وفلاتر التصنيف
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                // أزرار الإضافة السريعة
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditMaterialDialog(),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text(
                          'إضافة ملزمة PDF 📄',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditFormDialog(),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text(
                          'إضافة فورمة تفاعلية 📝',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // تصنيفات المواد (الكل / حاسوب / عربي / إنكليزي)
                Row(
                  children: categories.map((cat) {
                    final isSelected = _materialCategoryFilter == cat['id'];
                    final color = cat['color'] as Color;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () => setState(() => _materialCategoryFilter = cat['id'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cat['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // فلتر النوع (الكل / الملازم فقط / الفورمات فقط)
                Row(
                  children: [
                    _buildMaterialTypeChip('all', 'الكل', isDark),
                    const SizedBox(width: 6),
                    _buildMaterialTypeChip('materials', 'الملازم PDF فقط', isDark),
                    const SizedBox(width: 6),
                    _buildMaterialTypeChip('forms', 'الفورمات فقط', isDark),
                  ],
                ),
              ],
            ),
          ),

          // 2. قائمة الملازم والفورمات المباشرة من Firestore
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الملازم PDF
                  if (_materialTypeFilter == 'all' || _materialTypeFilter == 'materials') ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('study_materials').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('خطأ في تحميل الملازم: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }

                        final docs = snapshot.data!.docs.where((d) {
                          if (_materialCategoryFilter == 'all') return true;
                          final data = d.data() as Map<String, dynamic>;
                          return data['category'] == _materialCategoryFilter;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'الملازم الدراسية PDF (${docs.length})',
                                  style: GoogleFonts.notoKufiArabic(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (docs.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                ),
                                child: const Center(
                                  child: Text('لا توجد ملازم مضافة في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF94A3B8))),
                                ),
                              )
                            else
                              ...docs.map((doc) => _buildMaterialAdminCard(doc, isDark)),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ],

                  // الفورمات التفاعلية
                  if (_materialTypeFilter == 'all' || _materialTypeFilter == 'forms') ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('google_forms').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('خطأ في تحميل الفورمات: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }

                        final docs = snapshot.data!.docs.where((d) {
                          if (_materialCategoryFilter == 'all') return true;
                          final data = d.data() as Map<String, dynamic>;
                          return data['category'] == _materialCategoryFilter;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.quiz_rounded, color: Color(0xFF2563EB), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'الفورمات والاختبارات التفاعلية (${docs.length})',
                                  style: GoogleFonts.notoKufiArabic(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (docs.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                ),
                                child: const Center(
                                  child: Text('لا توجد فورمات مضافة في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF94A3B8))),
                                ),
                              )
                            else
                              ...docs.map((doc) => _buildFormAdminCard(doc, isDark)),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
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

  Widget _buildMaterialTypeChip(String type, String label, bool isDark) {
    final isSelected = _materialTypeFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _materialTypeFilter = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFACC15)
                  : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFFFACC15) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialAdminCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'بدون عنوان';
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'computer';
    final pdfUrl = data['pdfUrl'] ?? '';

    String catName = 'حاسوب';
    Color catColor = const Color(0xFF2563EB);
    if (category == 'arabic') {
      catName = 'عربي';
      catColor = const Color(0xFFD97706);
    } else if (category == 'english') {
      catName = 'إنكليزي';
      catColor = const Color(0xFF059669);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(catName, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: catColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.notoKufiArabic(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
                tooltip: 'تعديل',
                onPressed: () => _showAddEditMaterialDialog(doc: doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'حذف',
                onPressed: () => _confirmDelete(doc.reference, name, 'الملزمة'),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pdfUrl,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormAdminCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'بدون عنوان';
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'computer';
    final formUrl = data['formUrl'] ?? '';

    String catName = 'حاسوب';
    Color catColor = const Color(0xFF2563EB);
    if (category == 'arabic') {
      catName = 'عربي';
      catColor = const Color(0xFFD97706);
    } else if (category == 'english') {
      catName = 'إنكليزي';
      catColor = const Color(0xFF059669);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(catName, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: catColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.notoKufiArabic(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
                tooltip: 'تعديل',
                onPressed: () => _showAddEditFormDialog(doc: doc),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'حذف',
                onPressed: () => _confirmDelete(doc.reference, name, 'الفورمة'),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formUrl,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== نافذة إضافة / تعديل ملزمة PDF =====
  void _showAddEditMaterialDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = isEdit ? (doc.data() as Map<String, dynamic>) : null;

    final nameController = TextEditingController(text: data?['name'] ?? '');
    final descController = TextEditingController(text: data?['description'] ?? '');
    final urlController = TextEditingController(text: data?['pdfUrl'] ?? '');
    String selectedCat = data?['category'] ?? 'computer';
    bool isSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'تعديل بيانات الملزمة' : 'إضافة ملزمة PDF جديدة',
                        style: GoogleFonts.notoKufiArabic(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // اختيار المادة
                  Text('المادة الدراسية:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'computer', child: Text('الحاسوب 💻', style: TextStyle(fontFamily: 'Tajawal'))),
                      DropdownMenuItem(value: 'arabic', child: Text('اللغة العربية 📖', style: TextStyle(fontFamily: 'Tajawal'))),
                      DropdownMenuItem(value: 'english', child: Text('اللغة الإنكليزية 🇬🇧', style: TextStyle(fontFamily: 'Tajawal'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // اسم الملزمة
                  Text('عنوان الملزمة:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'مثال: ملزمة الحاسوب الشاملة 2026',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),

                  // الوصف
                  Text('الوصف أو الملاحظات:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      hintText: 'مثال: خاصة بالأستاذ م. أحمد سلام الخزرجي',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),

                  // رابط الـ PDF المباشر / Cloudflare R2
                  Text('رابط ملف الـ PDF (Cloudflare R2 / Drive):', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://pub-xxxxxx.r2.dev/file.pdf',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                  ),
                  const SizedBox(height: 22),

                  // أزرار الحفظ والإلغاء
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty || urlController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('يرجى ملء اسم الملزمة ورابط الـ PDF')),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSaving = true);
                                  try {
                                    final materialData = {
                                      'name': nameController.text.trim(),
                                      'description': descController.text.trim(),
                                      'category': selectedCat,
                                      'pdfUrl': urlController.text.trim(),
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    };

                                    if (isEdit) {
                                      await doc.reference.update(materialData);
                                    } else {
                                      materialData['createdAt'] = FieldValue.serverTimestamp();
                                      await _db.collection('study_materials').add(materialData);
                                    }

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEdit ? 'تم تحديث الملزمة بنجاح 🚀' : 'تمت إضافة الملزمة بنجاح 🎉', style: const TextStyle(fontFamily: 'Tajawal')),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isEdit ? 'حفظ التعديلات' : 'إضافة الآن 🚀', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                        ),
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

  // ===== نافذة إضافة / تعديل فورمة Google Form =====
  void _showAddEditFormDialog({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final data = isEdit ? (doc.data() as Map<String, dynamic>) : null;

    final nameController = TextEditingController(text: data?['name'] ?? '');
    final descController = TextEditingController(text: data?['description'] ?? '');
    final urlController = TextEditingController(text: data?['formUrl'] ?? '');
    String selectedCat = data?['category'] ?? 'computer';
    bool isSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.quiz_rounded, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'تعديل بيانات الفورمة' : 'إضافة فورمة تفاعلية جديدة',
                        style: GoogleFonts.notoKufiArabic(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // اختيار المادة
                  Text('المادة الدراسية:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'computer', child: Text('الحاسوب 💻', style: TextStyle(fontFamily: 'Tajawal'))),
                      DropdownMenuItem(value: 'arabic', child: Text('اللغة العربية 📖', style: TextStyle(fontFamily: 'Tajawal'))),
                      DropdownMenuItem(value: 'english', child: Text('اللغة الإنكليزية 🇬🇧', style: TextStyle(fontFamily: 'Tajawal'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // اسم الفورمة
                  Text('عنوان الفورمة:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'مثال: اختبار تجريبي حاسوب - نماذج 2026',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),

                  // الوصف
                  Text('الوصف:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      hintText: 'مثال: تدريب على أسئلة الاختيارات المتعددة',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),

                  // رابط الفورمة
                  Text('رابط الفورمة (Google Form):', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://docs.google.com/forms/d/e/.../viewform',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
                  ),
                  const SizedBox(height: 22),

                  // أزرار الحفظ والإلغاء
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty || urlController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('يرجى ملء اسم الفورمة ورابطها')),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSaving = true);
                                  try {
                                    final formData = {
                                      'name': nameController.text.trim(),
                                      'description': descController.text.trim(),
                                      'category': selectedCat,
                                      'formUrl': urlController.text.trim(),
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    };

                                    if (isEdit) {
                                      await doc.reference.update(formData);
                                    } else {
                                      formData['createdAt'] = FieldValue.serverTimestamp();
                                      await _db.collection('google_forms').add(formData);
                                    }

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEdit ? 'تم تحديث الفورمة بنجاح 🚀' : 'تمت إضافة الفورمة بنجاح 🎉', style: const TextStyle(fontFamily: 'Tajawal')),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isEdit ? 'حفظ التعديلات' : 'إضافة الآن 🚀', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                        ),
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

  // ===== نافذة تأكيد الحذف =====
  void _confirmDelete(DocumentReference ref, String title, String typeName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            Text('حذف $typeName', style: GoogleFonts.notoKufiArabic(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف "$title" نهائياً من قاعدة البيانات؟',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white70 : Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حذف $typeName بنجاح 🗑️', style: const TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB: 📬 رسائل وتذاكر الدعم الفني (Support Tickets)
  // ==========================================
  Widget _buildSupportTicketsTab(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 1. شريط الفلاتر العلوية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                // فلتر الحالة (الكل / قيد الانتظار / تم الحل)
                Row(
                  children: [
                    _buildSupportStatusChip('all', 'الكل 📬', isDark),
                    const SizedBox(width: 6),
                    _buildSupportStatusChip('pending', 'قيد الانتظار ⏳', isDark),
                    const SizedBox(width: 6),
                    _buildSupportStatusChip('resolved', 'تم الحل والتواصل ✅', isDark),
                  ],
                ),
              ],
            ),
          ),

          // 2. قائمة الرسائل والتذاكر المباشرة من Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('support_tickets').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في تحميل الرسائل: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';

                  if (_supportFilterStatus == 'all') return true;
                  return status == _supportFilterStatus;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_rounded, size: 48, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد رسائل دعم في هذا القسم حالياً',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return _buildSupportTicketCard(doc, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportStatusChip(String status, String label, bool isDark) {
    final isSelected = _supportFilterStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _supportFilterStatus = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportTicketCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final userName = data['userName'] ?? 'طالب';
    final userEmail = data['userEmail'] ?? '';
    final categoryLabel = data['categoryLabel'] ?? 'استفسار عام';
    final whatsapp = data['whatsapp'] ?? '';
    final message = data['message'] ?? '';
    final status = data['status'] ?? 'pending';
    final isResolved = status == 'resolved';

    DateTime? createdAt;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }
    final formattedDate = createdAt != null ? DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isResolved
              ? const Color(0xFF10B981).withOpacity(0.5)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isResolved ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرأس: نوع الاستعلام والحالة وتاريخ الإرسال
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isResolved ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isResolved ? 'تم الحل والتواصل ✅' : 'قيد الانتظار ⏳',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // معلومات الطالب المرسل
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'ط',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.notoKufiArabic(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    if (userEmail.isNotEmpty)
                      Text(
                        userEmail,
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // نص الرسالة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // شريط أزرار الإجراءات والواتساب
          Row(
            children: [
              // زر مراسلة الواتساب المباشر
              if (whatsapp.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(whatsapp, userName, categoryLabel),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                  label: Text(
                    'واتساب: $whatsapp 💬',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              const Spacer(),

              // زر تبديل الحالة (تم الحل / قيد الانتظار)
              IconButton(
                icon: Icon(
                  isResolved ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded,
                  color: isResolved ? const Color(0xFFD97706) : const Color(0xFF10B981),
                  size: 22,
                ),
                tooltip: isResolved ? 'إعادة إلى قيد الانتظار' : 'تحديد كـ تم الحل',
                onPressed: () async {
                  await doc.reference.update({
                    'status': isResolved ? 'pending' : 'resolved',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
              ),

              // زر حذف الرسالة
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'حذف التذكرة',
                onPressed: () => _confirmDelete(doc.reference, userName, 'تذكرة الدعم'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // فتح المحادثة المباشرة على واتساب مع الطالب
  void _openWhatsApp(String phone, String userName, String issueCategory) async {
    String cleanNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('07')) {
      cleanNumber = '964${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('7')) {
      cleanNumber = '964$cleanNumber';
    }

    final message = 'مرحباً $userName، معك فريق الدعم الفني لتطبيق الاختبارات الوطني (INPT) بخصوص تذكرتك ($issueCategory). كيف يمكننا مساعدتك؟';
    final url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح واتساب: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================
  // TAB 9: 🔥 Firebase Hosting & Server Analytics
  // ==========================================
  Widget _buildFirebaseHostingTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إحصائيات استضافة وسيرفر Firebase',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المشروع الرسمي: inpt-app-20260108022659 | الموقع: inptiq.web.app',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // بطاقات إحصائيات الاستهلاك المباشرة
          Row(
            children: [
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'إجمالي وثائق المستخدمين',
                  value: '$_totalUsers',
                  icon: Icons.storage_rounded,
                  color: const Color(0xFF2563EB),
                  subtitle: 'عملية قراءة عند المزامنة',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'المشتركون المفعلون',
                  value: '$_premiumUsers',
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFF16A34A),
                  subtitle: 'سجلات VIP النشطة',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'سجلات المتصدرين',
                  value: '$_leaderboardCount',
                  icon: Icons.leaderboard_rounded,
                  color: const Color(0xFFD97706),
                  subtitle: 'وثائق Firestore الشرفية',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'حالة الاستضافة Hosting',
                  value: 'نشط 100%',
                  icon: Icons.cloud_done_rounded,
                  color: const Color(0xFF10B981),
                  subtitle: 'inptiq.web.app متصل',
                  isDark: isDark,
                  onTap: () => _launchWebUrl('https://inptiq.web.app'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // قسم تفاصيل حدود باقة Firebase المجانية (Spark Plan Quotas)
          Text(
            'حدود واستهلاك خطة Firebase Spark (المجانية):',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          _buildQuotaDetailTile(
            title: 'قراءات Firestore اليومية (Reads)',
            usedText: 'أقل من 3,500 قراءة يومياً',
            limitText: 'الحد الأقصى المجاني: 50,000 قراءة / يوم',
            percentage: 0.07,
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildQuotaDetailTile(
            title: 'كتابات وتعديلات Firestore (Writes)',
            usedText: 'أقل من 1,200 كتابة يومياً',
            limitText: 'الحد الأقصى المجاني: 20,000 كتابة / يوم',
            percentage: 0.06,
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildQuotaDetailTile(
            title: 'تخزين قاعدة البيانات Firestore Storage',
            usedText: 'حوالي 12.5 MB مستخدمة',
            limitText: 'الحد الأقصى المجاني: 1,024 MB (1 GB)',
            percentage: 0.015,
            icon: Icons.folder_shared_rounded,
            color: const Color(0xFF7C3AED),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildQuotaDetailTile(
            title: 'استضافة الويب Firebase Hosting Bandwidth',
            usedText: 'حوالي 1.2 GB منقولة هذا الشهر',
            limitText: 'الحد الأقصى المجاني: 10 GB شهرياً (360 MB/يومياً)',
            percentage: 0.12,
            icon: Icons.public_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // روابط سريعة للكونسول المباشر
          Text(
            'روابط مباشرة لإدارة السيرفر والقواعد:',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          _buildQuickLinkButton(
            title: 'فتح إحصائيات Firestore المباشرة (Usage Console)',
            subtitle: 'عرض الرسوم البيانية للقراءات والكتابات في Google Cloud',
            url: 'https://console.firebase.google.com/project/inpt-app-20260108022659/firestore/usage',
            icon: Icons.insights_rounded,
            color: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildQuickLinkButton(
            title: 'إدارة استضافة الويب (Firebase Hosting)',
            subtitle: 'مراقبة الـ Releases والدومينات ومعدل استهلاك البيانات',
            url: 'https://console.firebase.google.com/project/inptiq/hosting/sites/inptiq',
            icon: Icons.language_rounded,
            color: const Color(0xFFD97706),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildQuickLinkButton(
            title: 'قواعد أمان فايرستور (Security Rules)',
            subtitle: 'مراجعة وتعديل صلاحيات القراءة والكتابة للطلاب والأدمن',
            url: 'https://console.firebase.google.com/project/inpt-app-20260108022659/firestore/rules',
            icon: Icons.security_rounded,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaDetailTile({
    required String title,
    required String usedText,
    required String limitText,
    required double percentage,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                usedText,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                limitText,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkButton({
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _launchWebUrl(url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _launchWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ==========================================
  // TAB 10: 🎨 Dynamic App Icon Manager
  // ==========================================
  Widget _buildAppIconManagerTab(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_settings')
          .doc('app_icon_config')
          .snapshots(),
      builder: (context, snapshot) {
        String activeKey = 'default';
        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          activeKey = data['active_icon']?.toString().toLowerCase().trim() ?? 'default';
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كارت الرأس التوضيحي
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.palette_rounded, color: Color(0xFF6366F1), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تغيير أيقونة التطبيق للمستخدمين (مباشر)',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'اختر أيقونة المناسبة، وسيتم تطبيقها على هواتف كافة الطلاب تلقائياً دون الحاجة لتحديث التطبيق!',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'الأيقونات المتاحة للتفعيل:',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12),

              // قائمة الأيقونات المتاحة
              ...DynamicAppIconService.availableIcons.entries.map((entry) {
                final key = entry.key;
                final info = entry.value;
                final isSelected = activeKey == key;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C31) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? const Color(0xFF22C55E).withOpacity(0.12) : Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          info['asset']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0F172A),
                            child: const Icon(Icons.apps_rounded, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      info['name']!,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        info['description']!,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF22C55E)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'المفعلة حالياً',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _applyNewGlobalIcon(key, info['name']!),
                            child: const Text(
                              'تفعيل الآن',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _applyNewGlobalIcon(String iconKey, String iconName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد تغيير أيقونة التطبيق', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من رغبتك بتفعيل أيقونة ($iconName) كأيقونة رسمية للتطبيق لجميع الطلاب؟\n\nستتغير الأيقونة تلقائياً على شاشات هواتفهم دون الحاجة لتحديث.',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، تفعيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await DynamicAppIconService.setGlobalAppIcon(iconKey);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 تم تعيين أيقونة ($iconName) وحفظها سحابياً بنجاح!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ تعذر تحديث الأيقونة، يرجى المحاولة ثانية.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}