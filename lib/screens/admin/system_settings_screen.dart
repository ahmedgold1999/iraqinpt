import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final _versionController = TextEditingController();
  final _storeUrlController = TextEditingController();
  
  // إعدادات أندرويد المنفصلة
  final _androidVersionController = TextEditingController();
  final _androidStoreUrlController = TextEditingController();
  bool _androidForceUpdate = false;
  bool _targetAndroid = true;

  // إعدادات آيفون المنفصلة
  final _iosVersionController = TextEditingController();
  final _iosStoreUrlController = TextEditingController();
  bool _iosForceUpdate = false;
  bool _targetIos = true;

  // إعدادات وضع الصيانة واستهداف المنصة
  bool _maintenanceMode = false;
  String _maintenancePlatform = 'all'; // 'all', 'android', 'ios'

  final _price1mController = TextEditingController();
  final _price2mController = TextEditingController();
  final _price3mController = TextEditingController();
  final _price1yController = TextEditingController();

  final _examEndDateController = TextEditingController();
  final _admissionsUrlController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();

  bool _targetWeb = true;
  bool _isLoading = true;
  String _currentAppVersion = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _currentAppVersion = info.version;
    });
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await _db.collection('system_settings').doc('maintenance_and_updates').get();
      if (doc.exists) {
        final data = doc.data()!;
        _versionController.text = data['latest_version'] ?? '';
        _storeUrlController.text = data['update_url'] ?? '';
        _forceUpdate = data['is_force_update'] ?? false;
        _maintenanceMode = data['is_maintenance_on'] ?? false;
        _maintenancePlatform = data['maintenance_platform'] ?? 'all';
        _targetAndroid = data['target_android'] ?? true;
        _targetIos = data['target_ios'] ?? true;
        _targetWeb = data['target_web'] ?? true;

        // تحميل بيانات أندرويد المستقلة
        _androidVersionController.text = data['android_latest_version'] ?? data['latest_version'] ?? '';
        _androidStoreUrlController.text = data['android_update_url'] ?? data['update_url'] ?? '';
        _androidForceUpdate = data['android_force_update'] ?? data['android_is_force_update'] ?? data['is_force_update'] ?? false;

        // تحميل بيانات آيفون المستقلة
        _iosVersionController.text = data['ios_latest_version'] ?? data['latest_version'] ?? '';
        _iosStoreUrlController.text = data['ios_update_url'] ?? data['update_url'] ?? '';
        _iosForceUpdate = data['ios_force_update'] ?? data['ios_is_force_update'] ?? data['is_force_update'] ?? false;
        
        _price1mController.text = (data['price_1m'] ?? '10,000').toString();
        _price2mController.text = (data['price_2m'] ?? '15,000').toString();
        _price3mController.text = (data['price_3m'] ?? '20,000').toString();
        _price1yController.text = (data['price_1y'] ?? '30,000').toString();
        
        _examEndDateController.text = data['exam_end_date'] ?? '2026-06-15';
        _admissionsUrlController.text = data['admissions_pdf_url'] ?? data['mohesr_pdf_url'] ?? 'https://pub-c2719701c033412b8917a6722dcf93d2.r2.dev/inpt/mohesr.pdf';
      }

      // تحميل إعدادات Gemini API
      try {
        final geminiDoc = await _db.collection('system_settings').doc('gemini_config').get();
        if (geminiDoc.exists && geminiDoc.data()?['api_key'] != null) {
          _geminiApiKeyController.text = geminiDoc.data()!['api_key'].toString();
        }
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التحميل: $e')));
    }
  }

  Future<void> _saveMaintenanceSettings() async {
    setState(() => _isLoading = true);
    try {
      await _db.collection('system_settings').doc('maintenance_and_updates').set({
        'is_maintenance_on': _maintenanceMode,
        'maintenance_platform': _maintenancePlatform, // 'all', 'android', 'ios'
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم تحديث وضع الصيانة واستهداف المنصة بنجاح ✨');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _saveUpdateSettings() async {
    setState(() => _isLoading = true);
    try {
      final androidVer = _androidVersionController.text.trim();
      final androidUrl = _androidStoreUrlController.text.trim();
      final iosVer = _iosVersionController.text.trim();
      final iosUrl = _iosStoreUrlController.text.trim();

      await _db.collection('system_settings').doc('maintenance_and_updates').set({
        // بيانات أندرويد المستقلة
        'android_latest_version': androidVer,
        'android_update_url': androidUrl,
        'android_force_update': _androidForceUpdate,
        'target_android': _targetAndroid,

        // بيانات آيفون المستقلة
        'ios_latest_version': iosVer,
        'ios_update_url': iosUrl,
        'ios_force_update': _iosForceUpdate,
        'target_ios': _targetIos,

        // حقول متوافقة عالمياً
        'latest_version': androidVer.isNotEmpty ? androidVer : iosVer,
        'update_url': androidUrl.isNotEmpty ? androidUrl : iosUrl,
        'is_force_update': _androidForceUpdate || _iosForceUpdate,
        'target_web': _targetWeb,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم تحديث إعدادات إصدارات الأندرويد والآيفون بنجاح ✨');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _savePriceSettings() async {
    setState(() => _isLoading = true);
    try {
      await _db.collection('system_settings').doc('maintenance_and_updates').set({
        'price_1m': _price1mController.text.trim(),
        'price_2m': _price2mController.text.trim(),
        'price_3m': _price3mController.text.trim(),
        'price_1y': _price1yController.text.trim(),
        'exam_end_date': _examEndDateController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم تحديث قائمة الأسعار وتاريخ الامتحان بنجاح');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _saveAdmissionsSettings() async {
    setState(() => _isLoading = true);
    try {
      await _db.collection('system_settings').doc('maintenance_and_updates').set({
        'admissions_pdf_url': _admissionsUrlController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم حفظ وتحديث رابط ضوابط القبول بنجاح');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _saveGeminiSettings() async {
    setState(() => _isLoading = true);
    try {
      await _db.collection('system_settings').doc('gemini_config').set({
        'api_key': _geminiApiKeyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم حفظ وتحديث مفتاح Gemini API بنجاح');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في حفظ المفتاح: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_examEndDateController.text) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF0F172A), onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1C1C1E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _examEndDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
      backgroundColor: const Color(0xFF00C853),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('إعدادات النظام العامة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('وضع الصيانة واستهداف المنصة', Icons.engineering_rounded),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _maintenanceMode ? const Color(0xFFEF4444) : const Color(0xFFE5E5EA), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تفعيل وضع الصيانة', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 15)),
                        subtitle: const Text('عند التفعيل سيتم إغلاق التطبيق مؤقتاً وعرض شاشة الصيانة للمنصة المحددة', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontFamily: 'Tajawal')),
                        value: _maintenanceMode,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (v) => setState(() => _maintenanceMode = v),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'اختيار منصة الصيانة المستهدفة:',
                        style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('كليهما (الجميع)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                              selected: _maintenancePlatform == 'all',
                              selectedColor: const Color(0xFFEF4444).withOpacity(0.18),
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: _maintenancePlatform == 'all' ? FontWeight.bold : FontWeight.normal,
                                color: _maintenancePlatform == 'all' ? const Color(0xFFDC2626) : const Color(0xFF4B5563),
                              ),
                              onSelected: (v) {
                                if (v) setState(() => _maintenancePlatform = 'all');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('🤖 أندرويد فقط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                              selected: _maintenancePlatform == 'android',
                              selectedColor: const Color(0xFF10B981).withOpacity(0.18),
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: _maintenancePlatform == 'android' ? FontWeight.bold : FontWeight.normal,
                                color: _maintenancePlatform == 'android' ? const Color(0xFF059669) : const Color(0xFF4B5563),
                              ),
                              onSelected: (v) {
                                if (v) setState(() => _maintenancePlatform = 'android');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('🍎 آيفون فقط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                              selected: _maintenancePlatform == 'ios',
                              selectedColor: const Color(0xFF0284C7).withOpacity(0.18),
                              labelStyle: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: _maintenancePlatform == 'ios' ? FontWeight.bold : FontWeight.normal,
                                color: _maintenancePlatform == 'ios' ? const Color(0xFF0284C7) : const Color(0xFF4B5563),
                              ),
                              onSelected: (v) {
                                if (v) setState(() => _maintenancePlatform = 'ios');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildMiniSaveButton(_saveMaintenanceSettings),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildSectionTitle('إدارات وتحديث التطبيق (أندرويد وآيفون)', Icons.system_update_rounded),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إصدار هذا الجهاز حالياً: $_currentAppVersion', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      const SizedBox(height: 16),

                      // ================= بطاقة تحديثات أندرويد 🤖 =================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 22),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'إعدادات أندرويد (Google Play)',
                                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                                ),
                                const Spacer(),
                                Switch.adaptive(
                                  value: _targetAndroid,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (v) => setState(() => _targetAndroid = v),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            TextFormField(
                              controller: _androidVersionController,
                              style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                              decoration: _inputDecoration('رقم إصدار الأندرويد المطلوب (مثلاً 2.1.1)', Icons.vignette_rounded),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _androidStoreUrlController,
                              style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                              decoration: _inputDecoration('رابط التوجيه (متجر Google Play أو APK)', Icons.link_rounded),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('تحديث إجباري للأندرويد', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 13.5)),
                              subtitle: const Text('يمنع مستخدم الأندرويد من المتابعة دون التحديث', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5, fontFamily: 'Tajawal')),
                              value: _androidForceUpdate,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (v) => setState(() => _androidForceUpdate = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= بطاقة تحديثات آيفون 🍎 =================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.apple_rounded, color: Color(0xFF0284C7), size: 22),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'إعدادات آيفون (App Store)',
                                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1)),
                                ),
                                const Spacer(),
                                Switch.adaptive(
                                  value: _targetIos,
                                  activeColor: const Color(0xFF0284C7),
                                  onChanged: (v) => setState(() => _targetIos = v),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            TextFormField(
                              controller: _iosVersionController,
                              style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                              decoration: _inputDecoration('رقم إصدار الآيفون المطلوب (مثلاً 2.1.0)', Icons.vignette_rounded),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _iosStoreUrlController,
                              style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                              decoration: _inputDecoration('رابط التوجيه (متجر App Store)', Icons.link_rounded),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('تحديث إجباري للآيفون', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 13.5)),
                              subtitle: const Text('يمنع مستخدم الآيفون من المتابعة دون التحديث', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11.5, fontFamily: 'Tajawal')),
                              value: _iosForceUpdate,
                              activeColor: const Color(0xFF0284C7),
                              onChanged: (v) => setState(() => _iosForceUpdate = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildMiniSaveButton(_saveUpdateSettings),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('قائمة الأسعار وتأهيل التوقيت', Icons.payments_rounded),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildPriceField(_price1mController, 'سعر اشتراك الشهر الواحد'),
                      const SizedBox(height: 10),
                      _buildPriceField(_price2mController, 'سعر اشتراك الشهرين'),
                      const SizedBox(height: 10),
                      _buildPriceField(_price3mController, 'سعر اشتراك الثلاثة أشهر'),
                      const SizedBox(height: 10),
                      _buildPriceField(_price1yController, 'سعر التفعيل الدائمي'),
                      const SizedBox(height: 20),
                      
                      const Divider(color: Color(0xFFE5E5EA), height: 30),
                      _buildSectionTitle('تاريخ انتهاء الامتحان الوطني', Icons.event_available_rounded),
                      TextFormField(
                        controller: _examEndDateController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                        onTap: () => _selectDate(context),
                        decoration: _inputDecoration('تاريخ نهاية الامتحانات الوطنية', Icons.calendar_month_rounded),
                      ),

                      const SizedBox(height: 16),
                      _buildMiniSaveButton(_savePriceSettings),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionTitle('ضوابط القبول السحابية (Cloudflare R2)', Icons.menu_book_rounded),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رابط ملف PDF الرسمي لضوابط القبول (يتم تحميله وعرضه للطلاب):',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _admissionsUrlController,
                        style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal', fontSize: 13),
                        decoration: _inputDecoration('https://pub-xxxx.r2.dev/.../mohesr.pdf', Icons.link_rounded),
                      ),
                      const SizedBox(height: 16),
                      _buildMiniSaveButton(_saveAdmissionsSettings),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // قسم إعدادات الذكاء الاصطناعي (Gemini API)
                _buildSectionTitle('الأستاذ الذكي (Gemini AI API)', Icons.auto_awesome_rounded),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مفتاح Gemini API Key (من Google AI Studio):',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _geminiApiKeyController,
                        style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal', fontSize: 13),
                        decoration: _inputDecoration('AIzaSy...', Icons.key_rounded),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 ملاحظة: عند تغيير المفتاح هنا، سيتحدث فوراً لدى جميع الطلاب دون الحاجة لتحديث التطبيق.',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMiniSaveButton(_saveGeminiSettings),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniSaveButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text('حفظ هذا القسم فقط', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F172A), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontFamily: 'Tajawal', fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF0F172A), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
    );
  }

  Widget _buildPriceField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
      decoration: _inputDecoration(label, Icons.payments_outlined),
    );
  }
}
