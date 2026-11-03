import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _userName = '';
  bool _isPremium = false;
  DateTime? _expiryDate;
  bool _isLoadingUserData = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data() ?? {};
          DateTime? exp;
          final expRaw = data['expiryDate'] ?? data['premiumUntil'];
          if (expRaw is Timestamp) exp = expRaw.toDate();
          if (expRaw is String) exp = DateTime.tryParse(expRaw);

          setState(() {
            _userName = data['name'] ?? user.displayName ?? '';
            _isPremium = data['isPremium'] == true &&
                (exp == null || exp.isAfter(DateTime.now()));
            _expiryDate = exp;
            _isLoadingUserData = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user subscription info: $e');
    }
    if (mounted) {
      setState(() => _isLoadingUserData = false);
    }
  }

  /// فتح محادثة الواتساب مع الإدارة بنص مهني متوافق مع سياسات قوقل
  Future<void> _launchWhatsApp() async {
    const String phoneNumber = '9647824255360';
    final String message = _userName.trim().isNotEmpty
        ? 'مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني. (اسم المستخدم: $_userName)'
        : 'مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني.';

    final String encoded = Uri.encodeComponent(message);
    final Uri appUri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
    final Uri webUri = Uri.parse('https://web.whatsapp.com/send?phone=$phoneNumber&text=$encoded');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showSnackBar('تعذر فتح تطبيق واتساب. يرجى التأكد من تثبيته على جهازك.');
    }
  }

  /// فتح محادثة التليجرام مع الإدارة بنص مهني متوافق مع سياسات قوقل
  Future<void> _launchTelegram() async {
    const String username = 'XG0LDX';
    final String message = _userName.trim().isNotEmpty
        ? 'مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني. (اسم المستخدم: $_userName)'
        : 'مرحباً، أود تفعيل اشتراكي في تطبيق دليل الامتحان الوطني.';

    final String encoded = Uri.encodeComponent(message);
    final Uri tgUri = Uri.parse('https://t.me/$username?text=$encoded');
    final Uri fallbackUri = Uri.parse('https://t.me/$username');

    try {
      if (await canLaunchUrl(tgUri)) {
        await launchUrl(tgUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showSnackBar('تعذر فتح تطبيق تليجرام. يرجى التأكد من تثبيته على جهازك.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : _kIosBg,
      appBar: AppBar(
        title: const Text(
          'عضوية الحساب المميز 👑',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // 1. الهيدر الفاخر بتدرج انسيابي
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
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
                            border: Border.all(
                              color: _kIosGold.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 44,
                            color: _kIosGold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'عضوية دليل الامتحان الوطني VIP',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Tajawal',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'الوصول الشامل لبنك الأسئلة المعتمد، الملازم، والاختبارات التفاعلية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'Tajawal',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. بطاقة حالة الحساب الحالية للطالب
                if (!_isLoadingUserData) _buildAccountStatusCard(isDark),

                const SizedBox(height: 16),

                // 3. البطاقة التفاعلية الرئيسية: طلب تفعيل الحساب ومراسلة الإدارة
                _buildActivationContactCard(isDark),

                const SizedBox(height: 16),

                // 4. بطاقة مميزات العضوية الكاملة
                _buildFeaturesCard(isDark),

                const SizedBox(height: 16),

                // 5. بطاقة معلومات الوصول والحساب المسبق
                _buildInstitutionalAccessCard(isDark),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقة تعرض حالة الحساب الحالية
  Widget _buildAccountStatusCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPremium
              ? const Color(0xFF10B981).withOpacity(0.4)
              : (isDark ? Colors.white10 : _kIosBorder),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isPremium
                  ? const Color(0xFF10B981).withOpacity(0.14)
                  : const Color(0xFF64748B).withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: _isPremium ? const Color(0xFF10B981) : const Color(0xFF64748B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty ? 'الطالب: $_userName' : 'حساب الطالب',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : _kIosTextDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isPremium
                      ? (_expiryDate != null
                          ? 'حسابك مفعل ومميز حتى: ${_expiryDate!.year}/${_expiryDate!.month}/${_expiryDate!.day}'
                          : 'حسابك مفعل ومميز دائماً 👑')
                      : 'حسابك حالياً غير مفعل (مجاني تجريبي)',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isPremium ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isPremium
                  ? const Color(0xFF10B981).withOpacity(0.12)
                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isPremium ? 'نشط VIP' : 'مجاني',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isPremium ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// البطاقة التفاعلية الفخمة لمراسلة الإدارة وطلب التفعيل (متوافقة 100% مع سياسات قوقل)
  Widget _buildActivationContactCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _kIosGold.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kIosGold.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kIosGold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.send_and_archive_rounded,
                  color: _kIosGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل الاشتراك والوصول الكامل',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16.5,
                        color: isDark ? Colors.white : _kIosTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'إدارة المنصة متاحة للتفعيل المباشر',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: isDark ? Colors.white60 : _kIosTextMuted,
                      ),
                    ),
                  ],
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
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              'للحصول على اشتراكك وتفعيل حسابك لفتح بنوك الأسئلة المعتمدة، الملازم، والاختبارات التخصصية، يرجى مراسلة إدارة المنصة عبر إحدى الوسائل التالية لإتمام التفعيل لحسابك فوراً:',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                height: 1.55,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // زر الواتساب الفاخر التفاعلي
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF1EBE5D), Color(0xFF128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _launchWhatsApp,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'مراسلة الإدارة عبر الواتساب لتفعيل الحساب',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // زر التليجرام الفاخر التفاعلي
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF0088CC), Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0088CC).withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _launchTelegram,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 21),
                      SizedBox(width: 10),
                      Text(
                        'مراسلة الإدارة عبر التليجرام لتفعيل الحساب',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // شريط توضيحي لطمأنة الطالب
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: _kIosGold),
              const SizedBox(width: 4),
              Text(
                'يتم الرد وتفعيل الحساب فوراً خلال دقائق من قبل الإدارة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// مميزات العضوية الكاملة
  Widget _buildFeaturesCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
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
                'ماذا تتضمن العضوية الكاملة؟',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _kIosTextDark,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFeatureItem(
            Icons.quiz_rounded,
            'بنك الأسئلة الشامل (3000+ سؤال)',
            'الوصول لجميع بنوك الأسئلة الوزارية لمواد العربي والإنكليزي والحاسوب مع التوضيحات.',
            const Color(0xFF3B82F6),
            isDark,
          ),
          _buildFeatureItem(
            Icons.menu_book_rounded,
            'الملازم والضوابط الرسمية',
            'تصفح الملازم المعتمدة وضوابط القبول التنافسي الوزارية مباشرة بصيغة PDF.',
            const Color(0xFF10B981),
            isDark,
          ),
          _buildFeatureItem(
            Icons.smart_toy_rounded,
            'الأستاذ الذكي المساعد (AI)',
            'إجابات وشروحات فورية ذكية على أسئلة ونماذج الامتحانات على مدار الساعة.',
            const Color(0xFF8B5CF6),
            isDark,
          ),
          _buildFeatureItem(
            Icons.leaderboard_rounded,
            'إحصائيات التقدم ولوحة الشرف',
            'تحليل مستواك الدراسي ونقاط القوة والضعف ومقارنة نتيجتك مع زملائك المتقدمين.',
            const Color(0xFFF59E0B),
            isDark,
          ),
          _buildFeatureItem(
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

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool isDark,
  ) {
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
                    fontSize: 14.5,
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

  /// بطاقة معلومات الوصول المؤسسي والتزامن
  Widget _buildInstitutionalAccessCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 8),
              Text(
                'ملاحظات الوصول والمزامنة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _kIosTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• إذا كان لديك حساب مفعّل مسبقاً، يمكنك تسجيل الدخول بنفس الحساب للوصول الفوري لكافة الميزات.\n• تتم مزامنة حالة العضوية واختباراتك تلقائياً عبر السحابة على كافة أجهزتك المسجلة.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.5,
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
