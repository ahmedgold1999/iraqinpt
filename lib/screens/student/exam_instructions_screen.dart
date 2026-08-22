import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamInstructionsScreen extends StatefulWidget {
  const ExamInstructionsScreen({super.key});

  @override
  State<ExamInstructionsScreen> createState() => _ExamInstructionsScreenState();
}

class _ExamInstructionsScreenState extends State<ExamInstructionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFACC15), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F2338)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFACC15).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel_rounded, size: 14, color: Color(0xFFFACC15)),
                              SizedBox(width: 6),
                              Text(
                                'الضوابط والتعليمات الوزارية المعتمدة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFACC15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'دليل وضوابط الامتحان الوطني',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'يرجى قراءة التعليمات بعناية لضمان سير الاختبار وتجنب أي مساءلة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: isDark ? const Color(0xFF131C31) : Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  physics: const BouncingScrollPhysics(),
                  indicatorColor: const Color(0xFFD97706),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFD97706),
                  unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  labelStyle: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(icon: Icon(Icons.bookmark_added_rounded, size: 18), text: 'الحجز والتأكيد'),
                    Tab(icon: Icon(Icons.meeting_room_rounded, size: 18), text: 'داخل القاعة'),
                    Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'حالات الحرمان'),
                    Tab(icon: Icon(Icons.emoji_objects_rounded, size: 18), text: 'نصائح التفوق'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingTab(isDark),
            _buildHallRulesTab(isDark),
            _buildCheatingWarningsTab(isDark),
            _buildTipsTab(isDark),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C31) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF16A34A),
                content: const Text(
                  'نتمنى لك كل التوفيق والنجاح الباهر في الامتحان الوطني! 🌟',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: const Color(0xFFFACC15),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFACC15)),
          label: const Text(
            'أقر بأنني اطلعت وفهمت كافة التعليمات',
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildLuxuryNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'ضوابط تثبيت وتأكيد الحجز',
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          number: '1',
          title: 'المستمسكات الأصلية المطلوبة',
          content: 'يجب جلب البطاقة الوطنية الموحدة الأصلية أو جواز السفر النافذ حصراً عند تأكيد الحجز وأثناء دخول قاعة الامتحان.',
          icon: Icons.badge_rounded,
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '2',
          title: 'مهلة تسديد الرسوم (48 ساعة)',
          content: 'يحق للمركز الامتحاني إلغاء الحجز تلقائياً في حال عدم مراجعة المركز وتسديد أجور الاختبار خلال 48 ساعة من تاريخ إجراء الحجز الإلكتروني.',
          icon: Icons.hourglass_bottom_rounded,
          color: const Color(0xFFD97706),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '3',
          title: 'موعد إغلاق التأكيد النهائي',
          content: 'يُغلق تأكيد الحجز نهائياً قبل ساعة واحدة كاملة من بدء موعد الجلسة الامتحانية.',
          icon: Icons.alarm_off_rounded,
          color: const Color(0xFFDC2626),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '4',
          title: 'الحضور المبكر للمركز',
          content: 'يُنصح بالتواجد في مقر المركز الامتحاني قبل 30 إلى 45 دقيقة من موعد الاختبار لاستلام كارت الدخول وتحديد رقم الحاسوب المخصص.',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF16A34A),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildHallRulesTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildLuxuryNoticeCard(
          icon: Icons.meeting_room_outlined,
          title: 'بروتوكول وضوابط قاعة الاختبار',
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          number: '1',
          title: 'حظر الأجهزة الإلكترونية والهواتف',
          content: 'يُمنع منعاً باتاً إدخال الهواتف الذكية، الساعات الإلكترونية، وسماعات البلوتوث داخل قاعة الاختبار ويجب تسليمها للأمانات.',
          icon: Icons.phonelink_erase_rounded,
          color: const Color(0xFFDC2626),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '2',
          title: 'المقعد والحاسوب المخصص',
          content: 'يلتزم الطالب بالجلوس أمام الحاسوب ورقم المقعد المخصص له في كارت الدخول دون تغييره.',
          icon: Icons.desktop_windows_rounded,
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '3',
          title: 'الهدوء التام وعدم التحدث',
          content: 'يمنع التحدث مع أي زميل داخل القاعة. في حال وجود خلل فني في الحاسوب يرفع الطالب يده لإشعار المشرف الفني فوراً.',
          icon: Icons.volume_off_rounded,
          color: const Color(0xFFD97706),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCheatingWarningsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عقوبة الحرمان وإلغاء الامتحان ⚠️',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'يُحرم الطالب من التقديم للدراسات العليا في حال ثبوت أي من الحالات التالية:',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11.5,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCheatingItem('التكلم أو محاولة التواصل مع طالب آخر أثناء الامتحان.', isDark),
        _buildCheatingItem('النظر إلى شاشة حاسوب طالب آخر أو توجيه شاشتك للغير.', isDark),
        _buildCheatingItem('انتحال الشخصية أو أداء الاختبار نيابة عن شخص آخر (عقوبة قانونية وجنائية).', isDark),
        _buildCheatingItem('استخدام قصاصات ورقية أو وسائل تقنية وسماعات غير مسموح بها.', isDark),
        _buildCheatingItem('استبدال كارت دخول الامتحان أو تداول أسئلة الاختبار.', isDark),
      ],
    );
  }

  Widget _buildTipsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildLuxuryNoticeCard(
          icon: Icons.star_rounded,
          title: 'إرشادات ونصائح ذهبية للتفوق',
          color: const Color(0xFF16A34A),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          number: '1',
          title: 'إدارة الوقت بذكاء',
          content: 'وزّع وقت الاختبار على جميع الأسئلة ولا تتوقف طويلاً عند سؤال يصعب عليك؛ ضع له علامة وانتقل لما يليه ثم عد إليه.',
          icon: Icons.timer_rounded,
          color: const Color(0xFF16A34A),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '2',
          title: 'تأكيد وحفظ الإجابات',
          content: 'تأكد من اختيار الإجابة وحفظها في واجهة النظام قبل الانتقال للسؤال التالي.',
          icon: Icons.save_rounded,
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildStepCard(
          number: '3',
          title: 'المراجعة قبل إنهاء الجلسة',
          content: 'لا تضغط على زر إنهاء الاختبار النهائي إلا بعد مراجعة شريط الأسئلة والتأكد من إجابة كل النقاط.',
          icon: Icons.fact_check_rounded,
          color: const Color(0xFFD97706),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildLuxuryNoticeCard({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheatingItem(String text, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
