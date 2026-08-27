import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../common/maintenance_screen.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/app_update_service.dart';
import '../../models/app_models.dart';

// ✅ ألوان زاهية وفاخرة بنمط تطبيقات الآيفون (iOS Vibrant Luxury Colors)
const Color _kIosBg = Color(0xFFF8FAFC); // خلفية أبل الناصعة الهادئة
const Color _kIosCardBg = Colors.white;
const Color _kIosTextDark = Color(0xFF0F172A); // أسود كحلي أبل الصافي
const Color _kIosTextMuted = Color(0xFF64748B); // رمادي ناعم
const Color _kIosPrimary = Color(0xFF2563EB); // أزرق ملكي زاهي للزر والهايلايت
const Color _kIosIndigo = Color(0xFF4F46E5); // إنديجو مكمل
const Color _kIosAccent = Color(0xFF00C853); // أخضر زمردي
const Color _kIosGold = Color(0xFFF59E0B); // ذهبي زاهي
const Color _kIosBorder = Color(0xFFE2E8F0);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  final AuthService _auth = AuthService();

  // متغيرات الأخطاء لكل حقل
  String? _usernameError;
  String? _passwordError;
  String? _nameError;
  String? _termsError;

  bool _checkingUpdate = true;
  bool _updateChecked = false;

  late AnimationController _pulseController;
  late AnimationController _cardController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardSlideAnimation;

  final String _disclaimerText = '''
هذا دليل الامتحان الوطني هو تطبيق تعليمي يهدف إلى مساعدة الطلاب على اداء امتحان الوطني بشكل تعليمي وبهدف التجربة.
يوفّر التطبيق بيئة سهلة الاستخدام لإجراء الاختبارات، متابعة النتائج، ومعرفة مستوى التقدم، مع نظام اشتراكات يتيح الوصول إلى محتوى تعليمي متجدد.
صُمم التطبيق لدعم العملية التعليمية وتوفير تجربة اختبار واضحة وموثوقة للطلاب.

إخلاء مسؤولية:
هذا التطبيق غير تابع لأي جهة حكومية ولا يمثل وزارة التعليم العالي والبحث العلمي أو أي مؤسسة رسمية أخرى.
يهدف التطبيق لأغراض تعليمية وتدريبية فقط، ويتم الاعتماد في المعلومات المعروضة على مصادر حكومية رسمية متاحة للعامة.
''';

  final String _privacyPolicyText = '''
**سياسة الخصوصية لتطبيق دليل الامتحان الوطني الموحد**

نحن نحترم خصوصية مستخدمي تطبيق الاختبار الوطني العراقي الموحد ونلتزم بحماية بياناتهم. توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات عند استخدام التطبيق.

**1. المعلومات التي نقوم بجمعها**
*   معلومات الحساب (مثل اسم المستخدم أو البريد الإلكتروني إن وُجد)
*   نتائج الاختبارات والتقدم الدراسي
*   بيانات الاشتراك أو أكواد التفعيل
*   بيانات تقنية غير شخصية (نوع الجهاز، نظام التشغيل)

**2. كيفية استخدام المعلومات**
تُستخدم البيانات من أجل:
*   تشغيل التطبيق وتقديم الخدمات التعليمية
*   إدارة الحسابات والاشتراكات
*   حفظ نتائج الاختبارات
*   تحسين أداء التطبيق وتجربة المستخدم
*   حماية النظام من إساءة الاستخدام

**3. مشاركة المعلومات**
*   لا يقوم التطبيق ببيع أو مشاركة بيانات المستخدمين مع أي جهة خارجية.
*   تُستخدم خدمات Firebase فقط لأغراض التوثيق والتخزين الآمن للبيانات.

**4. حماية البيانات**
نلتزم باتخاذ الإجراءات التقنية المناسبة لحماية بيانات المستخدم ومنع الوصول غير المصرح به أو التلاعب بها.

**5. حذف البيانات**
يمكن للمستخدم طلب حذف بياناته بشكل كامل عبر التواصل معنا من خلال البريد الإلكتروني:
ahmeedgold1000@gmail.com

**6. خصوصية الأطفال**
التطبيق تعليمي، ولا يجمع بيانات حساسة من الأطفال، ويقع استخدامه تحت مسؤولية المستخدم أو ولي الأمر.

**7. التعديلات على سياسة الخصوصية**
قد يتم تحديث سياسة الخصوصية عند الحاجة، وسيتم نشر أي تعديل داخل التطبيق.
''';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _cardSlideAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cardController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidFullName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) return false;
    for (var part in parts) {
      if (part.isEmpty) return false;
      if (!RegExp(r'^[\u0600-\u06FF]+$').hasMatch(part)) {
        return false;
      }
    }
    return true;
  }

  bool _isValidUsername(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains(' ')) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed);
  }

  bool _isValidPassword(String password) {
    return password.trim().length >= 6;
  }

  void _validateUsername(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _usernameError = 'يرجى إدخال اسم المستخدم';
      } else if (!_isValidUsername(value)) {
        _usernameError = 'أحرف إنجليزية وأرقام بدون مسافات';
      } else {
        _usernameError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _passwordError = 'يرجى إدخال كلمة المرور';
      } else if (!_isValidPassword(value)) {
        _passwordError = '6 أحرف على الأقل';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateName(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _nameError = 'يرجى إدخال الاسم الكامل';
      } else if (!_isValidFullName(value)) {
        _nameError = 'اسم ثنائي بالعربية على الأقل (مثال: أحمد سلام)';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateTerms(bool value) {
    setState(() {
      if (!value) {
        _termsError = 'يجب الموافقة على شروط الاستخدام وسياسة الخصوصية';
      } else {
        _termsError = null;
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      await AppUpdateService.checkAppUpdate(context);
    } catch (e) {
      debugPrint('Error checking update: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
          _updateChecked = true;
        });
      }
    }
  }

  bool _isVersionLower(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < math.min(currentParts.length, latestParts.length); i++) {
        if (currentParts[i] < latestParts[i]) return true;
        if (currentParts[i] > latestParts[i]) return false;
      }

      return currentParts.length < latestParts.length;
    } catch (e) {
      return false;
    }
  }

  void _showUpdateDialog(String url, bool forceUpdate) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showGeneralDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _kIosAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.system_update_rounded, color: _kIosAccent, size: 36),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isArabic ? "تحديث جديد متوفر" : "New Update Available",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _kIosTextDark,
                            fontFamily: 'Tajawal',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isArabic
                              ? "يوجد إصدار أحدث يحتوي على تحسينات مهمة وأداء أفضل.\nيرجى تحديث التطبيق للاستمرار."
                              : "A newer version is available with important improvements.\nPlease update the app to continue.",
                          style: const TextStyle(
                            fontSize: 15,
                            color: _kIosTextMuted,
                            height: 1.5,
                            fontFamily: 'Tajawal',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kIosPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              isArabic ? "تحديث الآن" : "Update Now",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal'),
                            ),
                          ),
                        ),
                        if (!forceUpdate) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isArabic ? "لاحقاً" : "Later",
                              style: const TextStyle(color: _kIosTextMuted, fontSize: 14, fontFamily: 'Tajawal'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDisclaimerDialog() {
    _showTextDialog(
      title: 'إخلاء مسؤولية',
      content: _disclaimerText,
      accentColor: _kIosPrimary,
      icon: Icons.info_outline_rounded,
    );
  }

  bool _validateForm() {
    bool isValid = true;

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = 'يرجى إدخال اسم المستخدم');
      isValid = false;
    } else if (!_isValidUsername(username)) {
      setState(() => _usernameError = 'اسم المستخدم يجب أن يحتوي على أحرف إنجليزية وأرقام فقط');
      isValid = false;
    } else {
      setState(() => _usernameError = null);
    }

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _passwordError = 'يرجى إدخال كلمة المرور');
      isValid = false;
    } else if (!_isValidPassword(password)) {
      setState(() => _passwordError = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      isValid = false;
    } else {
      setState(() => _passwordError = null);
    }

    if (!_isLogin) {
      final fullName = _nameController.text.trim();
      if (fullName.isEmpty) {
        setState(() => _nameError = 'يرجى إدخال الاسم الكامل');
        isValid = false;
      } else if (!_isValidFullName(fullName)) {
        setState(() => _nameError = 'اسم ثنائي بالعربية على الأقل (مثال: أحمد سلام)');
        isValid = false;
      } else {
        setState(() => _nameError = null);
      }

      if (!_agreeTerms) {
        setState(() => _termsError = 'يجب الموافقة على شروط الاستخدام وسياسة الخصوصية');
        isValid = false;
      } else {
        setState(() => _termsError = null);
      }
    }

    return isValid;
  }

  void _submit() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (!_validateForm()) {
        setState(() => _isLoading = false);
        return;
      }

      if (!_isLogin) {
        final uniqueness = await _auth.checkUserUniqueness(
          _usernameController.text.trim(),
          _nameController.text.trim(),
        );

        bool isUnique = true;
        if (uniqueness['usernameExists'] == true) {
          setState(() => _usernameError = 'اسم المستخدم موجود مسبقاً');
          isUnique = false;
        }
        if (uniqueness['fullNameExists'] == true) {
          setState(() => _nameError = 'الاسم الكامل موجود مسبقاً');
          isUnique = false;
        }

        if (!isUnique) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_isLogin) {
        final userModel = await _auth.signIn(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (userModel != null) {
          await NotificationService.enableNotifications();
          _navigateBasedOnRole(userModel.role);
        } else {
          _showError('اسم المستخدم أو كلمة المرور غير صحيحة');
          setState(() => _isLoading = false);
        }
      } else {
        final userModel = await _auth.signUp(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );

        if (userModel != null) {
          await NotificationService.enableNotifications();
          _navigateBasedOnRole(userModel.role);
        } else {
          _showError('فشل إنشاء الحساب');
          setState(() => _isLoading = false);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e));
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('حدث خطأ: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userModel = await _auth.signInWithGoogle();
      if (userModel != null) {
        await NotificationService.enableNotifications();
        if (mounted) {
          _navigateBasedOnRole(userModel.role);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showError(_getFirebaseErrorMessage(e));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (!errStr.contains('canceled') && !errStr.contains('cancelled') && !errStr.contains('sign_in_canceled')) {
          _showError('فشل تسجيل الدخول عبر جوجل: ${e.toString()}');
        }
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isAppleUI() {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _signInWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userModel = await _auth.signInWithApple();
      if (userModel != null) {
        await NotificationService.enableNotifications();
        _navigateBasedOnRole(userModel.role);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('فشل تسجيل الدخول عبر آبل: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
        break;
      case UserRole.student:
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
        break;
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'اسم المستخدم مستخدم مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'الحساب معطل';
      case 'operation-not-allowed':
        return 'العملية غير مسموحة';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'خطأ في المصادقة: ${e.message}';
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
    );
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _nameController.clear();
    _agreeTerms = false;
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _nameError = null;
      _termsError = null;
    });
  }

  Future<void> _showTextDialog({
    required String title,
    required String content,
    required Color accentColor,
    required IconData icon,
  }) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(icon, color: accentColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: _kIosTextDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _kIosBorder, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      content,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: _kIosTextDark,
                        fontSize: 14.5,
                        height: 1.7,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kIosPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'إغلاق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
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
    );
  }

  void _showPrivacyPolicyDialog() {
    _showTextDialog(
      title: 'سياسة الخصـوصية',
      content: _privacyPolicyText,
      accentColor: _kIosAccent,
      icon: Icons.policy_rounded,
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    String? errorText,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: _kIosTextDark, fontSize: 15, fontFamily: 'Tajawal'),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            labelStyle: const TextStyle(color: _kIosTextMuted, fontSize: 14, fontFamily: 'Tajawal'),
            hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 13, fontFamily: 'Tajawal'),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEF4444),
              fontFamily: 'Tajawal',
            ),
            prefixIcon: Icon(icon, color: _kIosPrimary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _kIosPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kIosPrimary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeTerms = !_agreeTerms;
                    _validateTerms(_agreeTerms);
                  });
                },
                child: RichText(
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: const TextStyle(
                      color: _kIosTextDark,
                      fontSize: 13.5,
                      height: 1.4,
                      fontFamily: 'Tajawal',
                    ),
                    children: [
                      const TextSpan(text: 'أوافق على '),
                      TextSpan(
                        text: 'شروط الاستخدام',
                        style: const TextStyle(
                          color: _kIosPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _showDisclaimerDialog();
                          },
                      ),
                      const TextSpan(text: ' و '),
                      TextSpan(
                        text: 'سياسة الخصوصية',
                        style: const TextStyle(
                          color: _kIosPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _showPrivacyPolicyDialog();
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Checkbox(
              value: _agreeTerms,
              onChanged: (value) {
                setState(() {
                  _agreeTerms = value!;
                  _validateTerms(_agreeTerms);
                });
              },
              activeColor: _kIosPrimary,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: _kIosTextMuted, width: 1.2),
            ),
          ],
        ),
        if (_termsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              _termsError!,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontFamily: 'Tajawal',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLuxuryButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [_kIosPrimary, _kIosIndigo],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
        color: _isLoading ? Colors.grey.shade400 : null,
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: _kIosPrimary.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isLoading || _checkingUpdate) ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isLoading || _checkingUpdate) ? null : _signInWithApple,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.apple, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'الدخول عبر آبل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: _kIosBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_isLoading || _checkingUpdate) ? null : _signInWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437), size: 18),
              const SizedBox(width: 10),
              Text(
                _isLogin ? 'الدخول عبر جوجل' : 'إنشاء حساب عبر جوجل',
                style: const TextStyle(
                  color: _kIosTextDark,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ شريط تحكم متناسق ينتمي إلى نمط أبل (iOS Segmented Control)
  Widget _buildTopSwitchButtons() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: _isLogin ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isLogin) {
                      _resetForm();
                      setState(() {
                        _isLogin = true;
                        _cardController.reset();
                        _cardController.forward();
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: _isLogin ? _kIosTextDark : _kIosTextMuted,
                          fontSize: 14,
                          fontWeight: _isLogin ? FontWeight.bold : FontWeight.w500,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isLogin) {
                      _resetForm();
                      setState(() {
                        _isLogin = false;
                        _cardController.reset();
                        _cardController.forward();
                      });
                    }
                  },
                  child: Container(
                    height: 40,
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          color: !_isLogin ? _kIosTextDark : _kIosTextMuted,
                          fontSize: 14,
                          fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w500,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kIosBg, // خلفية بيضاء هادئة
      body: SafeArea(
        child: Stack(
          children: [
            if (_checkingUpdate)
              Container(
                color: Colors.white.withOpacity(0.9),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: _kIosPrimary,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'جاري التحقق من التحديثات...',
                          style: TextStyle(
                            color: _kIosTextDark,
                            fontSize: 15,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_checkingUpdate)
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header: شعار وعنوان التطبيق بنمط آيفون هادئ
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [_kIosPrimary, _kIosIndigo, _kIosGold, _kIosAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kIosPrimary.withOpacity(0.25),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    size: 46,
                                    color: _kIosPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            const Text(
                              'دليل الامتحان الوطني العراقي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _kIosTextDark,
                                fontFamily: 'Tajawal',
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isLogin
                                  ? 'أهلاً بك، سجل الدخول للاستمرار في التعلم'
                                  : 'أنشئ حسابك وابدأ رحلتك التعليمية',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _kIosTextMuted,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Card Content with Smooth iOS Slide & Fade Animation
                      AnimatedBuilder(
                        animation: _cardSlideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 40 * _cardSlideAnimation.value),
                            child: Opacity(
                              opacity: (1 - _cardSlideAnimation.value).clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: _kIosCardBg,
                            border: Border.all(color: _kIosBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                _buildTopSwitchButtons(),
                                if (!_isLogin) ...[
                                  _buildModernTextField(
                                    controller: _nameController,
                                    label: 'الاسم الكامل',
                                    icon: Icons.person_outline_rounded,
                                    hint: 'أدخل اسمك الكامل بالعربية',
                                    errorText: _nameError,
                                    onChanged: _validateName,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildModernTextField(
                                  controller: _usernameController,
                                  label: 'اسم المستخدم',
                                  icon: Icons.alternate_email_rounded,
                                  hint: 'ادخل اسم المستخدم',
                                  errorText: _usernameError,
                                  onChanged: _validateUsername,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  icon: Icons.lock_outline_rounded,
                                  hint: '6 أحرف على الأقل',
                                  isPassword: true,
                                  errorText: _passwordError,
                                  onChanged: _validatePassword,
                                ),
                                if (!_isLogin) ...[
                                  const SizedBox(height: 20),
                                  _buildTermsCheckbox(),
                                ],
                                const SizedBox(height: 24),
                                _buildLuxuryButton(),
                                const SizedBox(height: 14),
                                _buildGoogleButton(),
                                if (_isAppleUI()) ...[
                                  const SizedBox(height: 12),
                                  _buildAppleButton(),
                                ],
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _showDisclaimerDialog,
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: _kIosTextMuted,
                                    ),
                                    label: const Text(
                                      'إخلاء مسؤولية',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Tajawal',
                                        color: _kIosTextDark,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _kIosTextDark,
                                      side: const BorderSide(
                                        color: _kIosBorder,
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}