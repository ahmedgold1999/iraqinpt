import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'services/config_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/device_service.dart';
import 'utils/web_helper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/common/vpn_block_screen.dart';
import 'screens/common/maintenance_screen.dart';
import 'screens/common/device_limit_screen.dart';
import 'models/app_models.dart';
import 'widgets/luxury_loading.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService.initialize();
    await ConfigService().initialize();
    NotificationService.setupListeners();

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      // ✅ استدعاء وظيفة إزالة اللودر بشكل آمن
      removeWebLoader();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('❌ Initialization error: $e');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
                child: child!,
              ),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ar', 'AE')],
              locale: const Locale('ar', 'AE'),
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      Text('خطأ في التهيئة: $e'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => main(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;
  bool _isVpnActive = false;
  bool _isDeviceLimitReached = false;
  UserModel? _currentUser;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
    _checkVpnStatus();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkVpnStatus() async {
    bool vpnEnabled = false;
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.vpn)) {
        vpnEnabled = true;
      }

      if (!vpnEnabled && !kIsWeb) {
        List<NetworkInterface> interfaces = await NetworkInterface.list(
            includeLoopback: false, type: InternetAddressType.any);
        for (var interface in interfaces) {
          String name = interface.name.toLowerCase();
          if (name.contains("tun") || name.contains("ppp") || name.contains("pptp") || name.contains("ipsec")) {
            vpnEnabled = true;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('VPN Check error: $e');
    }

    if (mounted) {
      setState(() => _isVpnActive = vpnEnabled);
    }
  }

  Future<void> _initializeApp() async {
    try {
      await NotificationService.enableNotifications();
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        if (_currentUser != null) {
          final allowed = await DeviceService.checkDeviceLimit();
          if (!allowed) {
            setState(() => _isDeviceLimitReached = true);
          }
        }
      }
    } catch (e) {
      print('App Init Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        // ✅ 1. شاشة التحميل الأولية (أثناء تهيئة التطبيق)
        if (!_isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar', 'AE')],
            locale: const Locale('ar', 'AE'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
              child: child!,
            ),
            home: _buildLuxuryLoadingScreen(),
          );
        }

        // ✅ 2. التطبيق الرئيسي (مع دعم RTL الشامل)
        return MaterialApp(
          title: 'الاختبار الوطني الموحد',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.luxuryTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'AE')],
          locale: const Locale('ar', 'AE'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
            child: child!,
          ),
          onGenerateRoute: AppRoutes.generateRoute,
          home: _buildHomeLogic(),
        );
      },
    );
  }

  // ✅ منطق اختيار الشاشة المناسبة (VPN, صيانة، أو الواجهة الرئيسية)
  Widget _buildHomeLogic() {
    if (_isVpnActive) {
      return VpnBlockScreen(onRefresh: _checkVpnStatus);
    }

    if (_isDeviceLimitReached) {
      return const DeviceLimitScreen();
    }

    // استخدام ConfigService من GitHub بدلاً من StreamBuilder لتوفير قراءات Firestore
    final bool isMaintenance = ConfigService().isMaintenanceOn;

    // إذا كانت الصيانة مفعلة والمستخدم ليس إدمن
    if (isMaintenance && (_currentUser == null || _currentUser!.role != UserRole.admin)) {
      return const MaintenanceScreen();
    }

    // الدخول الطبيعي للتطبيق
    return _currentUser != null 
        ? RedirectScreen(user: _currentUser!) 
        : const LoginScreen();
  }

  Widget _buildLuxuryLoadingScreen() {
    return const LuxuryLoading(
      message: 'جاري تهيئة عالمك التعليمي...',
    );
  }
}

class RedirectScreen extends StatelessWidget {
  final UserModel user;
  const RedirectScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = user.role == UserRole.admin ? AppRoutes.adminDashboard : AppRoutes.studentHome;
      Navigator.of(context).pushReplacementNamed(route);
    });
    return const Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 3)),
    );
  }
}
