import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/config_service.dart';

const Color _kIosBg = Color(0xFFF8F9FA);
const Color _kIosTextDark = Color(0xFF1C1C1E);
const Color _kIosTextMuted = Color(0xFF8E8E93);
const Color _kIosPrimary = Color(0xFF0F172A);
const Color _kIosGold = Color(0xFFF59E0B);
const Color _kIosBorder = Color(0xFFE5E5EA);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _userName = '';

  String _price1m = '10,000';
  String _price2m = '15,000';
  String _price3m = '20,000';
  String _price1y = '30,000';

  String _selectedPlan = '1m';

  StreamSubscription<DocumentSnapshot>? _pricesSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _loadUserName();
    _loadPrices();
    _listenToFirestorePrices();
  }

  void _listenToFirestorePrices() {
    _pricesSubscription = FirebaseFirestore.instance
        .collection('system_settings')
        .doc('maintenance_and_updates')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        setState(() {
          if (data['price_1m'] != null && data['price_1m'].toString().trim().isNotEmpty) {
            _price1m = data['price_1m'].toString().trim();
          }
          if (data['price_2m'] != null && data['price_2m'].toString().trim().isNotEmpty) {
            _price2m = data['price_2m'].toString().trim();
          }
          if (data['price_3m'] != null && data['price_3m'].toString().trim().isNotEmpty) {
            _price3m = data['price_3m'].toString().trim();
          }
          if (data['price_1y'] != null && data['price_1y'].toString().trim().isNotEmpty) {
            _price1y = data['price_1y'].toString().trim();
          }
        });
      }
    }, onError: (e) => debugPrint('⚠️ Error listening to prices: $e'));
  }

  Future<void> _loadPrices() async {
    setState(() {
      _price1m = ConfigService().getPrice('1m');
      _price2m = ConfigService().getPrice('2m');
      _price3m = ConfigService().getPrice('3m');
      _price1y = ConfigService().getPrice('1y');
    });
  }

  @override
  void dispose() {
    _pricesSubscription?.cancel();
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('خطأ في جلب اسم المستخدم: $e');
    }
  }

  Future<void> _launchWhatsAppWithMessage() async {
    String phoneNumber = '9647824255360';
    String planLabel = _getPlanLabel(_selectedPlan);
    String price = _getPlanPrice(_selectedPlan);

    String message = _userName.isNotEmpty
        ? 'السلام عليكم، اريد اشترك بالتطبيق (دليل الامتحان الوطني العراقي) لمدة ($planLabel) بسعر ($price) واسمي داخل التطبيق هو $_userName'
        : 'السلام عليكم، اريد اشترك بالتطبيق (دليل الامتحان الوطني العراقي) لمدة ($planLabel) بسعر ($price)';

    String encodedMessage = Uri.encodeComponent(message);
    String whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

    final Uri uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://web.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar('⚠️ لم يتم العثور على تطبيق واتساب', Colors.red);
    }
  }

  Future<void> _launchTelegramWithMessage() async {
    String username = 'XG0LDX';
    String planLabel = _getPlanLabel(_selectedPlan);
    String price = _getPlanPrice(_selectedPlan);

    String message = _userName.isNotEmpty
        ? 'السلام عليكم، اريد اشترك بالتطبيق (دليل الامتحان الوطني العراقي) لمدة ($planLabel) بسعر ($price) واسمي داخل التطبيق هو $_userName'
        : 'السلام عليكم، اريد اشترك بالتطبيق (دليل الامتحان الوطني العراقي) لمدة ($planLabel) بسعر ($price)';

    String encodedMessage = Uri.encodeComponent(message);
    String telegramUrl = 'https://t.me/$username?text=$encodedMessage';

    final Uri uri = Uri.parse(telegramUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://t.me/$username'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar('⚠️ لم يتم العثور على تطبيق تليجرام', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildStepItem(String text, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2563EB) : _kIosPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : _kIosTextDark,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanLabel(String plan) {
    switch (plan) {
      case '1m': return 'شهر واحد';
      case '2m': return 'شهرين';
      case '3m': return '3 أشهر';
      case '1y': return 'سنة كاملة';
      default: return '';
    }
  }

  String _getPlanPrice(String plan) {
    switch (plan) {
      case '1m': return '$_price1m د.ع';
      case '2m': return '$_price2m د.ع';
      case '3m': return '$_price3m د.ع';
      case '1y': return '$_price1y د.ع';
      default: return '';
    }
  }

  Widget _buildPlanCard(String id, String label, String price, bool isDark) {
    bool isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFFFFBEB))
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kIosGold : (isDark ? Colors.white10 : _kIosBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kIosGold.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _kIosGold : (isDark ? Colors.white38 : _kIosTextMuted),
                  width: 2,
                ),
                color: isSelected ? _kIosGold : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: isDark ? Colors.white : _kIosTextDark,
                ),
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: isSelected ? _kIosGold : (isDark ? Colors.white60 : _kIosTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSupportForIos() async {
    String username = 'XG0LDX';
    String message = _userName.isNotEmpty
        ? 'السلام عليكم، أحتاج مساعدة أو استفسار بخصوص حسابي في تطبيق دليل الامتحان الوطني واسمي داخل التطبيق هو $_userName'
        : 'السلام عليكم، أحتاج مساعدة أو استفسار بخصوص حسابي في تطبيق دليل الامتحان الوطني';

    String encodedMessage = Uri.encodeComponent(message);
    String telegramUrl = 'https://t.me/$username?text=$encodedMessage';

    final Uri uri = Uri.parse(telegramUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://t.me/$username'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar('⚠️ تعذر فتح قناة الدعم الفني', Colors.red);
    }
  }

  Widget _buildIosFeatureItem(IconData icon, String title, String subtitle, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: isDark ? Colors.white : _kIosTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Tajawal',
                    color: isDark ? Colors.white60 : _kIosTextMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosFeaturesCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : _kIosBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
              const Icon(Icons.stars_rounded, color: _kIosGold, size: 24),
              const SizedBox(width: 8),
              Text(
                'مميزات العضوية الكاملة',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _kIosTextDark,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildIosFeatureItem(
            Icons.quiz_rounded,
            'بنك الأسئلة الشامل (3000+ سؤال)',
            'الوصول لجميع بنوك الأسئلة الوزارية لمواد العربي والإنكليزي والحاسوب مع التوضيحات.',
            const Color(0xFF3B82F6),
            isDark,
          ),
          _buildIosFeatureItem(
            Icons.menu_book_rounded,
            'الملازم والضوابط الرسمية',
            'تصفح الملازم المعتمدة وضوابط القبول التنافسي الوزارية مباشرة بصيغة PDF.',
            const Color(0xFF10B981),
            isDark,
          ),
          _buildIosFeatureItem(
            Icons.smart_toy_rounded,
            'الأستاذ الذكي المساعد (AI)',
            'إجابات وشروحات فورية ذكية على أسئلة ونماذج الامتحانات على مدار الساعة.',
            const Color(0xFF8B5CF6),
            isDark,
          ),
          _buildIosFeatureItem(
            Icons.leaderboard_rounded,
            'إحصائيات التقدم ولوحة الشرف',
            'تحليل مستواك الدراسي ونقاط القوة والضعف ومقارنة نتيجتك مع زملائك المتقدمين.',
            const Color(0xFFF59E0B),
            isDark,
          ),
          _buildIosFeatureItem(
            Icons.bolt_rounded,
            'بنك الأخطاء الذكي واختبارات السرعة',
            'مراجعة مكثفة ومركزة لكافة الأخطاء السابقة لتثبيت المعلومة وتحقيق أعلى معدل.',
            const Color(0xFFEC4899),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildIosAccessInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : _kIosBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
              const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 22),
              const SizedBox(width: 8),
              Text(
                'معلومات الوصول للعضوية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _kIosTextDark,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'إذا كان لديك حساب مفعل مسبقاً عبر منصة الامتحان الوطني أو مركز التدريب، يرجى تسجيل الدخول بنفس الحساب للوصول الفوري لكافة الميزات.',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Tajawal',
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sync_rounded, color: Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تتم مزامنة حالة وصلاحية الحساب تلقائياً عبر السحابة لجميع أجهزتك المسجلة.',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Tajawal',
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _launchSupportForIos,
              icon: const Icon(Icons.support_agent_rounded, size: 22),
              label: const Text(
                'تواصل مع الدعم الفني والاستفسارات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : _kIosBg,
      appBar: AppBar(
        title: Text(isIos ? 'عضوية الحساب المميز 👑' : 'الاشتراك المميز 👑'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Hero Crown Banner
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              size: 44,
                              color: _kIosGold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isIos ? 'عضوية الحساب المميز' : 'ترقية الحساب المميز',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isIos
                                ? 'الوصول الشامل لبنك الأسئلة والملازم والاختبارات التفاعلية'
                                : 'احصل على الوصول الكامل لجميع الامتحانات والملازم',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ================= iOS ONLY VIEW =================
              if (isIos) ...[
                _buildIosFeaturesCard(isDark),
                const SizedBox(height: 16),
                _buildIosAccessInfoCard(isDark),
              ] else ...[
                // ================= ANDROID / WEB VIEW =================
                // Plans Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : _kIosBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر مدة الاشتراك',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _kIosTextDark,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPlanCard('1m', 'شهر واحد', '$_price1m د.ع', isDark),
                      _buildPlanCard('2m', 'شهرين', '$_price2m د.ع', isDark),
                      _buildPlanCard('3m', '3 أشهر', '$_price3m د.ع', isDark),
                      _buildPlanCard('1y', 'سنة كاملة', '$_price1y د.ع', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // How to Activate & Contact Buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : _kIosBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'خطوات التفعيل الفوري',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _kIosTextDark,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildStepItem('اختر مدة الاشتراك المناسبة من الأعلى', 1, isDark),
                      _buildStepItem('اضغط على رابط الدعم (واتساب أو تليجرام)', 2, isDark),
                      _buildStepItem('سيقوم الأدمن بتفعيل حسابك فوراً', 3, isDark),

                      const SizedBox(height: 20),

                      // WhatsApp & Telegram Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _launchWhatsAppWithMessage,
                          icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                          label: const Text(
                            'تواصل عبر الواتساب للتفعيل',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _launchTelegramWithMessage,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: const Text(
                            'تواصل عبر التليجرام للتفعيل',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0088CC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}