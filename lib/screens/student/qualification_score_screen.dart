import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpecializationRequirement {
  final String title;
  final int requiredScore;
  final String details;
  final String levelDescriptor;

  const SpecializationRequirement({
    required this.title,
    required this.requiredScore,
    required this.details,
    required this.levelDescriptor,
  });
}

class ExamTrackData {
  final String id;
  final String title;
  final String examName;
  final IconData icon;
  final Color color;
  final List<SpecializationRequirement> specializations;

  const ExamTrackData({
    required this.id,
    required this.title,
    required this.examName,
    required this.icon,
    required this.color,
    required this.specializations,
  });
}

class QualificationScoreScreen extends StatefulWidget {
  const QualificationScoreScreen({super.key});

  @override
  State<QualificationScoreScreen> createState() => _QualificationScoreScreenState();
}

class _QualificationScoreScreenState extends State<QualificationScoreScreen> {
  static const List<ExamTrackData> _tracks = [
    ExamTrackData(
      id: 'arabic',
      title: 'اللغة العربية وآدابها',
      examName: 'اختبار اللغة العربية (الكفاءة الجامعية)',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF10B981),
      specializations: [
        SpecializationRequirement(
          title: 'ماجستير - كافة التخصصات (عدا اللغة العربية)',
          requiredScore: 50,
          details: 'الحد الأدنى لاجتياز المادة: 50 درجة من 100، يشترط الإلمام بقواعد النحو والصرف الأساسية.',
          levelDescriptor: 'مستوى أساسي B1',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - كافة التخصصات (عدا اللغة العربية)',
          requiredScore: 55,
          details: 'يتطلب درجة 55 فما فوق، مع قدرة على التحليل الأدبي والنقدي لنصوص متوسطة.',
          levelDescriptor: 'مستوى متوسط B2',
        ),
        SpecializationRequirement(
          title: 'ماجستير - تخصص لغة عربية وآدابها',
          requiredScore: 60,
          details: 'يُشترط تحصيل 60 درجة، إجادة البلاغة والنقد، والكتابة الأكاديمية المتقدمة.',
          levelDescriptor: 'مستوى متقدم C1',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - تخصص لغة عربية وآدابها',
          requiredScore: 70,
          details: 'درجة 70 كحد أدنى، ويتطلب إتقان فائق للتراث اللغوي والبحث العلمي الرصين.',
          levelDescriptor: 'مستوى خبير C2+',
        ),
      ],
    ),
    ExamTrackData(
      id: 'computer',
      title: 'كفاءة الحاسوب (ICDL)',
      examName: 'امتحان كفاءة الحاسوب (تطبيقات متخصصة)',
      icon: Icons.computer_rounded,
      color: Color(0xFF0284C7),
      specializations: [
        SpecializationRequirement(
          title: 'ماجستير - التخصصات الإنسانية (آداب، فنون، قانون)',
          requiredScore: 50,
          details: 'اجتياز أساسيات الحاسوب، معالجة النصوص، العروض التقديمية، درجة النجاح 50.',
          levelDescriptor: 'مهارات أساسية',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - التخصصات الإنسانية',
          requiredScore: 55,
          details: 'يتطلب 55 درجة، مع إجادة قواعد البيانات البسيطة والبحث الرقمي.',
          levelDescriptor: 'متوسط المهارات الرقمية',
        ),
        SpecializationRequirement(
          title: 'ماجستير - التخصصات العلمية (علوم، رياضيات، زراعة)',
          requiredScore: 60,
          details: 'درجة النجاح 60، إتقان جداول متقدمة، تحليل بيانات باستخدام Excel متقدم.',
          levelDescriptor: 'مستوى علمي متقدم',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - التخصصات العلمية (هندسة، علوم حياة)',
          requiredScore: 65,
          details: 'يتطلب 65 درجة، القدرة على برمجة بسيطة أو التعامل مع بيئات المحاكاة.',
          levelDescriptor: 'مستوى احترافي',
        ),
        SpecializationRequirement(
          title: 'ماجستير - تخصص علوم حاسوب / نظم معلومات',
          requiredScore: 70,
          details: 'درجة النجاح 70، إجادة الخوارزميات، قواعد البيانات، وإدارة الشبكات الأساسية.',
          levelDescriptor: 'متقدم تقني C1',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - تخصص حاسوب / ذكاء اصطناعي',
          requiredScore: 75,
          details: 'يُشترط 75 درجة، ويتطلب مشاريع برمجية وتحليل خوارزميات معقدة.',
          levelDescriptor: 'خبير في الحوسبة',
        ),
      ],
    ),
    ExamTrackData(
      id: 'english',
      title: 'اللغة الإنجليزية (INELT)',
      examName: 'INELT – الاختبار الدولي للغة الإنجليزية (كفاءة أكاديمية)',
      icon: Icons.language_rounded,
      color: Color(0xFF2563EB),
      specializations: [
        SpecializationRequirement(
          title: 'دبلوم عالي (علمية / إنسانية)',
          requiredScore: 50,
          details: 'المطلوب درجة 50، مستوى A1 حسب الإطار الأوروبي، قدرة على الفهم البسيط.',
          levelDescriptor: 'A1 (مبتدئ متقدم)',
        ),
        SpecializationRequirement(
          title: 'ماجستير - تخصصات إنسانية (عدا اللغة الإنجليزية)',
          requiredScore: 50,
          details: '50 درجة مع إتقان أساسيات القراءة والاستيعاب، مستوى A2 تقريباً.',
          levelDescriptor: 'A2 – أساسي',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - إنسانية (عدا الإنجليزية)',
          requiredScore: 55,
          details: '55 درجة، قدرة على قراءة المقالات الأكاديمية وكتابة ملخصات بسيطة. مستوى A2/B1',
          levelDescriptor: 'A2/B1',
        ),
        SpecializationRequirement(
          title: 'ماجستير - علمية (تربية، زراعة، رياضة، سياحة)',
          requiredScore: 60,
          details: 'درجة 60، مستوى B1، فهم نصوص تخصصية ومحادثة متوسطة.',
          levelDescriptor: 'B1 (متوسط)',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - علمية (تربية، زراعة، رياضة، سياحة)',
          requiredScore: 65,
          details: '65 درجة، مستوى B2، إجادة مناقشة الأبحاث وإعداد عروض باللغة الإنجليزية.',
          levelDescriptor: 'B2 (متوسط مرتفع)',
        ),
        SpecializationRequirement(
          title: 'ماجستير - علمية (هندسة، طب، صيدلة، علوم)',
          requiredScore: 65,
          details: 'يتطلب 65 درجة، مستوى B2 متقدم، وفهم المصطلحات الطبية والهندسية.',
          levelDescriptor: 'B2+',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - علمية (هندسة، طب، صيدلة، علوم)',
          requiredScore: 70,
          details: 'درجة 70 كحد أدنى، مستوى C1، تحليل الأبحاث وكتابة مقالات علمية رصينة.',
          levelDescriptor: 'C1 (متقدم)',
        ),
        SpecializationRequirement(
          title: 'ماجستير - تخصص لغة إنجليزية / ترجمة',
          requiredScore: 70,
          details: '70 درجة، مستوى C1 احترافي، إجادة الترجمة التحريرية والشفوية المتقدمة.',
          levelDescriptor: 'C1 – ترجمة',
        ),
        SpecializationRequirement(
          title: 'دكتوراه - تخصص لغة إنجليزية / أدب وترجمة',
          requiredScore: 75,
          details: '75 درجة مطلوبة، مستوى C2 (إتقان تام)، كتابة أبحاث دولية وتحليل أدبي نقدي.',
          levelDescriptor: 'C2 (إجادة خبيرة)',
        ),
        SpecializationRequirement(
          title: 'دكتوراه طبية والبورد العراقي (جميع الاختصاصات)',
          requiredScore: 75,
          details: 'درجة النجاح 75، مستوى C2، ضروري للابتعاث والزمالات الدولية.',
          levelDescriptor: 'C2 – معياري دولي',
        ),
      ],
    ),
  ];

  int _selectedTrackIndex = 0;
  int? _selectedSpecIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTrack = _tracks[_selectedTrackIndex];

    final filteredSpecs = _searchQuery.trim().isEmpty
        ? currentTrack.specializations
        : currentTrack.specializations.where((s) {
            return s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.details.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.levelDescriptor.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    final selectedSpec = (_selectedSpecIndex != null &&
            _selectedSpecIndex! < currentTrack.specializations.length)
        ? currentTrack.specializations[_selectedSpecIndex!]
        : null;

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
          'معرفة درجة التأهيل',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👑 Royal Header Banner
            _buildRoyalHeader(isDark),
            const SizedBox(height: 18),

            // 🗂️ Subject Selector Tabs
            Text(
              '1. اختر الاختبار التخصصي:',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildTrackSelector(isDark),
            const SizedBox(height: 18),

            // 🎓 Specialization Dropdown / List
            Text(
              '2. اختر التخصص والدرجة العلمية:',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildSpecializationSelector(
              currentTrack: currentTrack,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 18),

            // 🏆 Detailed Result Pavilion
            if (selectedSpec != null)
              _buildResultPavilion(
                track: currentTrack,
                spec: selectedSpec,
                isDark: isDark,
              ),

            const SizedBox(height: 18),

            // 📜 All Specializations Quick Reference Table
            _buildQuickReferenceList(
              track: currentTrack,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),

            const SizedBox(height: 20),

            // Footer note
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFFD4AF37), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تعتمد هذه المعايير رسمياً وفق دليل ضوابط التقديم للدراسات العليا في الجامعات العراقية.',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoyalHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1927), Color(0xFF102B3F), Color(0xFF1A3D54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1927).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_rounded, color: Color(0xFFD4AF37), size: 24),
              const SizedBox(width: 8),
              Text(
                'معرفة درجة التأهل في الامتحان',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF9E0A0),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            ),
            child: const Text(
              '⚜️ دليل الدراسات العليا المعتمد ⚜️',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Color(0xFFB8D0E5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackSelector(bool isDark) {
    return Row(
      children: List.generate(_tracks.length, (index) {
        final track = _tracks[index];
        final isSelected = _selectedTrackIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTrackIndex = index;
                _selectedSpecIndex = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(left: index != 0 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? track.color
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? track.color
                      : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: track.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    track.icon,
                    size: 22,
                    color: isSelected ? Colors.white : track.color,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpecializationSelector({
    required ExamTrackData currentTrack,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedSpecIndex,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4AF37), size: 26),
          dropdownColor: cardBg,
          borderRadius: BorderRadius.circular(18),
          items: List.generate(currentTrack.specializations.length, (index) {
            final spec = currentTrack.specializations[index];
            return DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${spec.requiredScore}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spec.title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSpecIndex = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultPavilion({
    required ExamTrackData track,
    required SpecializationRequirement spec,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFEFBF0), const Color(0xFFF7F3E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of result card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, color: track.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'المادة المعتمدة',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF1E3B2F),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0F1A24)),
                    SizedBox(width: 4),
                    Text(
                      'معتمد من الوزارة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F1A24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            track.examName,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F2C3D),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 16, color: Color(0xFFD4AF37)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    spec.title,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF1F3B4C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Score & Level Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الدرجة المطلوبة للنجاح',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${spec.requiredScore}',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFC67C2E),
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ 100',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102B3F).withOpacity(isDark ? 0.5 : 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF102B3F).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مستوى الكفاءة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102B3F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          spec.levelDescriptor,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE8B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Details breakdown card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 6),
                    Text(
                      '📋 تفصيل المادة والمتطلبات الأكاديمية:',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E3B2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  spec.details,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReferenceList({
    required ExamTrackData track,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_rounded, size: 18, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text(
                'جدول كافة تخصصات ${track.title}',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: track.specializations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = track.specializations[index];
              final isCurrent = _selectedSpecIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSpecIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFD4AF37).withOpacity(0.12)
                        : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFD4AF37)
                          : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0)),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s.requiredScore}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1927),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              s.levelDescriptor,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
