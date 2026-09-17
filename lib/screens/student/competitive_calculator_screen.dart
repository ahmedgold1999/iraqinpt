import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class CompetitiveCalculatorScreen extends StatefulWidget {
  const CompetitiveCalculatorScreen({super.key});

  @override
  State<CompetitiveCalculatorScreen> createState() => _CompetitiveCalculatorScreenState();
}

class _CompetitiveCalculatorScreenState extends State<CompetitiveCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // الحقول
  final _studentGpaController = TextEditingController(text: '75.0');
  final _firstStudentGpaController = TextEditingController(text: '85.0');
  final _competitiveExamController = TextEditingController(text: '70.0');

  // نوع التقديم
  String _targetDegree = 'master'; // 'master', 'phd', 'diploma'

  // قناة التقديم
  String _channel = 'general'; // 'general', 'private', 'martyrs', 'top_students', 'employees'

  // قيم محسوبة
  double _relativeGpa = 0.0;
  double _weightedGpaScore = 0.0;
  double _weightedExamScore = 0.0;
  double _bonusPoints = 0.0;
  double _finalScore = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateScore();
  }

  @override
  void dispose() {
    _studentGpaController.dispose();
    _firstStudentGpaController.dispose();
    _competitiveExamController.dispose();
    super.dispose();
  }

  void _calculateScore() {
    final studentGpa = double.tryParse(_studentGpaController.text.trim()) ?? 0.0;
    final firstGpa = double.tryParse(_firstStudentGpaController.text.trim()) ?? 0.0;
    final examScore = double.tryParse(_competitiveExamController.text.trim()) ?? 0.0;

    if (studentGpa <= 0 || firstGpa <= 0) {
      setState(() {
        _relativeGpa = 0.0;
        _weightedGpaScore = 0.0;
        _weightedExamScore = 0.0;
        _finalScore = 0.0;
      });
      return;
    }

    // 1. المعدل النسبي: (معدل الطالب / معدل الأول) * 100
    // لا يتجاوز 100% في حال كان الطالب هو الأول
    double relative = (studentGpa / firstGpa) * 100.0;
    if (relative > 100.0) relative = 100.0;

    // 2. الأوزان الرسمية لوزارة التعليم العالي العراقية
    // الماجستير والدكتوراه: 65% للمعدل النسبي + 35% للامتحان التنافسي
    // الدبلوم العالي: 70% للمعدل النسبي + 30% للامتحان التنافسي
    double gpaWeight = 0.65;
    double examWeight = 0.35;

    if (_targetDegree == 'diploma') {
      gpaWeight = 0.70;
      examWeight = 0.30;
    }

    double gpaPart = relative * gpaWeight;
    double examPart = (examScore.clamp(0.0, 100.0)) * examWeight;

    // 3. نقاط المفاضلة الإضافية بحسب القنوات
    double bonus = 0.0;
    if (_channel == 'top_students') {
      bonus = 5.0; // إضافة تقديرية للأوائل
    }

    setState(() {
      _relativeGpa = relative;
      _weightedGpaScore = gpaPart;
      _weightedExamScore = examPart;
      _bonusPoints = bonus;
      _finalScore = (gpaPart + examPart + bonus).clamp(0.0, 105.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'حاسبة المعدل التنافسي والتفاضلي',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'مشاركة النتيجة',
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. بطاقة النتيجة الفاخرة المباشرة
              _buildResultCard(isDark),

              const SizedBox(height: 18),

              // 2. اختيار المرحلة الدراسية المستهدفة
              _buildDegreeSelector(isDark),

              const SizedBox(height: 16),

              // 3. حقول إدخال المعدلات
              _buildInputsCard(isDark),

              const SizedBox(height: 16),

              // 4. محاكي ماذا لو لدرجة التنافسي (Interactive Slider)
              _buildWhatIfSimulator(isDark),

              const SizedBox(height: 16),

              // 5. قناة التقديم
              _buildChannelSelector(isDark),

              const SizedBox(height: 16),

              // 6. دليل المعادلة الوزارية الرسمية
              _buildExplanationCard(isDark),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 1. بطاقة النتيجة الذهبية =================
  Widget _buildResultCard(bool isDark) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_finalScore >= 75) {
      statusText = 'فرصة منافسة ممتازة جداً على مقاعد القبول العام 🟢';
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.stars_rounded;
    } else if (_finalScore >= 65) {
      statusText = 'فرصة جيدة للمنافسة على العام والنفقة الخاصة 🟡';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.thumb_up_rounded;
    } else {
      statusText = 'يُنصح برفع درجة التنافسي لزيادة حظوظ الظفر بالمقعد 🚀';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.35), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFACC15).withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calculate_rounded, color: Color(0xFFFACC15), size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'المعدل التفاضلي النهائي',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _targetDegree == 'master'
                      ? 'ماجستير 🎓'
                      : (_targetDegree == 'phd' ? 'دكتوراه 🎖️' : 'دبلوم عالي 📜'),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFACC15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // الرقم النهائي الكبير
          Text(
            '${_finalScore.toStringAsFixed(2)}%',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFACC15),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          // شريط التقييم التنبؤي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 14),
          // تفصيل الدرجات الموزونة
          Row(
            children: [
              _buildScoreDetailColumn(
                'المعدل النسبي',
                '${_relativeGpa.toStringAsFixed(1)}%',
                const Color(0xFF38BDF8),
              ),
              _buildVerticalDivider(),
              _buildScoreDetailColumn(
                _targetDegree == 'diploma' ? 'وزن المعدل (70%)' : 'وزن المعدل (65%)',
                _weightedGpaScore.toStringAsFixed(2),
                const Color(0xFF818CF8),
              ),
              _buildVerticalDivider(),
              _buildScoreDetailColumn(
                _targetDegree == 'diploma' ? 'التنافسي (30%)' : 'التنافسي (35%)',
                _weightedExamScore.toStringAsFixed(2),
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetailColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.notoKufiArabic(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.12),
    );
  }

  // ================= 2. محدد المرحلة =================
  Widget _buildDegreeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildDegreeTab('master', 'الماجستير 🎓', isDark),
          _buildDegreeTab('phd', 'الدكتوراه 🎖️', isDark),
          _buildDegreeTab('diploma', 'الدبلوم العالي 📜', isDark),
        ],
      ),
    );
  }

  Widget _buildDegreeTab(String key, String title, bool isDark) {
    final isSelected = _targetDegree == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _targetDegree = key;
            _calculateScore();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= 3. حقول إدخال المعدلات =================
  Widget _buildInputsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_document, size: 20, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Text(
                'الدرجات والمعدلات',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // معدل الطالب
          _buildNumberField(
            controller: _studentGpaController,
            label: _targetDegree == 'phd'
                ? 'معدل شهادة الماجستير (من 100)'
                : 'معدل شهادة البكالوريوس (من 100)',
            hint: 'مثال: 76.45',
            icon: Icons.school_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // معدل الطالب الأول
          _buildNumberField(
            controller: _firstStudentGpaController,
            label: 'معدل الطالب الأول على دفعتك في سنة التخرج',
            hint: 'مثال: 85.00',
            icon: Icons.workspace_premium_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // درجة التنافسي
          _buildNumberField(
            controller: _competitiveExamController,
            label: 'درجة الامتحان التنافسي المتوقعة (من 100)',
            hint: 'مثال: 70.0',
            icon: Icons.quiz_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white30 : Colors.grey[400],
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
            ),
          ),
          onChanged: (_) => _calculateScore(),
        ),
      ],
    );
  }

  // ================= 4. محاكي ماذا لو لدرجة التنافسي =================
  Widget _buildWhatIfSimulator(bool isDark) {
    double currentExamVal = double.tryParse(_competitiveExamController.text) ?? 50.0;
    currentExamVal = currentExamVal.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B).withOpacity(0.5), const Color(0xFF1E293B)]
              : [const Color(0xFFEFF6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'محاكي درجات التنافسي (ماذا لو؟)',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                '${currentExamVal.toInt()} / 100',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'حرك المؤشر لتجربة درجات مختلفة للامتحان ومشاهدة أثرها على معدلك النهائي فوراً',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2563EB),
              inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[200],
              thumbColor: const Color(0xFFFACC15),
              overlayColor: const Color(0xFFFACC15).withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: currentExamVal,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (val) {
                setState(() {
                  _competitiveExamController.text = val.toInt().toString();
                  _calculateScore();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= 5. قنوات التقديم =================
  Widget _buildChannelSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, size: 20, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text(
                'قناة التقديم والامتيازات',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            items: const [
              DropdownMenuItem(value: 'general', child: Text('القبول العام (قناة عامة)')),
              DropdownMenuItem(value: 'private', child: Text('النفقة الخاصة')),
              DropdownMenuItem(value: 'top_students', child: Text('الأوائل على الكليات والأقسام (+5 نقاط تفاضلية)')),
              DropdownMenuItem(value: 'martyrs', child: Text('قناة ذوي الشهداء وضحايا الإرهاب')),
              DropdownMenuItem(value: 'employees', child: Text('قناة الموظفين والملاكات الحكومية')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _channel = val;
                  _calculateScore();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= 6. دليل المعادلة الوزارية =================
  Widget _buildExplanationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'كيف تحسب الوزارة المعدل التنافسي؟',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '1. يتم أولاً حساب المعدل النسبي:\n'
            'المعدل النسبي = (معدل الطالب ÷ معدل الطالب الأول) × 100\n\n'
            '2. تؤخذ نسبة 65% من المعدل النسبي للماجستير والدكتوراه (و70% للدبلوم العالي).\n\n'
            '3. تؤخذ نسبة 35% من درجة الامتحان التنافسي (و30% للدبلوم العالي).\n\n'
            '4. المجموع التفاضلي النهائي = (وزن المعدل + وزن الامتحان التنافسي + نقاط المفاضلة).',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.5,
              height: 1.6,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResult() {
    final text = '🧮 نتيجتي في حاسبة المعدل التنافسي الوزاري:\n'
        '• المرحلة: ${_targetDegree == 'master' ? 'ماجستير' : (_targetDegree == 'phd' ? 'دكتوراه' : 'دبلوم عالي')}\n'
        '• المعدل النسبي: ${_relativeGpa.toStringAsFixed(2)}%\n'
        '• درجة التنافسي: ${_competitiveExamController.text}\n'
        '• المعدل التفاضلي النهائي: ${_finalScore.toStringAsFixed(2)}%\n\n'
        'تم الحساب عبر تطبيق الامتحان الوطني للدراسات العليا 🎓';

    Share.share(text);
  }
}
