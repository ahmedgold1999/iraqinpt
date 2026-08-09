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
  
  final _price1mController = TextEditingController();
  final _price2mController = TextEditingController();
  final _price3mController = TextEditingController();
  final _price1yController = TextEditingController();

  final _examEndDateController = TextEditingController();

  bool _forceUpdate = false;
  bool _maintenanceMode = false;
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
        setState(() {
          _versionController.text = data['latest_version'] ?? '';
          _storeUrlController.text = data['update_url'] ?? '';
          _forceUpdate = data['is_force_update'] ?? false;
          _maintenanceMode = data['is_maintenance_on'] ?? false;
          
          _price1mController.text = (data['price_1m'] ?? '10,000').toString();
          _price2mController.text = (data['price_2m'] ?? '15,000').toString();
          _price3mController.text = (data['price_3m'] ?? '20,000').toString();
          _price1yController.text = (data['price_1y'] ?? '30,000').toString();
          
          _examEndDateController.text = data['exam_end_date'] ?? '2026-06-15';

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
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
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم تحديث وضع الصيانة بنجاح');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في الحفظ: $e');
    }
  }

  Future<void> _saveUpdateSettings() async {
    if (_versionController.text.isEmpty || _storeUrlController.text.isEmpty) {
      _showError('يرجى ملء جميع حقول التحديث');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _db.collection('system_settings').doc('maintenance_and_updates').set({
        'latest_version': _versionController.text.trim(),
        'update_url': _storeUrlController.text.trim(),
        'is_force_update': _forceUpdate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => _isLoading = false);
      _showSuccess('تم تحديث بيانات الإصدار بنجاح');
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
                _buildSectionTitle('وضع الصيانة', Icons.engineering_rounded),
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
                    children: [
                      SwitchListTile(
                        title: const Text('تفعيل وضع الصيانة', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 15)),
                        subtitle: const Text('عند التفعيل سيتم إغلاق التطبيق مؤقتاً وإظهار شاشة الصيانة', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontFamily: 'Tajawal')),
                        value: _maintenanceMode,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (v) => setState(() => _maintenanceMode = v),
                      ),
                      const SizedBox(height: 12),
                      _buildMiniSaveButton(_saveMaintenanceSettings),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildSectionTitle('إدارات وتحديث التطبيق', Icons.system_update_rounded),
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
                      Text('إصدار التطبيق الحالي: $_currentAppVersion', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _versionController,
                        style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                        decoration: _inputDecoration('رقم أحدث إصدار (مثلاً 1.1.5)', Icons.vignette_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _storeUrlController,
                        style: const TextStyle(color: Color(0xFF1C1C1E), fontFamily: 'Tajawal'),
                        decoration: _inputDecoration('رابط التحديث على المتجر', Icons.link_rounded),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('تحديث إجباري', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 15)),
                        subtitle: const Text('يمنع الطالب من الاستمرار دون تحديث التطبيق', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontFamily: 'Tajawal')),
                        value: _forceUpdate,
                        activeColor: const Color(0xFF0F172A),
                        onChanged: (v) => setState(() => _forceUpdate = v),
                      ),
                      const SizedBox(height: 12),
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
