import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';
import '../../models/app_models.dart';
import '../../utils/avatar_helper.dart';
import '../../widgets/luxury_loading.dart';
import '../../routes.dart';
import '../../services/sound_effects_service.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  static const _gold = Color(0xFFFACC15);
  static const _goldDark = Color(0xFFD97706);
  static const _sapphire = Color(0xFF2563EB);

  // Local state for active gender filter in avatar picker
  String? _currentSelectedGender;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===== نافذة تعديل الاسم الشخصي مع التحقق من عدم التكرار =====
  void _showEditNameDialog(BuildContext context, UserModel user, AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: user.name);
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تعديل الاسم الشخصي',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'سيظهر اسمك في لوحة المتصدرين والشهادات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'الاسم الجديد (الاسم الكامل)',
                    labelStyle: TextStyle(
                      fontFamily: 'Tajawal',
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    hintText: 'مثال: أحمد علي محمد',
                    hintStyle: TextStyle(
                      fontFamily: 'Tajawal',
                      color: isDark ? Colors.white30 : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.8),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newName = nameController.text.trim();
                          if (newName == user.name) {
                            Navigator.pop(modalCtx);
                            return;
                          }
                          setModalState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await authService.updateStudentName(newName);
                            if (ctx.mounted) {
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحديث اسمك بنجاح ✨'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'حفظ الاسم الجديد',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== نافذة تأكيد تسجيل الخروج =====
  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'تسجيل الخروج',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          try {
                            await authService.signOut();
                            await FirebaseAuth.instance.signOut();
                          } catch (e) {
                            // Ignored
                          }
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'تأكيد الخروج',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== نافذة سياسة الخصوصية وشروط الاستخدام (متطلب أبل) =====
  void _showPrivacyPolicyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520, maxWidth: 450),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF3B82F6), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'سياسة الخصوصية والشروط',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    '''سياسة الخصوصية وشروط الاستخدام:

نحن نحترم خصوصية مستخدمي تطبيق دليل الامتحان الوطني الموحد ونلتزم بحماية بياناتهم.

1. جمع واستخدام المعلومات:
تُستخدم البيانات المحفوظة حصراً لتقديم الخدمات التعليمية وإدارة الحسابات ومزامنة نتائج الاختبارات.

2. حماية وسرية البيانات:
لا نقوم بمشاركة أو بيع بيانات المستخدمين لأي جهة خارجية إطلاقاً، وتُحفظ البيانات بأمان عبر خدمات Firebase المشفرة.

3. حذف الحساب والبيانات:
يحق للمستخدم حذف حسابه وبياناته نهائياً في أي وقت مباشرة من شاشة الملف الشخصي عبر خيار (حذف الحساب نهائياً).

4. إخلاء مسؤولية:
هذا التطبيق تعليمي وتدريبي مستقل ولا يمثل أي جهة أو وزارة حكومية رسمية، ويستند في مناهجه وأدلته على المصادر والضوابط الأكاديمية العامة المتاحة للطلبة.''',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.5,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== نافذة إرسال تذكرة الدعم الفني والمساعدة =====
  void _showSupportTicketDialog(BuildContext context, UserModel user) {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'question';
    bool isSubmitting = false;

    final categories = [
      {'id': 'question', 'label': 'سؤال أو استفسار عام ❓'},
      {'id': 'technical_issue', 'label': 'مشكلة تقنية أو خطأ بالتطبيق 🛠️'},
      {'id': 'subscription', 'label': 'استفسار حول الاشتراك والترقية 💳'},
      {'id': 'suggestion', 'label': 'اقتراح لتطوير التطبيق 💡'},
      {'id': 'materials', 'label': 'ملاحظة حول الملازم أو الأسئلة 📄'},
      {'id': 'other', 'label': 'أخرى 💬'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدعم الفني والمساعدة',
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Text(
                              'يسعدنا التواصل معك وحل أي استفسار',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. نوع الاستعلام
                  Text('نوع الاستعلام:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'],
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 2. رقم هاتف الواتساب للتواصل
                  Text('رقم الواتساب للتواصل معك:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '07XXXXXXXXX',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 20),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // 3. نص الرسالة
                  Text('تفاصيل الرسالة أو المشكلة:', style: GoogleFonts.notoKufiArabic(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'اكتب استفسارك أو تفاصيل المشكلة التي تواجهها هنا بدقة...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // 4. أزرار الإلغاء والإرسال
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final phone = phoneController.text.trim();
                                  final msg = messageController.text.trim();

                                  if (phone.isEmpty || msg.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى إدخال رقم الواتساب وتفاصيل الرسالة', style: TextStyle(fontFamily: 'Tajawal')),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSubmitting = true);

                                  try {
                                    final catObj = categories.firstWhere((c) => c['id'] == selectedCategory);
                                    await FirebaseFirestore.instance.collection('support_tickets').add({
                                      'userId': user.uid,
                                      'userName': user.name.isNotEmpty ? user.name : 'طالب',
                                      'userEmail': user.email,
                                      'category': selectedCategory,
                                      'categoryLabel': catObj['label'] ?? 'استفسار',
                                      'whatsapp': phone,
                                      'message': msg,
                                      'status': 'pending', // 'pending', 'resolved'
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                          title: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                                              const SizedBox(width: 8),
                                              Text(
                                                'تم الإرسال بنجاح',
                                                style: GoogleFonts.notoKufiArabic(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                              ),
                                            ],
                                          ),
                                          content: const Text(
                                            'تم استلام رسالتك وتذكرتك بنجاح لدى الإدارة، وسيتواصل معك فريق الدعم الفني عبر الواتساب في أقرب وقت ممكن. شكراً لتواصلك معنا! 🌟',
                                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, height: 1.4),
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('حدث خطأ في الإرسال: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('إرسال الآن 🚀', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: authService.userData,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: LuxuryLoading(message: 'جاري تحميل الملف الشخصي...'),
          );
        }

        final user = snapshot.data!;
        final isPremium = user.isPremium;
        final expiryDate = user.expiryDate;
        final now = DateTime.now();

        int daysRemaining = 0;
        if (expiryDate != null && isPremium) {
          daysRemaining = expiryDate.difference(now).inDays;
          if (daysRemaining < 0) daysRemaining = 0;
        }

        final activeGender = _currentSelectedGender ?? user.gender;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ================= الرأس الفاخر الملكي بنمط آبل =================
                SliverAppBar(
                  expandedHeight: 210,
                  pinned: true,
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),
                            // الأفاتار المخصص المتوهج
                            AvatarHelper.buildAvatarWidget(
                              avatarId: user.avatarId,
                              gender: user.gender,
                              radius: 38,
                              isPremium: isPremium,
                              showCrown: isPremium,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.name.isNotEmpty ? user.name : 'مستخدم التطبيق',
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showEditNameDialog(context, user, authService),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                if (isPremium) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFACC15), Color(0xFFD97706)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'VIP 👑',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ================= قسم تخصيص الأفاتار والجنس =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildAvatarCustomizerSection(user, activeGender, authService, isDark),
                  ),
                ),

                // ================= بطاقة الاشتراك الفاخرة =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _buildSubscriptionCard(user, isDark),
                  ),
                ),

                // ================= بطاقة إحصائيات المواد الذكية =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildSmartStatsSection(user.uid, isDark),
                  ),
                ),

                // ================= بوابة لوحة تحكم المدير (إذا كان مدير) =================
                if (user.role == UserRole.admin)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _gold.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.admin_panel_settings_rounded, color: _gold, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'لوحة تحكم المدير الشاملة 👑',
                                          style: GoogleFonts.notoKufiArabic(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'إدارة الطلاب، الملازم، الأكواد، الإشعارات، والنظام',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 11.5,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ================= قسم الإعدادات والتفضيلات =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'تفضيلات التطبيق والمظهر',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildThemeSwitchTile(isDark),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          _buildFontSizeSelector(isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                // ================= قسم الأدوات والحساب =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'الأدوات وإدارة الحساب',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildActionTile(
                            icon: Icons.edit_note_rounded,
                            color: const Color(0xFF38BDF8),
                            title: 'تعديل الاسم الشخصي',
                            subtitle: 'تغيير اسمك الظاهر في لوحة المتصدرين والشهادات',
                            isDark: isDark,
                            onTap: () => _showEditNameDialog(context, user, authService),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'أصوات وتفاعلات الاختبارات',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'تشغيل نغمات الإجابة الصحيحة والخاطئة',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: !SoundEffectsService().isMuted,
                                  activeTrackColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    SoundEffectsService().setMuted(!val);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          _buildActionTile(
                            icon: Icons.support_agent_rounded,
                            color: const Color(0xFF10B981),
                            title: 'الدعم الفني والمساعدة',
                            subtitle: 'إرسال استفسار أو مشكلة وسيتم الرد عبر الواتساب',
                            isDark: isDark,
                            onTap: () => _showSupportTicketDialog(context, user),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          _buildActionTile(
                            icon: Icons.privacy_tip_rounded,
                            color: const Color(0xFF3B82F6),
                            title: 'سياسة الخصوصية والشروط',
                            subtitle: 'معلومات الخصوصية، حماية البيانات، وإخلاء المسؤولية',
                            isDark: isDark,
                            onTap: () => _showPrivacyPolicyDialog(context),
                          ),
                          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          _buildActionTile(
                            icon: Icons.delete_forever_rounded,
                            color: const Color(0xFFDC2626),
                            title: 'حذف الحساب نهائياً',
                            subtitle: 'مسح كافة بياناتك وسجلاتك من السيرفر',
                            isDark: isDark,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.deleteAccount),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ================= زر تسجيل الخروج الملكي =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _showLogoutDialog(context, authService),
                          borderRadius: BorderRadius.circular(16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'تسجيل الخروج من الحساب',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // مسافة سفلية واسعة لتفادي شريط التنقل السفلي العائم
                const SliverToBoxAdapter(child: SizedBox(height: 125)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= بطاقة الاشتراك الفاخرة وتفاصيل الانتهاء =================
  Widget _buildSubscriptionCard(UserModel user, bool isDark) {
    final isPremium = user.isPremium;
    final expiryDate = user.expiryDate;
    final isExpired = user.isSubscriptionExpired;
    final daysRemaining = user.remainingDays;

    String formattedDate = '';
    if (expiryDate != null) {
      formattedDate = '${expiryDate.year}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.day.toString().padLeft(2, '0')}';
    }

    // الألوان والتدرجات حسب حالة الاشتراك
    final LinearGradient cardGradient;
    final Color borderColor;
    final Color iconBgColor;
    final IconData statusIcon;
    final String titleText;
    final Color titleColor;
    final String subtitleText;
    final String buttonText;
    final Color buttonColor;
    final Color buttonFgColor;

    if (isPremium) {
      cardGradient = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF2E1065)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = _gold.withOpacity(0.4);
      iconBgColor = const Color(0xFFFACC15);
      statusIcon = Icons.workspace_premium_rounded;
      titleText = 'باقة دراسية مميزة 👑';
      titleColor = _gold;
      if (expiryDate != null) {
        subtitleText = daysRemaining > 365
            ? 'اشتراك دائمي فعال'
            : 'متبقي على الصلاحية: $daysRemaining يوم';
      } else {
        subtitleText = 'اشتراك دائمي فعال مدى الحياة ♾️';
      }
      buttonText = 'إدارة ⚡';
      buttonColor = _gold;
      buttonFgColor = const Color(0xFF0F172A);
    } else if (isExpired) {
      cardGradient = LinearGradient(
        colors: isDark
            ? [const Color(0xFF450A0A), const Color(0xFF1E293B)]
            : [const Color(0xFFFEF2F2), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFEF4444).withOpacity(0.4);
      iconBgColor = const Color(0xFFEF4444);
      statusIcon = Icons.timer_off_rounded;
      titleText = 'انتهت صلاحية اشتراكك ⚠️';
      titleColor = const Color(0xFFEF4444);
      subtitleText = 'انتهى اشتراكك بتاريخ: $formattedDate\nجدّد الآن لفتح جميع المواد والامتحانات';
      buttonText = 'تجديد 🚀';
      buttonColor = const Color(0xFF10B981);
      buttonFgColor = Colors.white;
    } else {
      cardGradient = LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [Colors.white, const Color(0xFFF1F5F9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
      iconBgColor = const Color(0xFF64748B);
      statusIcon = Icons.lock_outline_rounded;
      titleText = 'حساب تجريبي مجاني 🔒';
      titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
      subtitleText = 'قم بالترقية لفتح كامل الملازم وبنوك الامتحانات';
      buttonText = 'ترقية ⚡';
      buttonColor = const Color(0xFF2563EB);
      buttonFgColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? _gold.withOpacity(0.12)
                : (isExpired ? const Color(0xFFEF4444).withOpacity(0.1) : Colors.black.withOpacity(0.04)),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconBgColor.withOpacity(0.3)),
                ),
                child: Icon(
                  statusIcon,
                  color: iconBgColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titleText,
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: isPremium ? Colors.white70 : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.subscription),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonFgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),

          // تفاصيل إضافية مخصصة للطلاب المشتركين تظهر تاريخ الانتهاء والأيام المتبقية بوضوح
          if (isPremium && expiryDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFFFACC15)),
                      const SizedBox(width: 6),
                      Text(
                        'ينتهي في: $formattedDate',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: daysRemaining <= 7
                          ? const Color(0xFFEF4444).withOpacity(0.25)
                          : const Color(0xFF10B981).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          daysRemaining <= 7 ? Icons.hourglass_bottom_rounded : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: daysRemaining <= 7 ? const Color(0xFFF87171) : const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysRemaining > 365 ? 'اشتراك دائمي' : '$daysRemaining يوم متبقي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: daysRemaining <= 7 ? const Color(0xFFF87171) : const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= قسم تخصيص الأفاتار والجنس =================
  Widget _buildAvatarCustomizerSection(
    UserModel user,
    String activeGender,
    AuthService authService,
    bool isDark,
  ) {
    final availableAvatars = AvatarHelper.getAvatarsByGender(activeGender);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF8B5CF6), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تخصيص الأفاتار والجنس',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'حفظ فوري',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // اختيار الجنس (ذكر / أنثى / عام)
          Row(
            children: [
              _buildGenderChip('male', 'ذكر 👦', activeGender, isDark, () {
                setState(() => _currentSelectedGender = 'male');
                authService.updateGenderAndAvatar('male', 'boy_1');
              }),
              const SizedBox(width: 8),
              _buildGenderChip('female', 'أنثى 👧', activeGender, isDark, () {
                setState(() => _currentSelectedGender = 'female');
                authService.updateGenderAndAvatar('female', 'girl_1');
              }),
              const SizedBox(width: 8),
              _buildGenderChip('unspecified', 'عام 🎓', activeGender, isDark, () {
                setState(() => _currentSelectedGender = 'unspecified');
                authService.updateGenderAndAvatar('unspecified', 'general_1');
              }),
            ],
          ),
          const SizedBox(height: 14),

          // قائمة الأفاتارات التفاعلية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: availableAvatars.map((avatar) {
                final isSelected = user.avatarId == avatar.id;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        await authService.updateGenderAndAvatar(activeGender, avatar.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Text(avatar.emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تم اختيار افتار "${avatar.name}" وحفظه بنجاح!',
                                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0F172A),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } catch (e) {
                        // Ignored
                      }
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _gold : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _gold.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: AvatarHelper.buildAvatarWidget(
                            avatarId: avatar.id,
                            gender: avatar.gender,
                            radius: 26,
                            isPremium: isSelected && user.isPremium,
                            showCrown: false,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          avatar.name,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? (isDark ? _gold : const Color(0xFF0F172A))
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(
    String genderKey,
    String label,
    String currentActiveGender,
    bool isDark,
    VoidCallback onTap,
  ) {
    final isSelected = currentActiveGender == genderKey;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  // ================= عناصر الإحصائيات والتفضيلات =================
  Widget _buildSmartStatsSection(String userId, bool isDark) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: SocialService().getSubjectStats(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final double arabicAcc = (stats['arabic'] ?? 0.0).toDouble();
        final double computerAcc = (stats['computer'] ?? 0.0).toDouble();
        final double englishAcc = (stats['english'] ?? 0.0).toDouble();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مستواك ودقتك في المواد',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSubjectProgressBar('اللغة العربية 📖', arabicAcc, const Color(0xFFD97706), isDark),
              const SizedBox(height: 12),
              _buildSubjectProgressBar('الحاسوب 💻', computerAcc, const Color(0xFF2563EB), isDark),
              const SizedBox(height: 12),
              _buildSubjectProgressBar('اللغة الإنكليزية 🇬🇧', englishAcc, const Color(0xFF10B981), isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectProgressBar(String label, double percentage, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            color: color,
            minHeight: 6.5,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSwitchTile(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A)).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المظهر الليلي (Dark Luxury)',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'راحة فائقة للعين أثناء المذاكرة ليلاً',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: settings.isDarkMode,
                activeColor: const Color(0xFF2563EB),
                onChanged: (_) => settings.toggleTheme(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontSizeSelector(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.format_size_rounded, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'حجم خط القراءة في التطبيق',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFontPill(context, settings, 'صغير', 0.85, isDark),
                  _buildFontPill(context, settings, 'افتراضي', 1.0, isDark),
                  _buildFontPill(context, settings, 'كبير', 1.15, isDark),
                  _buildFontPill(context, settings, 'كبير جداً', 1.3, isDark),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontPill(BuildContext context, SettingsProvider settings, String label, double scale, bool isDark) {
    final isSelected = settings.fontScale == scale;
    return GestureDetector(
      onTap: () => settings.setFontScale(scale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}