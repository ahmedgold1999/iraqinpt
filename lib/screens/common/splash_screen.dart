import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_models.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';
import '../../services/device_service.dart';
import '../../services/notification_service.dart';
import '../../services/sound_effects_service.dart';
import '../auth/login_screen.dart';
import 'device_limit_screen.dart';
import 'maintenance_screen.dart';
import 'onboarding_screen.dart';
import 'vpn_block_screen.dart';

/// =========================================================================
/// شاشة البداية الملكية والتقديمية العصرية الفاخرة (App Intro Splash Screen)
/// =========================================================================
class AppIntroSplashScreen extends StatefulWidget {
  const AppIntroSplashScreen({super.key});

  @override
  State<AppIntroSplashScreen> createState() => _AppIntroSplashScreenState();
}

class _AppIntroSplashScreenState extends State<AppIntroSplashScreen>
    with TickerProviderStateMixin {
  // ألوان الهوية الملكية العصرية
  static const Color _bgDark = Color(0xFF070B14);
  static const Color _bgDeep = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFFACC15);
  static const Color _goldAmber = Color(0xFFF59E0B);
  static const Color _goldGlow = Color(0xFFFFE066);

  // متحكمات الحركة
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;

  late AnimationController _ambientGlowController;
  late Animation<double> _ambientGlowAnimation;

  late AnimationController _questionMarkController;
  late Animation<double> _questionMarkScale;
  late Animation<double> _questionMarkRotate;

  late AnimationController _burstRingController;
  late Animation<double> _burstRingScale;
  late Animation<double> _burstRingOpacity;

  late AnimationController _subtextController;
  late Animation<double> _subtextFade;
  late Animation<double> _subtextSlide;

  // نص العبارة المطلوب
  static const String _fullText = 'ليش تحير بالامتحان الوطني وتطبيقنه موجود';
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;

  bool _isTypingComplete = false;
  bool _showQuestionMark = false;
  bool _showCursor = true;
  Timer? _cursorTimer;

  // منطق الانتقال والتهيئة في الخلفية
  Widget? _destinationScreen;
  bool _isInitDone = false;
  bool _isAnimationDone = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startPresentationTimeline();
    _runBackgroundAppInit();
  }

  void _initAnimations() {
    // 1. حركة دخول الأيقونة
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    // 2. توهج خلفي هادئ يتنفس
    _ambientGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _ambientGlowAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _ambientGlowController, curve: Curves.easeInOut),
    );

    // 3. حركة ظهور علامة الاستفهام بفرقعة وتأرجح ارتدادي فاخر
    _questionMarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _questionMarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionMarkController, curve: Curves.elasticOut),
    );
    _questionMarkRotate = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _questionMarkController, curve: Curves.easeOutBack),
    );

    // 4. حلقة الصدمة الضوئية (Shockwave Ring) الذهبية عند ظهور علامة الاستفهام
    _burstRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _burstRingScale = Tween<double>(begin: 0.2, end: 2.2).animate(
      CurvedAnimation(parent: _burstRingController, curve: Curves.easeOutCubic),
    );
    _burstRingOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _burstRingController, curve: Curves.easeOutQuad),
    );

    // 5. حركة ظهور العناصر التكميلية (النص الفرعي ومؤشر التقدم)
    _subtextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtextFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtextController, curve: Curves.easeOut),
    );
    _subtextSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _subtextController, curve: Curves.easeOutQuad),
    );

    // وميض مؤشر الكتابة |
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (mounted && !_isTypingComplete) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  /// الجدول الزمني للعرض السينمائي المبهر
  void _startPresentationTimeline() async {
    // بدء دخول الأيقونة
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _iconController.forward();

    // بدء طباعة النص حرفاً حرفاً بسرعة رشيقة وغير مملة (~38 ميلي ثانية لكل حرف)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 38), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTypingComplete = true;
          _showCursor = false;
        });
        _triggerQuestionMarkPop();
      }
    });
  }

  /// إطلاق ظهور علامة الاستفهام مع صوت الطقة والاهتزاز ولمعان الصدمة الذهبية
  Future<void> _triggerQuestionMarkPop() async {
    // وقفة ذكية قصيرة جداً (120ms) لتجهيز الأثر النفسي للعلامة
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    setState(() {
      _showQuestionMark = true;
    });

    // 🔊 تشغيل صوت الطقة فوراً + اهتزاز فيزيائي بالهاتف
    SoundEffectsService.playClickSound();
    HapticFeedback.heavyImpact();

    // تشغيل حركات الانفجار الضوئي والتأرجح
    _burstRingController.forward(from: 0.0);
    _questionMarkController.forward(from: 0.0);

    // ظهور النص الترحيبي الفرعي الأنيق بعد ظهور العلامة
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _subtextController.forward();

    // إنهاء جدول العرض التقديمي والانتقال
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _isAnimationDone = true;
    _checkAndNavigate();
  }

  /// التهيئة الشاملة للتطبيق بالخلفية بالتوازي مع العرض
  Future<void> _runBackgroundAppInit() async {
    try {
      NotificationService.enableNotifications().catchError((_) => null);

      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );

      UserModel? currentUser;
      bool isDeviceLimitReached = false;

      if (isLoggedIn) {
        currentUser = await authService.getCurrentUser().timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );

        if (currentUser != null) {
          final allowed = await DeviceService.checkDeviceLimit().timeout(
            const Duration(seconds: 2),
            onTimeout: () => true,
          ).catchError((_) => true);
          isDeviceLimitReached = !allowed;
        }
      }

      // فحص الـ VPN (معطل افتراضياً)
      const bool enableVpnCheck = false;
      bool isVpnActive = false;
      if (enableVpnCheck) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.vpn)) {
            isVpnActive = true;
          }
        } catch (_) {}
      }

      // فحص حالة الصيانة
      final bool isMaintenance = ConfigService().isMaintenanceOn;

      // فحص شاشة التعريف
      bool hasSeenOnboarding = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      } catch (_) {}

      // تحديد الشاشة التالية بدقة
      if (enableVpnCheck && isVpnActive) {
        _destinationScreen = VpnBlockScreen(onRefresh: () async {});
      } else if (isDeviceLimitReached) {
        _destinationScreen = const DeviceLimitScreen();
      } else if (isMaintenance && (currentUser == null || currentUser.role != UserRole.admin)) {
        _destinationScreen = const MaintenanceScreen();
      } else if (currentUser != null) {
        _destinationScreen = _RedirectDispatcher(user: currentUser);
      } else if (!hasSeenOnboarding) {
        _destinationScreen = const OnboardingScreen();
      } else {
        _destinationScreen = const LoginScreen();
      }
    } catch (e) {
      debugPrint('Splash Init Error: $e');
      _destinationScreen = const LoginScreen();
    } finally {
      _isInitDone = true;
      _checkAndNavigate();
    }
  }

  /// التحقق من اكتمال الرسوم والتهيئة ثم الانتقال بسلاسة
  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    if (_isInitDone && _isAnimationDone) {
      _hasNavigated = true;
      _navigateToDestination();
    }
  }

  /// إمكانية التخطي الفوري عند النقر
  void _skipIntro() {
    if (_hasNavigated) return;

    if (!_isTypingComplete) {
      _typewriterTimer?.cancel();
      setState(() {
        _displayedText = _fullText;
        _isTypingComplete = true;
        _showQuestionMark = true;
        _showCursor = false;
      });
      _questionMarkController.value = 1.0;
      _subtextController.value = 1.0;
      SoundEffectsService.playClickSound();
      HapticFeedback.selectionClick();
    }

    _isAnimationDone = true;
    if (_isInitDone) {
      _hasNavigated = true;
      _navigateToDestination();
    }
  }

  void _navigateToDestination() {
    final next = _destinationScreen ?? const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _typewriterTimer?.cancel();
    _iconController.dispose();
    _ambientGlowController.dispose();
    _questionMarkController.dispose();
    _burstRingController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgDark,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipIntro,
        child: Stack(
          children: [
            // ================= 1. الخلفية الملكية ذات التدرج الفاخر =================
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.1,
                  colors: [
                    Color(0xFF131D38),
                    Color(0xFF0B1224),
                    _bgDark,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ================= 2. هالة التوهج الذهبي خلف الأيقونة =================
            Center(
              child: Transform.translate(
                offset: const Offset(0, -45),
                child: AnimatedBuilder(
                  animation: _ambientGlowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 220 * _ambientGlowAnimation.value,
                      height: 220 * _ambientGlowAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.16 * _ambientGlowAnimation.value),
                            _goldAmber.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ================= 3. حلقة الانفجار الضوئي عند علامة الاستفهام =================
            Center(
              child: Transform.translate(
                offset: const Offset(0, 48),
                child: AnimatedBuilder(
                  animation: _burstRingController,
                  builder: (context, child) {
                    if (!_showQuestionMark || _burstRingOpacity.value <= 0.01) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: _burstRingOpacity.value,
                      child: Container(
                        width: 70 * _burstRingScale.value,
                        height: 70 * _burstRingScale.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _goldGlow.withValues(alpha: _burstRingOpacity.value),
                            width: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ================= 4. المحتوى المركزي (الأيقونة والنص) =================
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- أيقونة التطبيق الفاخرة بدون خلفية ---
                        ScaleTransition(
                          scale: _iconScale,
                          child: FadeTransition(
                            opacity: _iconFade,
                            child: Hero(
                              tag: 'app_main_logo',
                              child: Container(
                                width: 145,
                                height: 145,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withValues(alpha: 0.25),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/icons/appwithoutbackground.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (context, error, stackTrace) {
                                    // بديل آمن إن لم يوجد المسار
                                    return Image.asset(
                                      'assets/icons/app_icon.png',
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),

                        // --- السطر التعبيري الرئيسي مع حركة الآلة الكاتبة وعلامة الاستفهام ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // نص العبارة التدريجي
                                Text(
                                  _displayedText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.45,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),

                                // وميض مؤشر الكتابة أثناء الطباعة
                                if (!_isTypingComplete && _showCursor)
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 2.5,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _gold,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _gold.withValues(alpha: 0.7),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),

                                // علامة الاستفهام الفاخرة المنبثقة بقوة
                                if (_showQuestionMark)
                                  ScaleTransition(
                                    scale: _questionMarkScale,
                                    child: RotationTransition(
                                      turns: _questionMarkRotate,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6, bottom: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [_gold, _goldAmber],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _gold.withValues(alpha: 0.6),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '؟! ⚡',
                                          style: GoogleFonts.cairo(
                                            fontSize: 18.5,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF070B14),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // --- النص الترحيبي الفرعي المكمل للفخامة والبساطة ---
                        AnimatedBuilder(
                          animation: _subtextController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _subtextFade.value,
                              child: Transform.translate(
                                offset: Offset(0, _subtextSlide.value),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _gold.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: _gold,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'دليلك الرسمي المعتمد للتفوق والنجاح • 2026',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFCBD5E1),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ================= 5. خط التحميل السفلي فائق النحافة والأناقة =================
            Positioned(
              bottom: 24,
              left: 48,
              right: 48,
              child: AnimatedBuilder(
                animation: _subtextController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _subtextFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 2.2,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.08),
                            child: const LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(_gold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'جاري تجهيز عالمك التعليمي...',
                          style: GoogleFonts.tajawal(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// موجه الشاشات للمستخدم المسجل الدخول
class _RedirectDispatcher extends StatelessWidget {
  final UserModel user;
  const _RedirectDispatcher({required this.user});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = user.role == UserRole.admin ? AppRoutes.adminDashboard : AppRoutes.studentHome;
      Navigator.of(context).pushReplacementNamed(route);
    });
    return const Scaffold(
      backgroundColor: Color(0xFF070B14),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFACC15), strokeWidth: 2.5),
      ),
    );
  }
}
