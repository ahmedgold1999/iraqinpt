import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../models/app_models.dart';
import '../../widgets/luxury_loading.dart';
import '../../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  // ===== Animation =====
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _containerColorAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _containerColorAnimation = ColorTween(
      begin: const Color(0xFFF8F9FA),
      end: Colors.white,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation after initialization
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===== Account Deletion Dialog =====
  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'حذف الحساب نهائياً',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك ونتائجك ولا يمكن استعادتها مرة أخرى. هذا الإجراء نهائي.',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.deleteAccount();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===== Logout Dialog =====
  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 50,
                          spreadRadius: -5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade700,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade300.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.shade400.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await authService.signOut();
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/login', (route) => false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'تأكيد',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                            fontSize: 15,
                          ),
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

  Widget _buildSubscriptionStatusCard(UserModel user) {
    final isPremium = user.isPremium;
    final expiryDate = user.expiryDate;
    final now = DateTime.now();
    
    String status = isPremium ? 'مشترك مميز ✨' : 'حساب مجاني';
    String subTitle = 'استمتع بكامل ميزات التطبيق';
    Color color = isPremium ? const Color(0xFFF59E0B) : const Color(0xFF6B7280);
    
    if (isPremium && expiryDate != null) {
      if (expiryDate.isBefore(now)) {
        status = 'انتهى الاشتراك';
        subTitle = 'يرجى التجديد للاستمرار';
        color = const Color(0xFFEF4444);
      } else {
        final days = expiryDate.difference(now).inDays;
        subTitle = days > 365 ? 'اشتراك دائمي' : 'ينتهي بعد $days يوم';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPremium ? Icons.stars_rounded : Icons.person_outline_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subTitle,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.subscription),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('ترقية', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildSmartStatsCard(String userId) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: SocialService().getSubjectStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
        
        final stats = snapshot.data!;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProgressBar('اللغة العربية', stats['arabic'] ?? 0.0, const Color(0xFF00C853)),
              const SizedBox(height: 14),
              _buildProgressBar('الحاسوب', stats['computer'] ?? 0.0, const Color(0xFF8B5CF6)),
              const SizedBox(height: 14),
              _buildProgressBar('اللغة الإنجليزية', stats['english'] ?? 0.0, const Color(0xFF2563EB)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1C1C1E))),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.12),
            color: color,
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSettingsCard() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
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
              const Row(
                children: [
                  Icon(Icons.text_fields_rounded, color: Color(0xFF0F172A), size: 20),
                  SizedBox(width: 8),
                  Text('حجم النص في التطبيق', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1C1C1E))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFontOption(context, settings, 'صغير', 0.85),
                  _buildFontOption(context, settings, 'افتراضي', 1.0),
                  _buildFontOption(context, settings, 'كبير', 1.15),
                  _buildFontOption(context, settings, 'ضخم', 1.3),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontOption(BuildContext context, SettingsProvider settings, String label, double scale) {
    final isSelected = settings.fontScale == scale;
    return GestureDetector(
      onTap: () => settings.setFontScale(scale),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE5E5EA)),
            ),
            child: Text('ع', style: TextStyle(fontSize: 14 * scale, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF8E8E93))),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  String _roleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'مدير النظام';
      case UserRole.teacher:
        return 'معلم';
      default:
        return 'طالب';
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Transform.translate(
      offset: Offset(0, _slideAnimation.value),
      child: Opacity(
        opacity: _fadeAnimation.value,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 25,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: color,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.notoKufiArabic(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<UserModel?>(
      stream: authService.userData,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: LuxuryLoading(message: 'جاري تحميل البيانات...'),
          );
        }

        final user = snapshot.data!;
        final daysLeft = user.expiryDate?.difference(DateTime.now()).inDays ?? 0;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Scaffold(
              backgroundColor: _containerColorAnimation.value,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Luxurious Vibrant iOS Header
                  SliverAppBar(
                    expandedHeight: 140,
                    floating: true,
                    pinned: true,
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF2563EB),
                              Color(0xFF4F46E5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFF00C853), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.35),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person_rounded,
                                size: 36,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: const Text(
                        'الملف الشخصي والإعدادات',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),

                  // User Info with Animation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Column(
                        children: [
                          if (_scaleAnimation != null)
                            ScaleTransition(
                              scale: _scaleAnimation!,
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            )
                          else
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.email,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Personal Info Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('المعلومات الشخصية'),
                  ),

                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildInfoCard(
                        icon: Icons.badge_rounded,
                        title: 'الدور',
                        value: _roleName(user.role),
                        color: const Color(0xFF3B82F6),
                      ),
                      _buildSubscriptionStatusCard(user),
                      
                      const SizedBox(height: 16),
                      _buildSectionHeader('مستواك في المواد'),
                      _buildSmartStatsCard(user.uid),

                      const SizedBox(height: 16),
                      _buildSectionHeader('إعدادات التطبيق'),
                      _buildFontSettingsCard(),
                      
                      const SizedBox(height: 16),
                      _buildSectionHeader('الحساب'),
                      _buildInfoCard(
                        icon: Icons.delete_forever_rounded,
                        title: 'إدارة البيانات',
                        value: 'حذف الحساب نهائياً',
                        color: Colors.red,
                        onTap: () => _showDeleteAccountDialog(context, authService),
                      ),
                    ]),
                  ),

                  // Premium Logout Button
                  if (daysLeft > 0 && daysLeft <= 7)
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFF3E0),
                                  Color(0xFFFFE0B2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFB74D),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB74D)
                                      .withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'متبقي $daysLeft أيام على انتهاء الاشتراك',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Premium Logout Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFEF4444),
                                  Color(0xFFDC2626),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade400.withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: () =>
                                    _showLogoutDialog(context, authService),
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'تسجيل الخروج',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer Spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}