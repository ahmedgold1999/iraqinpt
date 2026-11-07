import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, FlutterError, PlatformDispatcher;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'services/config_service.dart';
import 'services/notification_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/dynamic_app_icon_service.dart';
import 'services/sound_effects_service.dart';
import 'utils/web_helper.dart';
import 'screens/common/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 4));

    // ✅ تهيئة مراقبة الأعطال (Firebase Crashlytics) بدون أي استهلاك للفايربيس
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // ✅ تهيئة الخدمات بالتوازي وسلاسة مع حماية ضد التعليق
    await Future.wait([
      NotificationService.initialize().catchError((_) => null),
      DailyReminderService.initialize().catchError((_) => null),
      ConfigService().initialize().timeout(const Duration(seconds: 6)).catchError((_) => null),
      SoundEffectsService().init().catchError((_) => null),
    ]);
    
    NotificationService.setupListeners();
    NotificationService.enableNotifications();

    // 🎨 المزامنة اللحظية لأيقونة التطبيق مع فايربيس (تتغير الأيقونة تلقائياً دون تحديث)
    DynamicAppIconService().initializeSync();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'الاختبار الوطني الموحد',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.luxuryTheme,
          darkTheme: AppTheme.luxuryDarkTheme,
          themeMode: settings.themeMode,
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
          home: const AppIntroSplashScreen(),
        );
      },
    );
  }
}
