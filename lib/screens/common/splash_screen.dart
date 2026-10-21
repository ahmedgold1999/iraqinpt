import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// =========================================================================
/// شاشة البداية الاحترافية الفاخرة (Cinematic Luxury Splash Screen)
/// تصميم فخم بالكامل مع أيقونة ثلاثية الأبعاد بمسحة ضوئية Shimmer وطوفان انسيابي
/// =========================================================================
class AppIntroSplashScreen extends StatefulWidget {
  const AppIntroSplashScreen({super.key});

  @override
  State<AppIntroSplashScreen> createState() => _AppIntroSplashScreenState();
}

class _AppIntroSplashScreenState extends State<AppIntroSplashScreen>
    with TickerProviderStateMixin {
  // ألوان المنصة الملكية
  static const Color _bgDeep = Color(0xFF070B14);
  static const Color _goldPrimary = Color(0xFFFACC15);
  static const Color _goldAccent = Color(0xFFF59E0B);
  static const Color _goldLight = Color(0xFFFEF08A);

  // 1. متحكم الدخول ثلاثي الأبعاد للأيقونة
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _tiltAnimation;

  // 2. متحكم مسحة الضوء المتلألئة (Light Sheen / Shimmer Sweep)
  late AnimationController _shimmerController;
  late Animation<double> _shimmerSweep;

  // 3. متحكم الطفو الانسيابي (Anti-Gravity Floating Hover)
  late AnimationController _floatingController;
  late Animation<double> _floatingOffset;

  // 4. متحكم الهالة الضوئية النابضة خلف الأيقونة
  late AnimationController _auraController;
  late Animation<double> _auraPulse;

  // 5. متحكم ظهور علامة الاستفهام الارتدادي
  late AnimationController _questionMarkController;
  late Animation<double> _questionScale;
  late Animation<double> _questionRotate;

  // 6. متحكم موجة الانفجار الضوئي لعلامة الاستفهام
  late AnimationController _shockwaveController;
  late Animation<double> _shockwaveRadius;
  late Animation<double> _shockwaveOpacity;

  // 7. حركة ظهور النص التكميلي السفلي
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;

  // نصوص الآلة الكاتبة الذكية
  static const String _targetSentence = 'ليش تحير بالامتحان الوطني وتطبيقنه موجود';
  String _currentText = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;

  bool _isTypingComplete = false;
  bool _showQuestionMark = false;
  bool _cursorBlink = true;
  Timer? _cursorTimer;

  // جزيئات الغبار الذهبي العائم بالخلفية
  final List<_GoldParticle> _particles = List.generate(
    28,
    (index) => _GoldParticle(
      x: math.Random().nextDouble(),
      y: math.Random().nextDouble(),
      radius: 0.8 + math.Random().nextDouble() * 1.8,
      speed: 0.15 + math.Random().nextDouble() * 0.35,
      opacity: 0.15 + math.Random().nextDouble() * 0.45,
    ),
  );

  // منطق التهيئة وتحديد الشاشة التالية
  Widget? _destinationScreen;
  bool _isInitReady = false;
  bool _isAnimationComplete = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initChoreographedAnimations();
    _startPresentationScript();
    _runAsyncAppWarmup();
  }

  void _initChoreographedAnimations() {
    // 1. حركة دخول الأيقونة بزاوية ثلاثية الأبعاد وارتداد سلس
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    _tiltAnimation = Tween<double>(begin: 0.18, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // 2. مسحة البريق الضوئي عبر الأيقونة (Shimmer Sweep)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shimmerSweep = Tween<double>(begin: -1.2, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // 3. الطفو الانسيابي في الهواء
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatingOffset = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // 4. الهالة الذهبية المتنفسة
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _auraPulse = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    // 5. ظهور علامة الاستفهام بفرقعة وتأرجح ارتدادي
    _questionMarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _questionScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionMarkController, curve: Curves.elasticOut),
    );
    _questionRotate = Tween<double>(begin: -0.25, end: 0.0).animate(
      CurvedAnimation(parent: _questionMarkController, curve: Curves.easeOutBack),
    );

    // 6. حلقة الصدمة الضوئية المتوسعة
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _shockwaveRadius = Tween<double>(begin: 10.0, end: 85.0).animate(
      CurvedAnimation(parent: _shockwaveController, curve: Curves.easeOutCubic),
    );
    _shockwaveOpacity = Tween<double>(begin: 0.9, end: 0.0).animate(
      CurvedAnimation(parent: _shockwaveController, curve: Curves.easeOutQuad),
    );

    // 7. ظهور النص الترحيبي الفرعي
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // وميض مؤشر الكتابة
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 360), (timer) {
      if (mounted && !_isTypingComplete) {
        setState(() => _cursorBlink = !_cursorBlink);
      }
    });
  }

  void _startPresentationScript() async {
    // 1. انطلاق دخول الأيقونة
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();

    // 2. إطلاق مسحة الضوء المتلألئة (Shimmer) فوق الأيقونة فور استقرارها
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _shimmerController.forward(from: 0.0);

    // 3. بدء كتابة الجملة حرفاً حرفاً بإيقاع رشيق وسريع (32ms لكل حرف)
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex < _targetSentence.length) {
        setState(() {
          _currentText += _targetSentence[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTypingComplete = true;
          _cursorBlink = false;
        });
        _fireQuestionMarkClimax();
      }
    });
  }

  /// لحظة الذروة السينمائية: انبثاق علامة الاستفهام مع صوت الطقة والموجة الضوئية
  Future<void> _fireQuestionMarkClimax() async {
    // وقفة تشويقية محسوبة (90ms)
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;

    setState(() {
      _showQuestionMark = true;
    });

    // تشغيل صوت الطقة الحاسم مع الاهتزاز الفيزيائي
    SoundEffectsService.playClickSound();
    HapticFeedback.heavyImpact();

    _shockwaveController.forward(from: 0.0);
    _questionMarkController.forward(from: 0.0);

    // إظهار النص الترحيبي الفرعي الأنيق
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    _taglineController.forward();

    // إتاحة فرصة مريحة للعين لمشاهدة اكتمال الشاشة قبل الانتقال
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _isAnimationComplete = true;
    _proceedIfReady();
  }

  /// التهيئة الشاملة للتطبيق بالخلفية
  Future<void> _runAsyncAppWarmup() async {
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

      final bool isMaintenance = ConfigService().isMaintenanceOn;

      bool hasSeenOnboarding = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      } catch (_) {}

      if (isDeviceLimitReached) {
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
      debugPrint('App Warmup Error: $e');
      _destinationScreen = const LoginScreen();
    } finally {
      _isInitReady = true;
      _proceedIfReady();
    }
  }

  void _proceedIfReady() {
    if (!mounted || _hasNavigated) return;
    if (_isInitReady && _isAnimationComplete) {
      _hasNavigated = true;
      _navigateSmoothly();
    }
  }

  /// التخطي الفوري عند لمس الشاشة
  void _skipOnUserTap() {
    if (_hasNavigated) return;

    if (!_isTypingComplete) {
      _typewriterTimer?.cancel();
      setState(() {
        _currentText = _targetSentence;
        _isTypingComplete = true;
        _showQuestionMark = true;
        _cursorBlink = false;
      });
      _questionMarkController.value = 1.0;
      _taglineController.value = 1.0;
      _shimmerController.value = 1.0;
      SoundEffectsService.playClickSound();
      HapticFeedback.selectionClick();
    }

    _isAnimationComplete = true;
    if (_isInitReady) {
      _hasNavigated = true;
      _navigateSmoothly();
    }
  }

  void _navigateSmoothly() {
    final next = _destinationScreen ?? const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
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
    _entranceController.dispose();
    _shimmerController.dispose();
    _floatingController.dispose();
    _auraController.dispose();
    _questionMarkController.dispose();
    _shockwaveController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgDeep,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipOnUserTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ================= 1. الخلفية الملكية العميقة =================
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.25,
                  colors: [
                    Color(0xFF111C36),
                    Color(0xFF090F1F),
                    _bgDeep,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ================= 2. جزيئات الغبار الذهبي الناعمة بالخلفية =================
            AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlesPainter(
                    particles: _particles,
                    progress: _floatingController.value,
                  ),
                );
              },
            ),

            // ================= 3. الهالة الضوئية الذهبية النابضة خلف الدرع =================
            Center(
              child: Transform.translate(
                offset: const Offset(0, -50),
                child: AnimatedBuilder(
                  animation: _auraController,
                  builder: (context, child) {
                    final pulse = _auraPulse.value;
                    return Container(
                      width: 250 * pulse,
                      height: 250 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _goldPrimary.withValues(alpha: 0.18 * (2.0 - pulse)),
                            _goldAccent.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ================= 4. موجة الانفجار الضوئي عند علامة الاستفهام =================
            if (_showQuestionMark)
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 52),
                  child: AnimatedBuilder(
                    animation: _shockwaveController,
                    builder: (context, child) {
                      if (_shockwaveOpacity.value <= 0.01) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        width: _shockwaveRadius.value * 2,
                        height: _shockwaveRadius.value * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _goldLight.withValues(alpha: _shockwaveOpacity.value),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _goldPrimary.withValues(alpha: _shockwaveOpacity.value * 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ================= 5. المحتوى المركزي (الأيقونة الفخمة والنص) =================
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
                        // --- مجمع الأيقونة الفاخر: درع زجاجي احترافي ثلاثي الأبعاد + مسحة ضوء Shimmer + طفو انسيابي ---
                        AnimatedBuilder(
                          animation: _floatingController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatingOffset.value),
                              child: child,
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              final transform = Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // منظور عمق ثلاثي الأبعاد
                                ..rotateX(_tiltAnimation.value);

                              return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Transform(
                                  transform: transform,
                                  alignment: Alignment.center,
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: _buildLuxuryIconPlaque(),
                          ),
                        ),

                        const SizedBox(height: 38),

                        // --- السطر التعبيري الرئيسي: طباعة رشيقة حرفاً حرفاً + علامة الاستفهام المنبثقة ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // نص العبارة الأساسي بتدرج أبيض ناصع
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Color(0xFFF8FAFC),
                                        Color(0xFFE2E8F0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    _currentText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      height: 1.45,
                                      letterSpacing: 0.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                // مؤشر الكتابة الذهبي النابض
                                if (!_isTypingComplete && _cursorBlink)
                                  Container(
                                    margin: const EdgeInsets.only(right: 3, top: 4),
                                    width: 2.5,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _goldPrimary,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _goldPrimary.withValues(alpha: 0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),

                                // علامة الاستفهام الفاخرة المنبثقة بحركة ارتدادية ممتعة
                                if (_showQuestionMark)
                                  ScaleTransition(
                                    scale: _questionScale,
                                    alignment: Alignment.centerRight,
                                    child: RotationTransition(
                                      turns: _questionRotate,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6, bottom: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              _goldPrimary,
                                              _goldAccent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _goldPrimary.withValues(alpha: 0.65),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '؟! ⚡',
                                          style: GoogleFonts.cairo(
                                            fontSize: 17.5,
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

                        const SizedBox(height: 22),

                        // --- النص الترحيبي الفرعي مع نجمة الإنجاز ---
                        FadeTransition(
                          opacity: _taglineFade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _goldPrimary.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: _goldPrimary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'دليلك الرسمي المعتمد للتفوق والنجاح • 2026',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                    letterSpacing: 0.3,
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

            // ================= 6. خط التحميل فائق النحافة والأناقة بالأسفل =================
            Positioned(
              bottom: 24,
              left: 54,
              right: 54,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 2.2,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.07),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(_goldPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'جاري تشغيل عالمك التعليمي...',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white38,
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

  /// بناء درع الأيقونة الزجاجي الفاخر (Squircle Plaque) مع تأثير مسحة الضوء
  Widget _buildLuxuryIconPlaque() {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withValues(alpha: 0.95),
            const Color(0xFF0F172A).withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _goldPrimary.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          // وهج ذهبي خارجي فخم
          BoxShadow(
            color: _goldPrimary.withValues(alpha: 0.22),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          // ظل عميق يعطي إيحاء بالارتفاع ثلاثي الأبعاد
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // حافة داخلية ساطعة (Inner Bevel)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
              ),
            ),

            // صورة الأيقونة الشفافة الأصلية بحجمها الكامل المتناسق
            Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset(
                'assets/icons/appwithoutbackground.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),

            // شريط مسحة الضوء المتلألئة المائلة (Specular Shimmer Beam)
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shimmerSweep.value * 160, 0),
                  child: Transform.rotate(
                    angle: 0.45,
                    child: Container(
                      width: 45,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.35),
                            _goldLight.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// نموذج لجزيئات الغبار الذهبي
class _GoldParticle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;

  _GoldParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

/// رسام جزيئات الغبار الذهبي في الخلفية
class _ParticlesPainter extends CustomPainter {
  final List<_GoldParticle> particles;
  final double progress;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.y - (progress * p.speed * 0.15)) % 1.0;
      final offset = Offset(p.x * size.width, currentY * size.height);

      paint.color = const Color(0xFFFACC15).withValues(alpha: p.opacity);
      canvas.drawCircle(offset, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
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
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Color(0xFFFACC15), strokeWidth: 2),
        ),
      ),
    );
  }
}
