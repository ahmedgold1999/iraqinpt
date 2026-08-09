import 'dart:math'; // أضف هذا
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../screens/admin/admin_home.dart';
import '../../screens/admin/activation_management_screen.dart';
import '../../screens/admin/system_settings_screen.dart';
import '../../widgets/luxury_loading.dart';
import '../../routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _premiumUsers = 0;
  int _totalQuestions = 0;
  double _totalRevenue = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // تحسين جلب الأعداد باستخدام .count() لتوفير قراءات Firestore (Spark Plan)
      final usersCount = await _db.collection('users').count().get();
      _totalUsers = usersCount.count ?? 0;

      final premiumCount = await _db.collection('users').where('isPremium', isEqualTo: true).count().get();
      _premiumUsers = premiumCount.count ?? 0;

      // إحصائيات الأسئلة (افتراضية لأنها تُجلب من GitHub)
      _totalQuestions = 300; // قيمة تقديرية توفيراً للموارد

      try {
        // حساب الإيرادات بشكل تقديري أو من وثيقة واحدة
        final statsDoc = await _db.collection('system_settings').doc('stats').get();
        if (statsDoc.exists) {
          _totalRevenue = (statsDoc.data()?['total_revenue'] ?? 0).toDouble();
        } else {
          _totalRevenue = _premiumUsers * 10000.0;
        }
      } catch (e) {
        _totalRevenue = 0;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'حدث خطأ في تحميل البيانات: ${e.toString()}';
        });
      }
    }
  }
  // أضف هذه الدوال داخل class _AdminDashboardState قبل آخر قوس }

  Future<void> _showDeleteNotificationsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حذف الإشعارات',
          style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع الإشعارات؟',
          style: TextStyle(color: Colors.white70, fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    try {
      // جلب جميع المستخدمين
      final users = await FirebaseFirestore.instance.collection('users').get();
      int deletedCount = 0;

      for (var user in users.docs) {
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.id)
            .collection('user_notifications')
            .get();

        for (var doc in notifications.docs) {
          await doc.reference.delete();
          deletedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حذف $deletedCount إشعار'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                            (route) => false
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    await _loadDashboardData();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      String subtitle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const Spacer(),
                Flexible( // غير Container إلى Flexible
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // قلل padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 12, // غير من 16 إلى 12
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Tajawal',
                        letterSpacing: 0.3, // قلل من 0.5 إلى 0.3
                      ),
                      maxLines: 1, // أضف هذا
                      overflow: TextOverflow.ellipsis, // وهذا
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Tajawal',
                letterSpacing: 1.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A2E).withOpacity(0.9),
                    const Color(0xFF0A0A1A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.dashboard_rounded,
                          color: Colors.white, size: 24),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لوحة تحكم المدير',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Tajawal',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مدير النظام • ${DateTime.now().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'مشرف',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingAnimation()
                  : _hasError
                  ? _buildErrorState()
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '📊 الإحصائيات',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Tajawal',
                            letterSpacing: 0.9,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _refreshData,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.teal],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'تحديث',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Tajawal',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 18,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.9,
                      children: [
                        _buildStatCard(
                          'المستخدمين',
                          '$_totalUsers',
                          Icons.people_alt_rounded,
                          Colors.blue.shade400,
                          'مستخدم',
                        ),
                        _buildStatCard(
                          'المميزين',
                          '$_premiumUsers',
                          Icons.workspace_premium_rounded,
                          Colors.amber.shade400,
                          'مميز',
                        ),


                      ],
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '🚀 الإجراءات السريعة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.9,
                      children: [
                        _buildActionButton(
                          'تفعيل الاشتراكات',
                          Icons.verified_user_rounded,
                          Colors.amber.shade600,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const ActivationManagementScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'إدارة المستخدمين',
                          Icons.people_outline_rounded,
                          Colors.blue.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const UserManagementScreen(),
                            ),
                          ),
                        ),

                        _buildActionButton(
                          'الاشتراكات',
                          Icons.subscriptions_rounded,
                          Colors.amber.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SubscriptionManagementScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'إرسال إشعار',
                          Icons.notifications_active_rounded,
                          Colors.green.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SendNotificationScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'جميع الإشعارات',
                          Icons.notifications_active_rounded,
                          Colors.orange.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageAllNotificationsScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'الملازم والفورمات',
                          Icons.book_rounded,
                          Colors.teal.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageStudyMaterialsScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'إعدادات النظام',
                          Icons.settings_applications_rounded,
                          Colors.grey.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SystemSettingsScreen(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          'مولد الأكواد',
                          Icons.vpn_key_rounded,
                          Colors.purple.shade400,
                              () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const CodeGeneratorScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // مسافة إضافية كبيرة في الأسفل
                    const SizedBox(height: 40),

                    // ================== أزرار التحكم في الأسفل ==================
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.purple.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Flexible(
                                fit: FlexFit.tight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  icon: const Icon(Icons.home, color: Colors.white, size: 18),
                                  label: const Text(
                                    'الرئيسية',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Flexible(
                                fit: FlexFit.tight,
                                child: ElevatedButton.icon(
                                  onPressed: () => _logout(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                                  label: const Text(
                                    'خروج',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'لوحة تحكم الإدمن - نظام إدارة اختبار الكفاءة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoadingAnimation() {
    return const LuxuryLoading(message: 'جاري تحميل البيانات...');
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.2),
                Colors.orange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ... باقي الكود كما هو بدون تغيير (UserManagementScreen, QuestionManagementScreen, etc.)
// ================== شاشات حقيقية تعمل ==================

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _db.collection('users').get();
      setState(() {
        _users = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير متوفر';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.year}/${date.month}/${date.day}";
    }
    return 'غير متوفر';
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final data = user.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final email = data.containsKey('email') ? data['email'].toString().toLowerCase() : '';
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('إدارة شؤون الأعضاء', style: TextStyle(fontFamily: 'Tajawal')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final userData = user.data() as Map<String, dynamic>;
                final bool isPremium = userData.containsKey('isPremium') ? userData['isPremium'] : false;
                // حماية ضد خطأ الحقل غير الموجود
                final String userEmail = userData.containsKey('email') ? userData['email'] : 'لا يوجد بريد مسجل';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white38,
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: isPremium ? Colors.amber : Colors.blueGrey,
                      child: Text(userData['name']?[0]?.toUpperCase() ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(userData['name'] ?? 'مستخدم بدون اسم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(isPremium ? '⭐ عضوية بريميوم' : '👤 عضوية عادية', style: TextStyle(color: isPremium ? Colors.amber : Colors.white38, fontSize: 11)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Column(
                          children: [
                            const Divider(color: Colors.white10),

                            _buildDetailItem(Icons.calendar_month_rounded, 'منذ تاريخ', _formatTimestamp(userData['createdAt'])),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionBtn(Icons.edit, 'تعديل', Colors.blue, () => _editUser(user)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildActionBtn(Icons.delete_forever, 'حذف', Colors.red, () => _deleteUser(user.id)),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'Tajawal')),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف الحساب؟', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم إزالة هذا الطالب من قاعدة البيانات نهائياً.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('تأكيد الحذف')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('users').doc(userId).delete();
      _loadUsers();
    }
  }

  void _editUser(QueryDocumentSnapshot user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EditUserScreen(user: user, onSave: _loadUsers),
    );
  }
}

// ================== نافذة التعديل المنبثقة ==================
class EditUserScreen extends StatefulWidget {
  final QueryDocumentSnapshot user;
  final VoidCallback onSave;

  const EditUserScreen({super.key, required this.user, required this.onSave});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;
  late bool _isPremium;

  @override
  void initState() {
    super.initState();
    final data = widget.user.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name'] ?? '');
    _isPremium = data.containsKey('isPremium') ? data['isPremium'] : false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: MediaQuery.of(context).viewInsets.bottom + 25),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text('تحديث بيانات العضو', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          const SizedBox(height: 25),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الاسم الكامل',
              labelStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('تفعيل الحالة المميزة (Premium)', style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Tajawal')),
            value: _isPremium,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _isPremium = v),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(widget.user.id).update({
                  'name': _nameController.text,
                  'isPremium': _isPremium,
                });
                widget.onSave();
                Navigator.pop(context);
              },
              child: const Text('تطبيق التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            ),
          ),
        ],
      ),
    );
  }
}

class AddQuestionScreen extends StatefulWidget {
  final VoidCallback onSave;

  const AddQuestionScreen({super.key, required this.onSave});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String _selectedSubject = 'اللغة العربية';

  final List<String> _subjects = ['اللغة العربية', 'الحاسوب', 'اللغة الإنجليزية'];
  Future<void> _showDeleteNotificationsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حذف الإشعارات',
          style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع الإشعارات؟',
          style: TextStyle(color: Colors.white70, fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllNotifications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    try {
      // جلب جميع المستخدمين
      final users = await FirebaseFirestore.instance.collection('users').get();
      int deletedCount = 0;

      for (var user in users.docs) {
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .doc(user.id)
            .collection('user_notifications')
            .get();

        for (var doc in notifications.docs) {
          await doc.reference.delete();
          deletedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حذف $deletedCount إشعار'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addQuestion() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('questions').add({
          'question': _questionController.text,
          'correctAnswer': _answerController.text,
          'subject': _selectedSubject,
          'createdAt': FieldValue.serverTimestamp(),
        });
        widget.onSave();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة السؤال بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الإضافة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'السؤال'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'يرجى إدخال السؤال' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الإجابة' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedSubject = value!),
                decoration: const InputDecoration(labelText: 'المادة'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addQuestion,
                      child: const Text('إضافة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _premiumUsers = [];
  List<QueryDocumentSnapshot> _activationCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [usersSnapshot, codesSnapshot] = await Future.wait([
        _db.collection('users').where('isPremium', isEqualTo: true).get(),
        _db.collection('activation_codes').get(),
      ]);
      setState(() {
        _premiumUsers = usersSnapshot.docs;
        _activationCodes = codesSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateCode() async {
    try {
      final code = _generateRandomCode();
      await _db.collection('activation_codes').doc(code).set({
        'code': code,
        'isUsed': false, // <-- هذا هو المهم
        'createdAt': FieldValue.serverTimestamp(),
        'value': 10000,
        'usedBy': '', // يمكنك إضافة هذا لحفظ من استخدم الكود
        'usedAt': null, // وقت الاستخدام (فارغ حالياً)
      });
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الكود: $code')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إنشاء الكود: $e')),
      );
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    // خلط الوقت مع أرقام عشوائية
    for (int i = 0; i < 8; i++) {
      final charIndex = (timestamp + random.nextInt(1000)) % chars.length;
      code += chars[charIndex];
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('إدارة الاشتراكات',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.people),
                text: 'المميزين',
              ),
              Tab(
                icon: const Icon(Icons.vpn_key),
                text: 'أكواد التفعيل',
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _generateCode,
          backgroundColor: Colors.amber,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            children: [
              // تبويب المشتركين
              ListView.builder(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 20,
                ),
                itemCount: _premiumUsers.length,
                itemBuilder: (context, index) {
                  final user = _premiumUsers[index];
                  final userData = user.data() as Map<String, dynamic>;
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.star, color: Colors.white),
                      ),
                      title: Text(userData['name'] ?? 'لا يوجد اسم',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(userData['email'] ?? 'لا يوجد بريد',
                          style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      trailing: Chip(
                        label: const Text('مميز', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),

              // تبويب الأكواد
              ListView.builder(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 20,
                ),
                itemCount: _activationCodes.length,
                itemBuilder: (context, index) {
                  final code = _activationCodes[index];
                  final codeData = code.data() as Map<String, dynamic>;
                  final isUsed = codeData['isUsed'] ?? false;

                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isUsed ? Icons.check_circle : Icons.circle_outlined,
                        color: isUsed ? Colors.green : Colors.amber,
                      ),
                      title: Text(codeData['code'] ?? 'لا يوجد كود',
                          style: TextStyle(
                            color: isUsed ? Colors.green : Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                      subtitle: Text(
                        isUsed ? 'مستخدم' : 'متاح',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      trailing: Text('${codeData['value'] ?? 0} د.ع',
                          style: const TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('الإعدادات',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _buildSettingItem('المظهر', Icons.palette, () {}),
            _buildSettingItem('الإشعارات', Icons.notifications, () {}),
            _buildSettingItem('الأمان', Icons.security, () {}),
            _buildSettingItem('حول التطبيق', Icons.info, () {}),
            _buildSettingItem('سياسة الخصوصية', Icons.privacy_tip, () {}),
            _buildSettingItem('تواصل معنا', Icons.contact_support, () {}),
            const SizedBox(height: 20), // مسافة إضافية
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }
}

class CodeGeneratorScreen extends StatefulWidget {
  const CodeGeneratorScreen({super.key});

  @override
  State<CodeGeneratorScreen> createState() => _CodeGeneratorScreenState();
}

class _CodeGeneratorScreenState extends State<CodeGeneratorScreen> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _valueController = TextEditingController(text: '10000');
  final List<Map<String, dynamic>> _generatedCodes = [];
  final Random _random = Random.secure();

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    String code = '';
    for (int i = 0; i < 8; i++) {
      // استخدام خوارزمية أفضل
      final seed = timestamp + _random.nextInt(9999999) + i * 100000;
      final charIndex = seed % chars.length;
      code += chars[charIndex];
    }
    return code;
  }

  void _generateCodes() async {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final value = int.tryParse(_valueController.text) ?? 10000;

    if (quantity > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 50 كود في المرة الواحدة')),
      );
      return;
    }

    final newCodes = <Map<String, dynamic>>[];
    int successCount = 0;

    for (int i = 0; i < quantity; i++) {
      String code;
      bool codeExists;

      // توليد كود فريد وغير موجود مسبقاً
      do {
        code = _generateCode();
        final existingCode = await FirebaseFirestore.instance
            .collection('activation_codes')
            .doc(code)
            .get();
        codeExists = existingCode.exists;
      } while (codeExists);

      final codeData = {
        'code': code,
        'value': value,
        'createdAt': DateTime.now(),
      };
      newCodes.add(codeData);

      try {
        await FirebaseFirestore.instance.collection('activation_codes').doc(code).set({
          'code': code,
          'isUsed': false, // الأهم - لا يغيرها إلا المستخدم عند التفعيل
          'createdAt': FieldValue.serverTimestamp(),
          'value': value,
          'generatedAt': FieldValue.serverTimestamp(),
          'usedBy': '',
          'usedAt': null,
          'status': 'active', // يمكنك إضافة حالة
        });
        successCount++;
      } catch (e) {
        print('Error saving code $code: $e');
      }
    }

    setState(() {
      _generatedCodes.addAll(newCodes);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم إنشاء $successCount كود جديد'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyToClipboard(String text) {
    // يمكنك إضافة حزمة clipboard هنا إذا أردت
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نسخ الكود: $text')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'مولد الأكواد',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // إدخال البيانات
              Card(
                color: Colors.white.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأكواد',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'قيمة كل كود (دينار)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // زر الإنشاء
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateCodes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.generating_tokens),
                  label: const Text(
                    'إنشاء أكواد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // قائمة الأكواد
              Expanded(
                child: _generatedCodes.isEmpty
                    ? const Center(
                  child: Text(
                    'لم يتم إنشاء أي أكواد بعد',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _generatedCodes.length,
                  itemBuilder: (context, index) {
                    final code = _generatedCodes[index];
                    return Card(
                      color: Colors.white.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          code['code'],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${code['value']} د.ع',
                          style: TextStyle(color: Colors.amber),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.content_copy, color: Colors.white),
                          onPressed: () => _copyToClipboard(code['code']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ================== شاشة إرسال الإشعارات ==================

// ================== شاشة إرسال الإشعارات (النسخة المصححة) ==================

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _notificationType = 'simple';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _buttonTextController = TextEditingController();
  final TextEditingController _buttonUrlController = TextEditingController();

  String _targetAudience = 'all';
  String _selectedUserId = '';
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoadingUsers = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = snapshot.docs;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      // جلب المستخدمين المستهدفين
      List<String> targetUserIds = [];

      switch (_targetAudience) {
        case 'all':
          targetUserIds = _users.map((u) => u.id).toList();
          break;
        case 'premium':
          targetUserIds = _users.where((u) => u['isPremium'] == true).map((u) => u.id).toList();
          break;
        case 'normal':
          targetUserIds = _users.where((u) => u['isPremium'] != true).map((u) => u.id).toList();
          break;
        case 'specific':
          if (_selectedUserId.isNotEmpty) {
            targetUserIds = [_selectedUserId];
          }
          break;
      }

      if (targetUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد مستخدمين مستهدفين'), backgroundColor: Colors.orange),
        );
        setState(() => _isSending = false);
        return;
      }

      // حفظ الإشعار الرئيسي في all_notifications (كإعلان عام لتوفير العمليات)
      final mainNotification = {
        'title': _titleController.text,
        'body': _bodyController.text,
        'type': _notificationType,
        'imageUrl': _notificationType == 'image' ? _imageUrlController.text : null,
        'buttonText': _notificationType == 'full' ? _buttonTextController.text : null,
        'buttonUrl': _notificationType == 'full' ? _buttonUrlController.text : null,
        'createdAt': FieldValue.serverTimestamp(),
        'target': _targetAudience, // 'all', 'premium', etc.
        'readBy': [], // قائمة المستخدمين الذين قرأوا الإشعار
      };

      if (_targetAudience == 'specific') {
        // للمستخدم المحدد، نستمر في الأسلوب القديم
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedUserId)
            .collection('notifications')
            .add({
          ...mainNotification,
          'isRead': false,
        });
      } else {
        // للجمهور العام، ننشئ وثيقة واحدة فقط (توفير هائل في Writes)
        await FirebaseFirestore.instance
            .collection('all_notifications')
            .add(mainNotification);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الإشعار بنجاح (نظام الإعلان العام)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('إرسال إشعار', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // نوع الإشعار
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('نوع الإشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTypeCard('نص فقط', Icons.text_fields, 'simple')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeCard('نص + صورة', Icons.image, 'image')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTypeCard('كامل', Icons.web, 'full')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'عنوان الإشعار *',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'نص الإشعار *',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              if (_notificationType == 'image') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رابط الصورة',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('الجمهور المستهدف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    _buildAudienceOption('الجميع', 'all'),
                    _buildAudienceOption('المميزين فقط', 'premium'),
                    _buildAudienceOption('العاديين فقط', 'normal'),
                    _buildAudienceOption('مستخدم محدد', 'specific'),
                    if (_targetAudience == 'specific')
                      _isLoadingUsers
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                        value: _selectedUserId.isEmpty ? null : _selectedUserId,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'اختر المستخدم',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: _users.map((u) => DropdownMenuItem(value: u.id, child: Text(u['name'] ?? 'بدون اسم'))).toList(),
                        onChanged: (v) => setState(() => _selectedUserId = v!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('إرسال الإشعار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, IconData icon, String type) {
    final isSelected = _notificationType == type;
    return GestureDetector(
      onTap: () => setState(() => _notificationType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Colors.blue, Colors.purple]) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceOption(String title, String value) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: _targetAudience,
      activeColor: Colors.blue,
      onChanged: (v) => setState(() => _targetAudience = v!),
    );
  }
}
// ================== شاشة إدارة جميع الإشعارات (نسخة تشخيصية) ==================
class ManageAllNotificationsScreen extends StatefulWidget {
  const ManageAllNotificationsScreen({super.key});

  @override
  State<ManageAllNotificationsScreen> createState() => _ManageAllNotificationsScreenState();
}

// ================== شاشة إدارة الملازم والفورمات (نسخة معدلة) ==================
class ManageStudyMaterialsScreen extends StatefulWidget {
  const ManageStudyMaterialsScreen({super.key});

  @override
  State<ManageStudyMaterialsScreen> createState() => _ManageStudyMaterialsScreenState();
}

class _ManageStudyMaterialsScreenState extends State<ManageStudyMaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // قوائم البيانات
  List<QueryDocumentSnapshot> _materials = [];
  List<QueryDocumentSnapshot> _forms = [];
  bool _isLoading = true;

  // تعريف المواد (الأقسام)
  final Map<String, String> _categoryNames = {
    'computer': 'قسم الحاسوب',
    'english': 'اللغة الإنكليزية',
    'arabic': 'اللغة العربية',
  };

  final Map<String, IconData> _categoryIcons = {
    'computer': Icons.computer_rounded,
    'english': Icons.translate_rounded,
    'arabic': Icons.menu_book_rounded,
  };

  final Map<String, Color> _categoryColors = {
    'computer': Colors.blue,
    'english': Colors.green,
    'arabic': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [materialsSnapshot, formsSnapshot] = await Future.wait([
        _db.collection('study_materials').orderBy('createdAt', descending: true).get(),
        _db.collection('google_forms').orderBy('createdAt', descending: true).get(),
      ]);

      setState(() {
        _materials = materialsSnapshot.docs;
        _forms = formsSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('خطأ في تحميل البيانات: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ================== دوال إدارة الملازم ==================
  Future<void> _addMaterial() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MaterialFormDialog(
        title: 'إضافة ملزمة جديدة',
        categoryNames: _categoryNames,
        categoryIcons: _categoryIcons,
        categoryColors: _categoryColors,
      ),
    );

    if (result != null) {
      try {
        await _db.collection('study_materials').add({
          'name': result['name'],
          'description': result['description'],
          'pdfUrl': result['pdfUrl'],
          'category': result['category'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _loadData();
        _showSnackBar('تم إضافة الملزمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  Future<void> _editMaterial(QueryDocumentSnapshot material) async {
    final data = material.data() as Map<String, dynamic>;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MaterialFormDialog(
        title: 'تعديل الملزمة',
        initialData: {
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'pdfUrl': data['pdfUrl'] ?? '',
          'category': data['category'] ?? 'computer',
        },
        categoryNames: _categoryNames,
        categoryIcons: _categoryIcons,
        categoryColors: _categoryColors,
      ),
    );

    if (result != null) {
      try {
        await _db.collection('study_materials').doc(material.id).update({
          'name': result['name'],
          'description': result['description'],
          'pdfUrl': result['pdfUrl'],
          'category': result['category'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _loadData();
        _showSnackBar('تم تعديل الملزمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteMaterial(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف "$name"؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.collection('study_materials').doc(id).delete();
        _loadData();
        _showSnackBar('تم حذف الملزمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  // ================== دوال إدارة الفورمات (مع اختيار المادة) ==================
  Future<void> _addForm() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FormDialog(
        title: 'إضافة فورمة جديدة',
        categoryNames: _categoryNames,
        categoryIcons: _categoryIcons,
        categoryColors: _categoryColors,
      ),
    );

    if (result != null) {
      try {
        await _db.collection('google_forms').add({
          'name': result['name'],
          'description': result['description'],
          'formUrl': result['formUrl'],
          'category': result['category'],  // ✅ الآن الفورمة لها قسم
          'createdAt': FieldValue.serverTimestamp(),
        });
        _loadData();
        _showSnackBar('تم إضافة الفورمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  Future<void> _editForm(QueryDocumentSnapshot form) async {
    final data = form.data() as Map<String, dynamic>;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FormDialog(
        title: 'تعديل الفورمة',
        initialData: {
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'formUrl': data['formUrl'] ?? '',
          'category': data['category'] ?? 'computer',
        },
        categoryNames: _categoryNames,
        categoryIcons: _categoryIcons,
        categoryColors: _categoryColors,
      ),
    );

    if (result != null) {
      try {
        await _db.collection('google_forms').doc(form.id).update({
          'name': result['name'],
          'description': result['description'],
          'formUrl': result['formUrl'],
          'category': result['category'],  // ✅ تعديل القسم أيضاً
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _loadData();
        _showSnackBar('تم تعديل الفورمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteForm(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف "$name"؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.collection('google_forms').doc(id).delete();
        _loadData();
        _showSnackBar('تم حذف الفورمة بنجاح', Colors.green);
      } catch (e) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'إدارة الملازم والفورمات',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book_rounded), text: 'الملازم الدراسية'),
            Tab(icon: Icon(Icons.description_rounded), text: 'الفورمات'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addMaterial();
          } else {
            _addForm();
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : TabBarView(
        controller: _tabController,
        children: [
          // تبويب الملازم
          _buildMaterialsList(),
          // تبويب الفورمات (مع عرض القسم)
          _buildFormsList(),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (_materials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.white30),
            SizedBox(height: 16),
            Text('لا توجد ملازم حالياً', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 8),
            Text('اضغط على زر + للإضافة', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final doc = _materials[index];
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? 'computer';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _categoryColors[category]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _categoryColors[category]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcons[category], color: _categoryColors[category], size: 28),
            ),
            title: Text(
              data['name'] ?? 'بدون عنوان',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _categoryColors[category]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _categoryNames[category] ?? category,
                    style: TextStyle(color: _categoryColors[category], fontSize: 10),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editMaterial(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMaterial(doc.id, data['name'] ?? 'هذه الملزمة'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ قائمة الفورمات مع عرض القسم (المادة) لكل فورمة
  Widget _buildFormsList() {
    if (_forms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.white30),
            SizedBox(height: 16),
            Text('لا توجد فورمات حالياً', style: TextStyle(color: Colors.white54)),
            SizedBox(height: 8),
            Text('اضغط على زر + للإضافة', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _forms.length,
      itemBuilder: (context, index) {
        final doc = _forms[index];
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? 'computer';  // ✅ الآن الفورمة لها قسم

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _categoryColors[category]?.withOpacity(0.3) ?? Colors.deepPurple.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _categoryColors[category]?.withOpacity(0.2) ?? Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcons[category] ?? Icons.description_rounded,
                  color: _categoryColors[category] ?? Colors.deepPurple,
                  size: 28),
            ),
            title: Text(
              data['name'] ?? 'بدون عنوان',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _categoryColors[category]?.withOpacity(0.2) ?? Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _categoryNames[category] ?? category,
                    style: TextStyle(color: _categoryColors[category] ?? Colors.deepPurple, fontSize: 10),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editForm(doc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteForm(doc.id, data['name'] ?? 'هذه الفورمة'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================== نموذج إضافة/تعديل الملزمة (بدون تغيير) ==================
class _MaterialFormDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialData;
  final Map<String, String> categoryNames;
  final Map<String, IconData> categoryIcons;
  final Map<String, Color> categoryColors;

  const _MaterialFormDialog({
    required this.title,
    this.initialData,
    required this.categoryNames,
    required this.categoryIcons,
    required this.categoryColors,
  });

  @override
  State<_MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<_MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _pdfUrlController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _pdfUrlController = TextEditingController(text: widget.initialData?['pdfUrl'] ?? '');
    _selectedCategory = widget.initialData?['category'] ?? 'computer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1A1A2E),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'اسم الملزمة *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف الملزمة',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pdfUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'رابط PDF *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'https://...',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF2A2A3E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'القسم',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.categoryNames.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(widget.categoryIcons[entry.key], color: widget.categoryColors[entry.key], size: 20),
                        const SizedBox(width: 8),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'description': _descriptionController.text,
                            'pdfUrl': _pdfUrlController.text,
                            'category': _selectedCategory,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== نموذج إضافة/تعديل الفورم (مع اختيار المادة) ==================
class _FormDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initialData;
  final Map<String, String> categoryNames;
  final Map<String, IconData> categoryIcons;
  final Map<String, Color> categoryColors;

  const _FormDialog({
    required this.title,
    this.initialData,
    required this.categoryNames,
    required this.categoryIcons,
    required this.categoryColors,
  });

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _formUrlController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _formUrlController = TextEditingController(text: widget.initialData?['formUrl'] ?? '');
    _selectedCategory = widget.initialData?['category'] ?? 'computer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _formUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1A1A2E),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'اسم الفورمة *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف الفورمة',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _formUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'رابط Google Form *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'https://docs.google.com/forms/...',
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              // ✅ اختيار المادة (القسم) للفورمة
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF2A2A3E),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'المادة',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.categoryNames.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(widget.categoryIcons[entry.key], color: widget.categoryColors[entry.key], size: 20),
                        const SizedBox(width: 8),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            'name': _nameController.text,
                            'description': _descriptionController.text,
                            'formUrl': _formUrlController.text,
                            'category': _selectedCategory,  // ✅ إضافة القسم
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageAllNotificationsScreenState extends State<ManageAllNotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _db
          .collection('all_notifications')
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ Found ${snapshot.docs.length} notifications in all_notifications');

      setState(() {
        _notifications = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تحديد أي إشعار'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف ${_selectedNotifications.length} إشعار؟\nسيتم حذفها من جميع المستخدمين نهائياً.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // 1. حذف من all_notifications
        final batch1 = _db.batch();
        for (var id in _selectedNotifications) {
          batch1.delete(_db.collection('all_notifications').doc(id));
        }
        await batch1.commit();

        // 2. حذف من جميع المستخدمين
        final users = await _db.collection('users').get();
        final batch2 = _db.batch();

        for (var notificationId in _selectedNotifications) {
          for (var user in users.docs) {
            final ref = _db
                .collection('users')
                .doc(user.id)
                .collection('notifications')
                .doc(notificationId);
            batch2.delete(ref);
          }
        }
        await batch2.commit();

        // 3. تحديث القائمة
        await _loadNotifications();
        _selectedNotifications.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ تم حذف الإشعارات نهائياً'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('❌ Error deleting: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedNotifications.length == _notifications.length) {
        _selectedNotifications.clear();
      } else {
        _selectedNotifications = _notifications.map((n) => n.id).toSet();
      }
    });
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} أيام';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'جميع الإشعارات المرسلة',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedNotifications.isNotEmpty)
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                'حذف (${_selectedNotifications.length})',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'جاري تحميل الإشعارات...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في التحميل',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.white30),
            const SizedBox(height: 16),
            const Text(
              'لا توجد إشعارات مرسلة',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _selectedNotifications.length == _notifications.length && _notifications.isNotEmpty,
                onChanged: (_) => _toggleSelectAll(),
                checkColor: Colors.white,
                activeColor: Colors.blue,
              ),
              const Text(
                'تحديد الكل',
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Text(
                '${_selectedNotifications.length} / ${_notifications.length}',
                style: const TextStyle(color: Colors.white38),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadNotifications,
                tooltip: 'تحديث',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final doc = _notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isSelected = _selectedNotifications.contains(doc.id);
              final sentToList = data['sentTo'] as List? ?? [];
              final readByList = data['readBy'] as List? ?? [];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedNotifications.remove(doc.id);
                    } else {
                      _selectedNotifications.add(doc.id);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.withOpacity(0.15) : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedNotifications.remove(doc.id);
                          } else {
                            _selectedNotifications.add(doc.id);
                          }
                        });
                      },
                      checkColor: Colors.white,
                      activeColor: Colors.red,
                    ),
                    title: Text(
                      data['title'] ?? 'بدون عنوان',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              'أرسل إلى: ${sentToList.length} مستخدم',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.remove_red_eye, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              'قرأ: ${readByList.length}',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time, size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(data['createdAt']),
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}