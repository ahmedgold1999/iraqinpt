import 'package:flutter/material.dart';
import 'screens/student/student_main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/quiz_screen.dart';
import 'screens/student/profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_home.dart';
import 'screens/student/exams_schedule_screen.dart';
import 'screens/student/study_materials_screen.dart';
// تأكد من أن subscription_screen.dart لا يتم استيراده هنا إذا كان يحتوي على StudyMaterialsScreen
import 'screens/student/subscription_screen.dart';
import 'screens/student/leaderboard_screen.dart';
import 'screens/student/mistakes_screen.dart';
import 'screens/student/speed_quiz_screen.dart';
import 'screens/student/question_search_screen.dart';
import 'screens/student/true_false_quiz_screen.dart';
import 'screens/student/about_national_exam_screen.dart';
import 'screens/student/qualification_score_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String studentHome = '/student-home';
  static const String quiz = '/quiz';
  static const String profile = '/profile';
  static const String adminHome = '/admin-home';
  static const String adminDashboard = '/admin-dashboard';
  static const String examsSchedule = '/exams-schedule';
  static const String studyMaterials = '/study-materials';
  static const String subscription = '/subscription';
  static const String leaderboard = '/leaderboard';
  static const String mistakes = '/mistakes';
  static const String speedQuiz = '/speed-quiz';
  static const String questionSearch = '/question-search';
  static const String trueFalseQuiz = '/true-false-quiz';
  static const String aboutExam = '/about-exam';
  static const String qualificationScore = '/qualification-score';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case studentHome:
        return MaterialPageRoute(builder: (_) => const StudentMainShell());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case leaderboard:
        return MaterialPageRoute(builder: (_) => const LeaderboardScreen());

      case mistakes:
        return MaterialPageRoute(builder: (_) => const MistakesScreen());

      case speedQuiz:
        return MaterialPageRoute(builder: (_) => const SpeedQuizScreen());

      case questionSearch:
        return MaterialPageRoute(builder: (_) => const QuestionSearchScreen());

      case trueFalseQuiz:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialSubject = args?['subject'] as String?;
        return MaterialPageRoute(builder: (_) => TrueFalseQuizScreen(initialSubject: initialSubject));

      case aboutExam:
        return MaterialPageRoute(builder: (_) => const AboutNationalExamScreen());

      case qualificationScore:
        return MaterialPageRoute(builder: (_) => const QualificationScoreScreen());

      case quiz:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text(
                  '⚠️ لا توجد بيانات للاختبار',
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QuizScreen(
            subject: args['subject'] ?? '',
            questionsUrl: args['questionsUrl'] ?? '',
          ),
        );

      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case adminHome:
        return MaterialPageRoute(builder: (_) => const StudentMainShell());

      case examsSchedule:
        return MaterialPageRoute(builder: (_) => const ExamsScheduleScreen());

      case studyMaterials:
        return MaterialPageRoute(builder: (_) => const StudyMaterialsScreen());

      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                '⚠️ لا يوجد مسار معروف لـ "${settings.name}"',
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          ),
        );
    }
  }
}