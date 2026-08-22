import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutNationalExamScreen extends StatelessWidget {
  const AboutNationalExamScreen({super.key});

  static const String _bookingUrl = 'https://inpt.rdd.edu.iq';

  Future<void> _openBookingLink(BuildContext context) async {
    try {
      final uri = Uri.parse(_bookingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر فتح الرابط، يرجى المحاولة لاحقاً', style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: primaryTextColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'دليل الامتحان الوطني العراقي',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Hero Banner
            _buildHeroBanner(isDark),
            const SizedBox(height: 18),

            // 1. ما هو الامتحان الوطني؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'ما هو الامتحان الوطني؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'الامتحان الوطني هو اختبار مخصص للطلبة الراغبين بالتقديم إلى الدراسات العليا (ماجستير، دكتوراه، دبلوم عالي)، ويشمل مختلف الأقسام والاختصاصات.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'كان يُعرف سابقاً باسم (امتحان الكفاءة)، أما الآن فأصبح يُعرف رسمياً باسم (الامتحان الوطني).',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'يُطلب من المتقدمين أداء الامتحان في ثلاث مواد:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSubjectTag('🇬🇧 اللغة الإنجليزية', isDark),
                            _buildSubjectTag('💻 الحاسوب', isDark),
                            _buildSubjectTag('📖 اللغة العربية', isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '💡 ملاحظة: لا يوجد منهج رسمي موحد لهذه الامتحانات الثلاثة، إذ تعتمد الأسئلة على المعلومات العامة، وجميع الأسئلة بنظام الاختيار من متعدد (MCQ).',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.5,
                      color: secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. درجات النجاح والتأهيل
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.military_tech_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'درجات النجاح والتأهيل',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الامتحان من 100 درجة، وتختلف الدرجة المطلوبة بحسب التخصص والكلية:',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, color: primaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildScoreBadge(
                          title: 'التخصصات الإنسانية',
                          score: '50 فأكثر',
                          subtext: 'درجة النجاح المطلوبة',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildScoreBadge(
                          title: 'التخصصات العلمية',
                          score: '60 فأكثر',
                          subtext: 'أو حسب متطلبات كليتك',
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📌 يتوفر داخل التطبيق جدول يوضح الدرجة المطلوبة لكل تخصص وكلية بدقة.',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. ماذا يوفر لك التطبيق؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.star_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: 'ماذا يوفر لك تطبيق دليل الامتحان الوطني؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يوفر لك التطبيق كل ما تحتاجه للتحضير والاجتياز باقتدار:',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, color: primaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeaturePill('📚 ملازم اللغة الإنجليزية', const Color(0xFF2563EB), isDark),
                      _buildFeaturePill('📖 ملازم اللغة العربية', const Color(0xFF10B981), isDark),
                      _buildFeaturePill('💻 ملازم ومصطلحات الحاسوب', const Color(0xFF0284C7), isDark),
                      _buildFeaturePill('📑 نماذج الفورمات الوزارية', const Color(0xFFF59E0B), isDark),
                      _buildFeaturePill('🎯 بنك الأسئلة والتدريب الذكي', const Color(0xFF8B5CF6), isDark),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '✨ ساعدت هذه المواد آلاف الطلبة في الاستعداد للامتحان الوطني واجتيازه بنجاح.',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. أين يُجرى الامتحان؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'أين يُجرى الامتحان؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'توجد مراكز امتحانية معتمدة في مختلف محافظات العراق (باستثناء إقليم كردستان).',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'لمعرفة وتحديد المركز الامتحاني في محافظتك، يجب إجراء الحجز الإلكتروني عبر الرابط الرسمي.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openBookingLink(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'فتح رابط الحجز الإلكتروني الرسمي',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. هل يجب حجز موعد للامتحان؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.event_available_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'هل يجب حجز موعد للامتحان؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'نعم، يجب إجراء حجز إلكتروني مسبق قبل أداء الامتحان.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'يمكنك اختيار الموعد الذي يناسب استعدادك، فلا يوجد يوم واحد موحد لجميع الطلبة.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'مرونة المواعيد: يمكنك أداء المواد في تواريخ مختلفة (مثلاً: الإنجليزية في يوم، والحاسوب في يوم آخر، والعربية في يوم آخر).',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. ما متطلبات الحجز والرسوم؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFF0284C7),
              title: 'متطلبات الحجز والرسوم',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequirementRow(Icons.badge_outlined, 'البطاقة الوطنية الموحدة', primaryTextColor),
                  const SizedBox(height: 6),
                  _buildRequirementRow(Icons.email_outlined, 'بريد إلكتروني شخصي فعال', primaryTextColor),
                  const SizedBox(height: 6),
                  _buildRequirementRow(Icons.payments_outlined, 'رسوم الامتحان: 30,000 دينار عراقي لكل مادة', primaryTextColor),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💳 طريقة وتوقيت الدفع:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• يتم دفع الرسوم في يوم الامتحان داخل المركز الامتحاني.\n• يُفضّل الحضور قبل موعد الامتحان بحوالي ساعة ونصف لإكمال إجراءات الدفع والحساب.\n• تنبيه: تحتاج إلى بطاقة (Mastercard) لإتمام عملية الدفع داخل المركز.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 7. كيف يكون الامتحان؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.computer_rounded,
              iconColor: const Color(0xFF4F46E5),
              title: 'كيف يُجرى الامتحان؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'يُجرى الامتحان إلكترونياً باستخدام أجهزة الحاسوب في قاعة المركز.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'لا تحتاج إلى مهارات متقدمة في الحاسوب؛ كل ما عليك هو قراءة السؤال واختيار الإجابة باستخدام الماوس.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'جميع الأسئلة بنظام الاختيار من متعدد (Multiple Choice Questions).',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 8. جدول عدد الأسئلة ومدة الامتحان
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF0D9488),
              title: 'عدد الأسئلة ومدة الامتحان',
              content: Column(
                children: [
                  _buildExamRow(
                    subject: 'اللغة الإنجليزية',
                    questions: '40 سؤالاً',
                    duration: 'ساعة واحدة (60 دقيقة)',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildExamRow(
                    subject: 'علوم الحاسوب',
                    questions: '40 سؤالاً',
                    duration: 'ساعة واحدة (60 دقيقة)',
                    color: const Color(0xFF0D9488),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildExamRow(
                    subject: 'اللغة العربية',
                    questions: '60 سؤالاً',
                    duration: 'ساعة واحدة (60 دقيقة)',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 9. متى تظهر النتيجة؟
            _buildSectionCard(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
              icon: Icons.verified_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'متى تظهر النتيجة؟',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'تظهر النتيجة فوراً ومباشرة على شاشة الحاسوب بعد إنهائك للامتحان.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'احرص على استلام وثيقة/ورقة النتيجة والاحتفاظ بها، حيث ستحتاج إليها لإرفاقها ضمن ملف تقديمك للدراسات العليا.',
                    primaryTextColor,
                    secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom CTA button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openBookingLink(context),
                icon: const Icon(Icons.language_rounded, size: 20),
                label: const Text(
                  'انتقل لبوابة الحجز الإلكتروني الرسمية 🚀',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدليل الشامل والموثق',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'كل ما يخص الامتحان الوطني 🇮🇶',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'مرجعك المعتمد لمعرفة طبيعة الاختبارات، الشروط، المواعيد، وآلية الحجز والدرجات المطلوبة للقبول بالدراسات العليا.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color primary, Color secondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.5,
              color: primary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScoreBadge({
    required String title,
    required String score,
    required String subtext,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String title, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
          color: isDark ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamRow({
    required String subject,
    required String questions,
    required String duration,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                subject,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  questions,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                duration,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
