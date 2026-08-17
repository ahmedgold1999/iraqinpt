import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/question_model.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import '../../services/app_update_service.dart';
import '../../services/question_service.dart';
import '../../services/config_service.dart';
import '../../services/notification_service.dart';
import '../../routes.dart';

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
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _updateUrlController = TextEditingController();
  final TextEditingController _changeLogController = TextEditingController();
  final TextEditingController _price1mController = TextEditingController(text: '10,000');
  final TextEditingController _price2mController = TextEditingController(text: '15,000');
  final TextEditingController _price3mController = TextEditingController(text: '20,000');
  final TextEditingController _price1yController = TextEditingController(text: '30,000');
  final TextEditingController _examEndDateController = TextEditingController(text: '2026-06-15');
  final TextEditingController _fcmServerKeyController =
      TextEditingController(text: 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0');
  bool _isForceUpdate = false;
  bool _isMaintenanceOn = false;
  bool _isLoadingUpdateConfig = false;
  bool _isSavingUpdateConfig = false;
  String _currentInstalledVersion = '';

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
    // Ensuring safety against uninitialized fields during hot reloads
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
    _fcmServerKeyController.dispose();
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

  // ✅ جلب الطلاب بذكاء مرتبين من الأحدث للأقدم
  Future<void> _fetchUsers({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoadingUsers = true;
        _userDocs.clear();
        _lastDoc = null;
        _hasMoreUsers = true;
      });
    } else {
      if (_isLoadingMore || !_hasMoreUsers) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      Query query = _db.collection('users').orderBy('createdAt', descending: true);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.limit(_pageSize).get();

      if (mounted) {
        setState(() {
          if (snapshot.docs.isNotEmpty) {
            _userDocs.addAll(snapshot.docs);
            _lastDoc = snapshot.docs.last;
            _hasMoreUsers = snapshot.docs.length >= _pageSize;
          } else {
            _hasMoreUsers = false;
          }
          _isLoadingUsers = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      try {
        Query fallbackQuery = _db.collection('users').limit(_pageSize);
        if (_lastDoc != null) {
          fallbackQuery = fallbackQuery.startAfterDocument(_lastDoc!);
        }
        final snapshot = await fallbackQuery.get();
        if (mounted) {
          setState(() {
            _userDocs.addAll(snapshot.docs);
            _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
            _hasMoreUsers = snapshot.docs.length >= _pageSize;
            _isLoadingUsers = false;
            _isLoadingMore = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoadingUsers = false;
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      }
    });
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
      await NotificationService.sendBroadcastPush(
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚀 تم إرسال الإشعار وتعميمه بنجاح ($targetText)!'),
            backgroundColor: const Color(0xFF16A34A),
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
        _price1mController.text = (data['price_1m'] ?? '10,000').toString();
        _price2mController.text = (data['price_2m'] ?? '15,000').toString();
        _price3mController.text = (data['price_3m'] ?? '20,000').toString();
        _price1yController.text = (data['price_1y'] ?? '30,000').toString();
        final loadedKey = (data['fcm_server_key'] ?? '').toString().trim();
        _fcmServerKeyController.text = loadedKey.isNotEmpty ? loadedKey : 'AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0';
      } else {
        final fallback = await _db.collection('app_config').doc('version').get();
        if (fallback.exists && fallback.data() != null) {
          final data = fallback.data()!;
          _versionController.text = (data['version'] ?? '1.0.0').toString();
          _updateUrlController.text = (data['url'] ?? '').toString();
          _changeLogController.text = (data['change_log'] ?? '').toString();
          _isForceUpdate = data['forceUpdate'] ?? false;
        }
      }
    } catch (e) {
      debugPrint('Error loading update config: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUpdateConfig = false);
    }
  }

  Future<void> _saveUpdateConfig() async {
    if (_versionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة رقم الإصدار')),
      );
      return;
    }

    setState(() => _isSavingUpdateConfig = true);
    try {
      final updateData = {
        'latest_version': _versionController.text.trim(),
        'version': _versionController.text.trim(),
        'update_url': _updateUrlController.text.trim(),
        'url': _updateUrlController.text.trim(),
        'is_force_update': _isForceUpdate,
        'forceUpdate': _isForceUpdate,
        'is_maintenance_on': _isMaintenanceOn,
        'change_log': _changeLogController.text.trim(),
        'price_1m': _price1mController.text.trim().isNotEmpty ? _price1mController.text.trim() : '10,000',
        'price_2m': _price2mController.text.trim().isNotEmpty ? _price2mController.text.trim() : '15,000',
        'price_3m': _price3mController.text.trim().isNotEmpty ? _price3mController.text.trim() : '20,000',
        'price_1y': _price1yController.text.trim().isNotEmpty ? _price1yController.text.trim() : '30,000',
        'exam_end_date': _examEndDateController.text.trim().isNotEmpty ? _examEndDateController.text.trim() : '2026-06-15',
        'fcm_server_key': _fcmServerKeyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('system_settings').doc('maintenance_and_updates').set(updateData, SetOptions(merge: true));
      await _db.collection('app_config').doc('version').set(updateData, SetOptions(merge: true));

      // تحديث الحالة محلياً وفورياً
      ConfigService().setMaintenanceLocal(_isMaintenanceOn);

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

  // =========================================================================
  // نافذة تفاصيل الطالب وتعديل الاسم والاشتراك (Student Details & Editor Sheet)
  // =========================================================================
  void _showStudentDetailsSheet(BuildContext context, String uid, Map<String, dynamic> data) {
    final initialName = data['name'] ?? data['displayName'] ?? 'طالب';
    final TextEditingController nameEditController = TextEditingController(text: initialName);
    
    // حساب مدة الاشتراك المحددة مبدئياً
    bool isPremium = data['isPremium'] == true;
    String selectedSubscription = isPremium ? '1_year' : 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final currentName = nameEditController.text.trim();
          final email = data['email'] ?? 'بدون بريد إلكتروني';
          final phone = data['phone'] ?? data['phoneNumber'] ?? 'غير مسجل';
          final role = data['role'] ?? 'student';
          final deviceId = data['deviceId'] ?? 'غير مقيد';
          bool isSavingChanges = false;

          DateTime? createdAt;
          if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }

          DateTime? expiryDate;
          if (data['premiumUntil'] != null && data['premiumUntil'] is Timestamp) {
            expiryDate = (data['premiumUntil'] as Timestamp).toDate();
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
                          _buildDetailTile(
                            icon: Icons.email_rounded,
                            label: 'البريد الإلكتروني',
                            value: email,
                            actionIcon: Icons.copy_rounded,
                            onAction: () {
                              Clipboard.setData(ClipboardData(text: email));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ البريد!')),
                              );
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

                                if (selectedSubscription == 'none') {
                                  updates['isPremium'] = false;
                                  updates['premiumUntil'] = null;
                                } else if (selectedSubscription == '1_month') {
                                  updates['isPremium'] = true;
                                  updates['premiumUntil'] = Timestamp.fromDate(
                                    DateTime.now().add(const Duration(days: 30)),
                                  );
                                } else if (selectedSubscription == '2_months') {
                                  updates['isPremium'] = true;
                                  updates['premiumUntil'] = Timestamp.fromDate(
                                    DateTime.now().add(const Duration(days: 60)),
                                  );
                                } else if (selectedSubscription == '3_months') {
                                  updates['isPremium'] = true;
                                  updates['premiumUntil'] = Timestamp.fromDate(
                                    DateTime.now().add(const Duration(days: 90)),
                                  );
                                } else if (selectedSubscription == '1_year') {
                                  updates['isPremium'] = true;
                                  updates['premiumUntil'] = Timestamp.fromDate(
                                    DateTime.now().add(const Duration(days: 365)),
                                  );
                                } else if (selectedSubscription == 'lifetime') {
                                  updates['isPremium'] = true;
                                  updates['premiumUntil'] = Timestamp.fromDate(
                                    DateTime.now().add(const Duration(days: 3650)),
                                  );
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
                  _buildTabButton(2, '📢 إشعار جماعي', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(3, '📣 شريط التنبيه', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(4, '⚙️ التحديثات والصيانة', isDark),
                  const SizedBox(width: 6),
                  _buildTabButton(5, '📦 استيراد الأسئلة JSON', isDark),
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
          _buildBroadcastNotificationTab(isDark),
          _buildAnnouncementTab(isDark),
          _buildUpdateSettingsTab(isDark),
          _buildJsonBulkQuestionsTab(isDark),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAppleKpiCard(
                  title: 'بنك الأسئلة',
                  value: '300+',
                  icon: Icons.cloud_done_rounded,
                  color: const Color(0xFF7C3AED),
                  subtitle: 'سؤال رسمي جاهز',
                  isDark: isDark,
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
            title: 'إرسال إشعار جماعي فوري',
            subtitle: 'إشعار مباشر يصل لجميع الطلاب المشتركين',
            icon: Icons.campaign_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => setState(() => _selectedTabIndex = 2),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'تعديل شريط التنبيه والإعلان العام',
            subtitle: 'تثبيت إعلان حي يظهر أعلى الشاشة الرئيسية',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFD97706),
            onTap: () => setState(() => _selectedTabIndex = 3),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildQuickActionTile(
            title: 'إدارة التحديثات والصيانة والتثبيت الإجباري',
            subtitle: 'تغيير رقم الإصدار، رابط التحديث، وتفعيل القفل الإجباري',
            icon: Icons.system_update_alt_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => setState(() => _selectedTabIndex = 4),
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
  }) {
    return Container(
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

    // 2. تصفية الاشتراكات: الكل / المميزون فقط / المجاني فقط
    if (_userFilter == 'premium') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['isPremium'] == true;
      }).toList();
    } else if (_userFilter == 'free') {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data['isPremium'] != true;
      }).toList();
    }

    // 3. تصفية البحث
    if (_searchQuery.isNotEmpty) {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? data['displayName'] ?? '')
            .toString()
            .toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) || email.contains(_searchQuery) || phone.contains(_searchQuery);
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
                  hintText: 'ابحث بالاسم، الإيميل أو الهاتف...',
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
              Row(
                children: [
                  _buildFilterChip('الكل', 'all', isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip('⭐ المميزون', 'premium', isDark),
                  const SizedBox(width: 6),
                  _buildFilterChip('🔓 المجاني', 'free', isDark),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () => _fetchUsers(isRefresh: true),
                    tooltip: 'تحديث القائمة',
                  ),
                ],
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
                      itemCount: filteredDocs.length + (_hasMoreUsers ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredDocs.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: _isLoadingMore
                                  ? const CircularProgressIndicator(strokeWidth: 2)
                                  : OutlinedButton.icon(
                                      onPressed: () => _fetchUsers(isRefresh: false),
                                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                                      label: const Text('عرض المزيد من الطلاب (+50 إضافي) 👥', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final name =
                            data['name'] ?? data['displayName'] ?? 'طالب';
                        final email = data['email'] ?? 'بدون بريد';
                        final isPremium = data['isPremium'] == true;

                        DateTime? expiryDate;
                        if (data['premiumUntil'] != null &&
                            data['premiumUntil'] is Timestamp) {
                          expiryDate =
                              (data['premiumUntil'] as Timestamp).toDate();
                        }

                        return _buildCompactStudentItem(
                          uid: uid,
                          data: data,
                          name: name,
                          email: email,
                          isPremium: isPremium,
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
    required bool isPremium,
    DateTime? expiryDate,
    required bool isDark,
  }) {
    String statusText = isPremium ? 'مفعل ⭐' : 'مجاني';
    if (isPremium && expiryDate != null) {
      statusText = '${expiryDate.year}/${expiryDate.month}/${expiryDate.day}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPremium
              ? const Color(0xFF16A34A).withOpacity(0.35)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE2E8F0)),
        ),
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
                  backgroundColor: isPremium
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF2563EB),
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
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? const Color(0xFF16A34A).withOpacity(0.15)
                                  : const Color(0xFF64748B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                color: isPremium
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        email,
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

          // Main Settings Card
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
                Text(
                  'بيانات الإصدار الجديد',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                // Version field
                TextField(
                  controller: _versionController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'رقم الإصدار الأحدث (مثال: 1.0.1 أو 1.1.0)',
                    hintText: '1.0.1',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Update URL
                TextField(
                  controller: _updateUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'رابط التحديث / تحميل التطبيق (URL)',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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
                const SizedBox(height: 18),

                // Force Update Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isForceUpdate
                        ? Colors.red.withOpacity(0.1)
                        : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isForceUpdate
                          ? Colors.red.withOpacity(0.3)
                          : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _isForceUpdate
                              ? Colors.red.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          color: _isForceUpdate ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفعيل التحديث الإجباري ⚠️',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: _isForceUpdate
                                    ? Colors.red
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            Text(
                              'يقفل التطبيق تماماً ويمنع الطلاب من الدخول حتى يقوموا بالتحديث',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isForceUpdate,
                        activeColor: Colors.red,
                        onChanged: (v) => setState(() => _isForceUpdate = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Maintenance Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isMaintenanceOn
                        ? Colors.orange.withOpacity(0.1)
                        : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isMaintenanceOn
                          ? Colors.orange.withOpacity(0.3)
                          : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _isMaintenanceOn
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.build_rounded,
                          color: _isMaintenanceOn ? Colors.orange : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وضع الصيانة الشامل 🛠️',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: _isMaintenanceOn
                                    ? Colors.orange
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            Text(
                              'إيقاف التطبيق مؤقتاً لجميع الطلاب لعرض رسالة الصيانة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                              ),
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
                        controller: _fcmServerKeyController,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'مفتاح خادم الإشعارات السحابية (FCM Server Key)',
                          hintText: 'AAAA... أو مفتاح FCM من Firebase Console',
                          prefixIcon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 20),
                          helperText: 'يسمح بوصول الإشعارات الفورية العامة لهواتف الطلاب والتطبيق مغلق تماماً',
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
                        latestVersion: _versionController.text.trim().isNotEmpty
                            ? _versionController.text.trim()
                            : '1.1.0',
                        updateUrl: _updateUrlController.text.trim(),
                        isForceUpdate: _isForceUpdate,
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
}