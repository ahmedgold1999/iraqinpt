import 'dart:async';
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
/// شاشة البداية بأسلوب أبل المينيمال الفاخر (Apple Minimal Luxury Splash)
/// تصميم نقي، هادئ، فخم، بدون أي تعقيد أو إطارات زائدة
/// =========================================================================
class AppIntroSplashScreen extends StatefulWidget {
  const AppIntroSplashScreen({super.key});

  @override
  State<AppIntroSplashScreen> createState() => _AppIntroSplashScreenState();
}

class _AppIntroSplashScreenState extends State<AppIntroSplashScreen>
    with TickerProviderStateMixin {
  // ألوان أبل المينيمال الفاخرة (درجات مات هادئة ونقية)
  static const Color _bgCanvas = Color(0xFF090D16);
  static const Color _gold = Color(0xFFFACC15);
  static const Color _textColor = Color(0xFFF1F5F9);

  // متحكمات حركة الأيقونة
  late AnimationController _iconAnimController;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;

  // متحكم حركة علامة الاستفهام المدمجة بانسيابية
  late AnimationController _questionMarkAnimController;
  late Animation<double> _questionMarkScale;
  late Animation<double> _questionMarkOpacity;

  // نص العبارة المطلوب
  static const String _mainSentence = 'ليش تحير بالامتحان الوطني وتطبيقنه موجود';
  String _typedText = '';
  int _charPointer = 0;
  Timer? _typewriterTimer;

  bool _isTypingDone = false;
  bool _showQuestionMark = false;
  bool _cursorBlink = true;
  Timer? _cursorTimer;

  // منطق التهيئة والانتقال
  Widget? _nextScreen;
  bool _isInitFinished = false;
  bool _isAnimationFinished = false;
  bool _hasTransitioned = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startFlowTimeline();
    _executeAppWarmup();
  }

  void _setupAnimations() {
    // 1. حركة الأيقونة: ظهور هادئ وناعم يشبه شاشات آبل (Fade + subtle micro-zoom)
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _iconAnimController, curve: Curves.easeOutCubic),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconAnimController, curve: Curves.easeOut),
    );

    // 2. حركة علامة الاستفهام: ظهور ارتدادي ممتع ومدمج مع النص بدون أي صناديق أو إطارات
    _questionMarkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _questionMarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionMarkAnimController, curve: Curves.elasticOut),
    );
    _questionMarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionMarkAnimController, curve: Curves.easeIn),
    );

    // وميض المؤشر الرقيق
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted && !_isTypingDone) {
        setState(() => _cursorBlink = !_cursorBlink);
      }
    });
  }

  void _startFlowTimeline() async {
    // ظهور الأيقونة أولاً بنعومة
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _iconAnimController.forward();

    // بدء طباعة النص بحركة سريعة وممتعة (34ms لكل حرف)
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 34), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charPointer < _mainSentence.length) {
        setState(() {
          _typedText += _mainSentence[_charPointer];
          _charPointer++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTypingDone = true;
          _cursorBlink = false;
        });
        _popQuestionMark();
      }
    });
  }

  /// ظهور علامة الاستفهام بنعومة طبيعية كجزء من النص مع صوت الطقة والاهتزاز اللمسي
  Future<void> _popQuestionMark() async {
    // وقفة ذكية قصيرة (100ms) لإعطاء أثر ترقب سينمائي
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    setState(() {
      _showQuestionMark = true;
    });

    // صوت الطقة والاهتزاز الخفيف
    SoundEffectsService.playClickSound();
    HapticFeedback.lightImpact();

    _questionMarkAnimController.forward(from: 0.0);

    // مهلة قصيرة لإتاحة قراءة العبارة كاملة قبل الانتقال
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _isAnimationFinished = true;
    _checkTransitionReady();
  }

  /// فحص الحساب والصيانة بالخلفية أثناء عمل الأنيميشن
  Future<void> _executeAppWarmup() async {
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
        _nextScreen = const DeviceLimitScreen();
      } else if (isMaintenance && (currentUser == null || currentUser.role != UserRole.admin)) {
        _nextScreen = const MaintenanceScreen();
      } else if (currentUser != null) {
        _nextScreen = _RedirectDispatcher(user: currentUser);
      } else if (!hasSeenOnboarding) {
        _nextScreen = const OnboardingScreen();
      } else {
        _nextScreen = const LoginScreen();
      }
    } catch (e) {
      debugPrint('App Warmup Error: $e');
      _nextScreen = const LoginScreen();
    } finally {
      _isInitFinished = true;
      _checkTransitionReady();
    }
  }

  void _checkTransitionReady() {
    if (!mounted || _hasTransitioned) return;
    if (_isInitFinished && _isAnimationFinished) {
      _hasTransitioned = true;
      _performSmoothTransition();
    }
  }

  /// تخطي فوري عند لمس الشاشة
  void _onScreenTapped() {
    if (_hasTransitioned) return;

    if (!_isTypingDone) {
      _typewriterTimer?.cancel();
      setState(() {
        _typedText = _mainSentence;
        _isTypingDone = true;
        _showQuestionMark = true;
        _cursorBlink = false;
      });
      _questionMarkAnimController.value = 1.0;
      SoundEffectsService.playClickSound();
      HapticFeedback.selectionClick();
    }

    _isAnimationFinished = true;
    if (_isInitFinished) {
      _hasTransitioned = true;
      _performSmoothTransition();
    }
  }

  void _performSmoothTransition() {
    final destination = _nextScreen ?? const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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
    _iconAnimController.dispose();
    _questionMarkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onScreenTapped,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ================= 1. أيقونة التطبيق (نقية، راقية، بأسلوب آبل المينيمال) =================
                FadeTransition(
                  opacity: _iconOpacity,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 125,
                      height: 125,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
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
                  ),
                ),

                const SizedBox(height: 28),

                // ================= 2. العبارة النصية المينيمال المنسابة بحرية =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // النص الأساسي المكتوب حرفاً حرفاً
                        Flexible(
                          child: Text(
                            _typedText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textColor,
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),

                        // وميض المؤشر الذهبي الخفيف أثناء الكتابة
                        if (!_isTypingDone && _cursorBlink)
                          Container(
                            margin: const EdgeInsets.only(right: 3, top: 4),
                            width: 2.0,
                            height: 18,
                            color: _gold,
                          ),

                        // علامة الاستفهام الذهبية المندمجة بانسيابية كحرف طبيعي فخم (بدون أي كبسولات أو إطارات)
                        if (_showQuestionMark)
                          FadeTransition(
                            opacity: _questionMarkOpacity,
                            child: ScaleTransition(
                              scale: _questionMarkScale,
                              alignment: Alignment.centerRight,
                              child: Text(
                                ' ؟!',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _gold,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 4),
              ],
            ),
          ),
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
      backgroundColor: Color(0xFF090D16),
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
