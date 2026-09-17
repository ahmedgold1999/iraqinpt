import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'subscription_screen.dart';
import 'about_national_exam_screen.dart';
import 'exams_schedule_screen.dart';
import 'study_materials_screen.dart';
import 'profile_screen.dart';
import '../admin/admin_dashboard.dart';
import '../../widgets/luxury_loading.dart';
import '../../widgets/luxury_bottom_nav.dart';
import '../../models/app_models.dart';
import '../../services/subscription_service.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';
import '../../services/app_update_service.dart';
import '../../services/daily_reminder_service.dart';

class StudentMainShell extends StatefulWidget {
  const StudentMainShell({super.key});

  @override
  State<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends State<StudentMainShell> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkUpdateOnStartup(context);
      DailyReminderService.checkAndDispatchTodayNotification();
    });
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    
    // ✅ فحص انتهاء الاشتراك التلقائي (مرة واحدة عند فتح التطبيق لتوفير الموارد)
    if (user != null && user.isPremium && user.expiryDate != null) {
      if (user.expiryDate!.isBefore(DateTime.now())) {
        await SubscriptionService().deactivateSubscription(user.uid);
      }
    }

    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  List<Widget> _getScreens() {
    final isIosReview = defaultTargetPlatform == TargetPlatform.iOS && ConfigService().isIosReviewMode;
    return [
      const StudentHomeScreen(),
      isIosReview ? const AboutNationalExamScreen() : const SubscriptionScreen(),
      const ExamsScheduleScreen(),
      const StudyMaterialsScreen(),
      _user?.role == UserRole.admin ? AdminDashboard() : ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LuxuryLoading(message: 'جاري جلب بياناتك الفخمة...');
    }

    final screens = _getScreens();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: LuxuryBottomNav(
        currentIndex: _currentIndex,
        isAdmin: _user?.role == UserRole.admin,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
