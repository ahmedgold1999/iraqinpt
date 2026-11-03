import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/specialized_exam_model.dart';
import '../../services/specialized_exam_service.dart';

class SpecializedExamsManagementScreen extends StatefulWidget {
  const SpecializedExamsManagementScreen({super.key});

  @override
  State<SpecializedExamsManagementScreen> createState() => _SpecializedExamsManagementScreenState();
}

class _SpecializedExamsManagementScreenState extends State<SpecializedExamsManagementScreen> {
  final SpecializedExamService _examService = SpecializedExamService();
  String _selectedFilterSubject = 'all'; // 'all', 'arabic', 'computer', 'english'
  bool _isSyncing = false;
  bool _isBatchChecking = false;

  /// فحص شامل لجميع روابط الاختبارات وتحديث عداد الوقت والأسئلة تلقائياً بمعدل 40 ثانية لكل سؤال
  Future<void> _runComprehensiveAuditAndFix() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('فحص شامل وضبط التوقيت', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'سيقوم النظام الآن بفحص جميع روابط ملفات الـ JSON في السحابة و GitHub لكافة الاختبارات التخصصية، وحساب عدد الأسئلة بدقة، وضبط وقت كل اختبار تلقائياً بمعدل (40 ثانية لكل سؤال) وتصحيح أي خطأ.\n\nهل تريد البدء الآن؟',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بدء الفحص الشامل 🚀', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBatchChecking = true);

    int total = 0;
    int current = 0;
    String currentTitle = '';
    StateSetter? setProgressState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          setProgressState = setStateModal;
          final double progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.manage_search_rounded, size: 48, color: Color(0xFF2563EB)),
                  const SizedBox(height: 14),
                  const Text(
                    'جاري الفحص الشامل وتحديث التوقيت...',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: total > 0 ? progress : null,
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    total > 0 ? 'تم فحص $current من إجمالي $total اختبار' : 'جاري جلب قائمة الاختبارات...',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5, color: Colors.grey),
                  ),
                  if (currentTitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      currentTitle,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    int updatedCount = 0;
    int successCount = 0;
    int failedCount = 0;
    List<Map<String, String>> failedExams = [];

    try {
      final snapshot = await FirebaseFirestore.instance.collection('specialized_exams').get();
      final docs = snapshot.docs;
      total = docs.length;
      if (setProgressState != null) setProgressState!(() {});

      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data();
        final examTitle = data['title'] ?? 'بدون عنوان';
        final jsonUrl = (data['jsonUrl'] ?? '').toString().trim();
        final existingCount = (data['questionsCount'] as num?)?.toInt() ?? 0;
        final existingDuration = (data['durationMinutes'] as num?)?.toInt() ?? 0;

        current = i + 1;
        currentTitle = examTitle;
        if (setProgressState != null) setProgressState!(() {});

        if (jsonUrl.isEmpty) {
          failedCount++;
          failedExams.add({'title': examTitle, 'error': 'الرابط فارغ'});
          continue;
        }

        final res = await SpecializedExamService.validateAndPreviewJson(jsonUrl);
        if (res['success'] == true) {
          successCount++;
          final count = res['count'] as int;
          // حساب الوقت بالدقائق استناداً لقاعدة 40 ثانية لكل سؤال
          final calculatedMinutes = count > 0 ? (count * 40 / 60).ceil() : existingDuration;

          // إذا كان الوقت الحالي خطأ أو عدد الأسئلة مختلف يتم التعديل في فايربيس فوراً
          if (calculatedMinutes != existingDuration || count != existingCount) {
            await doc.reference.update({
              'questionsCount': count,
              'durationMinutes': calculatedMinutes,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            updatedCount++;
          }
        } else {
          failedCount++;
          failedExams.add({'title': examTitle, 'error': res['error']?.toString() ?? 'فشل الاتصال'});
        }
      }
    } catch (e) {
      debugPrint('Error in comprehensive audit: $e');
    } finally {
      if (mounted) {
        Navigator.pop(context); // إغلاق حوار التقدم
        setState(() => _isBatchChecking = false);

        // إظهار تقرير النتائج
        _showAuditReportDialog(
          total: total,
          updated: updatedCount,
          success: successCount,
          failed: failedCount,
          failedList: failedExams,
        );
      }
    }
  }

  void _showAuditReportDialog({
    required int total,
    required int updated,
    required int success,
    required int failed,
    required List<Map<String, String>> failedList,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'تقرير الفحص الشامل وضبط الوقت',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportStatTile(
                  icon: Icons.all_inbox_rounded,
                  color: const Color(0xFF2563EB),
                  title: 'إجمالي الاختبارات التي تم فحصها',
                  value: '$total اختبار',
                ),
                const SizedBox(height: 8),
                _buildReportStatTile(
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'اختبارات تم تصحيح وضبط توقيتها',
                  value: '$updated اختبار (بمعدل 40ث/سؤال)',
                ),
                const SizedBox(height: 8),
                _buildReportStatTile(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF22C55E),
                  title: 'روابط سليمة ومطابقة',
                  value: '$success اختبار',
                ),
                if (failed > 0) ...[
                  const SizedBox(height: 8),
                  _buildReportStatTile(
                    icon: Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    title: 'روابط بها أخطاء أو تعذر جلبها',
                    value: '$failed اختبار',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'قائمة الاختبارات التي بها أخطاء في الروابط:',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 6),
                  ...failedList.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ${f['title']}', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${f['error']}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً، تم الفحص بنجاح ✨', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5, color: color),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, dynamic>> _subjectMeta = {
    'computer': {
      'name': 'الحاسوب',
      'icon': Icons.computer_rounded,
      'color': const Color(0xFF3B82F6),
    },
    'arabic': {
      'name': 'اللغة العربية',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF22C55E),
    },
    'english': {
      'name': 'اللغة الإنجليزية',
      'icon': Icons.language_rounded,
      'color': const Color(0xFFF59E0B),
    },
  };

  void _showAddEditExamDialog({SpecializedExamModel? existingExam}) {
    final isEdit = existingExam != null;
    final titleController = TextEditingController(text: existingExam?.title ?? '');
    final descController = TextEditingController(text: existingExam?.description ?? '');
    final urlController = TextEditingController(text: existingExam?.jsonUrl ?? '');
    final countController = TextEditingController(
      text: existingExam != null ? existingExam.questionsCount.toString() : '0',
    );
    final durationController = TextEditingController(
      text: existingExam != null ? existingExam.durationMinutes.toString() : '30',
    );
    final orderController = TextEditingController(
      text: existingExam != null ? existingExam.order.toString() : '0',
    );
    final emojiController = TextEditingController(
      text: existingExam?.iconEmoji ?? '📝',
    );

    String selectedSubject = existingExam?.subjectKey ??
        (_selectedFilterSubject != 'all' ? _selectedFilterSubject : 'computer');
    bool isActive = existingExam?.isActive ?? true;

    bool isValidating = false;
    String? validationMessage;
    bool validationSuccess = false;
    Map<String, dynamic>? sampleData;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 540,
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                            color: const Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'تعديل الاختبار التخصصي' : 'إضافة اختبار تخصصي جديد',
                                style: GoogleFonts.notoKufiArabic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                'ربط ملف JSON من GitHub ليتم تحميله أوفلاين للطلاب',
                                style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // اختيار المادة
                    const Text(
                      'المادة التابع لها الاختبار:',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: _subjectMeta.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Row(
                                children: [
                                  Icon(e.value['icon'] as IconData, color: e.value['color'] as Color, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    e.value['name'] as String,
                                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedSubject = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // إيموجي وأيقونة الاختبار
                    const Text(
                      'أيقونة الاختبار (إيموجي آيفون مميز):',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                          ),
                          child: Text(
                            emojiController.text.trim().isEmpty ? '📝' : emojiController.text.trim(),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: emojiController,
                            label: 'رمز الإيموجي (أدخل إيموجي أو اختر من المقترحات)',
                            hint: '📝',
                            icon: Icons.emoji_emotions_outlined,
                            isDark: isDark,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          '📝', '💻', '⌨️', '📚', '⚡', '🎯', '🧠', '🔍', '📖', '🏆', '🌟', '💡', '⏱️', '🎓', '🔥', '📊', '🌐', '🚀'
                        ].map((em) {
                          final isSel = emojiController.text.trim() == em;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  emojiController.text = em;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF2563EB).withOpacity(0.2)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF2563EB) : Colors.transparent,
                                  ),
                                ),
                                child: Text(em, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // عنوان الاختبار
                    _buildTextField(
                      controller: titleController,
                      label: 'عنوان الاختبار (مثال: اختصارات لوحة المفاتيح Ctrl +)',
                      hint: 'مثال: أسئلة الهمزات وقواعد الإملاء',
                      icon: Icons.title_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // وصف الاختبار
                    _buildTextField(
                      controller: descController,
                      label: 'وصف مختصر للاختبار',
                      hint: 'مثال: تدريب مكثف على كافة الاختصارات الوزارية الشائعة',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // رابط ملف الـ JSON
                    _buildTextField(
                      controller: urlController,
                      label: 'رابط ملف JSON (سيرفر السحابة الآمن أو مسار الملف أو GitHub)',
                      hint: 'مثال: english/ProficiencyandConversational أو رابط السيرفر',
                      icon: Icons.security_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // زر فحص الرابط ومعاينة الأسئلة
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: isValidating
                              ? null
                              : () async {
                                  final url = urlController.text.trim();
                                  if (url.isEmpty) {
                                    setDialogState(() {
                                      validationMessage = 'يرجى إدخال رابط JSON أولاً';
                                      validationSuccess = false;
                                    });
                                    return;
                                  }

                                  setDialogState(() {
                                    isValidating = true;
                                    validationMessage = null;
                                  });

                                  final res = await SpecializedExamService.validateAndPreviewJson(url);

                                  setDialogState(() {
                                    isValidating = false;
                                    validationSuccess = res['success'] == true;
                                    if (validationSuccess) {
                                      final count = res['count'] as int;
                                      countController.text = count.toString();
                                      // ⏱️ حساب الوقت بالدقائق تلقائياً: كل سؤال 40 ثانية
                                      final calculatedMinutes = count > 0 ? (count * 40 / 60).ceil() : 0;
                                      durationController.text = calculatedMinutes.toString();
                                      validationMessage = '✅ تم فحص الملف بنجاح! تم العثور على $count سؤالاً ($calculatedMinutes دقيقة بمعدل 40 ثانية لكل سؤال).';
                                      sampleData = res;
                                    } else {
                                      validationMessage = '❌ ${res['error']}';
                                      sampleData = null;
                                    }
                                  });
                                },
                          icon: isValidating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(
                            isValidating ? 'جاري الفحص...' : 'فحص الرابط واستخراج الأسئلة',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    if (validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: validationSuccess
                              ? const Color(0xFF22C55E).withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validationSuccess ? const Color(0xFF22C55E).withOpacity(0.3) : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          validationMessage!,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: validationSuccess ? const Color(0xFF22C55E) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],

                    if (sampleData != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'عينة من السؤال الأول:',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '❓ ${sampleData!['sampleQuestion']}',
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الإجابة الصحيحة: ${sampleData!['sampleAnswer']}',
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF22C55E)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // الأرقام: عدد الأسئلة والمدة والترتيب
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: countController,
                            label: 'عدد الأسئلة',
                            hint: '30',
                            icon: Icons.format_list_numbered_rounded,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final count = int.tryParse(val.trim());
                              if (count != null && count > 0) {
                                final calculatedMinutes = (count * 40 / 60).ceil();
                                durationController.text = calculatedMinutes.toString();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: durationController,
                            label: 'المدة (بالدقائق)',
                            hint: 'محسوبة تلقائياً',
                            icon: Icons.timer_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: orderController,
                            label: 'الترتيب',
                            hint: '0',
                            icon: Icons.sort_rounded,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // مفتاح تفعيل الاختبار
                    Row(
                      children: [
                        Switch(
                          value: isActive,
                          activeColor: const Color(0xFF22C55E),
                          onChanged: (val) => setDialogState(() => isActive = val),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'الاختبار مفعل ومتاح للطلاب' : 'الاختبار معطل ومخفي عن الطلاب',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF22C55E) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // أزرار الحفظ والإلغاء
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final jsonUrl = urlController.text.trim();
                              final count = int.tryParse(countController.text.trim()) ?? 0;
                              final duration = int.tryParse(durationController.text.trim()) ??
                                  (count > 0 ? (count * 40 / 60).ceil() : 30);
                              final order = int.tryParse(orderController.text.trim()) ?? 0;

                              if (title.isEmpty || jsonUrl.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى ملء عنوان الاختبار ورابط JSON على الأقل', style: TextStyle(fontFamily: 'Tajawal')),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              final examEmoji = emojiController.text.trim().isEmpty ? '📝' : emojiController.text.trim();
                              final examModel = SpecializedExamModel(
                                id: isEdit ? existingExam.id : '',
                                subjectKey: selectedSubject,
                                subjectName: _subjectMeta[selectedSubject]?['name'] ?? '',
                                title: title,
                                description: descController.text.trim(),
                                jsonUrl: jsonUrl,
                                questionsCount: count,
                                durationMinutes: duration,
                                iconEmoji: examEmoji,
                                order: order,
                                isActive: isActive,
                                createdAt: isEdit ? existingExam.createdAt : DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              Navigator.pop(ctx);

                              if (isEdit) {
                                await _examService.updateExam(examModel);
                              } else {
                                await _examService.createExam(examModel);
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit ? 'تم تحديث الاختبار بنجاح ✨' : 'تم إضافة الاختبار وحفظه أوفلاين بنجاح 🚀',
                                      style: const TextStyle(fontFamily: 'Tajawal'),
                                    ),
                                    backgroundColor: const Color(0xFF22C55E),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isEdit ? 'حفظ التعديلات' : 'إضافة وحفظ الاختبار 🚀',
                              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
            decoration: InputDecoration(
              icon: Icon(icon, size: 18, color: Colors.grey),
              hintText: hint,
              hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteExam(SpecializedExamModel exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الاختبار التخصصي', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(
          'هل أنت متأكد من حذف اختبار "${exam.title}"؟ سيتم حذفه من التطبيق ومن ذاكرة الهاتف أيضاً.',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _examService.deleteExam(exam.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الاختبار بنجاح', style: TextStyle(fontFamily: 'Tajawal'))),
                );
              }
            },
            child: const Text('نعم، حذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _syncAllNow() async {
    setState(() => _isSyncing = true);
    await _examService.syncAllExamsOffline();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ تمت مزامنة كافة الاختبارات التخصصية والأسئلة محلياً في الهاتف بنجاح!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131C31) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'إدارة الاختبارات التخصصية والفرعية',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync_rounded, color: Color(0xFF22C55E)),
            tooltip: 'مزامنة أوفلاين الآن',
            onPressed: _isSyncing ? null : _syncAllNow,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // شريط المواد والأزرار أسفله
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // المواد
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterPill('all', 'جميع المواد'),
                      const SizedBox(width: 6),
                      _buildFilterPill('computer', '💻 الحاسوب'),
                      const SizedBox(width: 6),
                      _buildFilterPill('arabic', '📖 العربي'),
                      const SizedBox(width: 6),
                      _buildFilterPill('english', '🇬🇧 الإنكليزي'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // أزرار العمليات أسفل المواد
                Row(
                  children: [
                    // زر إضافة اختبار
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => _showAddEditExamDialog(),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text(
                          'إضافة اختبار ➕',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // زر فحص الروابط وتحديث الوقت الشامل
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isBatchChecking ? null : _runComprehensiveAuditAndFix,
                        icon: _isBatchChecking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: Text(
                          _isBatchChecking ? 'جاري الفحص...' : 'فحص الروابط وضبط الوقت ⏱️',
                          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة الاختبارات التخصصية
          Expanded(
            child: StreamBuilder<List<SpecializedExamModel>>(
              stream: _examService.streamAllExamsForAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var exams = snapshot.data ?? [];
                if (_selectedFilterSubject != 'all') {
                  exams = exams.where((e) => e.subjectKey == _selectedFilterSubject).toList();
                }

                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_clear_rounded, size: 54, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 14),
                        Text(
                          'لا توجد اختبارات تخصصية مضافة حالياً',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط على زر "إضافة اختبار ➕" لإضافة اختبار جديد برابط JSON من GitHub.',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return _buildAdminExamCard(exam, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilterSubject == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilterSubject = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminExamCard(SpecializedExamModel exam, bool isDark) {
    final cardBg = isDark ? const Color(0xFF131C31) : Colors.white;
    final meta = _subjectMeta[exam.subjectKey] ?? _subjectMeta['computer']!;
    final Color subjectColor = meta['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: exam.isActive
              ? (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: subjectColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta['icon'] as IconData, size: 14, color: subjectColor),
                      const SizedBox(width: 4),
                      Text(
                        meta['name'] as String,
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: subjectColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: exam.isActive ? const Color(0xFF22C55E).withOpacity(0.12) : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exam.isActive ? 'مفعل للطلاب' : 'معطل ومخفي',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: exam.isActive ? const Color(0xFF22C55E) : Colors.redAccent,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: exam.isActive,
                  activeColor: const Color(0xFF22C55E),
                  onChanged: (val) => _examService.toggleExamStatus(exam.id, exam.isActive),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  exam.iconEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.title,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
// تم إخفاء الوصف من كارد العرض للإدارة للتركيز على باقي البيانات
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInfoBadge('${exam.questionsCount} سؤال', Icons.quiz_outlined),
                const SizedBox(width: 6),
                _buildInfoBadge('${exam.durationMinutes} دقيقة', Icons.schedule_rounded),
                const SizedBox(width: 6),
                _buildInfoBadge('ترتيب: ${exam.order}', Icons.sort_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exam.jsonUrl,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                  tooltip: 'تعديل',
                  onPressed: () => _showAddEditExamDialog(existingExam: exam),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  tooltip: 'حذف',
                  onPressed: () => _confirmDeleteExam(exam),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
