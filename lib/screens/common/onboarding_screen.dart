import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  // ألوان وهوية كل صفحة من الصفحات الأربع
  static const List<_OnboardingPageData> _pagesData = [
    _OnboardingPageData(
      badge: '🎓 المنصة التعليمية الأولى للدراسات العليا',
      title: 'بوابتك الأولى للنجاح في\nالامتحان الوطني الموحد',
      description:
          'التدريب الأقوى والأشمل للمتقدمين للدراسات العليا (دكتوراه، ماجستير، دبلوم عالي) في كافة الجامعات العراقية لضمان التفوق وتحقيق أعلى الدرجات.',
      primaryColor: Color(0xFF2563EB), // Royal Blue
      accentColor: Color(0xFF6366F1),  // Indigo
      gradient: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF4F46E5)],
      features: [
        '🏛️ متوافق 100% مع معايير وزارة التعليم العالي',
        '⏱️ محاكاة واقعية لنظام الاختبار والوقت الوزاري',
      ],
    ),
    _OnboardingPageData(
      badge: '📚 بنك أسئلة ذكي وشامل لكافة المواد',
      title: 'آلاف الأسئلة الوزارية\nوالاختبارات التخصصية',
      description:
          'تدرب على مهارات الحاسوب، اللغة الإنجليزية، واللغة العربية مع اختبارات تخصصية مركزة (الاختصارات، القواعد، المحادثات) ودعم العمل بدون إنترنت أوفلاين.',
      primaryColor: Color(0xFF059669), // Emerald
      accentColor: Color(0xFF0D9488),  // Teal
      gradient: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF0D9488)],
      features: [
        '💾 حفظ وتحديث بنك الأسئلة للاستخدام أوفلاين',
        '🎯 تصحيح فوري وشروحات تفصيلية لكل سؤال',
      ],
    ),
    _OnboardingPageData(
      badge: '🤖 أستاذك الذكي المدعوم بالذكاء الاصطناعي',
      title: 'الأستاذ الذكي AI..\nشرح وتفكيك فوري لكل سؤال',
      description:
          'لا تدع أي سؤال غامض يوقفك! يرافقك الأستاذ الذكي AI لتفكيك خطوات الإجابة لحظياً، مع حفظ جميع أخطائك في بنك الأخطاء التلقائي لضمان عدم تكرارها.',
      primaryColor: Color(0xFF7C3AED), // Purple
      accentColor: Color(0xFFDB2777),  // Pink
      gradient: [Color(0xFF581C87), Color(0xFF7C3AED), Color(0xFFC026D3)],
      features: [
        '💡 تحليل منطقي لخيارات السؤال وأسباب الصحة',
        '📂 بنك الأخطاء الذكي لمراجعة نقاط ضعفك',
      ],
    ),
    _OnboardingPageData(
      badge: '🏆 التنافس الوطني وشهادة الكفاءة',
      title: 'نافس آلاف الطلاب\nواضمن مقعدك الدراسي',
      description:
          'تابع تقدمك اليومي، تصدر لوحة الشرف الوطنية على مستوى محافظات العراق، وتسلّح بالثقة الكاملة لاجتياز الامتحان الوطني من المحاولة الأولى وبامتياز.',
      primaryColor: Color(0xFFEA580C), // Sunset Orange
      accentColor: Color(0xFFD97706),  // Amber Gold
      gradient: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFF59E0B)],
      features: [
        '📊 إحصائيات دقيقة لمستواك الحقيقي ونقاط قوتك',
        '👑 لوحة شرف تفاعلية للمتفوقين في عموم العراق',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeData = _pagesData[_currentPage];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. الشريط العلوي (الشعار وزر التخطي)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // هوية التطبيق المصغرة
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: activeData.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: activeData.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الامتحان الوطني',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  // زر التخطي (Skip)
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تخطي',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // 2. المحتوى التفاعلي عبر PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pagesData.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildPageItem(
                    data: _pagesData[index],
                    pageIndex: index,
                    isDark: isDark,
                    screenHeight: screenHeight,
                  );
                },
              ),
            ),

            // 3. الجزء السفلي (مؤشر الصفحات وزر المتابعة)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // مؤشر الصفحات المتحرك الفاخر (Expanding Indicator)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pagesData.length, (idx) {
                      final isSelected = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isSelected ? 30 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeData.primaryColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: activeData.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  // أزرار التنقل (السابق / التالي / البدء)
                  Row(
                    children: [
                      // زر السابق (يظهر من الصفحة 2 فما فوق)
                      if (_currentPage > 0) ...[
                        OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 22), // في RTL يرجع لليمين
                        ),
                        const SizedBox(width: 12),
                      ],

                      // الزر الرئيسي (التالي أو ابدأ الآن)
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeData.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: activeData.primaryColor.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == 3 ? 'ابدأ رحلة التفوق الآن 🚀' : 'متابعة ⬅️',
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem({
    required _OnboardingPageData data,
    required int pageIndex,
    required bool isDark,
    required double screenHeight,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.02),

          // 1. العنصر البصري التفاعلي الخاص بكل صفحة
          _buildHeroGraphic(pageIndex, data, isDark),

          SizedBox(height: screenHeight * 0.03),

          // 2. الشارة الفخمة العلوية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: data.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: data.primaryColor.withValues(alpha: 0.28)),
            ),
            child: Text(
              data.badge,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: data.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // 3. العنوان الرئيسي القوي
          Text(
            data.title,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // 4. الوصف التفصيلي
          Text(
            data.description,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.5,
              color: textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // 5. بطاقات الميزات السريعة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: data.features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: data.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feat,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// بناء العنصر البصري المتحرك المخصص لكل صفحة
  Widget _buildHeroGraphic(int pageIndex, _OnboardingPageData data, bool isDark) {
    switch (pageIndex) {
      case 0:
        return _buildGraduationHero(data, isDark);
      case 1:
        return _buildQuestionBanksHero(data, isDark);
      case 2:
        return _buildAiTutorHero(data, isDark);
      case 3:
      default:
        return _buildLeaderboardHero(data, isDark);
    }
  }

  // الصفحة 1: قبعة التخرج Lottie مع بوابة مشعة
  Widget _buildGraduationHero(_OnboardingPageData data, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  data.primaryColor.withValues(alpha: 0.35),
                  data.accentColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // حلقة خارجية متوهجة
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.primaryColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
                // Lottie Animation
                Lottie.asset(
                  'assets/icons/graduation_hat.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.school_rounded, size: 90, color: data.primaryColor);
                  },
                ),
                // شارة العراق العائمة
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                        ),
                      ],
                      border: Border.all(color: data.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇮🇶', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          'جمهورية العراق',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
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

  // الصفحة 2: بطاقات المواد الثلاثية العائمة + عداد الأسئلة
  Widget _buildQuestionBanksHero(_OnboardingPageData data, bool isDark) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: SizedBox(
            width: 250,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // بطاقة الحاسوب (الخلفية اليسرى)
                Positioned(
                  left: 10,
                  top: 25,
                  child: Transform.rotate(
                    angle: -0.12,
                    child: _buildMiniSubjectCard('💻', 'الحاسوب', const Color(0xFF0284C7), isDark),
                  ),
                ),
                // بطاقة الإنجليزية (الخلفية اليمنى)
                Positioned(
                  right: 10,
                  top: 25,
                  child: Transform.rotate(
                    angle: 0.12,
                    child: _buildMiniSubjectCard('🇬🇧', 'English', const Color(0xFF7C3AED), isDark),
                  ),
                ),
                // بطاقة اللغة العربية (الوسط الأمامي)
                Positioned(
                  top: 45,
                  child: _buildMiniSubjectCard('📚', 'اللغة العربية', const Color(0xFF059669), isDark, isProminent: true),
                ),
                // شارة عدد الأسئلة المتوهجة
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '+3000 سؤال وزاري محدث',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildMiniSubjectCard(String emoji, String title, Color color, bool isDark, {bool isProminent = false}) {
    return Container(
      width: isProminent ? 140 : 120,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isProminent ? 12 : 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isProminent ? 0.6 : 0.3),
          width: isProminent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isProminent ? 0.25 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: isProminent ? 22 : 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: isProminent ? 13 : 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // الصفحة 3: الأستاذ الذكي AI مع بالونات المحادثة الذكية
  Widget _buildAiTutorHero(_OnboardingPageData data, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 250,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الهالة البنفسجية المشعة
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      data.primaryColor.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // روبوت الذكاء الاصطناعي المركزي
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [data.primaryColor, data.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 46),
                ),
              ),
              // فقاعة محادثة ذكية 1 (يسار أعلى)
              Positioned(
                top: 15,
                left: 10,
                child: _buildChatBubble('لماذا هذا الخيار صحيح؟ 💡', isDark),
              ),
              // فقاعة محادثة ذكية 2 (يمين أسفل)
              Positioned(
                bottom: 20,
                right: 10,
                child: _buildChatBubble('تفكيك خطوات الإجابة ⚡', isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }

  // الصفحة 4: لوحة الشرف والكأس الذهبي والمراكز
  Widget _buildLeaderboardHero(_OnboardingPageData data, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 250,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الكأس الذهبي المركزي المتوهج
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 52),
                ),
              ),
              // بطاقة المركز الأول (أعلى يمين)
              Positioned(
                top: 15,
                right: 8,
                child: _buildPodiumBadge('🥇 المركز الأول', '100%', const Color(0xFFF59E0B), isDark),
              ),
              // بطاقة المركز الثاني (أسفل يسار)
              Positioned(
                bottom: 20,
                left: 8,
                child: _buildPodiumBadge('🥈 المركز الثاني', '98%', const Color(0xFF94A3B8), isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodiumBadge(String title, String score, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final String badge;
  final String title;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final List<Color> gradient;
  final List<String> features;

  const _OnboardingPageData({
    required this.badge,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.gradient,
    required this.features,
  });
}
